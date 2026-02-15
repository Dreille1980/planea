import Foundation
import SwiftUI
import FirebaseAnalytics

@MainActor
class MealPrepViewModel: ObservableObject {
    @Published var history: [MealPrepInstance] = []
    @Published var generatedKits: [MealPrepKit] = []
    @Published var kits: [MealPrepKit] = []  // ✨ NEW - All saved kits
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    // Concept selection
    @Published var concepts: [MealPrepConcept] = []
    @Published var selectedConcept: MealPrepConcept?
    @Published var customConceptText: String = ""
    @Published var isLoadingConcepts: Bool = false
    @Published var conceptsError: String?
    
    private let service: MealPrepService
    private let storageService: MealPrepStorageService
    
    init(baseURL: URL) {
        self.service = MealPrepService(baseURL: baseURL)
        self.storageService = MealPrepStorageService()
        loadHistory()
    }
    
    // MARK: - History Management
    
    func loadHistory() {
        history = storageService.loadMealPrepHistory()
        // Also update kits from history
        kits = history.map { $0.kit }
    }
    
    // ✨ NEW - Load meal preps for picker
    func loadMealPreps() {
        loadHistory()
    }
    
    func deleteHistoryItem(id: UUID) {
        storageService.deleteMealPrepInstance(id: id)
        loadHistory()
    }
    
    func clearHistory() {
        storageService.clearHistory()
        loadHistory()
    }
    
    // MARK: - Concept Selection
    
    func loadConcepts(
        constraints: [String: Any],
        language: String
    ) async {
        isLoadingConcepts = true
        conceptsError = nil
        
        do {
            concepts = try await service.generateConcepts(
                constraints: constraints,
                language: language
            )
            print("✅ Loaded \(concepts.count) concepts")
        } catch {
            conceptsError = error.localizedDescription
            print("❌ Error loading concepts: \(error)")
        }
        
        isLoadingConcepts = false
    }
    
    // MARK: - Kit Generation
    
    func generateKits(
        params: MealPrepGenerationParams,
        constraints: [String: Any],
        units: UnitSystem,
        language: String
    ) async {
        isGenerating = true
        errorMessage = nil
        generatedKits = []
        
        do {
            let kits = try await service.generateMealPrepKits(
                params: params,
                constraints: constraints,
                units: units,
                language: language,
                selectedConcept: selectedConcept,
                customConceptText: customConceptText
            )
            
            generatedKits = kits
            print("✅ Generated \(kits.count) meal prep kits")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error generating kits: \(error)")
        }
        
        isGenerating = false
    }
    
    // MARK: - Kit Application
    
    func confirmKit(
        _ kit: MealPrepKit,
        params: MealPrepGenerationParams,
        planViewModel: PlanViewModel,
        usageViewModel: UsageViewModel,
        shoppingViewModel: ShoppingViewModel
    ) async -> Int {
        // Record usage - 1 generation per recipe in the kit
        usageViewModel.recordGenerations(count: kit.recipes.count)
        
        // Save to history
        let instance = MealPrepInstance(
            kit: kit,
            appliedWeekStart: Date()
        )
        storageService.saveMealPrepInstance(instance)
        loadHistory()
        
        // Apply to week plan
        await storageService.applyKitToWeekPlan(
            kit: kit,
            params: params,
            planViewModel: planViewModel
        )
        
        // Add all ingredients to shopping list
        var totalIngredientsAdded = 0
        for recipeRef in kit.recipes {
            if let recipe = recipeRef.recipe {
                shoppingViewModel.addRecipeToList(recipe: recipe)
                totalIngredientsAdded += recipe.ingredients.count
            }
        }
        
        return totalIngredientsAdded
    }
    
    /// Replay a meal prep from history
    func replayMealPrep(
        instance: MealPrepInstance,
        params: MealPrepGenerationParams,
        planViewModel: PlanViewModel
    ) async {
        // Note: Replay doesn't count as new generation since it's reusing existing recipes
        
        // Create new instance with current date
        let newInstance = MealPrepInstance(
            kit: instance.kit,
            appliedWeekStart: Date()
        )
        
        storageService.saveMealPrepInstance(newInstance)
        loadHistory()
        
        // Apply to week plan
        await storageService.applyKitToWeekPlan(
            kit: instance.kit,
            params: params,
            planViewModel: planViewModel
        )
    }
    
    // MARK: - Helpers
    
    func formatPrepTime(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h\(mins)"
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - ✨ NEW - Portion Assignment (Phase 2)
    
    /// Assigne un MealPrep à une journée du plan
    func assignToWeek(
        kit: MealPrepKit,
        date: Date,
        mealType: MealType,
        portions: Int,
        recipeId: String? = nil
    ) {
        do {
            // Find the kit in history
            guard let instanceIndex = history.firstIndex(where: { $0.kit.id == kit.id }) else {
                errorMessage = NSLocalizedString("mealprep.error.kit_not_found", comment: "")
                return
            }
            
            var mutableKit = history[instanceIndex].kit
            
            // Créer l'assignment
            let assignment = try mutableKit.assignPortions(
                date: date,
                mealType: mealType,
                portions: portions,
                specificRecipeId: recipeId
            )
            
            // Mettre à jour le kit dans l'historique
            var updatedInstance = history[instanceIndex]
            updatedInstance = MealPrepInstance(
                id: updatedInstance.id,
                kit: mutableKit,
                appliedWeekStart: updatedInstance.appliedWeekStart,
                createdAt: updatedInstance.createdAt
            )
            
            // Sauvegarder
            storageService.updateMealPrepInstance(updatedInstance)
            loadHistory()
            
            // Analytics
            AnalyticsService.shared.logMealPrepAssigned(
                kitID: kit.id.uuidString,
                kitName: kit.name,
                portions: portions,
                date: date.description
            )
            
            print("✅ Assigned \(portions) portions of \(kit.name) to \(date)")
            
        } catch let error as MealPrepError {
            errorMessage = error.localizedDescription
            print("❌ Error assigning meal prep: \(error)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Unexpected error: \(error)")
        }
    }
    
    /// Retire une assignation
    func unassignFromWeek(assignment: MealPrepAssignment) {
        do {
            // Find the kit containing this assignment
            guard let instanceIndex = history.firstIndex(where: { instance in
                instance.kit.assignments.contains(where: { $0.id == assignment.id })
            }) else {
                errorMessage = NSLocalizedString("mealprep.error.assignment_not_found", comment: "")
                return
            }
            
            var mutableKit = history[instanceIndex].kit
            try mutableKit.unassign(assignment.id)
            
            // Mettre à jour
            var updatedInstance = history[instanceIndex]
            updatedInstance = MealPrepInstance(
                id: updatedInstance.id,
                kit: mutableKit,
                appliedWeekStart: updatedInstance.appliedWeekStart,
                createdAt: updatedInstance.createdAt
            )
            
            storageService.updateMealPrepInstance(updatedInstance)
            loadHistory()
            
            // Analytics
            AnalyticsService.shared.logMealPrepUnassigned(
                assignmentID: assignment.id.uuidString,
                reason: "user_action"
            )
            
            print("✅ Unassigned \(assignment.portionsUsed) portions")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error unassigning: \(error)")
        }
    }
}

// MARK: - ✨ NEW - Analytics Extension

extension AnalyticsService {
    func logMealPrepAssigned(kitID: String, kitName: String, portions: Int, date: String) {
        Analytics.logEvent("meal_prep_assigned", parameters: [
            "kit_id": kitID,
            "kit_name": kitName,
            "portions": portions,
            "date": date
        ])
    }
    
    func logMealPrepUnassigned(assignmentID: String, reason: String) {
        Analytics.logEvent("meal_prep_unassigned", parameters: [
            "assignment_id": assignmentID,
            "reason": reason
        ])
    }
}
