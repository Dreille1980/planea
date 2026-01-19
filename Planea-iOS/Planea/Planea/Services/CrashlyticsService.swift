import Foundation
import FirebaseCrashlytics

/// Service centralisé pour gérer Firebase Crashlytics
class CrashlyticsService {
    static let shared = CrashlyticsService()
    
    private init() {}
    
    // MARK: - User Identification
    
    func setUserID(_ userID: String?) {
        Crashlytics.crashlytics().setUserID(userID ?? "")
    }
    
    func setCustomValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
    
    // MARK: - Logging
    
    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    func logError(_ error: Error, additionalInfo: [String: Any]? = nil) {
        if let info = additionalInfo {
            for (key, value) in info {
                setCustomValue(value, forKey: key)
            }
        }
        Crashlytics.crashlytics().record(error: error)
    }
    
    // MARK: - Custom Keys for Context
    
    func setSubscriptionStatus(_ status: String) {
        setCustomValue(status, forKey: "subscription_status")
    }
    
    func setLanguage(_ language: String) {
        setCustomValue(language, forKey: "app_language")
    }
    
    func setUnitSystem(_ system: String) {
        setCustomValue(system, forKey: "unit_system")
    }
    
    func setFamilyMemberCount(_ count: Int) {
        setCustomValue(count, forKey: "family_member_count")
    }
    
    func setGenerationCount(_ count: Int) {
        setCustomValue(count, forKey: "generation_count")
    }
    
    // MARK: - Test Crash (Debug Only)
    
    #if DEBUG
    func forceCrash() {
        fatalError("Test crash from Crashlytics")
    }
    #endif
}
