import Foundation
import Combine

final class FamilyViewModel: ObservableObject {
    @Published var family = Family(name: "Famille")
    @Published var members: [Member] = []
    
    func addMember(name: String) {
        let m = Member(familyId: family.id, displayName: name, preferences: [])
        members.append(m)
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
