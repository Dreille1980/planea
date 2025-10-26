import Foundation

struct ChatConversation: Codable, Identifiable {
    let id: UUID
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    var title: String
    
    init(id: UUID = UUID(), messages: [ChatMessage] = [], createdAt: Date = Date(), updatedAt: Date = Date(), title: String = "chat.conversation.new".localized) {
        self.id = id
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
    }
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updatedAt = Date()
        
        // Auto-generate title from first user message if still default
        if title == "chat.conversation.new".localized || title == "New Conversation" {
            if let firstUserMessage = messages.first(where: { $0.isFromUser }) {
                title = String(firstUserMessage.content.prefix(50))
            }
        }
    }
    
    // Get last N messages for context
    func getRecentMessages(limit: Int = 10) -> [ChatMessage] {
        return Array(messages.suffix(limit))
    }
}
