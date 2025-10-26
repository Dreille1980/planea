import SwiftUI

struct ChatMessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)
                
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
