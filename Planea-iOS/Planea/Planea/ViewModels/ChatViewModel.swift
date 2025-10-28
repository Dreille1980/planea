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
    @Published var pendingRecipeModification: Recipe?
    @Published var pendingModificationType: String?
    @Published var pendingModificationMetadata: [String: String]?
    
    private let chatService: ChatService
    private let storageService = ChatStorageService.shared
    private let storeManager = StoreManager.shared
    private let monitor = NWPathMonitor()
    
    // Context providers - injected
    var getRecentRecipes: (() -> [Recipe])?
    var getFavoriteRecipes: (() -> [Recipe])?
    var getPreferences: (() -> GenerationPreferences)?
    var getCurrentPlan: (() -> MealPlan?)?
    var updateRecipe: ((Recipe, String?, String?) -> Void)?  // Recipe, weekday, meal_type
    var refreshShoppingList: (() -> Void)?
    var familyViewModel: FamilyViewModel?
    
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
            
            // Handle member addition if present
            if let memberData = response.memberData, let name = memberData.name {
                // Filter out confirmation words that shouldn't be names
                let confirmationWords = [
                    // French
                    "parfait", "ok", "oui", "bien", "super", "génial", "correct", "exact",
                    "d'accord", "daccord", "dacord", "merci", "excellent", "impeccable",
                    // English
                    "perfect", "okay", "ok", "yes", "good", "great", "correct", "right",
                    "sure", "thanks", "excellent"
                ]
                
                let nameLower = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Only add member if name is not a confirmation word and has reasonable length
                guard !confirmationWords.contains(nameLower) && name.count >= 2 else {
                    print("⚠️ Skipping member addition - '\(name)' looks like a confirmation word")
                    return
                }
                
                print("👤 Adding member: \(name)")
                print("  Allergens: \(memberData.allergens)")
                print("  Dislikes: \(memberData.dislikes)")
                
                // Add the member using FamilyViewModel
                if let familyVM = familyViewModel {
                    let newMember = familyVM.addMember(name: name)
                    
                    // Update member with preferences, allergens, and dislikes
                    familyVM.updateMember(
                        id: newMember.id,
                        name: name,
                        preferences: [],
                        allergens: memberData.allergens,
                        dislikes: memberData.dislikes
                    )
                    
                    // Add confirmation message
                    let confirmationText = language == "fr"
                        ? "✅ \(name) a été ajouté à votre famille!"
                        : "✅ \(name) has been added to your family!"
                    
                    let confirmationMessage = ChatMessage(
                        content: confirmationText,
                        isFromUser: false,
                        detectedMode: response.detectedMode
                    )
                    currentConversation.addMessage(confirmationMessage)
                    
                    print("✅ Member successfully added to family settings!")
                } else {
                    print("⚠️ FamilyViewModel not available")
                }
            }
            
            // Handle pending recipe modification (awaiting confirmation)
            if let pendingRecipe = response.pendingRecipeModification {
                pendingRecipeModification = pendingRecipe
                pendingModificationType = response.modificationType
                pendingModificationMetadata = response.modificationMetadata
                print("📝 Pending recipe modification stored, awaiting user confirmation")
                if let metadata = response.modificationMetadata {
                    print("   Metadata: weekday=\(metadata["weekday"] ?? "nil"), meal_type=\(metadata["meal_type"] ?? "nil")")
                }
            }
            
            // Handle confirmed recipe modification
            if let modifiedRecipe = response.modifiedRecipe {
                // Get metadata for plan update
                let weekday = response.modificationMetadata?["weekday"]
                let mealType = response.modificationMetadata?["meal_type"]
                
                // Clear any pending modification
                pendingRecipeModification = nil
                pendingModificationType = nil
                pendingModificationMetadata = nil
                
                // Update the recipe in the plan with metadata
                updateRecipe?(modifiedRecipe, weekday, mealType)
                
                // Refresh shopping list
                refreshShoppingList?()
                
                print("✅ Recipe modification applied successfully")
                if let wd = weekday, let mt = mealType {
                    print("   Updated: \(wd) \(mt)")
                }
            }
            
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
        
        // Add current meal plan if available
        if let getPlan = getCurrentPlan, let plan = getPlan() {
            var mealsByDay: [String: [[String: Any]]] = [:]
            for item in plan.items {
                let dayKey = item.weekday.rawValue
                let meal: [String: Any] = [
                    "type": item.mealType.rawValue,
                    "title": item.recipe.title,
                    "servings": item.recipe.servings,
                    "time_minutes": item.recipe.totalMinutes,
                    "ingredients": item.recipe.ingredients.map { ing in
                        [
                            "name": ing.name,
                            "quantity": ing.quantity,
                            "unit": ing.unit
                        ]
                    },
                    "steps": item.recipe.steps
                ]
                
                if mealsByDay[dayKey] == nil {
                    mealsByDay[dayKey] = []
                }
                mealsByDay[dayKey]?.append(meal)
            }
            context["current_plan"] = mealsByDay
        }
        
        // Add recent recipes with full details
        if let getRecent = getRecentRecipes {
            let recipes = getRecent().prefix(3)
            context["recent_recipes"] = recipes.map { recipe in
                [
                    "title": recipe.title,
                    "servings": recipe.servings,
                    "time_minutes": recipe.totalMinutes,
                    "ingredients": recipe.ingredients.map { ing in
                        [
                            "name": ing.name,
                            "quantity": ing.quantity,
                            "unit": ing.unit
                        ]
                    },
                    "steps": recipe.steps
                ]
            }
        }
        
        // Add favorite recipes with full details
        if let getFavorites = getFavoriteRecipes {
            let recipes = getFavorites().prefix(3)
            context["favorite_recipes"] = recipes.map { recipe in
                [
                    "title": recipe.title,
                    "servings": recipe.servings,
                    "time_minutes": recipe.totalMinutes,
                    "ingredients": recipe.ingredients.map { ing in
                        [
                            "name": ing.name,
                            "quantity": ing.quantity,
                            "unit": ing.unit
                        ]
                    },
                    "steps": recipe.steps
                ]
            }
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
    
    // MARK: - Recipe Modification Confirmation
    
    func confirmRecipeModification() async {
        guard pendingRecipeModification != nil else {
            print("⚠️ No pending recipe modification to confirm")
            return
        }
        
        // Send confirmation message to backend
        let language = LocalizationHelper.shared.currentLanguage == "fr" ? "fr" : "en"
        let confirmationMessage = language == "fr" ? "oui" : "yes"
        
        await sendMessage(confirmationMessage)
    }
    
    func cancelRecipeModification() {
        pendingRecipeModification = nil
        pendingModificationType = nil
        pendingModificationMetadata = nil
        print("❌ Recipe modification cancelled by user")
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func useSuggestedAction(_ action: String) async {
        await sendMessage(action)
    }
}
