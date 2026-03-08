import SwiftUI
import StoreKit

struct SubscriptionPaywallView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    
    let canDismiss: Bool
    let limitReached: Bool
    let onDismiss: (() -> Void)?
    
    init(canDismiss: Bool = false, limitReached: Bool = false, onDismiss: (() -> Void)? = nil) {
        self.canDismiss = canDismiss
        self.limitReached = limitReached
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: PlaneaSpacing.sm) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                        
                        Text("subscription.title".localized)
                            .font(.planeaLargeTitle)
                            .fontWeight(.bold)
                        
                        if limitReached {
                            Text("usage.limit_message".localized)
                                .font(.planeaTitle3)
                                .foregroundColor(.planeaTextSecondary)
                                .multilineTextAlignment(.center)
                        } else if !viewModel.hasActiveSubscription {
                            Text("subscription.trialEnded".localized)
                                .font(.planeaTitle3)
                                .foregroundColor(.planeaTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Features
                    VStack(alignment: .leading, spacing: PlaneaSpacing.md) {
                        FeatureRow(icon: "calendar.badge.checkmark", text: "subscription.feature.planning".localized)
                        FeatureRow(icon: "cart.fill", text: "subscription.feature.shopping".localized)
                        FeatureRow(icon: "sparkles", text: "subscription.feature.ai".localized)
                        FeatureRow(icon: "photo.on.rectangle.angled", text: "subscription.feature.adhoc".localized)
                        FeatureRow(icon: "person.3.fill", text: "subscription.feature.family".localized)
                    }
                    .padding(.horizontal)
                    
                    // Subscription Options
                    VStack(spacing: PlaneaSpacing.md) {
                        if viewModel.isLoading {
                            // Loading state
                            VStack(spacing: PlaneaSpacing.sm) {
                                ProgressView()
                                Text("Loading subscription options...")
                                    .font(.planeaSubheadline)
                                    .foregroundColor(.planeaTextSecondary)
                            }
                            .frame(height: 200)
                        } else if viewModel.monthlyProduct == nil && viewModel.yearlyProduct == nil {
                            // No products loaded - show helpful message
                            VStack(spacing: PlaneaSpacing.md) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.orange)
                                
                                Text("Subscription Options Unavailable")
                                    .font(.planeaHeadline)
                                
                                Text("Please try the following:\n\n1. Restart the app\n2. Check your internet connection\n3. Verify StoreKit Configuration in Xcode")
                                    .font(.planeaSubheadline)
                                    .foregroundColor(.planeaTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding()
                        } else {
                            // Products loaded - show subscription cards
                            if let monthlyProduct = viewModel.monthlyProduct {
                                SubscriptionOptionCard(
                                    product: monthlyProduct,
                                    isSelected: false,
                                    trialDescription: viewModel.trialDescription(for: monthlyProduct),
                                    onTap: {
                                        Task {
                                            await viewModel.purchase(monthlyProduct)
                                        }
                                    }
                                )
                            }
                            
                            if let yearlyProduct = viewModel.yearlyProduct {
                                SubscriptionOptionCard(
                                    product: yearlyProduct,
                                    isSelected: true,
                                    trialDescription: viewModel.trialDescription(for: yearlyProduct),
                                    savingsText: viewModel.savingsAmount().map { String(format: "subscription.save".localized, $0) },
                                    onTap: {
                                        Task {
                                            await viewModel.purchase(yearlyProduct)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: PlaneaSpacing.sm) {
                        // Restore Button
                        Button(action: {
                            Task {
                                await viewModel.restorePurchases()
                            }
                        }) {
                            Text("subscription.restore".localized)
                                .font(.planeaSubheadline)
                                .foregroundStyle(.blue)
                        }
                        
                        // Manage Subscription Button
                        Button(action: {
                            Task {
                                await viewModel.openSubscriptionManagement()
                            }
                        }) {
                            Text("subscription.manage".localized)
                                .font(.planeaSubheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    // Terms and Privacy
                    HStack(spacing: PlaneaSpacing.md) {
                        Button("subscription.terms".localized) {
                            openLegalURL(type: .terms)
                        }
                        .font(.planeaCaption)
                        .foregroundColor(.planeaTextSecondary)
                        
                        Button("subscription.privacy".localized) {
                            openLegalURL(type: .privacy)
                        }
                        .font(.planeaCaption)
                        .foregroundColor(.planeaTextSecondary)
                    }
                    
                    // Auto-renewal Legal Text
                    Text("subscription.autorenewal".localized)
                        .font(.system(size: 10))
                        .foregroundColor(.planeaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
            }
            
            // Close button (only if dismissible)
            if canDismiss {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            onDismiss?()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.planeaTitle2)
                                .foregroundColor(.planeaTextSecondary)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
            
            // Loading overlay
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .alert("subscription.error".localized, isPresented: $viewModel.showError) {
            Button("action.done".localized, role: .cancel) { }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onChange(of: viewModel.purchaseSuccessful) {
            if viewModel.purchaseSuccessful {
                onDismiss?()
            }
        }
        .task {
            await viewModel.loadProducts()
        }
    }
    
    // MARK: - Helper Methods
    
    private enum LegalDocumentType {
        case terms
        case privacy
    }
    
    private func openLegalURL(type: LegalDocumentType) {
        let baseURL = "https://dreille1980.github.io/planea-legal/"
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        
        let path: String
        switch type {
        case .terms:
            path = language == "fr" ? "terms-fr.html" : "terms-en.html"
        case .privacy:
            path = language == "fr" ? "privacy-fr.html" : "privacy-en.html"
        }
        
        if let url = URL(string: baseURL + path) {
            UIApplication.shared.open(url)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: PlaneaSpacing.sm) {
            Image(systemName: icon)
                .font(.planeaTitle3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.planeaBody)
            
            Spacer()
        }
    }
}

struct SubscriptionOptionCard: View {
    let product: Product
    let isSelected: Bool
    let trialDescription: String?
    var savingsText: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: PlaneaSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.planeaHeadline)
                            .foregroundColor(.planeaTextPrimary)
                        
                        if let trialDescription = trialDescription {
                            Text(trialDescription)
                                .font(.planeaSubheadline)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.planeaTitle3)
                            .fontWeight(.bold)
                            .foregroundColor(.planeaTextPrimary)
                        
                        if let subscription = product.subscription {
                            Text("/ \(periodText(for: subscription.subscriptionPeriod))")
                                .font(.planeaCaption)
                                .foregroundColor(.planeaTextSecondary)
                        }
                    }
                }
                
                if let savingsText = savingsText {
                    HStack {
                        Text(savingsText)
                            .font(.planeaSubheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1), radius: isSelected ? 8 : 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func periodText(for period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            return period.value == 1 ? "subscription.period.day".localized : "subscription.period.days".localized
        case .week:
            return period.value == 1 ? "subscription.period.week".localized : "subscription.period.weeks".localized
        case .month:
            return period.value == 1 ? "subscription.period.month".localized : "subscription.period.months".localized
        case .year:
            return period.value == 1 ? "subscription.period.year".localized : "subscription.period.years".localized
        @unknown default:
            return ""
        }
    }
}

#Preview {
    SubscriptionPaywallView(canDismiss: true)
}
