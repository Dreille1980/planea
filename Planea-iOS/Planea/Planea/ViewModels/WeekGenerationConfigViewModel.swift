import Foundation
import Combine

// MARK: - Config Model

struct WeekGenerationConfig {
    var selectedSlots: [SlotSelection] = []
    var mealPrepGroupId: UUID = UUID()

    var hasMealPrep: Bool {
        selectedSlots.contains { $0.isMealPrep }
    }
}

// MARK: - ViewModel

@MainActor
final class WeekGenerationConfigViewModel: ObservableObject {

    // MARK: Navigation
    @Published var currentStep: Int = 0
    @Published var generationSuccess: Bool = false

    // MARK: Config
    @Published var config: WeekGenerationConfig = WeekGenerationConfig()

    // MARK: Generation state
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?

    // MARK: Private
    private let planViewModel: PlanViewModel

    // MARK: Computed

    var totalSteps: Int {
        config.hasMealPrep ? 2 : 1
    }

    var selectedDaysCount: Int {
        config.selectedSlots.count
    }

    var canProceed: Bool {
        if currentStep == 0 {
            return !config.selectedSlots.isEmpty
        }
        return true
    }

    // MARK: Init

    init(planViewModel: PlanViewModel) {
        self.planViewModel = planViewModel
    }

    // MARK: Navigation

    func canGoBack() -> Bool {
        currentStep > 0
    }

    func nextStep() {
        guard currentStep < totalSteps - 1 else { return }
        currentStep += 1
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    func resetSuccessState() {
        generationSuccess = false
    }

    // MARK: Generation

    func generate(familyVM: FamilyViewModel, unitSystem: String, appLanguage: String) async {
        isGenerating = true
        errorMessage = nil

        do {
            let service = IAService(baseURL: URL(string: Config.baseURL)!)
            let units = UnitSystem(rawValue: unitSystem) ?? .metric
            let constraints = familyVM.aggregatedConstraints()
            let dislikedProteins = familyVM.aggregatedDislikedProteins()
            let constraintsDict: [String: Any] = [
                "diet": constraints.diet,
                "evict": constraints.evict,
                "excludedProteins": dislikedProteins
            ]

            let language = String(AppLanguage.currentLocale(appLanguage).prefix(2).lowercased())
            let servings = max(1, familyVM.members.count)

            let plan = try await service.generatePlan(
                weekStart: Date(),
                slots: config.selectedSlots,
                constraints: constraintsDict,
                servings: servings,
                units: units,
                language: language
            )

            planViewModel.savePlan(plan)

            // Record usage
            let usageVM = UsageViewModel()
            usageVM.recordGenerations(count: plan.items.count)

            generationSuccess = true
        } catch let urlError as URLError {
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
        } catch {
            errorMessage = "\("plan.error".localized): \(error.localizedDescription)"
        }

        isGenerating = false
    }
}
