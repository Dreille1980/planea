import SwiftUI

struct MealPrepWizardView: View {
    @ObservedObject var viewModel: MealPrepViewModel
    @ObservedObject var familyViewModel: FamilyViewModel
    @ObservedObject var planViewModel: PlanViewModel
    @ObservedObject var usageViewModel: UsageViewModel
    @ObservedObject var shoppingViewModel: ShoppingViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 1
    @State private var showIngredientsAddedToast = false
    
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
    
    // Step 2.5: Concept Selection (now step 3)
    @State private var selectedConceptId: UUID?
    @State private var customConceptText: String = ""
    
    // Step 3 (now 4): Generated kit (single kit, no selection needed)
    
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
                            step3ConceptSelection
                        case 4:
                            step4SelectKit
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
            .overlay(
                Group {
                    if showIngredientsAddedToast {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                Text(LocalizedStringKey("meal_prep.ingredients_added_toast"))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.bottom, 50)
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
            )
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...4, id: \.self) { step in
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
    
    // MARK: - Step 3: Concept Selection
    
    private var step3ConceptSelection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("meal_prep.concept_selection.title"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(LocalizedStringKey("meal_prep.concept_selection.subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.isLoadingConcepts {
                // Loading state for concepts
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(LocalizedStringKey("meal_prep_please_wait"))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if viewModel.isGenerating {
                // Loading state for meal generation
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(LocalizedStringKey("meal_prep_generating"))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if !viewModel.concepts.isEmpty {
                // Concept cards
                ForEach(viewModel.concepts) { concept in
                    conceptCard(concept)
                }
                
                // Custom concept input
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedStringKey("meal_prep.concept_selection.custom"))
                        .font(.headline)
                    
                    TextField(
                        NSLocalizedString("meal_prep.concept_selection.custom_placeholder", comment: ""),
                        text: $customConceptText
                    )
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .onChange(of: customConceptText) { oldValue, newValue in
                        if !newValue.isEmpty {
                            selectedConceptId = nil
                        }
                    }
                }
            } else if let error = viewModel.conceptsError {
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
        .onAppear {
            if viewModel.concepts.isEmpty && !viewModel.isLoadingConcepts {
                Task {
                    await loadConcepts()
                }
            }
        }
    }
    
    private func conceptCard(_ concept: MealPrepConcept) -> some View {
        Button(action: {
            selectedConceptId = concept.id
            customConceptText = ""
            viewModel.selectedConcept = concept
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(concept.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(concept.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Image(systemName: selectedConceptId == concept.id ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(selectedConceptId == concept.id ? .accentColor : .gray)
                }
                
                if let cuisine = concept.cuisine {
                    HStack {
                        Image(systemName: "fork.knife")
                            .font(.caption)
                        Text(cuisine)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                if !concept.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(concept.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.1))
                                    .foregroundColor(.accentColor)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedConceptId == concept.id ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedConceptId == concept.id ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Step 4: Review Kit (Single kit display with detailed summary)
    
    private var step4SelectKit: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("meal_prep_step3_title"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(LocalizedStringKey("meal_prep_step3_subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let kit = viewModel.generatedKits.first {
                // Display single kit with detailed summary
                kitDetailView(kit)
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
    
    private func kitDetailView(_ kit: MealPrepKit) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Kit summary
            VStack(alignment: .leading, spacing: 12) {
                Text(kit.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let description = kit.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Statistics
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("\(kit.recipes.count)", systemImage: "fork.knife")
                            .font(.headline)
                        Text("recettes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("\(kit.totalPortions)", systemImage: "person.2")
                            .font(.headline)
                        Text("portions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label(viewModel.formatPrepTime(minutes: kit.estimatedPrepMinutes), systemImage: "clock")
                            .font(.headline)
                        Text(LocalizedStringKey("meal_prep.total_time"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            // Recipe list with storage info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(LocalizedStringKey("meal_prep.recipes_included"))
                        .font(.headline)
                    Spacer()
                    Image(systemName: "refrigerator")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text(LocalizedStringKey("meal_prep.storage"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(kit.recipes) { recipeRef in
                        recipeRow(recipeRef)
                    }
                }
            }
        }
    }
    
    private func recipeRow(_ recipeRef: MealPrepRecipeRef) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Recipe icon
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipeRef.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // Storage info
                    HStack(spacing: 12) {
                        // Shelf life
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text("\(recipeRef.shelfLifeDays)j")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        // Freezable indicator
                        HStack(spacing: 4) {
                            Image(systemName: recipeRef.isFreezable ? "snowflake" : "snowflake.slash")
                                .font(.caption2)
                            Text(LocalizedStringKey(recipeRef.isFreezable ? "meal_prep.freezable" : "meal_prep.not_freezable"))
                                .font(.caption)
                        }
                        .foregroundColor(recipeRef.isFreezable ? .blue : .orange)
                    }
                }
                
                Spacer()
            }
            
            Divider()
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
        case 1, 2:
            return "next"
        case 3:
            return "meal_prep_generate_kits"
        case 4:
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
            // Can proceed if concept selected and not currently loading
            return (selectedConceptId != nil || !customConceptText.isEmpty) && !viewModel.isLoadingConcepts && !viewModel.isGenerating
        case 4:
            return !viewModel.generatedKits.isEmpty && !viewModel.isGenerating
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
        if currentStep < 4 {
            if currentStep == 3 {
                // Set selected concept and generate kits at step 3
                if !customConceptText.isEmpty {
                    viewModel.customConceptText = customConceptText
                    viewModel.selectedConcept = nil
                }
                
                // Generate kits
                Task {
                    await generateKits()
                    
                    // Once generation is complete, move to step 4
                    if !viewModel.generatedKits.isEmpty {
                        withAnimation {
                            currentStep = 4
                        }
                    }
                }
            } else {
                withAnimation {
                    currentStep += 1
                }
            }
        } else {
            // Confirm and apply kit
            confirmKit()
        }
    }
    
    private func buildConstraints() -> [String: Any] {
        let familyConstraints = familyViewModel.aggregatedConstraints()
        let generationPrefs = PreferencesService.shared.loadPreferences()
        
        var constraintsDict: [String: Any] = [
            "diet": familyConstraints.diet,
            "evict": familyConstraints.evict
        ]
        
        // Add generation preferences as a string that the backend can use to enrich the prompt
        constraintsDict["preferences_string"] = generationPrefs.toPromptString()
        
        // CRITICAL: Add preferred proteins so backend knows which proteins to use
        let preferredProteinStrings = generationPrefs.preferredProteins.map { $0.rawValue }
        constraintsDict["preferredProteins"] = preferredProteinStrings
        
        return constraintsDict
    }
    
    private func loadConcepts() async {
        await viewModel.loadConcepts(
            constraints: buildConstraints(),
            language: LocalizationHelper.currentLanguageCode()
        )
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
            constraints: buildConstraints(),
            units: .metric,
            language: LocalizationHelper.currentLanguageCode()
        )
    }
    
    private func confirmKit() {
        guard let selectedKit = viewModel.generatedKits.first else {
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
            let ingredientsCount = await viewModel.confirmKit(
                selectedKit,
                params: params,
                planViewModel: planViewModel,
                usageViewModel: usageViewModel,
                shoppingViewModel: shoppingViewModel
            )
            
            // Show toast
            if ingredientsCount > 0 {
                withAnimation {
                    showIngredientsAddedToast = true
                }
                
                // Hide toast after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showIngredientsAddedToast = false
                    }
                    // Dismiss after toast disappears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }
            } else {
                dismiss()
            }
        }
    }
}
