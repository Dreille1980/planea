import Foundation
import SwiftUI

@MainActor
class UsageViewModel: ObservableObject {
    @Published var generationsUsed: Int = 0
    @Published var generationsRemaining: Int = 15
    
    private let usageTracking = UsageTrackingService.shared
    private let storeManager = StoreManager.shared
    
    init() {
        updateUsageStats()
    }
    
    // MARK: - Computed Properties
    
    /// Check if user can generate recipes (considering subscription and usage limits)
    var canGenerateRecipes: Bool {
        // In free version mode, always check usage limit
        if Config.isFreeVersion {
            return generationsRemaining > 0
        }
        
        // Premium and trial users have unlimited access
        if storeManager.hasActiveSubscription {
            return true
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
        // In free version mode, always check usage limit
        if Config.isFreeVersion {
            return usageTracking.canGenerate(count: count)
        }
        
        // Premium and trial users can always generate
        if storeManager.hasActiveSubscription {
            return true
        }
        
        // Free users must check usage limit
        return usageTracking.canGenerate(count: count)
    }
    
    /// Record that recipes were generated
    func recordGenerations(count: Int) {
        // In free version mode, always track usage
        if Config.isFreeVersion {
            usageTracking.recordGenerations(count: count)
            updateUsageStats()
            return
        }
        
        // Only track for free users
        guard !storeManager.hasActiveSubscription else {
            return
        }
        
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
        if Config.isFreeVersion {
            return String(format: String(localized: "usage.remaining"), generationsUsed, Config.monthlyGenerationLimit)
        }
        
        if storeManager.hasActiveSubscription {
            return String(localized: "usage.unlimited")
        } else {
            return String(format: String(localized: "usage.remaining"), generationsUsed, Config.monthlyGenerationLimit)
        }
    }
}
