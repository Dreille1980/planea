import Foundation
import Combine

final class FamilyViewModel: ObservableObject {
    @Published var family = Family(name: "")
    @Published var members: [Member] = []
    
    private let persistence = PersistenceController.shared
    
    init() {
        loadData()
    }
    
    func loadData() {
        let (loadedFamily, loadedMembers) = persistence.loadFamily()
        if let loadedFamily = loadedFamily {
            family = loadedFamily
        }
        
        // Eliminate duplicates based on member ID
        var uniqueMembers: [UUID: Member] = [:]
        for member in loadedMembers {
            uniqueMembers[member.id] = member
        }
        members = Array(uniqueMembers.values)
    }
    
    func saveData() {
        persistence.saveFamily(family, members: members)
    }
    
    func addMember(name: String) {
        let m = Member(familyId: family.id, displayName: name, preferences: [])
        members.append(m)
        saveData()
    }
    
    func removeMember(id: UUID) {
        members.removeAll { $0.id == id }
        saveData()
    }
    
    func updateMember(id: UUID, name: String, preferences: [String], allergens: [String], dislikes: [String]) {
        guard let index = members.firstIndex(where: { $0.id == id }) else { return }
        
        var prefs: [Preference] = []
        
        // Add diet preferences
        for pref in preferences {
            prefs.append(Preference(type: .diet, value: pref))
        }
        
        // Add allergens
        for allergen in allergens {
            prefs.append(Preference(type: .allergen, value: allergen))
        }
        
        // Add dislikes
        for dislike in dislikes {
            prefs.append(Preference(type: .dislike, value: dislike))
        }
        
        members[index] = Member(
            id: id,
            familyId: members[index].familyId,
            displayName: name,
            preferences: prefs
        )
        saveData()
    }
    
    func aggregatedConstraints() -> (diet: [String], evict: [String]) {
        var diet = Set<String>()
        var evict = Set<String>()
        for m in members {
            for p in m.preferences {
                switch p.type {
                case .diet: diet.insert(p.value.lowercased())
                case .allergen, .dislike: evict.insert(p.value.lowercased())
                }
            }
        }
        return (Array(diet), Array(evict))
    }
}
