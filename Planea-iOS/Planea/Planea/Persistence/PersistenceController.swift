import Foundation
import CoreData

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Planea")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure to use App Group for sharing data with widget
            if let appGroupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.dreille.planea"
            ) {
                let storeURL = appGroupURL.appendingPathComponent("Planea.sqlite")
                let description = NSPersistentStoreDescription(url: storeURL)
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                container.persistentStoreDescriptions = [description]
            }
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
        
        // Check if plan already exists
        let request: NSFetchRequest<MealPlanEntity> = MealPlanEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", plan.id as CVarArg)
        
        let planEntity: MealPlanEntity
        if let existing = try? context.fetch(request).first {
            planEntity = existing
        } else {
            planEntity = MealPlanEntity(context: context)
            planEntity.id = plan.id
        }
        
        planEntity.familyId = plan.familyId
        planEntity.weekStart = plan.weekStart
        planEntity.itemsData = try? JSONEncoder().encode(plan.items)
        planEntity.status = plan.status.rawValue
        planEntity.confirmedDate = plan.confirmedDate
        planEntity.name = plan.name
        
        save()
    }
    
    func loadCurrentDraftPlan() -> MealPlan? {
        let context = container.viewContext
        let request: NSFetchRequest<MealPlanEntity> = MealPlanEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", PlanStatus.draft.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealPlanEntity.weekStart, ascending: false)]
        request.fetchLimit = 1
        
        do {
            guard let entity = try context.fetch(request).first else { return nil }
            return convertEntityToPlan(entity)
        } catch {
            print("Error loading draft plan: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loadActivePlan() -> MealPlan? {
        let context = container.viewContext
        let request: NSFetchRequest<MealPlanEntity> = MealPlanEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", PlanStatus.active.rawValue)
        request.fetchLimit = 1
        
        do {
            guard let entity = try context.fetch(request).first else { return nil }
            return convertEntityToPlan(entity)
        } catch {
            print("Error loading active plan: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loadArchivedPlans() -> [MealPlan] {
        let context = container.viewContext
        let request: NSFetchRequest<MealPlanEntity> = MealPlanEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", PlanStatus.archived.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealPlanEntity.confirmedDate, ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { convertEntityToPlan($0) }
        } catch {
            print("Error loading archived plans: \(error.localizedDescription)")
            return []
        }
    }
    
    func activatePlan(id: UUID) {
        let context = container.viewContext
        
        // First, archive any existing active plan
        let activeRequest: NSFetchRequest<MealPlanEntity> = MealPlanEntity.fetchRequest()
        activeRequest.predicate = NSPredicate(format: "status == %@", PlanStatus.active.rawValue)
        
        do {
            let activePlans = try context.fetch(activeRequest)
            for plan in activePlans {
                plan.status = PlanStatus.archived.rawValue
                if plan.confirmedDate == nil {
                    plan.confirmedDate = Date()
                }
            }
            
            // Now activate the specified plan
            let request: NSFetchRequest<MealPlanEntity> = MealPlanEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            if let entity = try context.fetch(request).first {
                entity.status = PlanStatus.active.rawValue
                entity.confirmedDate = Date()
                save()
            }
        } catch {
            print("Error activating plan: \(error.localizedDescription)")
        }
    }
    
    func archivePlan(id: UUID) {
        let context = container.viewContext
        let request: NSFetchRequest<MealPlanEntity> = MealPlanEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                entity.status = PlanStatus.archived.rawValue
                if entity.confirmedDate == nil {
                    entity.confirmedDate = Date()
                }
                save()
            }
        } catch {
            print("Error archiving plan: \(error.localizedDescription)")
        }
    }
    
    @available(*, deprecated, message: "Use loadArchivedPlans() instead")
    func loadConfirmedPlans() -> [MealPlan] {
        return loadArchivedPlans()
    }
    
    @available(*, deprecated, message: "Use activatePlan(id:) instead")
    func confirmPlan(id: UUID) {
        activatePlan(id: id)
    }
    
    func deletePlan(id: UUID) {
        let context = container.viewContext
        let request: NSFetchRequest<MealPlanEntity> = MealPlanEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                save()
            }
        } catch {
            print("Error deleting plan: \(error.localizedDescription)")
        }
    }
    
    func loadMealPlans() -> [MealPlan] {
        let context = container.viewContext
        let request: NSFetchRequest<MealPlanEntity> = MealPlanEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealPlanEntity.weekStart, ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { convertEntityToPlan($0) }
        } catch {
            print("Error loading meal plans: \(error.localizedDescription)")
            return []
        }
    }
    
    private func convertEntityToPlan(_ entity: MealPlanEntity) -> MealPlan? {
        guard let id = entity.id,
              let familyId = entity.familyId,
              let weekStart = entity.weekStart,
              let itemsData = entity.itemsData,
              let items = try? JSONDecoder().decode([MealItem].self, from: itemsData) else { return nil }
        
        let status = PlanStatus(rawValue: entity.status ?? "draft") ?? .draft
        
        return MealPlan(
            id: id,
            familyId: familyId,
            weekStart: weekStart,
            items: items,
            status: status,
            confirmedDate: entity.confirmedDate,
            name: entity.name
        )
    }
    
    // MARK: - Recent Recipe Operations
    
    func saveRecentRecipe(_ recipe: Recipe, source: String) {
        let context = container.viewContext
        
        let entity = RecentRecipeEntity(context: context)
        entity.id = recipe.id
        entity.title = recipe.title
        entity.servings = Int16(recipe.servings)
        entity.totalTime = Int16(recipe.totalMinutes)
        entity.ingredients = try? JSONEncoder().encode(recipe.ingredients)
        entity.steps = try? JSONEncoder().encode(recipe.steps)
        entity.generatedDate = Date()
        entity.source = source
        
        save()
        
        // Clean up old recipes
        deleteOldRecentRecipes(keepCount: 15)
    }
    
    func loadRecentRecipes(limit: Int = 15) -> [Recipe] {
        let context = container.viewContext
        let request: NSFetchRequest<RecentRecipeEntity> = RecentRecipeEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RecentRecipeEntity.generatedDate, ascending: false)]
        request.fetchLimit = limit
        
        do {
            let entities = try context.fetch(request)
            return entities.compactMap { entity -> Recipe? in
                guard let id = entity.id,
                      let title = entity.title,
                      let ingredientsData = entity.ingredients,
                      let stepsData = entity.steps,
                      let ingredients = try? JSONDecoder().decode([RecipeIngredient].self, from: ingredientsData),
                      let steps = try? JSONDecoder().decode([String].self, from: stepsData) else { return nil }
                
                return Recipe(
                    id: id,
                    title: title,
                    servings: Int(entity.servings),
                    totalMinutes: Int(entity.totalTime),
                    ingredients: ingredients,
                    steps: steps
                )
            }
        } catch {
            print("Error loading recent recipes: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteRecentRecipe(id: UUID) {
        let context = container.viewContext
        let request: NSFetchRequest<RecentRecipeEntity> = RecentRecipeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                save()
            }
        } catch {
            print("Error deleting recent recipe: \(error.localizedDescription)")
        }
    }
    
    func deleteOldRecentRecipes(keepCount: Int) {
        let context = container.viewContext
        let request: NSFetchRequest<RecentRecipeEntity> = RecentRecipeEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RecentRecipeEntity.generatedDate, ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            if entities.count > keepCount {
                let entitiesToDelete = Array(entities[keepCount...])
                for entity in entitiesToDelete {
                    context.delete(entity)
                }
                save()
            }
        } catch {
            print("Error cleaning up old recent recipes: \(error.localizedDescription)")
        }
    }
}
