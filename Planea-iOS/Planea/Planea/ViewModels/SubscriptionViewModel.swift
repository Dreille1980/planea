import Foundation
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var purchaseSuccessful = false
    
    private let storeManager = StoreManager.shared
    
    var products: [Product] {
        storeManager.products
    }
    
    var subscriptionInfo: SubscriptionInfo? {
        storeManager.subscriptionInfo
    }
    
    var hasActiveSubscription: Bool {
        storeManager.hasActiveSubscription
    }
    
    var isInTrial: Bool {
        storeManager.isInTrial
    }
    
    var monthlyProduct: Product? {
        storeManager.monthlyProduct
    }
    
    var yearlyProduct: Product? {
        storeManager.yearlyProduct
    }
    
    // MARK: - Actions
    
    func loadProducts() async {
        isLoading = true
        await storeManager.loadProducts()
        isLoading = false
    }
    
    func purchase(_ product: Product) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let transaction = try await storeManager.purchase(product)
            if transaction != nil {
                purchaseSuccessful = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await storeManager.restorePurchases()
            if storeManager.hasActiveSubscription {
                purchaseSuccessful = true
            } else {
                errorMessage = String(localized: "subscription.restore.notfound")
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func openSubscriptionManagement() async {
        await storeManager.openSubscriptionManagement()
    }
    
    // MARK: - Formatting Helpers
    
    func formattedPrice(for product: Product) -> String {
        return product.displayPrice
    }
    
    func formattedPeriod(for product: Product) -> String {
        guard let subscription = product.subscription else {
            return ""
        }
        
        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value
        
        switch unit {
        case .day:
            return value == 1 ? String(localized: "subscription.period.day") : String(localized: "subscription.period.days")
        case .week:
            return value == 1 ? String(localized: "subscription.period.week") : String(localized: "subscription.period.weeks")
        case .month:
            return value == 1 ? String(localized: "subscription.period.month") : String(localized: "subscription.period.months")
        case .year:
            return value == 1 ? String(localized: "subscription.period.year") : String(localized: "subscription.period.years")
        @unknown default:
            return ""
        }
    }
    
    func trialDescription(for product: Product) -> String? {
        guard let subscription = product.subscription,
              let introductoryOffer = subscription.introductoryOffer,
              introductoryOffer.paymentMode == .freeTrial else {
            return nil
        }
        
        let period = introductoryOffer.period
        let value = period.value
        
        switch period.unit {
        case .day:
            return String(localized: "subscription.trial.days", defaultValue: "\(value) days free trial")
        case .week:
            return String(localized: "subscription.trial.weeks", defaultValue: "\(value) weeks free trial")
        case .month:
            return String(localized: "subscription.trial.months", defaultValue: "\(value) months free trial")
        case .year:
            return String(localized: "subscription.trial.years", defaultValue: "\(value) years free trial")
        @unknown default:
            return nil
        }
    }
    
    func savingsAmount() -> String? {
        guard let monthlyProduct = monthlyProduct,
              let yearlyProduct = yearlyProduct,
              let monthlyPrice = Double(monthlyProduct.price.description),
              let yearlyPrice = Double(yearlyProduct.price.description) else {
            return nil
        }
        
        let yearlyEquivalent = monthlyPrice * 12
        let savings = yearlyEquivalent - yearlyPrice
        
        if savings > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = yearlyProduct.priceFormatStyle.currencyCode
            formatter.locale = yearlyProduct.priceFormatStyle.locale
            return formatter.string(from: NSNumber(value: savings))
        }
        
        return nil
    }
}
