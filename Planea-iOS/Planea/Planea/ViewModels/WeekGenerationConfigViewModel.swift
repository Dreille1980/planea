import Foundation
import Combine

@MainActor
final class WeekGenerationConfigViewModel: ObservableObject {
    @Published var config: WeekGenerationConfig
    @Published var currentStep: Int = 0
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    private let planViewModel: PlanViewModel
    private let persistence = PersistenceController.shared
    
    init(planViewModel: PlanViewModel) {
        self.planViewModel = planViewModel
        
        // Load family to get size
        let (family, _) = persistence.loadFamily()
        let familySize = family?.members.count ?? 4
        
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
    
    func toggleDay(_ dayConfig: Binding<DayConfig>) {
        dayConfig.wrappedValue.selected.toggle()
        
        // If deselecting, auto-recalculate portions
        if config.hasMealPrep {
            config.recalculateMealPrepPortions()
        }
    }
    
    func setDayType(_ dayConfig: Binding<DayConfig>, type: DayMealType) {
        dayConfig.wrappedValue.mealType = type
        
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
    
    func generate() async {
        guard config.isValid else {
            errorMessage = NSLocalizedString("wizard.error.invalid_config", comment: "")
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        do {
            // Call PlanViewModel to generate the week
            try await planViewModel.generateWeekWithConfig(config)
            
            // Analytics
            AnalyticsService.shared.logEvent(
                name: "week_generated_with_wizard",
                parameters: [
                    "meal_prep_days": mealPrepDaysCount,
                    "normal_days": normalDaysCount,
                    "total_portions": config.mealPrepPortions,
                    "meal_types": config.mealPrepMealTypeSelection.rawValue
                ]
            )
            
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsService.shared.logEvent(
                name: "week_generation_failed",
                parameters: [
                    "error": error.localizedDescription
                ]
            )
        }
        
        isGenerating = false
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
}
