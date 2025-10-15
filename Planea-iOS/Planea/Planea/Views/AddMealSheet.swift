import SwiftUI

struct AddMealSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    
    @State private var selectedDay: Weekday = .monday
    @State private var selectedMealType: MealType = .lunch
    @State private var customTitle: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    @State private var showConflictAlert: Bool = false
    @State private var conflictAction: ConflictAction = .replace
    @State private var generatedRecipe: Recipe?
    
    enum ConflictAction {
        case replace, add
    }
    
    let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    let mealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]
    
    var body: some View {
        NavigationStack {
            Form {
                // Day selection
                Section {
                    Picker(String(localized: "add_meal.select_day"), selection: $selectedDay) {
                        ForEach(weekdays, id: \.self) { day in
                            Text(dayLabel(for: day)).tag(day)
                        }
                    }
                } header: {
                    Text(String(localized: "add_meal.day"))
                }
                
                // Meal type selection
                Section {
                    Picker(String(localized: "add_meal.select_meal_type"), selection: $selectedMealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            HStack {
                                Image(systemName: iconName(for: type))
                                Text(mealLabel(for: type))
                            }
                            .tag(type)
                        }
                    }
                } header: {
                    Text(String(localized: "add_meal.meal_type"))
                }
                
                // Manual entry section
                Section {
                    TextField(String(localized: "add_meal.enter_title"), text: $customTitle)
                    
                    Button(action: {
                        Task {
                            await generateFromTitle()
                        }
                    }) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "text.badge.sparkles")
                                Text(String(localized: "add_meal.generate_from_title"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(customTitle.isEmpty || isGenerating)
                } header: {
                    Text(String(localized: "add_meal.manual_entry"))
                } footer: {
                    Text(String(localized: "add_meal.manual_entry_footer"))
                        .font(.caption)
                }
                
                // AI Generation section
                Section {
                    Button(action: {
                        Task {
                            await generateWithAI()
                        }
                    }) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "sparkles")
                                Text(String(localized: "add_meal.generate_with_ai"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isGenerating)
                } header: {
                    Text(String(localized: "add_meal.ai_generation"))
                } footer: {
                    Text(String(localized: "add_meal.ai_generation_footer"))
                        .font(.caption)
                }
                
                // Error message
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(String(localized: "add_meal.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) {
                        dismiss()
                    }
                }
            }
            .alert(String(localized: "add_meal.conflict_title"), isPresented: $showConflictAlert) {
                Button(String(localized: "add_meal.replace"), role: .destructive) {
                    conflictAction = .replace
                    addMealToPlan()
                }
                Button(String(localized: "add_meal.add_anyway")) {
                    conflictAction = .add
                    addMealToPlan()
                }
                Button(String(localized: "action.cancel"), role: .cancel) {
                    generatedRecipe = nil
                }
            } message: {
                Text(String(localized: "add_meal.conflict_message"))
            }
        }
    }
    
    func generateFromTitle() async {
        guard !customTitle.isEmpty else { return }
        
        isGenerating = true
        errorMessage = nil
        
        do {
            let service = IAService(baseURL: URL(string: Config.baseURL)!)
            let units = UnitSystem(rawValue: unitSystem) ?? .metric
            let constraints = familyVM.aggregatedConstraints()
            let constraintsDict: [String: Any] = [
                "diet": constraints.diet,
                "evict": constraints.evict
            ]
            
            let language = AppLanguage.currentLocale(appLanguage).prefix(2).lowercased()
            
            let recipe = try await service.generateRecipeFromTitle(
                title: customTitle,
                servings: 4,
                constraints: constraintsDict,
                units: units,
                language: String(language)
            )
            
            generatedRecipe = recipe
            checkForConflictAndAdd()
            
        } catch {
            errorMessage = "\(String(localized: "plan.error")): \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
    
    func generateWithAI() async {
        isGenerating = true
        errorMessage = nil
        
        do {
            let service = IAService(baseURL: URL(string: Config.baseURL)!)
            let units = UnitSystem(rawValue: unitSystem) ?? .metric
            let constraints = familyVM.aggregatedConstraints()
            let constraintsDict: [String: Any] = [
                "diet": constraints.diet,
                "evict": constraints.evict
            ]
            
            let language = AppLanguage.currentLocale(appLanguage).prefix(2).lowercased()
            
            let recipe = try await service.regenerateMeal(
                weekday: selectedDay,
                mealType: selectedMealType,
                constraints: constraintsDict,
                servings: 4,
                units: units,
                language: String(language),
                diversitySeed: Int.random(in: 0...1000)
            )
            
            generatedRecipe = recipe
            checkForConflictAndAdd()
            
        } catch {
            errorMessage = "\(String(localized: "plan.error")): \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
    
    func checkForConflictAndAdd() {
        // Check if a meal already exists in this slot
        if planVM.hasMealInSlot(weekday: selectedDay, mealType: selectedMealType) {
            showConflictAlert = true
        } else {
            addMealToPlan()
        }
    }
    
    func addMealToPlan() {
        guard let recipe = generatedRecipe else { return }
        
        // If replacing, remove existing meal first
        if conflictAction == .replace {
            if let existingMeal = planVM.currentPlan?.items.first(where: { 
                $0.weekday == selectedDay && $0.mealType == selectedMealType 
            }) {
                planVM.removeMeal(mealItem: existingMeal)
            }
        }
        
        // Add new meal
        let newMeal = MealItem(
            id: UUID(),
            weekday: selectedDay,
            mealType: selectedMealType,
            recipe: recipe
        )
        
        withAnimation {
            planVM.addMeal(mealItem: newMeal)
        }
        
        dismiss()
    }
    
    func dayLabel(for day: Weekday) -> String {
        switch day {
        case .monday: return String(localized: "week.monday")
        case .tuesday: return String(localized: "week.tuesday")
        case .wednesday: return String(localized: "week.wednesday")
        case .thursday: return String(localized: "week.thursday")
        case .friday: return String(localized: "week.friday")
        case .saturday: return String(localized: "week.saturday")
        case .sunday: return String(localized: "week.sunday")
        }
    }
    
    func mealLabel(for type: MealType) -> String {
        switch type {
        case .breakfast: return String(localized: "meal.breakfast")
        case .lunch: return String(localized: "meal.lunch")
        case .dinner: return String(localized: "meal.dinner")
        case .snack: return String(localized: "meal.snack")
        }
    }
    
    func iconName(for type: MealType) -> String {
        switch type {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
}
