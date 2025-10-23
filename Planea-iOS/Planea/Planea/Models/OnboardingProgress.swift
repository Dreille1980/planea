import Foundation

/// Tracks the user's progress through the onboarding flow
/// Saved to UserDefaults to allow resuming if the user exits mid-flow
struct OnboardingProgress: Codable {
    var hasSeenTour: Bool = false
    var hasCompletedFamilyName: Bool = false
    var familyName: String = ""
    var configuredMemberIds: [UUID] = []
    var hasCompletedPreferences: Bool = false
    var currentStepIndex: Int = 0
    var isComplete: Bool = false
    
    private static let storageKey = "onboardingProgress"
    
    /// Save the current progress to UserDefaults
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.storageKey)
        }
    }
    
    /// Load the saved progress from UserDefaults
    static func load() -> OnboardingProgress {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let progress = try? JSONDecoder().decode(OnboardingProgress.self, from: data) else {
            return OnboardingProgress()
        }
        return progress
    }
    
    /// Reset the onboarding progress
    static func reset() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    /// Check if a specific member has been configured
    func isMemberConfigured(_ memberId: UUID) -> Bool {
        return configuredMemberIds.contains(memberId)
    }
    
    /// Mark a member as configured
    mutating func markMemberConfigured(_ memberId: UUID) {
        if !configuredMemberIds.contains(memberId) {
            configuredMemberIds.append(memberId)
        }
    }
}

/// Defines the steps in the onboarding flow
enum OnboardingStep: Int, CaseIterable {
    case featureTour = 0
    case familyName = 1
    case membersManagement = 2
    case generationPreferences = 3
    case completion = 4
    
    var title: String {
        switch self {
        case .featureTour:
            return "tour.welcome.title".localized
        case .familyName:
            return "onboarding.familyname.title".localized
        case .membersManagement:
            return "onboarding.members.title".localized
        case .generationPreferences:
            return "onboarding.prefs.title".localized
        case .completion:
            return "onboarding.completion.title".localized
        }
    }
    
    var progressValue: Double {
        Double(self.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}
