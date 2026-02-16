import Foundation
import Combine
import SwiftUI
import FirebaseAnalytics

@MainActor
final class WeekGenerationConfigViewModel: ObservableObject {
    @Published var config: WeekGenerationConfig
    @Published var currentStep: Int = 0
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var generationSuccess: Bool = false
    @Published var generatedPlan: MealPlan?
    
    private let planViewModel: PlanViewModel
    private let persistence = PersistenceController.shared
    
    init(planViewModel: PlanViewModel) {
        self.planViewModel = planViewModel
        
        // Load members to get family size
        let (_, members) = persistence.loadFamily()
        let familySize = members.count > 0 ? members.count : 4
        
        // Load preferences to get week start day
        let preferences = PreferencesService.shared.loadPreferences()
        
        // Initialize config
        self.config = WeekGenerationConfig.default(
            familySize: familySize,
            weekStartDay: preferences.weekStartDay
        )
    }
    
    // MARK: - Computed Properties
    
    var totalSteps: Int {
        config.hasMealPrep ? 3 : 2  // Step 2 (Meal Prep Config) is conditional
    }
    
    var canProceed: Bool {
        config.canProceedFromStep(currentStep)
    }
    
    var mealPrepDaysCount: Int {
        config.mealPrepDays.count
    }
    
    var normalDaysCount: Int {
        config.normalDays.count
    }
    
    var selectedDaysCount: Int {
        config.selectedDays.count
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        guard currentStep < totalSteps - 1 else { return }
        
        // If moving from step 1 and no meal prep, skip step 2
        if currentStep == 0 && !config.hasMealPrep {
            currentStep = 2  // Skip to preferences
        } else {
            currentStep += 1
        }
        
        // Recalculate portions when entering meal prep config
        if currentStep == 1 && config.hasMealPrep {
            config.recalculateMealPrepPortions()
        }
    }
    
    func previousStep() {
        guard currentStep > 0 else { return }
        
        // If moving back from step 2 (preferences) and no meal prep, skip step 1
        if currentStep == 2 && !config.hasMealPrep {
            currentStep = 0  // Skip back to day selection
        } else {
            currentStep -= 1
        }
    }
    
    func canGoBack() -> Bool {
        return currentStep > 0
    }
    
    // MARK: - Day Configuration
    
    func toggleDay(_ dayConfig: inout DayConfig) {
        dayConfig.selected.toggle()
        
        // If deselecting, auto-recalculate portions
        if config.hasMealPrep {
            config.recalculateMealPrepPortions()
        }
    }
    
    func setDayType(_ dayConfig: inout DayConfig, type: DayMealType) {
        dayConfig.mealType = type
        
        // Auto-recalculate portions when changing to/from meal prep
        config.recalculateMealPrepPortions()
    }
    
    // MARK: - Meal Prep Configuration
    
    func updateMealPrepMealTypeSelection(_ selection: MealPrepMealTypeSelection) {
        config.mealPrepMealTypeSelection = selection
        config.recalculateMealPrepPortions()
    }
    
    func updateMealPrepPortions(_ portions: Int) {
        config.mealPrepPortions = max(1, portions)
    }
    
    // MARK: - Generation
    
    func generate(
        familyVM: FamilyViewModel,
        unitSystem: String,
        appLanguage: String
    ) async {
        guard config.isValid else {
            errorMessage = NSLocalizedString("wizard.error.invalid_config", comment: "")
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        do {
            // Generate the plan using the config
            let plan = try await planViewModel.generateWeekWithConfig(
                config: config,
                familyVM: familyVM,
                unitSystem: unitSystem,
                appLanguage: appLanguage
            )
            
            // Save the plan
            await planViewModel.savePlan(plan)
            
            // Analytics
            Analytics.logEvent("week_generated_with_wizard", parameters: [
                "meal_prep_days": mealPrepDaysCount as NSObject,
                "normal_days": normalDaysCount as NSObject,
                "total_portions": config.mealPrepPortions as NSObject,
                "meal_types": config.mealPrepMealTypeSelection.rawValue as NSObject,
                "total_meals": plan.items.count as NSObject
            ])
            
            // Set success state
            generatedPlan = plan
            generationSuccess = true
            isGenerating = false
        } catch {
            isGenerating = false
            
            // Handle errors with localized messages
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    errorMessage = "Aucune connexion Internet. Vérifiez votre WiFi ou données cellulaires."
                case .timedOut:
                    errorMessage = "Le serveur ne répond pas. Réessayez dans quelques instants."
                case .cannotFindHost, .cannotConnectToHost:
                    errorMessage = "Impossible de contacter le serveur. Vérifiez votre connexion."
                default:
                    errorMessage = "Erreur réseau: \(urlError.localizedDescription)"
                }
            } else {
                errorMessage = "Erreur: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Step Labels
    
    func stepLabel(for step: Int) -> String {
        switch step {
        case 0:
            return NSLocalizedString("wizard.step1.title", comment: "")
        case 1:
            return NSLocalizedString("wizard.step2.title", comment: "")
        case 2:
            return NSLocalizedString("wizard.step3.title", comment: "")
        default:
            return ""
        }
    }
    
    func stepNumber(for step: Int) -> String {
        "\(step + 1)/\(totalSteps)"
    }
    
    // MARK: - Success State Reset
    
    func resetSuccessState() {
        generationSuccess = false
        generatedPlan = nil
    }
}
