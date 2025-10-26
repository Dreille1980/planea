import Foundation

class ChatStorageService {
    static let shared = ChatStorageService()
    
    private let fileManager = FileManager.default
    private let maxConversations = 20
    private let maxMessagesPerConversation = 50
    
    private init() {}
    
    // Get the directory for storing conversations
    private func getConversationsDirectory() -> URL? {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let conversationsDir = documentsPath.appendingPathComponent("Conversations", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: conversationsDir.path) {
            try? fileManager.createDirectory(at: conversationsDir, withIntermediateDirectories: true)
        }
        
        return conversationsDir
    }
    
    // Save a conversation
    func saveConversation(_ conversation: ChatConversation) {
        guard let directory = getConversationsDirectory() else {
            print("❌ Failed to get conversations directory")
            return
        }
        
        // Trim messages if needed
        var conversationToSave = conversation
        if conversationToSave.messages.count > maxMessagesPerConversation {
            conversationToSave.messages = Array(conversationToSave.messages.suffix(maxMessagesPerConversation))
        }
        
        let fileURL = directory.appendingPathComponent("\(conversation.id.uuidString).json")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(conversationToSave)
            try data.write(to: fileURL)
            print("✅ Conversation saved: \(conversation.id)")
            
            // Clean up old conversations if we exceed the limit
            cleanUpOldConversations()
        } catch {
            print("❌ Failed to save conversation: \(error)")
        }
    }
    
    // Load a specific conversation
    func loadConversation(id: UUID) -> ChatConversation? {
        guard let directory = getConversationsDirectory() else { return nil }
        
        let fileURL = directory.appendingPathComponent("\(id.uuidString).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let conversation = try decoder.decode(ChatConversation.self, from: data)
            return conversation
        } catch {
            print("❌ Failed to load conversation \(id): \(error)")
            return nil
        }
    }
    
    // Load all conversations
    func loadAllConversations() -> [ChatConversation] {
        guard let directory = getConversationsDirectory() else { return [] }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let conversations = fileURLs.compactMap { fileURL -> ChatConversation? in
                guard fileURL.pathExtension == "json" else { return nil }
                
                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    return try decoder.decode(ChatConversation.self, from: data)
                } catch {
                    print("❌ Failed to load conversation from \(fileURL): \(error)")
                    return nil
                }
            }
            
            // Sort by most recent first
            return conversations.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            print("❌ Failed to load conversations: \(error)")
            return []
        }
    }
    
    // Delete a conversation
    func deleteConversation(id: UUID) {
        guard let directory = getConversationsDirectory() else { return }
        
        let fileURL = directory.appendingPathComponent("\(id.uuidString).json")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
            print("✅ Conversation deleted: \(id)")
        }
    }
    
    // Clean up old conversations to maintain the limit
    private func cleanUpOldConversations() {
        let conversations = loadAllConversations()
        
        if conversations.count > maxConversations {
            let conversationsToDelete = conversations.suffix(from: maxConversations)
            for conversation in conversationsToDelete {
                deleteConversation(id: conversation.id)
            }
            print("🧹 Cleaned up \(conversationsToDelete.count) old conversations")
        }
    }
    
    // Delete all conversations (for testing or user request)
    func deleteAllConversations() {
        guard let directory = getConversationsDirectory() else { return }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            for fileURL in fileURLs where fileURL.pathExtension == "json" {
                try? fileManager.removeItem(at: fileURL)
            }
            
            print("🧹 All conversations deleted")
        } catch {
            print("❌ Failed to delete all conversations: \(error)")
        }
    }
}
