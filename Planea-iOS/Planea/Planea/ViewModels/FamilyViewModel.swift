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
    
    func addMember(name: String) -> Member {
        let m = Member(familyId: family.id, displayName: name, preferences: [])
        members.append(m)
        saveData()
        return m
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
    
    /// Extract disliked proteins from all family members to explicitly exclude them from recipes
    func aggregatedDislikedProteins() -> [String] {
        // Common protein keywords in both French and English
        let commonProteins = [
            "poulet", "chicken", "boeuf", "beef", "porc", "pork", 
            "agneau", "lamb", "poisson", "fish", "saumon", "salmon", 
            "thon", "tuna", "crevettes", "shrimp", "tofu", "turkey", "dinde",
            "canard", "duck", "veau", "veal", "lapin", "rabbit"
        ]
        
        var dislikedProteins = Set<String>()
        
        for member in members {
            for preference in member.preferences where preference.type == .dislike {
                let value = preference.value.lowercased().trimmingCharacters(in: .whitespaces)
                
                // Check if this dislike is a protein or contains a protein keyword
                for protein in commonProteins {
                    if value == protein || value.contains(protein) {
                        dislikedProteins.insert(protein)
                    }
                }
            }
        }
        
        return Array(dislikedProteins)
    }
}
