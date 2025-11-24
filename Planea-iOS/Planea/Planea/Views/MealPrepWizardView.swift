import SwiftUI

struct MealPrepWizardView: View {
    @ObservedObject var viewModel: MealPrepViewModel
    @ObservedObject var familyViewModel: FamilyViewModel
    @ObservedObject var planViewModel: PlanViewModel
    @ObservedObject var usageViewModel: UsageViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    
    // Step 1: Parameters
    @State private var selectedDaysPreset: DaysPreset = .mondayToFriday
    @State private var customDays: Set<Weekday> = []
    @State private var selectedMeals: Set<MealType> = [.lunch, .dinner]
    @State private var servingsPerMeal: Int = 4
    
    // Step 2: Preferences
    @State private var prepTimePreference: PrepTimePreference = .oneHourThirty
    @State private var skillLevel: SkillLevel = .intermediate
    @State private var avoidRareIngredients = false
    @State private var preferLongShelfLife = false
    
    // Step 3: Generated kits
    @State private var selectedKitId: UUID?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case 1:
                            step1Parameters
                        case 2:
                            step2Preferences
                        case 3:
                            step3SelectKit
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // Navigation buttons
                navigationButtons
            }
            .navigationTitle(LocalizedStringKey("meal_prep_wizard_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStringKey("cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Step 1: Parameters
    
    private var step1Parameters: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("meal_prep_step1_title"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(LocalizedStringKey("meal_prep_step1_subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Days covered
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("meal_prep_days_covered"))
                    .font(.headline)
                
                VStack(spacing: 8) {
                    daysPresetButton(.mondayToFriday)
                    daysPresetButton(.mondayToSunday)
                    daysPresetButton(.custom)
                }
                
                // Custom days selector
                if selectedDaysPreset == .custom {
                    customDaysSelector
                }
            }
            
            // Meals to cover
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("meal_prep_meals_to_cover"))
                    .font(.headline)
                
                VStack(spacing: 8) {
                    mealToggle(.lunch)
                    mealToggle(.dinner)
                }
            }
            
            // Servings per meal
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("meal_prep_servings_per_meal"))
                    .font(.headline)
                
                Stepper(value: $servingsPerMeal, in: 1...8) {
                    HStack {
                        Text("\(servingsPerMeal)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(LocalizedStringKey("portions"))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                if !familyViewModel.members.isEmpty {
                    Text(String(format: NSLocalizedString("meal_prep_family_size_hint", comment: ""), familyViewModel.members.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func daysPresetButton(_ preset: DaysPreset) -> some View {
        Button(action: {
            selectedDaysPreset = preset
        }) {
            HStack {
                Image(systemName: selectedDaysPreset == preset ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedDaysPreset == preset ? .accentColor : .gray)
                
                Text(preset.localizedName)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private var customDaysSelector: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(Weekday.allCases, id: \.self) { day in
                Button(action: {
                    if customDays.contains(day) {
                        customDays.remove(day)
                    } else {
                        customDays.insert(day)
                    }
                }) {
                    Text(day.localizedShortName)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(customDays.contains(day) ? Color.accentColor.opacity(0.2) : Color(UIColor.tertiarySystemBackground))
                        .foregroundColor(customDays.contains(day) ? .accentColor : .primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func mealToggle(_ meal: MealType) -> some View {
        Button(action: {
            if selectedMeals.contains(meal) {
                selectedMeals.remove(meal)
            } else {
                selectedMeals.insert(meal)
            }
        }) {
            HStack {
                Image(systemName: selectedMeals.contains(meal) ? "checkmark.square.fill" : "square")
                    .foregroundColor(selectedMeals.contains(meal) ? .accentColor : .gray)
                
                Text(meal.localizedName)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Step 2: Preferences
    
    private var step2Preferences: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("meal_prep_step2_title"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(LocalizedStringKey("meal_prep_step2_subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Prep time
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("meal_prep_total_prep_time"))
                    .font(.headline)
                
                VStack(spacing: 8) {
                    prepTimeButton(.oneHour)
                    prepTimeButton(.oneHourThirty)
                    prepTimeButton(.twoHoursPlus)
                }
            }
            
            // Skill level
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("meal_prep_skill_level"))
                    .font(.headline)
                
                VStack(spacing: 8) {
                    skillLevelButton(.beginner)
                    skillLevelButton(.intermediate)
                    skillLevelButton(.quickEfficient)
                }
            }
            
            // Toggles
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("meal_prep_options"))
                    .font(.headline)
                
                Toggle(isOn: $avoidRareIngredients) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("meal_prep_avoid_rare"))
                        Text(LocalizedStringKey("meal_prep_avoid_rare_hint"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                Toggle(isOn: $preferLongShelfLife) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("meal_prep_prefer_long_shelf"))
                        Text(LocalizedStringKey("meal_prep_prefer_long_shelf_hint"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private func prepTimeButton(_ time: PrepTimePreference) -> some View {
        Button(action: {
            prepTimePreference = time
        }) {
            HStack {
                Image(systemName: prepTimePreference == time ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(prepTimePreference == time ? .accentColor : .gray)
                
                Text(time.localizedName)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private func skillLevelButton(_ level: SkillLevel) -> some View {
        Button(action: {
            skillLevel = level
        }) {
            HStack {
                Image(systemName: skillLevel == level ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(skillLevel == level ? .accentColor : .gray)
                
                Text(level.localizedName)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Step 3: Select Kit
    
    private var step3SelectKit: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("meal_prep_step3_title"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                if viewModel.isGenerating {
                    Text(LocalizedStringKey("meal_prep_generating"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text(LocalizedStringKey("meal_prep_step3_subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.isGenerating {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(LocalizedStringKey("meal_prep_please_wait"))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if !viewModel.generatedKits.isEmpty {
                // Generated kits
                ForEach(viewModel.generatedKits) { kit in
                    kitSelectionCard(kit)
                }
            } else if let error = viewModel.errorMessage {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    private func kitSelectionCard(_ kit: MealPrepKit) -> some View {
        Button(action: {
            selectedKitId = kit.id
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(kit.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let description = kit.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: selectedKitId == kit.id ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(selectedKitId == kit.id ? .accentColor : .gray)
                }
                
                HStack(spacing: 16) {
                    Label("\(kit.recipes.count) recettes", systemImage: "fork.knife")
                        .font(.caption)
                    Label("\(kit.totalPortions) portions", systemImage: "person.2")
                        .font(.caption)
                    Label("~\(kit.estimatedPrepMinutes/60)h\(kit.estimatedPrepMinutes%60)", systemImage: "clock")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Recipe previews with storage info
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(kit.recipes.prefix(4)) { recipe in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                                .frame(width: 6, height: 6)
                            
                            Text(recipe.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                if let note = recipe.storageNote {
                                    Text(note)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                if !recipe.isFreezable {
                                    Image(systemName: "snowflake.slash")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedKitId == kit.id ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedKitId == kit.id ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 1 {
                Button(action: goBack) {
                    Text(LocalizedStringKey("back"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            
            Button(action: goNext) {
                Text(nextButtonTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canProceed ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!canProceed)
        }
        .padding()
    }
    
    private var nextButtonTitle: LocalizedStringKey {
        switch currentStep {
        case 1:
            return "next"
        case 2:
            return "meal_prep_generate_kits"
        case 3:
            return "confirm"
        default:
            return "next"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            let days = selectedDaysPreset == .custom ? Array(customDays) : selectedDaysPreset.days
            return !days.isEmpty && !selectedMeals.isEmpty && servingsPerMeal > 0
        case 2:
            return true
        case 3:
            return selectedKitId != nil && !viewModel.isGenerating
        default:
            return false
        }
    }
    
    private func goBack() {
        withAnimation {
            currentStep -= 1
        }
    }
    
    private func goNext() {
        if currentStep < 3 {
            if currentStep == 2 {
                // Generate kits when moving to step 3
                Task {
                    await generateKits()
                }
            }
            withAnimation {
                currentStep += 1
            }
        } else {
            // Confirm and apply kit
            confirmKit()
        }
    }
    
    private func generateKits() async {
        let days = selectedDaysPreset == .custom ? Array(customDays) : selectedDaysPreset.days
        
        let params = MealPrepGenerationParams(
            days: days,
            meals: Array(selectedMeals),
            servingsPerMeal: servingsPerMeal,
            totalPrepTimePreference: prepTimePreference,
            skillLevel: skillLevel,
            avoidRareIngredients: avoidRareIngredients,
            preferLongShelfLife: preferLongShelfLife
        )
        
        await viewModel.generateKits(
            params: params,
            constraints: [:],
            units: .metric,
            language: LocalizationHelper.currentLanguageCode()
        )
    }
    
    private func confirmKit() {
        guard let kitId = selectedKitId,
              let selectedKit = viewModel.generatedKits.first(where: { $0.id == kitId }) else {
            return
        }
        
        let days = selectedDaysPreset == .custom ? Array(customDays) : selectedDaysPreset.days
        
        let params = MealPrepGenerationParams(
            days: days,
            meals: Array(selectedMeals),
            servingsPerMeal: servingsPerMeal,
            totalPrepTimePreference: prepTimePreference,
            skillLevel: skillLevel,
            avoidRareIngredients: avoidRareIngredients,
            preferLongShelfLife: preferLongShelfLife
        )
        
        Task {
            await viewModel.confirmKit(selectedKit, params: params, planViewModel: planViewModel, usageViewModel: usageViewModel)
            dismiss()
        }
    }
}
