import SwiftUI

struct SubscriptionLockOverlay: View {
    @EnvironmentObject var storeManager: StoreManager
    @State private var showSubscriptionSheet = false
    
    var body: some View {
        ZStack {
            // Blurred/dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Lock content
            VStack(spacing: 24) {
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                
                // Title
                Text("subscription.locked.title".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                Text("subscription.locked.description".localized)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Subscribe button
                Button(action: {
                    showSubscriptionSheet = true
                }) {
                    Text("subscription.unlock".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showSubscriptionSheet) {
            SubscriptionPaywallView(canDismiss: true, onDismiss: {
                showSubscriptionSheet = false
            })
        }
    }
}

#Preview {
    SubscriptionLockOverlay()
        .environmentObject(StoreManager.shared)
}
