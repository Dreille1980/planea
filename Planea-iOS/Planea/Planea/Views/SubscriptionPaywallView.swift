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
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                        
                        Text("subscription.title".localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if limitReached {
                            Text("usage.limit_message".localized)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        } else if !viewModel.hasActiveSubscription {
                            Text("subscription.trialEnded".localized)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "calendar.badge.checkmark", text: "subscription.feature.planning".localized)
                        FeatureRow(icon: "cart.fill", text: "subscription.feature.shopping".localized)
                        FeatureRow(icon: "sparkles", text: "subscription.feature.ai".localized)
                        FeatureRow(icon: "person.3.fill", text: "subscription.feature.family".localized)
                    }
                    .padding(.horizontal)
                    
                    // Subscription Options
                    VStack(spacing: 16) {
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
                    .padding(.horizontal)
                    
                    // Restore Button
                    Button(action: {
                        Task {
                            await viewModel.restorePurchases()
                        }
                    }) {
                        Text("subscription.restore".localized)
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    
                    // Terms and Privacy
                    HStack(spacing: 16) {
                        Button("subscription.terms".localized) {
                            // Open terms URL
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        Button("subscription.privacy".localized) {
                            // Open privacy URL
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
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
                                .font(.title2)
                                .foregroundStyle(.secondary)
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
        .onChange(of: viewModel.purchaseSuccessful) { success in
            if success {
                onDismiss?()
            }
        }
        .task {
            await viewModel.loadProducts()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
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
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let trialDescription = trialDescription {
                            Text(trialDescription)
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(product.displayPrice)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        
                        if let subscription = product.subscription {
                            Text("/ \(periodText(for: subscription.subscriptionPeriod))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if let savingsText = savingsText {
                    HStack {
                        Text(savingsText)
                            .font(.subheadline)
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
