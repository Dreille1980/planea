import Foundation
import SwiftUI

@MainActor
class UsageViewModel: ObservableObject {
    @Published var generationsUsed: Int = 0
    @Published var generationsRemaining: Int = 30
    
    private let usageTracking = UsageTrackingService.shared
    private let storeManager = StoreManager.shared
    
    init() {
        updateUsageStats()
    }
    
    // MARK: - Computed Properties
    
    /// Check if user can generate recipes (considering subscription and usage limits)
    var canGenerateRecipes: Bool {
        // Premium and trial users (including developer access) have unlimited access
        if storeManager.hasActiveSubscription {
            return true
        }
        
        // In free version mode, check usage limit
        if Config.isFreeVersion {
            return generationsRemaining > 0
        }
        
        // Free users must check usage limit
        return generationsRemaining > 0
    }
    
    /// Check if user has free plan restrictions
    var hasFreePlanRestrictions: Bool {
        return !storeManager.hasActiveSubscription
    }
    
    /// Check if user is in trial period
    var isInTrial: Bool {
        return storeManager.isInTrial
    }
    
    /// Check if user is in free trial period (7-day trial)
    var isInFreeTrial: Bool {
        return storeManager.subscriptionInfo?.status == .freeTrial
    }
    
    /// Get days remaining in free trial
    var daysRemainingInFreeTrial: Int {
        return FreeTrialService.shared.daysRemaining
    }
    
    /// Check if user has active subscription (trial or premium)
    var hasActiveSubscription: Bool {
        return storeManager.hasActiveSubscription
    }
    
    /// Get subscription info for display
    var subscriptionInfo: SubscriptionInfo? {
        return storeManager.subscriptionInfo
    }
    
    // MARK: - Public Methods
    
    /// Check if user can generate a specific number of recipes
    func canGenerate(count: Int) -> Bool {
        // Premium and trial users (including developer access) can always generate
        if storeManager.hasActiveSubscription {
            return true
        }
        
        // In free version mode, check usage limit
        if Config.isFreeVersion {
            return usageTracking.canGenerate(count: count)
        }
        
        // Free users must check usage limit
        return usageTracking.canGenerate(count: count)
    }
    
    /// Record that recipes were generated
    func recordGenerations(count: Int) {
        // Don't track for premium/trial users (including developer access)
        guard !storeManager.hasActiveSubscription else {
            return
        }
        
        // In free version mode, track usage for non-subscribed users
        if Config.isFreeVersion {
            usageTracking.recordGenerations(count: count)
            updateUsageStats()
            return
        }
        
        // Track for free users
        usageTracking.recordGenerations(count: count)
        updateUsageStats()
    }
    
    /// Update usage statistics
    func updateUsageStats() {
        generationsUsed = usageTracking.monthlyGenerations
        generationsRemaining = usageTracking.remainingGenerations()
    }
    
    /// Reset usage (for testing)
    func resetUsage() {
        usageTracking.resetUsage()
        updateUsageStats()
    }
    
    /// Get usage display string for UI
    func usageDisplayString() -> String {
        // Premium/trial users (including developer access) have unlimited
        if storeManager.hasActiveSubscription {
            return String(localized: "usage.unlimited")
        }
        
        // Show usage for free users
        if Config.isFreeVersion {
            return String(format: String(localized: "usage.remaining"), generationsUsed, Config.monthlyGenerationLimit)
        }
        
        return String(format: String(localized: "usage.remaining"), generationsUsed, Config.monthlyGenerationLimit)
    }
}
