import Foundation
import Combine

final class PlanViewModel: ObservableObject {
    @Published var slots: Set<SlotSelection> = []
    @Published var currentPlan: MealPlan?  // Plan en cours d'édition (draft ou active)
    @Published var activePlan: MealPlan?   // Plan de la semaine actif
    @Published var archivedPlans: [MealPlan] = []  // Historique des plans
    @Published var showConfirmationAlert = false
    
    private let persistence = PersistenceController.shared
    
    init() {
        loadPlans()
    }
    
    func loadPlans() {
        // Load active plan first
        activePlan = persistence.loadActivePlan()
        
        // If there's an active plan, use it as current plan
        // Otherwise, check for draft plan
        if let active = activePlan {
            currentPlan = active
        } else {
            currentPlan = persistence.loadCurrentDraftPlan()
        }
        
        // Load archived plans for history
        archivedPlans = persistence.loadArchivedPlans()
    }
    
    func select(_ slot: SlotSelection) {
        slots.insert(slot)
    }
    
    func deselect(_ slot: SlotSelection) {
        slots.remove(slot)
    }
    
    @MainActor func savePlan(_ plan: MealPlan) {
        var mutablePlan = plan
        mutablePlan.status = .draft
        currentPlan = mutablePlan
        persistence.saveMealPlan(mutablePlan)
        
        // Record that 1 generation was used (1 plan = 1 generation)
        let usageVM = UsageViewModel()
        usageVM.recordGenerations(count: 1)
    }
    
    func activateCurrentPlan(withName name: String? = nil) {
        guard var plan = currentPlan else { return }
        
        // Update plan name if provided
        if let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            plan.name = name
            persistence.saveMealPlan(plan)
        }
        
        // Activate the plan (archives any existing active plan)
        persistence.activatePlan(id: plan.id)
        loadPlans()
    }
    
    func archiveAndStartNew() {
        // Archive the current active plan
        if let active = activePlan {
            persistence.archivePlan(id: active.id)
        }
        
        // Clear current state to start fresh
        currentPlan = nil
        activePlan = nil
        slots.removeAll()
        
        loadPlans()
    }
    
    func startEditingActivePlan() {
        // Allow editing the active plan by keeping it as current
        if let active = activePlan {
            currentPlan = active
        }
    }
    
    func deletePlan(plan: MealPlan) {
        persistence.deletePlan(id: plan.id)
        loadPlans()
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
    
    @MainActor func addMeal(mealItem: MealItem) {
        guard var plan = currentPlan else { return }
        
        // Add the new meal item
        plan.items.append(mealItem)
        currentPlan = plan
        persistence.saveMealPlan(plan)
        
        // Record that 1 generation was used for adding a meal
        let usageVM = UsageViewModel()
        usageVM.recordGenerations(count: 1)
    }
    
    func hasMealInSlot(weekday: Weekday, mealType: MealType) -> Bool {
        guard let plan = currentPlan else { return false }
        return plan.items.contains(where: { $0.weekday == weekday && $0.mealType == mealType })
    }
}
