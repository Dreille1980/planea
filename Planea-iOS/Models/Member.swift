import Foundation

struct Member: Identifiable, Codable {
    var id: UUID = .init()
    var familyId: UUID
    var displayName: String
    var preferences: [Preference] = []
}

struct Preference: Identifiable, Codable {
    var id: UUID = .init()
    var type: PreferenceType
    var value: String
    var severity: String? = nil
}
