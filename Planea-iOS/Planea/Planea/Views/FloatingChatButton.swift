import SwiftUI

struct FloatingChatButton: View {
    @State private var showChatView = false
    
    var body: some View {
        chatButton
    }
    
    private var chatButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: openChat) {
                    ZStack {
                        Circle()
                            .fill(Color.planeaPrimary)
                            .frame(width: 60, height: 60)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showChatView) {
            ChatView()
        }
    }
    
    private func openChat() {
        // All users can access chat - no restrictions
        showChatView = true
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
