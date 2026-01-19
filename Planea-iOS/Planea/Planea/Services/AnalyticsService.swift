import Foundation
import FirebaseAnalytics

/// Service centralisé pour gérer tous les événements Firebase Analytics
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - User Properties
    
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    func setUserID(_ userID: String?) {
        Analytics.setUserID(userID)
    }
    
    // MARK: - Navigation & Engagement
    
    func logScreenView(screenName: String, screenClass: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
    }
    
    func logAppOpen() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }
    
    func logOnboardingComplete() {
        Analytics.logEvent("onboarding_complete", parameters: nil)
    }
    
    func logOnboardingStep(step: String) {
        Analytics.logEvent("onboarding_step", parameters: [
            "step_name": step
        ])
    }
    
    // MARK: - Recipe Generation
    
    func logRecipeGenerated(type: String, recipeCount: Int, agentMode: String? = nil) {
        var params: [String: Any] = [
            "generation_type": type, // "plan" or "adhoc"
            "recipe_count": recipeCount
        ]
        
        if let mode = agentMode {
            params["agent_mode"] = mode
        }
        
        Analytics.logEvent("recipe_generated", parameters: params)
    }
    
    func logRecipeViewed(recipeID: String, recipeTitle: String, source: String) {
        Analytics.logEvent("recipe_viewed", parameters: [
            "recipe_id": recipeID,
            "recipe_title": recipeTitle,
            "source": source // "plan", "adhoc", "favorite", "history"
        ])
    }
    
    // MARK: - Favorites
    
    func logRecipeFavorited(recipeID: String, recipeTitle: String) {
        Analytics.logEvent("recipe_favorited", parameters: [
            "recipe_id": recipeID,
            "recipe_title": recipeTitle
        ])
    }
    
    func logRecipeUnfavorited(recipeID: String, recipeTitle: String) {
        Analytics.logEvent("recipe_unfavorited", parameters: [
            "recipe_id": recipeID,
            "recipe_title": recipeTitle
        ])
    }
    
    func logFavoriteAddedToWeek(recipeID: String, recipeTitle: String, weekDate: String) {
        Analytics.logEvent("favorite_added_to_week", parameters: [
            "recipe_id": recipeID,
            "recipe_title": recipeTitle,
            "week_date": weekDate
        ])
    }
    
    // MARK: - Meal Prep
    
    func logMealPrepCreated(recipeCount: Int, totalServings: Int) {
        Analytics.logEvent("meal_prep_created", parameters: [
            "recipe_count": recipeCount,
            "total_servings": totalServings
        ])
    }
    
    func logMealPrepViewed(sessionID: String, recipeCount: Int) {
        Analytics.logEvent("meal_prep_viewed", parameters: [
            "session_id": sessionID,
            "recipe_count": recipeCount
        ])
    }
    
    // MARK: - Shopping
    
    func logShoppingListExported(itemCount: Int, format: String) {
        Analytics.logEvent("shopping_list_exported", parameters: [
            "item_count": itemCount,
            "export_format": format // "text", "share"
        ])
    }
    
    func logShoppingItemAdded(manually: Bool) {
        Analytics.logEvent("shopping_item_added", parameters: [
            "is_manual": manually
        ])
    }
    
    func logShoppingItemToggled(checked: Bool) {
        Analytics.logEvent("shopping_item_toggled", parameters: [
            "is_checked": checked
        ])
    }
    
    // MARK: - Chat
    
    func logChatMessageSent(agentMode: String, messageLength: Int) {
        Analytics.logEvent("chat_message_sent", parameters: [
            "agent_mode": agentMode, // "chef", "nutritionist"
            "message_length": messageLength
        ])
    }
    
    func logChatConversationStarted(agentMode: String) {
        Analytics.logEvent("chat_conversation_started", parameters: [
            "agent_mode": agentMode
        ])
    }
    
    func logVoiceInputUsed(agentMode: String) {
        Analytics.logEvent("voice_input_used", parameters: [
            "agent_mode": agentMode
        ])
    }
    
    // MARK: - Subscription & Monetization
    
    func logPaywallViewed(source: String) {
        Analytics.logEvent("paywall_viewed", parameters: [
            "source": source // "trial_banner", "limit_reached", "settings"
        ])
    }
    
    func logSubscriptionPurchased(productID: String, price: Double, currency: String) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productID,
            AnalyticsParameterPrice: price,
            AnalyticsParameterCurrency: currency
        ])
    }
    
    func logFreeTrialStarted() {
        Analytics.logEvent("free_trial_started", parameters: nil)
    }
    
    func logUsageLimitReached(currentCount: Int, limit: Int) {
        Analytics.logEvent("usage_limit_reached", parameters: [
            "current_count": currentCount,
            "limit": limit
        ])
    }
    
    func logSubscriptionRestored(productID: String) {
        Analytics.logEvent("subscription_restored", parameters: [
            "product_id": productID
        ])
    }
    
    // MARK: - Settings
    
    func logLanguageChanged(from: String, to: String) {
        Analytics.logEvent("language_changed", parameters: [
            "from_language": from,
            "to_language": to
        ])
    }
    
    func logUnitSystemChanged(from: String, to: String) {
        Analytics.logEvent("unit_system_changed", parameters: [
            "from_system": from,
            "to_system": to
        ])
    }
    
    func logFamilyMemberAdded(totalMembers: Int) {
        Analytics.logEvent("family_member_added", parameters: [
            "total_members": totalMembers
        ])
    }
    
    func logFamilyMemberRemoved(totalMembers: Int) {
        Analytics.logEvent("family_member_removed", parameters: [
            "total_members": totalMembers
        ])
    }
    
    // MARK: - Errors
    
    func logAPIError(endpoint: String, statusCode: Int, errorMessage: String) {
        Analytics.logEvent("api_error", parameters: [
            "endpoint": endpoint,
            "status_code": statusCode,
            "error_message": errorMessage
        ])
    }
    
    func logGenerationFailed(type: String, reason: String) {
        Analytics.logEvent("generation_failed", parameters: [
            "generation_type": type,
            "failure_reason": reason
        ])
    }
    
    // MARK: - What's New
    
    func logWhatsNewViewed(version: String) {
        Analytics.logEvent("whats_new_viewed", parameters: [
            "app_version": version
        ])
    }
}
