import Foundation

enum AgentMode: String, Codable {
    case onboarding = "onboarding"
    case recipeQA = "recipe_qa"
    case nutritionCoach = "nutrition_coach"
    
    var displayName: String {
        switch self {
        case .onboarding:
            return "agent.mode.onboarding".localized
        case .recipeQA:
            return "agent.mode.recipeqa".localized
        case .nutritionCoach:
            return "agent.mode.coach".localized
        }
    }
    
    var icon: String {
        switch self {
        case .onboarding:
            return "person.crop.circle.badge.checkmark"
        case .recipeQA:
            return "book.closed"
        case .nutritionCoach:
            return "heart.text.square"
        }
    }
}
