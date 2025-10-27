import SwiftUI

struct ChatMessageBubble: View {
    let message: ChatMessage
    let isLastAgentMessage: Bool
    @ObservedObject var chatViewModel: ChatViewModel
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                messageContentView
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)
                
                // Show confirmation buttons if this is the last agent message and there's a pending modification
                if !message.isFromUser && isLastAgentMessage && chatViewModel.pendingRecipeModification != nil {
                    confirmationButtons
                }
                
                // Show mode indicator for agent messages
                if !message.isFromUser, let mode = message.detectedMode {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.caption2)
                        Text(mode.displayName)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var messageContentView: some View {
        let lines = message.content.components(separatedBy: "\n")
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if line.hasPrefix("ℹ️") {
                    // Disclaimer line - smaller font
                    Text(line)
                        .font(.caption2)
                        .foregroundColor(message.isFromUser ? .white.opacity(0.8) : .secondary)
                } else if !line.isEmpty {
                    // Regular content
                    Text(line)
                }
            }
        }
    }
    
    @ViewBuilder
    private var confirmationButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                Task {
                    await chatViewModel.confirmRecipeModification()
                }
            }) {
                Label("chat.confirm.button".localized, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(20)
            }
            
            Button(action: {
                chatViewModel.cancelRecipeModification()
            }) {
                Label("chat.cancel.button".localized, systemImage: "xmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(20)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatMessageBubble(
            message: ChatMessage(
                content: "Bonjour! Comment puis-je vous aider avec vos repas aujourd'hui?",
                isFromUser: false,
                detectedMode: .nutritionCoach
            )
        )
        
        ChatMessageBubble(
            message: ChatMessage(
                content: "Je voudrais des conseils pour des repas équilibrés",
                isFromUser: true
            )
        )
        
        ChatMessageBubble(
            message: ChatMessage(
                content: "ℹ️ Cette information est à titre général seulement et ne remplace pas un avis médical professionnel.\n\nPour des repas équilibrés, voici quelques conseils...",
                isFromUser: false,
                detectedMode: .nutritionCoach
            )
        )
    }
    .padding()
}
