import Foundation

/// Service to track recipe generation usage for free plan users
class UsageTrackingService {
    static let shared = UsageTrackingService()
    
    // MARK: - Constants
    
    private var FREE_PLAN_LIMIT: Int {
        return Config.monthlyGenerationLimit
    }
    
    // MARK: - UserDefaults Keys
    
    private let monthlyGenerationsKey = "com.planea.monthlyGenerations"
    private let lastResetDateKey = "com.planea.lastResetDate"
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    
    private init() {
        // Initialize last reset date if not set
        if userDefaults.object(forKey: lastResetDateKey) == nil {
            userDefaults.set(Date(), forKey: lastResetDateKey)
        }
        
        // Check if we need to reset for new month
        resetIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// Check if user can generate the specified number of recipes
    func canGenerate(count: Int) -> Bool {
        resetIfNeeded()
        let current = monthlyGenerations
        return (current + count) <= FREE_PLAN_LIMIT
    }
    
    /// Record that recipes were generated
    func recordGenerations(count: Int) {
        resetIfNeeded()
        let current = monthlyGenerations
        userDefaults.set(current + count, forKey: monthlyGenerationsKey)
    }
    
    /// Get remaining generations for the month
    func remainingGenerations() -> Int {
        resetIfNeeded()
        let remaining = FREE_PLAN_LIMIT - monthlyGenerations
        return max(0, remaining)
    }
    
    /// Get current month's generation count
    var monthlyGenerations: Int {
        resetIfNeeded()
        return userDefaults.integer(forKey: monthlyGenerationsKey)
    }
    
    /// Reset usage counter (for testing purposes)
    func resetUsage() {
        userDefaults.set(0, forKey: monthlyGenerationsKey)
        userDefaults.set(Date(), forKey: lastResetDateKey)
    }
    
    // MARK: - Private Methods
    
    /// Check if we're in a new month and reset if needed
    private func resetIfNeeded() {
        guard let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date else {
            // First time - initialize
            userDefaults.set(Date(), forKey: lastResetDateKey)
            userDefaults.set(0, forKey: monthlyGenerationsKey)
            return
        }
        
        let calendar = Calendar.current
        let lastMonth = calendar.component(.month, from: lastResetDate)
        let lastYear = calendar.component(.year, from: lastResetDate)
        
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        // Reset if we're in a different month or year
        if currentMonth != lastMonth || currentYear != lastYear {
            userDefaults.set(0, forKey: monthlyGenerationsKey)
            userDefaults.set(currentDate, forKey: lastResetDateKey)
        }
    }
}
