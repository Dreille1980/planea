import Foundation

struct ChatService {
    var baseURL: URL
    
    // Custom URLSession with extended timeout
    private static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        return URLSession(configuration: configuration)
    }()
    
    // Response models
    private struct ChatAPIResponse: Codable {
        let reply: String
        let detected_mode: String
        let requires_confirmation: Bool
        let suggested_actions: [String]
        let modified_recipe: Recipe?
        let pending_recipe_modification: Recipe?
        let modification_type: String?
        let modification_metadata: [String: String]?
        let member_data: MemberData?
        
        enum CodingKeys: String, CodingKey {
            case reply
            case detected_mode
            case requires_confirmation
            case suggested_actions
            case modified_recipe
            case pending_recipe_modification
            case modification_type
            case modification_metadata
            case member_data
        }
    }
    
    struct MemberData: Codable {
        let name: String?
        let allergens: [String]
        let dislikes: [String]
    }
    
    @MainActor
    func sendMessage(
        message: String,
        conversationHistory: [ChatMessage],
        userContext: [String: Any],
        language: String
    ) async throws -> (reply: String, detectedMode: AgentMode, requiresConfirmation: Bool, suggestedActions: [String], modifiedRecipe: Recipe?, pendingRecipeModification: Recipe?, modificationType: String?, modificationMetadata: [String: String]?, memberData: MemberData?) {
        
        let url = baseURL.appendingPathComponent("/ai/chat")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert conversation history to dictionaries
        let historyDicts = conversationHistory.map { msg -> [String: Any] in
            return [
                "content": msg.content,
                "isFromUser": msg.isFromUser,
                "timestamp": ISO8601DateFormatter().string(from: msg.timestamp)
            ]
        }
        
        // Build request payload
        let payload: [String: Any] = [
            "message": message,
            "conversation_history": historyDicts,
            "user_context": userContext,
            "language": language
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("💬 Sending chat message to agent...")
        let (data, response) = try await Self.urlSession.data(for: req)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                throw ChatError.serverError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        // Decode response
        let apiResponse = try JSONDecoder().decode(ChatAPIResponse.self, from: data)
        
        // Convert detected mode string to enum
        let detectedMode: AgentMode
        switch apiResponse.detected_mode {
        case "onboarding":
            detectedMode = .onboarding
        case "recipe_qa":
            detectedMode = .recipeQA
        case "nutrition_coach":
            detectedMode = .nutritionCoach
        default:
            detectedMode = .nutritionCoach
        }
        
        return (
            reply: apiResponse.reply,
            detectedMode: detectedMode,
            requiresConfirmation: apiResponse.requires_confirmation,
            suggestedActions: apiResponse.suggested_actions,
            modifiedRecipe: apiResponse.modified_recipe,
            pendingRecipeModification: apiResponse.pending_recipe_modification,
            modificationType: apiResponse.modification_type,
            modificationMetadata: apiResponse.modification_metadata,
            memberData: apiResponse.member_data
        )
    }
}

enum ChatError: Error {
    case premiumRequired
    case serverError(String)
    case networkError
    case decodingError
}

extension ChatError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .premiumRequired:
            return "chat.error.premium".localized
        case .serverError(let message):
            return "chat.error.server".localized + ": \(message)"
        case .networkError:
            return "chat.error.network".localized
        case .decodingError:
            return "chat.error.decode".localized
        }
    }
}
