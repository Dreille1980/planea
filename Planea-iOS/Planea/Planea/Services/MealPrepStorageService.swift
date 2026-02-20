import Foundation

class MealPrepStorageService {
    static let shared = MealPrepStorageService()
    
    private let historyKey = "mealPrepHistory"
    private let kitsKey = "mealPrepKits"  // NEW: Storage for raw backend kits
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {  // Private to enforce singleton
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
    
    // MARK: - Raw Kit Storage (from backend)
    
    /// Save a raw meal prep kit from backend
    func saveMealPrepKit(groupId: String, kitData: [String: Any]) {
        var allKits = loadAllMealPrepKits()
        allKits[groupId] = kitData
        
        // Save to UserDefaults
        if let data = try? JSONSerialization.data(withJSONObject: allKits) {
            UserDefaults.standard.set(data, forKey: kitsKey)
            print("✅ Saved kit for group: \(groupId)")
        }
    }
    
    /// Load a specific meal prep kit by group ID
    func loadMealPrepKit(groupId: String) -> [String: Any]? {
        let allKits = loadAllMealPrepKits()
        return allKits[groupId]
    }
    
    /// Load all meal prep kits
    func loadAllMealPrepKits() -> [String: [String: Any]] {
        guard let data = UserDefaults.standard.data(forKey: kitsKey),
              let kits = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            return [:]
        }
        return kits
    }
    
    /// Clear all stored kits
    func clearAllKits() {
        UserDefaults.standard.removeObject(forKey: kitsKey)
    }
    
    // MARK: - Kit Mapping Logic
    
    /// Map meal prep kit recipes to week plan slots based on storage metadata with adaptive shelf life validation
    func mapKitToWeekPlan(
        kit: MealPrepKit,
        params: MealPrepGenerationParams
    ) -> [(day: Weekday, mealType: MealType, recipe: MealPrepRecipeRef)] {
        var mappings: [(Weekday, MealType, MealPrepRecipeRef)] = []
        
        // Sort recipes by shelf life (shortest first for early consumption)
        let sortedRecipes = kit.recipes.sorted { r1, r2 in
            let shelf1 = r1.shelfLifeDays
            let shelf2 = r2.shelfLifeDays
            
            // Prioritize non-freezable short shelf life recipes first
            if !r1.isFreezable && r2.isFreezable {
                return true
            } else if r1.isFreezable && !r2.isFreezable {
                return false
            }
            
            return shelf1 < shelf2
        }
        
        print("📦 Mapping kit recipes with adaptive storage:")
        print("  Total recipes: \(sortedRecipes.count)")
        for (idx, recipe) in sortedRecipes.enumerated() {
            let freezable = recipe.isFreezable ? "❄️" : "🚫"
            print("  \(idx + 1). \(recipe.recipe?.title ?? "Unknown") - \(recipe.shelfLifeDays) days \(freezable)")
        }
        
        // Create slots in chronological order (day index represents days from prep day)
        var slots: [(dayIndex: Int, day: Weekday, mealType: MealType)] = []
        for (dayIndex, day) in params.days.enumerated() {
            for meal in params.meals {
                slots.append((dayIndex, day, meal))
            }
        }
        
        // Map recipes to slots with storage validation
        var availableRecipes = sortedRecipes
        
        for slot in slots {
            guard !availableRecipes.isEmpty else { break }
            
            let daysUntilConsumption = slot.dayIndex + 1 // +1 because prep day is day 0
            
            // Find suitable recipe for this slot
            if let suitableIndex = availableRecipes.firstIndex(where: { recipe in
                let canKeep = recipe.shelfLifeDays >= daysUntilConsumption
                let canFreeze = recipe.isFreezable
                return canKeep || canFreeze
            }) {
                let recipe = availableRecipes.remove(at: suitableIndex)
                mappings.append((slot.day, slot.mealType, recipe))
                
                let method = recipe.shelfLifeDays >= daysUntilConsumption ? "fridge" : "freezer"
                print("  ✅ Day \(daysUntilConsumption): \(recipe.recipe?.title ?? "Unknown") (\(method))")
            } else {
                // Fallback: use first available recipe (should not happen with proper generation)
                let recipe = availableRecipes.removeFirst()
                mappings.append((slot.day, slot.mealType, recipe))
                print("  ⚠️ Day \(daysUntilConsumption): \(recipe.recipe?.title ?? "Unknown") (fallback)")
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
