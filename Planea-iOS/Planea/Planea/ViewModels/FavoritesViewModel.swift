import SwiftUI
import CoreData

class FavoritesViewModel: ObservableObject {
    @Published var savedRecipes: [Recipe] = []
    @Published var showPaywall = false
    
    private let persistenceController: PersistenceController
    private let container: NSPersistentContainer
    private var usageVM: UsageViewModel?
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.container = persistenceController.container
        loadSavedRecipes()
    }
    
    func setUsageViewModel(_ usageVM: UsageViewModel) {
        self.usageVM = usageVM
    }
    
    func loadSavedRecipes() {
        let request = NSFetchRequest<SavedRecipeEntity>(entityName: "SavedRecipeEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavedRecipeEntity.savedDate, ascending: false)]
        
        do {
            let entities = try container.viewContext.fetch(request)
            savedRecipes = entities.compactMap { entity -> Recipe? in
                guard let title = entity.title,
                      let ingredientsData = entity.ingredients,
                      let stepsData = entity.steps else {
                    return nil
                }
                
                let ingredients = try? JSONDecoder().decode([RecipeIngredient].self, from: ingredientsData)
                let steps = try? JSONDecoder().decode([String].self, from: stepsData)
                
                return Recipe(
                    id: entity.id ?? UUID(),
                    title: title,
                    servings: Int(entity.servings),
                    totalMinutes: Int(entity.totalTime),
                    ingredients: ingredients ?? [],
                    steps: steps ?? []
                )
            }
        } catch {
            print("Error loading saved recipes: \(error)")
        }
    }
    
    @MainActor
    func saveRecipe(_ recipe: Recipe) {
        // Check if user has free plan restrictions
        if let usageVM = usageVM, usageVM.hasFreePlanRestrictions {
            showPaywall = true
            return
        }
        
        let context = container.viewContext
        
        // Check if already saved
        let request = NSFetchRequest<SavedRecipeEntity>(entityName: "SavedRecipeEntity")
        request.predicate = NSPredicate(format: "id == %@", recipe.id as CVarArg)
        
        do {
            let existing = try context.fetch(request)
            if !existing.isEmpty {
                // Already saved
                return
            }
            
            let entity = SavedRecipeEntity(context: context)
            entity.id = recipe.id
            entity.title = recipe.title
            entity.servings = Int16(recipe.servings)
            entity.totalTime = Int16(recipe.totalMinutes)
            entity.ingredients = try? JSONEncoder().encode(recipe.ingredients)
            entity.steps = try? JSONEncoder().encode(recipe.steps)
            entity.savedDate = Date()
            
            try context.save()
            loadSavedRecipes()
        } catch {
            print("Error saving recipe: \(error)")
        }
    }
    
    func removeRecipe(_ recipe: Recipe) {
        let context = container.viewContext
        let request = NSFetchRequest<SavedRecipeEntity>(entityName: "SavedRecipeEntity")
        request.predicate = NSPredicate(format: "id == %@", recipe.id as CVarArg)
        
        do {
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
            loadSavedRecipes()
        } catch {
            print("Error removing recipe: \(error)")
        }
    }
    
    func isRecipeSaved(_ recipe: Recipe) -> Bool {
        return savedRecipes.contains { $0.id == recipe.id }
    }
}
