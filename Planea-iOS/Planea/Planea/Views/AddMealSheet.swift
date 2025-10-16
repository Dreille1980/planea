import SwiftUI

struct AddMealSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    
    @State private var selectedDay: Weekday = .monday
    @State private var selectedMealType: MealType = .lunch
    @State private var customTitle: String = ""
    @State private var isGenerating: Bool = false
    @State private var errorMessage: String?
    @State private var showConflictAlert: Bool = false
    @State private var showPaywall: Bool = false
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
                    Picker("add_meal.select_day".localized, selection: $selectedDay) {
                        ForEach(weekdays, id: \.self) { day in
                            Text(dayLabel(for: day)).tag(day)
                        }
                    }
                } header: {
                    Text("add_meal.day".localized)
                }
                
                // Meal type selection
                Section {
                    Picker("add_meal.select_meal_type".localized, selection: $selectedMealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            HStack {
                                Image(systemName: iconName(for: type))
                                Text(mealLabel(for: type))
                            }
                            .tag(type)
                        }
                    }
                } header: {
                    Text("add_meal.meal_type".localized)
                }
                
                // Manual entry section
                Section {
                    TextField("add_meal.enter_title".localized, text: $customTitle)
                    
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
                                Text("add_meal.generate_from_title".localized)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(customTitle.isEmpty || isGenerating)
                } header: {
                    Text("add_meal.manual_entry".localized)
                } footer: {
                    Text("add_meal.manual_entry_footer".localized)
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
                                Text("add_meal.generate_with_ai".localized)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isGenerating)
                } header: {
                    Text("add_meal.ai_generation".localized)
                } footer: {
                    Text("add_meal.ai_generation_footer".localized)
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
            .navigationTitle("add_meal.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel".localized) {
                        dismiss()
                    }
                }
            }
            .alert("add_meal.conflict_title".localized, isPresented: $showConflictAlert) {
                Button("add_meal.replace".localized, role: .destructive) {
                    conflictAction = .replace
                    addMealToPlan()
                }
                Button("add_meal.add_anyway".localized) {
                    conflictAction = .add
                    addMealToPlan()
                }
                Button("action.cancel".localized, role: .cancel) {
                    generatedRecipe = nil
                }
            } message: {
                Text("add_meal.conflict_message".localized)
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallView(limitReached: true)
            }
        }
    }
    
    func generateFromTitle() async {
        guard !customTitle.isEmpty else { return }
        
        // Check if user can generate
        guard usageVM.canGenerate(count: 1) else {
            showPaywall = true
            return
        }
        
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
            usageVM.recordGenerations(count: 1)
            checkForConflictAndAdd()
            
        } catch {
            errorMessage = "\("plan.error".localized): \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
    
    func generateWithAI() async {
        // Check if user can generate
        guard usageVM.canGenerate(count: 1) else {
            showPaywall = true
            return
        }
        
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
            usageVM.recordGenerations(count: 1)
            checkForConflictAndAdd()
            
        } catch {
            errorMessage = "\("plan.error".localized): \(error.localizedDescription)"
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
        case .monday: return "week.monday".localized
        case .tuesday: return "week.tuesday".localized
        case .wednesday: return "week.wednesday".localized
        case .thursday: return "week.thursday".localized
        case .friday: return "week.friday".localized
        case .saturday: return "week.saturday".localized
        case .sunday: return "week.sunday".localized
        }
    }
    
    func mealLabel(for type: MealType) -> String {
        switch type {
        case .breakfast: return "meal.breakfast".localized
        case .lunch: return "meal.lunch".localized
        case .dinner: return "meal.dinner".localized
        case .snack: return "meal.snack".localized
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
