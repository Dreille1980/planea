import SwiftUI

struct FloatingChatButton: View {
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var usageVM: UsageViewModel
    @State private var showChatView = false
    @State private var showPaywall = false
    
    private var hasPremiumAccess: Bool {
        storeManager.hasActiveSubscription
    }
    
    var body: some View {
        // Don't show chat button if usage limit is reached in free version mode
        if Config.isFreeVersion && !usageVM.canGenerateRecipes {
            EmptyView()
        } else {
            chatButton
        }
    }
    
    private var chatButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: openChat) {
                    ZStack(alignment: .topTrailing) {
                        // Main circle with agent icon
                        ZStack {
                            Circle()
                                .fill(Color.planeaPrimary)
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        // AI badge with sparkles
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 22, height: 22)
                            
                            Circle()
                                .fill(Color.planeaPrimary)
                                .frame(width: 20, height: 20)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        }
                        .offset(x: -2, y: 2)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showChatView) {
            ChatView()
        }
        .sheet(isPresented: $showPaywall) {
            SubscriptionPaywallView()
        }
    }
    
    private func openChat() {
        if hasPremiumAccess {
            showChatView = true
        } else {
            showPaywall = true
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        FloatingChatButton()
            .environmentObject(StoreManager.shared)
    }
}
