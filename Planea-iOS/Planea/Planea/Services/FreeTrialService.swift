import Foundation

/// Service to manage the 7-day free trial period for new users
class FreeTrialService {
    static let shared = FreeTrialService()
    
    // MARK: - Constants
    
    private let TRIAL_DURATION_DAYS = 7
    
    // MARK: - UserDefaults Keys
    
    private let trialStartDateKey = "com.planea.freeTrial.startDate"
    private let trialHasStartedKey = "com.planea.freeTrial.hasStarted"
    private let trialExpirationShownKey = "com.planea.freeTrial.expirationShown"
    
    // MARK: - iCloud Keys (for persistence across reinstalls)
    
    private let iCloudTrialStartDateKey = "com.planea.icloud.freeTrial.startDate"
    private let iCloudTrialHasStartedKey = "com.planea.icloud.freeTrial.hasStarted"
    
    private let userDefaults = UserDefaults.standard
    private let ubiquitousStore = NSUbiquitousKeyValueStore.default
    
    // MARK: - Initialization
    
    private init() {
        // Sync iCloud data on initialization
        ubiquitousStore.synchronize()
        
        // Check if we have iCloud data but not local data (reinstall case)
        if ubiquitousStore.bool(forKey: iCloudTrialHasStartedKey) && 
           !userDefaults.bool(forKey: trialHasStartedKey) {
            // Restore from iCloud
            if let iCloudDate = ubiquitousStore.object(forKey: iCloudTrialStartDateKey) as? Date {
                userDefaults.set(iCloudDate, forKey: trialStartDateKey)
                userDefaults.set(true, forKey: trialHasStartedKey)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Start the free trial (called after onboarding completion)
    func startTrial() {
        // Don't start trial if free version mode is enabled
        if Config.isFreeVersion {
            print("ℹ️ [FreeTrialService] Free version mode enabled, skipping trial start")
            return
        }
        
        guard !hasTrialStarted else {
            print("⚠️ [FreeTrialService] Trial already started, ignoring")
            return
        }
        
        let now = Date()
        
        // Save to UserDefaults
        userDefaults.set(now, forKey: trialStartDateKey)
        userDefaults.set(true, forKey: trialHasStartedKey)
        
        // Save to iCloud for persistence across reinstalls
        ubiquitousStore.set(now, forKey: iCloudTrialStartDateKey)
        ubiquitousStore.set(true, forKey: iCloudTrialHasStartedKey)
        ubiquitousStore.synchronize()
        
        print("✅ [FreeTrialService] Trial started at \(now)")
    }
    
    /// Check if trial has been started
    var hasTrialStarted: Bool {
        return userDefaults.bool(forKey: trialHasStartedKey)
    }
    
    /// Check if trial is currently active
    var isTrialActive: Bool {
        guard hasTrialStarted,
              let startDate = userDefaults.object(forKey: trialStartDateKey) as? Date else {
            return false
        }
        
        let now = Date()
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: now).day ?? 0
        
        return daysSinceStart < TRIAL_DURATION_DAYS
    }
    
    /// Get the number of days remaining in the trial
    var daysRemaining: Int {
        guard hasTrialStarted,
              let startDate = userDefaults.object(forKey: trialStartDateKey) as? Date else {
            return 0
        }
        
        let expirationDate = Calendar.current.date(byAdding: .day, value: TRIAL_DURATION_DAYS, to: startDate)!
        let now = Date()
        let daysLeft = Calendar.current.dateComponents([.day], from: now, to: expirationDate).day ?? 0
        
        return max(0, daysLeft)
    }
    
    /// Get the trial expiration date
    var expirationDate: Date? {
        guard hasTrialStarted,
              let startDate = userDefaults.object(forKey: trialStartDateKey) as? Date else {
            return nil
        }
        
        return Calendar.current.date(byAdding: .day, value: TRIAL_DURATION_DAYS, to: startDate)
    }
    
    /// Check if trial has expired (and user has been notified)
    var hasTrialExpired: Bool {
        return hasTrialStarted && !isTrialActive
    }
    
    /// Check if we should show the trial reminder banner (3 days or less remaining)
    var shouldShowTrialReminder: Bool {
        guard isTrialActive else { return false }
        return daysRemaining <= 3 && daysRemaining > 0
    }
    
    /// Check if we should show expiration message
    var shouldShowExpirationMessage: Bool {
        guard hasTrialExpired else { return false }
        return !userDefaults.bool(forKey: trialExpirationShownKey)
    }
    
    /// Mark expiration message as shown
    func markExpirationMessageShown() {
        userDefaults.set(true, forKey: trialExpirationShownKey)
    }
    
    /// Reset trial (for testing only - should not be exposed in production)
    func resetTrial() {
        userDefaults.removeObject(forKey: trialStartDateKey)
        userDefaults.removeObject(forKey: trialHasStartedKey)
        userDefaults.removeObject(forKey: trialExpirationShownKey)
        
        ubiquitousStore.removeObject(forKey: iCloudTrialStartDateKey)
        ubiquitousStore.removeObject(forKey: iCloudTrialHasStartedKey)
        ubiquitousStore.synchronize()
        
        print("🔄 [FreeTrialService] Trial reset")
    }
    
    /// Get trial status description for debugging
    func getTrialStatusDescription() -> String {
        if !hasTrialStarted {
            return "Trial not started"
        } else if isTrialActive {
            return "Trial active: \(daysRemaining) days remaining"
        } else {
            return "Trial expired"
        }
    }
}
