import Foundation
import CoreData

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Planea")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
            }
        }
    }
    
    // MARK: - Family Operations
    
    func saveFamily(_ family: Family, members: [Member]) {
        let context = container.viewContext
        
        // Save family
        let familyEntity = FamilyEntity(context: context)
        familyEntity.id = family.id
        familyEntity.name = family.name
        
        // Save members
        for member in members {
            let memberEntity = MemberEntity(context: context)
            memberEntity.id = member.id
            memberEntity.familyId = member.familyId
            memberEntity.displayName = member.displayName
            memberEntity.preferenceData = try? JSONEncoder().encode(member.preferences)
        }
        
        save()
    }
    
    func loadFamily() -> (Family?, [Member]) {
        let context = container.viewContext
        
        // Load family
        let familyRequest: NSFetchRequest<FamilyEntity> = FamilyEntity.fetchRequest()
        let families = try? context.fetch(familyRequest)
        let family = families?.first.map { Family(id: $0.id ?? UUID(), name: $0.name ?? "Famille") }
        
        // Load members
        let memberRequest: NSFetchRequest<MemberEntity> = MemberEntity.fetchRequest()
        let memberEntities = try? context.fetch(memberRequest)
        let members = memberEntities?.compactMap { entity -> Member? in
            guard let id = entity.id,
                  let familyId = entity.familyId,
                  let name = entity.displayName else { return nil }
            
            let preferences = (try? JSONDecoder().decode([Preference].self, from: entity.preferenceData ?? Data())) ?? []
            
            return Member(id: id, familyId: familyId, displayName: name, preferences: preferences)
        } ?? []
        
        return (family, members)
    }
    
    // MARK: - Meal Plan Operations
    
    func saveMealPlan(_ plan: MealPlan) {
        let context = container.viewContext
        
        let planEntity = MealPlanEntity(context: context)
        planEntity.id = plan.id
        planEntity.familyId = plan.familyId
        planEntity.weekStart = plan.weekStart
        planEntity.itemsData = try? JSONEncoder().encode(plan.items)
        
        save()
    }
    
    func loadMealPlans() -> [MealPlan] {
        let context = container.viewContext
        let request: NSFetchRequest<MealPlanEntity> = MealPlanEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealPlanEntity.weekStart, ascending: false)]
        
        let entities = try? context.fetch(request)
        return entities?.compactMap { entity -> MealPlan? in
            guard let id = entity.id,
                  let familyId = entity.familyId,
                  let weekStart = entity.weekStart,
                  let itemsData = entity.itemsData,
                  let items = try? JSONDecoder().decode([MealItem].self, from: itemsData) else { return nil }
            
            return MealPlan(id: id, familyId: familyId, weekStart: weekStart, items: items)
        } ?? []
    }
}
