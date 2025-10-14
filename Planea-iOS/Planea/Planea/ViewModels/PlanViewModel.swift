import Foundation
import Combine

final class PlanViewModel: ObservableObject {
    @Published var slots: Set<SlotSelection> = []
    @Published var currentPlan: MealPlan?
    
    private let persistence = PersistenceController.shared
    
    init() {
        loadLatestPlan()
    }
    
    func select(_ slot: SlotSelection) {
        slots.insert(slot)
    }
    
    func deselect(_ slot: SlotSelection) {
        slots.remove(slot)
    }
    
    func savePlan(_ plan: MealPlan) {
        currentPlan = plan
        persistence.saveMealPlan(plan)
    }
    
    func loadLatestPlan() {
        let plans = persistence.loadMealPlans()
        currentPlan = plans.first
    }
    
    func regenerateMeal(mealItem: MealItem, newRecipe: Recipe) {
        guard var plan = currentPlan else { return }
        
        // Find and replace the meal item
        if let index = plan.items.firstIndex(where: { $0.id == mealItem.id }) {
            let updatedItem = MealItem(
                id: mealItem.id,
                weekday: mealItem.weekday,
                mealType: mealItem.mealType,
                recipe: newRecipe
            )
            plan.items[index] = updatedItem
            currentPlan = plan
            persistence.saveMealPlan(plan)
        }
    }
    
    func removeMeal(mealItem: MealItem) {
        guard var plan = currentPlan else { return }
        
        // Remove the meal item
        plan.items.removeAll(where: { $0.id == mealItem.id })
        
        // If no items left, clear the plan
        if plan.items.isEmpty {
            currentPlan = nil
        } else {
            currentPlan = plan
            persistence.saveMealPlan(plan)
        }
    }
    
    func addMeal(mealItem: MealItem) {
        guard var plan = currentPlan else { return }
        
        // Add the new meal item
        plan.items.append(mealItem)
        currentPlan = plan
        persistence.saveMealPlan(plan)
    }
    
    func hasMealInSlot(weekday: Weekday, mealType: MealType) -> Bool {
        guard let plan = currentPlan else { return false }
        return plan.items.contains(where: { $0.weekday == weekday && $0.mealType == mealType })
    }
}
