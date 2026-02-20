import Foundation
import SwiftUI

@MainActor
class MealPrepViewModel: ObservableObject {
    @Published var history: [MealPrepInstance] = []
    @Published var generatedKits: [MealPrepKit] = []
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    // Concept selection
    @Published var concepts: [MealPrepConcept] = []
    @Published var selectedConcept: MealPrepConcept?
    @Published var customConceptText: String = ""
    @Published var isLoadingConcepts: Bool = false
    @Published var conceptsError: String?
    
    private let service: MealPrepService
    private let storageService = MealPrepStorageService.shared  // Use singleton
    
    init(baseURL: URL) {
        self.service = MealPrepService(baseURL: baseURL)
        loadHistory()
    }
    
    // MARK: - History Management
    
    func loadHistory() {
        history = storageService.loadMealPrepHistory()
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
}
