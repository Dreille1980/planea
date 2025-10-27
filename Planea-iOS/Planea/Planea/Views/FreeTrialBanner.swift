import SwiftUI

struct FreeTrialBanner: View {
    @EnvironmentObject var usageVM: UsageViewModel
    @State private var showSubscriptionView = false
    
    var body: some View {
        if usageVM.isInFreeTrial {
            Button(action: {
                showSubscriptionView = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("freetrial.banner.title".localized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(String(format: "freetrial.banner.daysLeft".localized, usageVM.daysRemainingInFreeTrial))
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionPaywallView(limitReached: false)
            }
        }
    }
}

#Preview {
    FreeTrialBanner()
        .environmentObject(UsageViewModel())
}
