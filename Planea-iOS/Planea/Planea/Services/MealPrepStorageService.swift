import Foundation

class MealPrepStorageService {
    private let historyKey = "mealPrepHistory"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - History Management
    
    /// Save a meal prep instance to history
    func saveMealPrepInstance(_ instance: MealPrepInstance) {
        var history = loadMealPrepHistory()
        history.append(instance)
        
        // Sort by creation date, most recent first
        history.sort { $0.createdAt > $1.createdAt }
        
        saveMealPrepHistory(history)
    }
    
    /// Load all meal prep instances from history
    func loadMealPrepHistory() -> [MealPrepInstance] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            return []
        }
        
        do {
            let history = try decoder.decode([MealPrepInstance].self, from: data)
            return history
        } catch {
            print("❌ Error loading meal prep history: \(error)")
            return []
        }
    }
    
    /// Save meal prep history
    private func saveMealPrepHistory(_ history: [MealPrepInstance]) {
        do {
            let data = try encoder.encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("❌ Error saving meal prep history: \(error)")
        }
    }
    
    /// Delete a meal prep instance from history
    func deleteMealPrepInstance(id: UUID) {
        var history = loadMealPrepHistory()
        history.removeAll { $0.id == id }
        saveMealPrepHistory(history)
    }
    
    /// Clear all meal prep history
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }
    
    // MARK: - Kit Mapping Logic
    
    /// Map meal prep kit recipes to week plan slots based on storage metadata
    func mapKitToWeekPlan(
        kit: MealPrepKit,
        params: MealPrepGenerationParams
    ) -> [(day: Weekday, mealType: MealType, recipe: MealPrepRecipeRef)] {
        var mappings: [(Weekday, MealType, MealPrepRecipeRef)] = []
        
        // Group recipes by storage characteristics
        let groupA = kit.recipes.filter { $0.shelfLifeDays <= 2 && !$0.isFreezable }
        let groupB = kit.recipes.filter { $0.shelfLifeDays <= 2 && $0.isFreezable }
        let groupC = kit.recipes.filter { $0.shelfLifeDays > 2 }
        
        print("📦 Mapping kit recipes:")
        print("  Group A (short shelf, not freezable): \(groupA.count)")
        print("  Group B (short shelf, freezable): \(groupB.count)")
        print("  Group C (long shelf life): \(groupC.count)")
        
        // Create all possible slots
        var slots: [(Weekday, MealType)] = []
        for day in params.days {
            for meal in params.meals {
                slots.append((day, meal))
            }
        }
        
        var recipeIndex = 0
        let allRecipes = groupA + groupC + groupB // Prioritize order
        
        // Assign recipes to slots in order
        for (_, slot) in slots.enumerated() {
            if recipeIndex < allRecipes.count {
                let recipe = allRecipes[recipeIndex]
                mappings.append((slot.0, slot.1, recipe))
                recipeIndex += 1
            }
        }
        
        return mappings
    }
    
    /// Apply meal prep kit to the current week plan
    func applyKitToWeekPlan(
        kit: MealPrepKit,
        params: MealPrepGenerationParams,
        planViewModel: PlanViewModel
    ) async {
        let mappings = mapKitToWeekPlan(kit: kit, params: params)
        
        // Clear existing meals for the specified days/meal types
        await clearExistingMeals(params: params, planViewModel: planViewModel)
        
        // Add mapped recipes to plan
        for (day, mealType, recipeRef) in mappings {
            if let recipe = recipeRef.recipe {
                let mealItem = MealItem(
                    id: UUID(),
                    weekday: day,
                    mealType: mealType,
                    recipe: recipe
                )
                await planViewModel.addMeal(mealItem: mealItem)
            }
        }
        
        print("✅ Applied meal prep kit to week plan: \(mappings.count) meals")
    }
    
    /// Clear existing meals for specified parameters
    private func clearExistingMeals(
        params: MealPrepGenerationParams,
        planViewModel: PlanViewModel
    ) async {
        // Remove meals matching the params days and meal types
        guard let plan = planViewModel.currentPlan else { return }
        
        for day in params.days {
            for mealType in params.meals {
                // Find and remove meal items that match the day and meal type
                if let mealItem = plan.items.first(where: { $0.weekday == day && $0.mealType == mealType }) {
                    planViewModel.removeMeal(mealItem: mealItem)
                }
            }
        }
    }
}
