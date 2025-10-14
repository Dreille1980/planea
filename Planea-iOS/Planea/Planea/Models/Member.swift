import Foundation

struct Member: Identifiable, Codable {
    var id: UUID = .init()
    var familyId: UUID
    var displayName: String
    var preferences: [Preference] = []
    
    // Computed properties for easier access
    var allergens: [String] {
        preferences.filter { $0.type == .allergen }.map { $0.value }
    }
    
    var dislikes: [String] {
        preferences.filter { $0.type == .dislike }.map { $0.value }
    }
    
    var diets: [String] {
        preferences.filter { $0.type == .diet }.map { $0.value }
    }
}

struct Preference: Identifiable, Codable {
    var id: UUID = .init()
    var type: PreferenceType
    var value: String
    var severity: String? = nil
}
