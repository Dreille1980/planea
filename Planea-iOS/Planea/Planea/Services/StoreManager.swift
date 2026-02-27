import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var subscriptionInfo: SubscriptionInfo?
    
    private var updateListenerTask: Task<Void, Error>?
    
    // Developer access codes (stored in keychain for security)
    private let developerAccessKey = "com.planea.developer.access"
    private let validAccessCodes = ["PLANEA_FAMILY_2025", "DEV_ACCESS_UNLIMITED"]
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            let productIDs = SubscriptionProduct.allCases.map { $0.rawValue }
            print("🔍 [StoreManager] Loading products with IDs: \(productIDs)")
            products = try await Product.products(for: productIDs)
            print("✅ [StoreManager] Successfully loaded \(products.count) products")
            for product in products {
                print("   - \(product.id): \(product.displayName) - \(product.displayPrice)")
            }
            if products.isEmpty {
                print("⚠️ [StoreManager] WARNING: No products loaded! Check StoreKit configuration.")
            }
        } catch {
            print("❌ [StoreManager] Failed to load products: \(error.localizedDescription)")
            print("   Error details: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try self.checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction
            
        case .userCancelled, .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        // First check for developer access (highest priority)
        if hasDeveloperAccess() {
            subscriptionInfo = SubscriptionInfo(
                status: .developerAccess,
                expirationDate: nil,
                product: nil,
                renewalInfo: nil
            )
            return
        }
        
        // Check if free version mode is enabled
        if Config.isFreeVersion {
            // Free version mode: users start as not subscribed (with 30 generation limit)
            // They can upgrade to premium or use developer code for unlimited access
            subscriptionInfo = SubscriptionInfo(
                status: .notSubscribed,
                expirationDate: nil,
                product: nil,
                renewalInfo: nil
            )
            return
        }
        
        // Check for free trial (7-day trial for new users)
        let freeTrialService = FreeTrialService.shared
        if freeTrialService.isTrialActive {
            subscriptionInfo = SubscriptionInfo(
                status: .freeTrial,
                expirationDate: freeTrialService.expirationDate,
                product: nil,
                renewalInfo: nil
            )
            return
        }
        
        var highestStatus: SubscriptionStatus = .notSubscribed
        var highestTransaction: Transaction?
        var highestProduct: Product?
        var renewalInfo: Product.SubscriptionInfo.RenewalInfo?
        
        // Check all subscription transactions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try self.checkVerified(result)
                
                // Only process subscription transactions
                guard let product = products.first(where: { $0.id == transaction.productID }),
                      product.subscription != nil else {
                    continue
                }
                
                guard let status = try await product.subscription?.status.first else {
                    continue
                }
                
                // Check subscription state
                let state = status.state
                if state == .subscribed {
                    // Check if in trial or regular subscription
                    let verifiedRenewal = try self.checkVerified(status.renewalInfo)
                    
                    if verifiedRenewal.willAutoRenew {
                        // Check if currently in trial period
                        if #available(iOS 17.2, *) {
                            if let offerID = transaction.offer?.id {
                                // Has an offer - check if it's introductory
                                highestStatus = offerID.contains("intro") || offerID.contains("trial") ? .inTrial : .active
                            } else {
                                // No offer = regular subscription
                                highestStatus = .active
                            }
                        } else {
                            // For iOS 16.6, default to active (can't determine trial status reliably)
                            highestStatus = .active
                        }
                        highestTransaction = transaction
                        highestProduct = product
                        renewalInfo = verifiedRenewal
                    }
                } else if state == .expired || state == .revoked {
                    if highestStatus == .notSubscribed {
                        highestStatus = .expired
                    }
                } else if state == .inGracePeriod || state == .inBillingRetryPeriod {
                    highestStatus = .active
                    highestTransaction = transaction
                    highestProduct = product
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        // Update subscription info
        subscriptionInfo = SubscriptionInfo(
            status: highestStatus,
            expirationDate: highestTransaction?.expirationDate,
            product: highestProduct,
            renewalInfo: renewalInfo
        )
        
        // Update purchased product IDs
        var newPurchasedIDs: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? self.checkVerified(result) {
                newPurchasedIDs.insert(transaction.productID)
            }
        }
        purchasedProductIDs = newPurchasedIDs
    }
    
    // MARK: - Transaction Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { @MainActor [weak self] in
            guard let self = self else { return }
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Developer Access
    
    func validateDeveloperAccessCode(_ code: String) -> Bool {
        guard validAccessCodes.contains(code) else {
            return false
        }
        
        // Store in UserDefaults (in production, use Keychain for better security)
        UserDefaults.standard.set(true, forKey: developerAccessKey)
        
        Task {
            await updateSubscriptionStatus()
        }
        
        return true
    }
    
    func hasDeveloperAccess() -> Bool {
        return UserDefaults.standard.bool(forKey: developerAccessKey)
    }
    
    func removeDeveloperAccess() {
        UserDefaults.standard.removeObject(forKey: developerAccessKey)
        Task {
            await updateSubscriptionStatus()
        }
    }
    
    // MARK: - Subscription Management
    
    func openSubscriptionManagement() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("Failed to show manage subscriptions: \(error)")
            }
        }
    }
    
    // MARK: - Helper Properties
    
    var hasActiveSubscription: Bool {
        // Always return true - all features are now free
        return true
    }
    
    var isInTrial: Bool {
        return subscriptionInfo?.status == .inTrial
    }
    
    var hasMealPrepAccess: Bool {
        // Public test phase: accessible to all users
        return true
    }
    
    var monthlyProduct: Product? {
        return products.first { $0.id == SubscriptionProduct.monthly.rawValue }
    }
    
    var yearlyProduct: Product? {
        return products.first { $0.id == SubscriptionProduct.yearly.rawValue }
    }
}

// MARK: - Store Errors

enum StoreError: Error {
    case failedVerification
    case purchaseFailed
    case productNotFound
}

extension StoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "subscription.error.verification".localized
        case .purchaseFailed:
            return "subscription.error.purchase".localized
        case .productNotFound:
            return "subscription.error.notfound".localized
        }
    }
}
