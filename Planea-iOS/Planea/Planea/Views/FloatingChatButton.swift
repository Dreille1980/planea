import SwiftUI

struct FloatingChatButton: View {
    @EnvironmentObject var storeManager: StoreManager
    @State private var showChatView = false
    @State private var showPaywall = false
    
    private var hasPremiumAccess: Bool {
        storeManager.hasActiveSubscription
    }
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: openChat) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
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
