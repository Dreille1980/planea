import Foundation

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let detectedMode: AgentMode?
    
    init(id: UUID = UUID(), content: String, isFromUser: Bool, timestamp: Date = Date(), detectedMode: AgentMode? = nil) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.detectedMode = detectedMode
    }
}
