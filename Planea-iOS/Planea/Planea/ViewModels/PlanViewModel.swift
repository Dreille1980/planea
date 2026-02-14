import Foundation
import Combine

final class PlanViewModel: ObservableObject {
    @Published var slots: Set<SlotSelection> = []
    @Published var currentPlan: MealPlan?  // Plan en cours d'édition (draft ou active)
    @Published var activePlan: MealPlan?   // Plan de la semaine actif
    @Published var archivedPlans: [MealPlan] = []  // Historique des plans
    @Published var showConfirmationAlert = false
    
    // Template support
    @Published var templates: [TemplateWeek] = []
    @Published var showApplyTemplateSheet = false
    @Published var selectedTemplate: TemplateWeek?
    
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
        
        // Log recipe generation to Analytics
        AnalyticsService.shared.logRecipeGenerated(
            type: "plan",
            recipeCount: plan.items.count
        )
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
        
        // Log to Analytics
        AnalyticsService.shared.logRecipeGenerated(
            type: "plan",
            recipeCount: 1
        )
    }
    
    func hasMealInSlot(weekday: Weekday, mealType: MealType) -> Bool {
        guard let plan = currentPlan else { return false }
        return plan.items.contains(where: { $0.weekday == weekday && $0.mealType == mealType })
    }
    
    // MARK: - Add Favorite Recipe to Plan
    
    @MainActor func addFavoriteRecipeToSlot(recipe: Recipe, weekday: Weekday, mealType: MealType, replaceIfExists: Bool) {
        // Get or create current plan
        var plan = getOrCreateCurrentPlan()
        
        // If replacing, remove existing meal first
        if replaceIfExists {
            plan.items.removeAll(where: { $0.weekday == weekday && $0.mealType == mealType })
        }
        
        // Create new meal item with the favorite recipe
        let newMeal = MealItem(
            id: UUID(),
            weekday: weekday,
            mealType: mealType,
            recipe: recipe
        )
        
        // Add to plan
        plan.items.append(newMeal)
        
        // Update current plan and save
        currentPlan = plan
        persistence.saveMealPlan(plan)
        
        // Note: We do NOT record usage here - adding favorites is free!
        
        // Log to Analytics
        let weekDateFormatter = DateFormatter()
        weekDateFormatter.dateFormat = "yyyy-MM-dd"
        AnalyticsService.shared.logFavoriteAddedToWeek(
            recipeID: recipe.id.uuidString,
            recipeTitle: recipe.title,
            weekDate: weekDateFormatter.string(from: plan.weekStart)
        )
    }
    
    private func getOrCreateCurrentPlan() -> MealPlan {
        // If current plan exists, return it
        if let existing = currentPlan {
            return existing
        }
        
        // Load family to get the familyId
        let (family, _) = persistence.loadFamily()
        let familyId = family?.id ?? UUID() // Use existing family ID or create a new one
        
        // Otherwise, create a new draft plan
        let newPlan = MealPlan(
            id: UUID(),
            familyId: familyId,
            weekStart: Date(),
            items: [],
            status: .draft,
            confirmedDate: nil,
            name: nil
        )
        
        return newPlan
    }
    
    // MARK: - Template Operations
    
    func loadTemplates() {
        templates = persistence.loadTemplateWeeks()
    }
    
    func saveTemplate(_ template: TemplateWeek) {
        persistence.saveTemplateWeek(template)
        loadTemplates()
        
        // Analytics
        AnalyticsService.shared.logEvent(
            name: "template_created",
            parameters: ["template_name": template.name]
        )
    }
    
    func saveCurrentPlanAsTemplate(name: String) {
        guard let plan = currentPlan else { return }
        
        // Validate the plan can be converted
        guard MealPlanAdapter.canConvert(plan) else {
            print("⚠️ Cannot convert plan to template: plan has invalid data")
            return
        }
        
        // Convert to template
        let template = MealPlanAdapter.mealPlanToTemplate(plan, name: name)
        saveTemplate(template)
    }
    
    func applyTemplate(_ template: TemplateWeek, startDate: Date) {
        // Apply template to create PlannedWeek
        let plannedWeek = WeekDateHelper.applyTemplate(template, to: startDate)
        
        // Convert to legacy MealPlan for compatibility
        let legacyPlan = MealPlanAdapter.toMealPlan(plannedWeek)
        
        // Save as current plan
        currentPlan = legacyPlan
        persistence.saveMealPlan(legacyPlan)
        
        // Analytics
        AnalyticsService.shared.logEvent(
            name: "template_applied",
            parameters: [
                "template_id": template.id.uuidString,
                "template_name": template.name,
                "start_date": startDate.description
            ]
        )
    }
    
    func deleteTemplate(id: UUID) {
        persistence.deleteTemplateWeek(id: id)
        loadTemplates()
        
        // Analytics
        AnalyticsService.shared.logEvent(
            name: "template_deleted",
            parameters: ["template_id": id.uuidString]
        )
    }
}
