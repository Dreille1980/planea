import Foundation

class PreferencesService {
    static let shared = PreferencesService()
    
    private let preferencesKey = "generationPreferences"
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    func savePreferences(_ preferences: GenerationPreferences) {
        if let encoded = try? JSONEncoder().encode(preferences) {
            defaults.set(encoded, forKey: preferencesKey)
        }
    }
    
    func loadPreferences() -> GenerationPreferences {
        guard let data = defaults.data(forKey: preferencesKey),
              let preferences = try? JSONDecoder().decode(GenerationPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }
    
    func resetToDefaults() {
        defaults.removeObject(forKey: preferencesKey)
    }
}
