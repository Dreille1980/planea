import Foundation
import SwiftUI
import Network

@MainActor
class ChatViewModel: ObservableObject {
    @Published var currentConversation: ChatConversation
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var suggestedActions: [String] = []
    @Published var isOnline = true
    
    private let chatService: ChatService
    private let storageService = ChatStorageService.shared
    private let storeManager = StoreManager.shared
    private let monitor = NWPathMonitor()
    
    // Context providers - injected
    var getRecentRecipes: (() -> [Recipe])?
    var getFavoriteRecipes: (() -> [Recipe])?
    var getPreferences: (() -> GenerationPreferences)?
    
    init() {
        // Initialize with a new conversation
        self.currentConversation = ChatConversation()
        
        // Initialize chat service with backend URL from Config
        if let backendURL = URL(string: Config.baseURL) {
            self.chatService = ChatService(baseURL: backendURL)
        } else {
            // Fallback URL (should never happen)
            self.chatService = ChatService(baseURL: URL(string: "https://planea-backend.onrender.com")!)
        }
        
        // Start monitoring network connectivity
        startMonitoringNetwork()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Network Monitoring
    
    private func startMonitoringNetwork() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    // MARK: - Premium Check
    
    var hasPremiumAccess: Bool {
        storeManager.hasActiveSubscription
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Check for network connectivity
        guard isOnline else {
            errorMessage = "chat.error.offline".localized
            return
        }
        
        // Check for Premium access
        guard hasPremiumAccess else {
            errorMessage = "chat.error.premium".localized
            return
        }
        
        // Add user message to conversation
        let userMessage = ChatMessage(content: text, isFromUser: true)
        currentConversation.addMessage(userMessage)
        
        // Clear error and start loading
        errorMessage = nil
        isLoading = true
        
        do {
            // Build user context
            let userContext = buildUserContext()
            
            // Get current language
            let language = LocalizationHelper.shared.currentLanguage == "fr" ? "fr" : "en"
            
            // Send message to backend
            let response = try await chatService.sendMessage(
                message: text,
                conversationHistory: currentConversation.getRecentMessages(limit: 10),
                userContext: userContext,
                language: language
            )
            
            // Add agent response to conversation
            let agentMessage = ChatMessage(
                content: response.reply,
                isFromUser: false,
                detectedMode: response.detectedMode
            )
            currentConversation.addMessage(agentMessage)
            
            // Update suggested actions
            suggestedActions = response.suggestedActions
            
            // Save conversation
            storageService.saveConversation(currentConversation)
            
            // If onboarding mode and requires confirmation, check for user confirmation
            if response.detectedMode == .onboarding && response.requiresConfirmation {
                // The next user message should be handled specially for saving preferences
                // This will be implemented in the UI layer
            }
            
        } catch let error as ChatError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "chat.error.unknown".localized
        }
        
        isLoading = false
    }
    
    // MARK: - Context Building
    
    private func buildUserContext() -> [String: Any] {
        var context: [String: Any] = [
            "has_premium": hasPremiumAccess
        ]
        
        // Add preferences if available
        if let getPrefs = getPreferences {
            let prefs = getPrefs()
            context["preferences"] = [
                "weekdayMaxMinutes": prefs.weekdayMaxMinutes,
                "weekendMaxMinutes": prefs.weekendMaxMinutes,
                "spiceLevel": prefs.spiceLevel.rawValue,
                "kidFriendly": prefs.kidFriendly,
                "preferredProteins": Array(prefs.preferredProteins).map { $0.rawValue },
                "availableAppliances": Array(prefs.availableAppliances).map { $0.rawValue }
            ]
        }
        
        // Add recent recipes if available
        if let getRecent = getRecentRecipes {
            let recipes = getRecent()
            context["recent_recipes"] = recipes.prefix(5).map { $0.title }
        }
        
        // Add favorite recipes if available
        if let getFavorites = getFavoriteRecipes {
            let recipes = getFavorites()
            context["favorite_recipes"] = recipes.prefix(5).map { $0.title }
        }
        
        return context
    }
    
    // MARK: - Conversation Management
    
    func startNewConversation() {
        // Save current conversation if it has messages
        if !currentConversation.messages.isEmpty {
            storageService.saveConversation(currentConversation)
        }
        
        // Create new conversation
        currentConversation = ChatConversation()
        suggestedActions = []
        errorMessage = nil
    }
    
    func loadConversation(id: UUID) {
        if let conversation = storageService.loadConversation(id: id) {
            currentConversation = conversation
            errorMessage = nil
            suggestedActions = []
        }
    }
    
    func deleteCurrentConversation() {
        storageService.deleteConversation(id: currentConversation.id)
        startNewConversation()
    }
    
    func getAllConversations() -> [ChatConversation] {
        return storageService.loadAllConversations()
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func useSuggestedAction(_ action: String) async {
        await sendMessage(action)
    }
}
