import Foundation
import Combine

final class PlanViewModel: ObservableObject {
    @Published var slots: Set<SlotSelection> = []
    @Published var draftPlan: MealPlan?
    @Published var confirmedPlans: [MealPlan] = []
    @Published var showConfirmationAlert = false
    
    private let persistence = PersistenceController.shared
    
    init() {
        loadPlans()
    }
    
    func loadPlans() {
        // Load current draft plan
        draftPlan = persistence.loadCurrentDraftPlan()
        
        // Load confirmed plans history
        confirmedPlans = persistence.loadConfirmedPlans()
    }
    
    func select(_ slot: SlotSelection) {
        slots.insert(slot)
    }
    
    func deselect(_ slot: SlotSelection) {
        slots.remove(slot)
    }
    
    func savePlan(_ plan: MealPlan) {
        var mutablePlan = plan
        mutablePlan.status = .draft
        draftPlan = mutablePlan
        persistence.saveMealPlan(mutablePlan)
    }
    
    func confirmCurrentPlan(withName name: String? = nil) {
        guard var plan = draftPlan else { return }
        
        // Update plan name if provided
        if let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            plan.name = name
            persistence.saveMealPlan(plan)
        }
        
        persistence.confirmPlan(id: plan.id)
        loadPlans()
    }
    
    func restorePlan(plan: MealPlan) {
        // Create a new draft from the confirmed plan
        var newDraft = plan
        newDraft.id = UUID()
        newDraft.status = .draft
        newDraft.confirmedDate = nil
        newDraft.weekStart = Date()
        
        // If there's an existing draft, confirm it first
        if let existingDraft = draftPlan {
            persistence.confirmPlan(id: existingDraft.id)
        }
        
        savePlan(newDraft)
    }
    
    func deletePlan(plan: MealPlan) {
        persistence.deletePlan(id: plan.id)
        loadPlans()
    }
    
    func regenerateMeal(mealItem: MealItem, newRecipe: Recipe) {
        guard var plan = draftPlan else { return }
        
        // Find and replace the meal item
        if let index = plan.items.firstIndex(where: { $0.id == mealItem.id }) {
            let updatedItem = MealItem(
                id: mealItem.id,
                weekday: mealItem.weekday,
                mealType: mealItem.mealType,
                recipe: newRecipe
            )
            plan.items[index] = updatedItem
            draftPlan = plan
            persistence.saveMealPlan(plan)
        }
    }
    
    func removeMeal(mealItem: MealItem) {
        guard var plan = draftPlan else { return }
        
        // Remove the meal item
        plan.items.removeAll(where: { $0.id == mealItem.id })
        
        // If no items left, clear the plan
        if plan.items.isEmpty {
            draftPlan = nil
        } else {
            draftPlan = plan
            persistence.saveMealPlan(plan)
        }
    }
    
    func addMeal(mealItem: MealItem) {
        guard var plan = draftPlan else { return }
        
        // Add the new meal item
        plan.items.append(mealItem)
        draftPlan = plan
        persistence.saveMealPlan(plan)
    }
    
    func hasMealInSlot(weekday: Weekday, mealType: MealType) -> Bool {
        guard let plan = draftPlan else { return false }
        return plan.items.contains(where: { $0.weekday == weekday && $0.mealType == mealType })
    }
}
