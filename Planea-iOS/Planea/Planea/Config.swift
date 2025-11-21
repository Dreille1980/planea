import Foundation

struct Config {
    // MARK: - Feature Flags
    
    /// Set to true for free version, false to re-enable paywall
    static let isFreeVersion = true
    
    /// Monthly generation limit for free users
    static let monthlyGenerationLimit = 30
    
    /// Support email for feedback
    static let supportEmail = "support@planea.app"
    
    // MARK: - Backend
    
    static var baseURL: String {
        // Always use Render backend for all generations
        return "https://planea-backend.onrender.com"
    }
}
