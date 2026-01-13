import SwiftUI

struct MealPrepDetailView: View {
    let kit: MealPrepKit
    @State private var selectedTab = 0
    @AppStorage("completedSteps") private var completedStepsData: Data = Data()
    @State private var completedSteps: Set<UUID> = []
    
    private var completedStepsKey: String {
        "mealprep_steps_\(kit.id.uuidString)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Tab Picker
            Picker("", selection: $selectedTab) {
                Text(LocalizedStringKey("meal_prep.detail.recipes_tab"))
                    .tag(0)
                Text(LocalizedStringKey("meal_prep.detail.preparation_tab"))
                    .tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            TabView(selection: $selectedTab) {
                recipesTab
                    .tag(0)
                
                preparationTab
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(kit.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCompletedSteps()
        }
    }
    
    // MARK: - Recipes Tab
    
    private var recipesTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Kit Summary
                kitSummarySection
                
                Divider()
                
                // Recipes List
                VStack(alignment: .leading, spacing: 16) {
                    Text(LocalizedStringKey("meal_prep.detail.recipes_section"))
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(kit.recipes) { recipeRef in
                        recipeCard(recipeRef)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private var kitSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let description = kit.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Statistics
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(kit.recipes.count)", systemImage: "fork.knife")
                        .font(.headline)
                    Text(LocalizedStringKey("meal_prep.detail.recipes_count"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(kit.totalPortions)", systemImage: "person.2")
                        .font(.headline)
                    Text(LocalizedStringKey("meal_prep.detail.portions_count"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Label(formatPrepTime(minutes: kit.estimatedPrepMinutes), systemImage: "clock")
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
            .padding(.horizontal)
        }
    }
    
    private func recipeCard(_ recipeRef: MealPrepRecipeRef) -> some View {
        Group {
            if let recipe = recipeRef.recipe {
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    recipeCardContent(recipeRef, recipe: recipe)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                recipeCardContent(recipeRef, recipe: nil)
            }
        }
    }
    
    private func recipeCardContent(_ recipeRef: MealPrepRecipeRef, recipe: Recipe?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Recipe Title & Storage Info
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipeRef.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Storage information
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text("\(recipeRef.shelfLifeDays)j")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: recipeRef.isFreezable ? "snowflake" : "snowflake.slash")
                                .font(.caption)
                            Text(LocalizedStringKey(recipeRef.isFreezable ? "meal_prep.freezable" : "meal_prep.not_freezable"))
                                .font(.caption)
                        }
                        .foregroundColor(recipeRef.isFreezable ? .blue : .orange)
                    }
                    
                    if let storageNote = recipeRef.storageNote {
                        Text(storageNote)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                Spacer()
                
                // Add chevron if recipe is available
                if recipe != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Recipe Details (if available)
            if let recipe = recipe {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("\(recipe.servings)", systemImage: "person.2")
                            .font(.caption)
                        Spacer()
                        Label("\(recipe.totalMinutes)min", systemImage: "clock")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Preparation Tab
    
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var completedPrepSections: Set<UUID> = []
    @State private var completedPrepItems: Set<UUID> = []
    @State private var cachedActionSections: [ActionBasedPrepSection] = []
    @State private var prepSubTab = 0  // 0 = Mise en place, 1 = Cuisson, 2 = Assemblage
    @State private var completedCookingSteps: Set<UUID> = []
    @State private var completedAssemblySteps: Set<UUID> = []
    
    private var prepSectionsKey: String {
        "mealprep_prep_sections_\(kit.id.uuidString)"
    }
    
    private var prepItemsKey: String {
        "mealprep_prep_items_\(kit.id.uuidString)"
    }
    
    private var preparationTab: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Section 1: Grouped Ingredients (always visible)
                    ingredientsSection
                        .id("ingredients")
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Section 2: NEW 3-Tab Picker
                    VStack(spacing: 0) {
                        // Sub-tab picker
                        Picker("", selection: $prepSubTab) {
                            Text(LocalizedStringKey("meal_prep.detail.mise_en_place_tab"))
                                .tag(0)
                            Text(LocalizedStringKey("meal_prep.detail.cuisson_tab"))
                                .tag(1)
                            Text(LocalizedStringKey("meal_prep.detail.assemblage_tab"))
                                .tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Content based on selected sub-tab
                        Group {
                            if prepSubTab == 0 {
                                // Mise en place tab
                                miseEnPlaceTab
                            } else if prepSubTab == 1 {
                                // Cuisson tab
                                cuissonTab
                            } else {
                                // Assemblage tab
                                assemblageTab
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .onAppear {
                scrollProxy = proxy
                loadPrepProgress()
                loadCookingProgress()
                loadAssemblyProgress()
            }
        }
    }
    
    // MARK: - Mise en place Tab
    
    private var miseEnPlaceTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Reuse existing action-based preparation section
            let sections = cachedActionSections.isEmpty ? kit.buildActionBasedPrep() : cachedActionSections
            
            if !sections.isEmpty {
                // Progress Bar
                preparationProgressBar(sections: sections)
                
                // Action Sections
                ForEach(sections) { section in
                    actionSectionCard(section)
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text(LocalizedStringKey("meal_prep.detail.no_grouped_steps"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .padding(.top)
        .onAppear {
            if cachedActionSections.isEmpty {
                cachedActionSections = kit.buildActionBasedPrep()
            }
        }
    }
    
    // MARK: - Cuisson Tab
    
    private var cuissonTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let cookingPhases = kit.cookingPhases,
               let recipeGroups = cookingPhases.cook.recipes, !recipeGroups.isEmpty {
                // NEW FORMAT: Grouped by recipe
                
                // Global progress bar
                globalCookingProgressBar(recipeGroups: recipeGroups)
                
                // For each recipe group
                ForEach(recipeGroups) { recipeGroup in
                    recipeGroupCookingCard(recipeGroup)
                }
            } else if let cookingPhases = kit.cookingPhases, !cookingPhases.cook.steps.isEmpty {
                // FALLBACK: Legacy flat format (group manually by recipeTitle)
                let groupedByRecipe = Dictionary(grouping: cookingPhases.cook.steps) { $0.recipeTitle }
                let sortedRecipes = groupedByRecipe.keys.sorted()
                
                // Global progress bar
                let allSteps = cookingPhases.cook.steps
                globalCookingProgressBarLegacy(steps: allSteps)
                
                // For each recipe
                ForEach(sortedRecipes, id: \.self) { recipeTitle in
                    if let steps = groupedByRecipe[recipeTitle] {
                        recipeGroupCookingCardLegacy(recipeTitle: recipeTitle, steps: steps)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "flame")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text(LocalizedStringKey("meal_prep.detail.cooking_instructions"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Assemblage Tab
    
    private var assemblageTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let cookingPhases = kit.cookingPhases {
                // Combine assemble + cool_down + store phases
                let combinedSteps = cookingPhases.assemble.steps +
                                   cookingPhases.coolDown.steps +
                                   cookingPhases.store.steps
                
                if !combinedSteps.isEmpty {
                    // Progress bar
                    assemblyProgressBar(steps: combinedSteps)
                    
                    // Steps
                    ForEach(Array(combinedSteps.enumerated()), id: \.element.id) { index, step in
                        assemblyStepCard(step, index: index + 1)
                    }
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "tray.2")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text(LocalizedStringKey("meal_prep.detail.assembly_instructions"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "tray.2")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text(LocalizedStringKey("meal_prep.detail.assembly_instructions"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Ingredients Section
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("meal_prep.detail.ingredients_title"))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(LocalizedStringKey("meal_prep.detail.ingredients_subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Group all ingredients by category
            let groupedIngredients = groupIngredientsByCategory()
            
            ForEach(Array(groupedIngredients.keys.sorted()), id: \.self) { category in
                if let ingredients = groupedIngredients[category] {
                    VStack(alignment: .leading, spacing: 12) {
                        // Category header
                        HStack {
                            Image(systemName: iconForCategory(category))
                                .foregroundColor(.accentColor)
                            Text(category)
                                .font(.headline)
                        }
                        .padding(.horizontal)
                        
                        // Ingredients in this category
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(ingredients, id: \.name) { ingredient in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(ingredient.name)
                                                .font(.body)
                                            Spacer()
                                            Text(formatIngredientQuantity(ingredient))
                                                .font(.body)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        // Show which recipes use this ingredient
                                        if ingredient.recipes.count > 1 {
                                            Text(ingredient.recipes.map { $0.title }.joined(separator: ", "))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .italic()
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func groupIngredientsByCategory() -> [String: [AggregatedIngredient]] {
        var grouped: [String: [String: AggregatedIngredient]] = [:]
        
        // Aggregate ingredients from all recipes
        for recipeRef in kit.recipes {
            guard let recipe = recipeRef.recipe else { continue }
            
            for ingredient in recipe.ingredients {
                let category = ingredient.category.isEmpty ? "Autre" : ingredient.category.capitalized
                
                if grouped[category] == nil {
                    grouped[category] = [:]
                }
                
                let key = ingredient.name.lowercased()
                
                if var existing = grouped[category]?[key] {
                    existing.totalQuantity += ingredient.quantity
                    existing.recipes.append((title: recipeRef.title, quantity: ingredient.quantity, unit: ingredient.unit))
                    grouped[category]?[key] = existing
                } else {
                    grouped[category]?[key] = AggregatedIngredient(
                        name: ingredient.name,
                        totalQuantity: ingredient.quantity,
                        unit: ingredient.unit,
                        category: category,
                        recipes: [(title: recipeRef.title, quantity: ingredient.quantity, unit: ingredient.unit)]
                    )
                }
            }
        }
        
        // Convert to final format
        return grouped.mapValues { dict in
            Array(dict.values).sorted { $0.name < $1.name }
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        let lowercased = category.lowercased()
        switch lowercased {
        case "légumes", "vegetables":
            return "carrot.fill"
        case "fruits":
            return "leaf.fill"
        case "viandes", "meats", "protéines", "proteins":
            return "flame.fill"
        case "poissons", "fish", "fruits de mer", "seafood":
            return "fish.fill"
        case "produits laitiers", "dairy":
            return "cup.and.saucer.fill"
        case "sec", "dry goods", "grains":
            return "circle.grid.3x3.fill"
        case "condiments", "épices", "spices":
            return "sparkles"
        case "conserves", "canned goods":
            return "cabinet.fill"
        default:
            return "bag.fill"
        }
    }
    
    private func formatQuantity(_ quantity: Double) -> String {
        if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", quantity)
        } else {
            return String(format: "%.1f", quantity)
        }
    }
    
    // Helper struct for aggregated ingredients
    struct AggregatedIngredient {
        let name: String
        var totalQuantity: Double
        let unit: String
        let category: String
        var recipes: [(title: String, quantity: Double, unit: String)]
    }
    
    private func groupedStepCard(_ step: GroupedPrepStep, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step header
            HStack {
                Text("\(index)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.accentColor))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.actionType)
                        .font(.headline)
                    
                    if let estimatedMinutes = step.estimatedMinutes {
                        Label("\(estimatedMinutes)min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Description
            Text(step.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Ingredients by recipe
            if !step.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("meal_prep.detail.ingredients"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(step.ingredients) { ingredient in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(ingredient.name) (\(ingredient.quantity))")
                                    .font(.caption)
                                
                                Text(ingredient.recipeTitle)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
            }
            
            // Detailed steps
            if !step.detailedSteps.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("meal_prep.detail.instructions"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(step.detailedSteps.enumerated()), id: \.offset) { index, detailStep in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(detailStep)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Optimized Recipe Steps
    
    private func progressBar(for steps: [OptimizedRecipeStep]) -> some View {
        let completedCount = steps.filter { completedSteps.contains($0.id) }.count
        let totalCount = steps.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(LocalizedStringKey("meal_prep.detail.steps_completed"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
    
    private func optimizedStepCard(_ step: OptimizedRecipeStep, overallIndex: Int, scrollProxy: ScrollViewProxy?) -> some View {
        let isCompleted = completedSteps.contains(step.id)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                Button(action: {
                    toggleStepCompletion(step.id)
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isCompleted ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    // Recipe badge
                    HStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.caption2)
                        Text(step.recipeTitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(recipeColor(for: step.recipeId))
                    )
                    
                    // Step number and description
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(overallIndex).")
                            .font(.headline)
                            .foregroundColor(isCompleted ? .secondary : .primary)
                        
                        Text(step.stepDescription)
                            .font(.body)
                            .foregroundColor(isCompleted ? .secondary : .primary)
                            .strikethrough(isCompleted)
                    }
                    
                    // Additional info
                    HStack(spacing: 12) {
                        if let minutes = step.estimatedMinutes {
                            Label("\(minutes)min", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if step.isParallel {
                            Label("meal_prep.detail.parallel", systemImage: "arrow.triangle.branch")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .opacity(isCompleted ? 0.6 : 1.0)
        )
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
    
    private func recipeColor(for recipeId: String) -> Color {
        // Generate consistent color based on recipe ID
        let hash = abs(recipeId.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
    
    private func toggleStepCompletion(_ stepId: UUID) {
        if completedSteps.contains(stepId) {
            completedSteps.remove(stepId)
        } else {
            completedSteps.insert(stepId)
        }
        saveCompletedSteps()
    }
    
    private func resetCompletedSteps() {
        completedSteps.removeAll()
        saveCompletedSteps()
    }
    
    private func loadCompletedSteps() {
        if let data = UserDefaults.standard.data(forKey: completedStepsKey),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            completedSteps = decoded
        }
    }
    
    private func saveCompletedSteps() {
        if let encoded = try? JSONEncoder().encode(completedSteps) {
            UserDefaults.standard.set(encoded, forKey: completedStepsKey)
        }
    }
    
    // MARK: - Helpers
    
    private func isPreparationStep(_ step: OptimizedRecipeStep) -> Bool {
        let prepKeywords = [
            "chop", "dice", "slice", "cut", "peel", "mince", "grate", 
            "wash", "rinse", "prepare", "prep", "measure", "mix together",
            "combine", "whisk together", "set aside"
        ]
        
        let description = step.stepDescription.lowercased()
        
        // Check if the step description contains any preparation keywords
        return prepKeywords.contains { keyword in
            description.contains(keyword)
        }
    }
    
    private func formatPrepTime(minutes: Int) -> String {
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
    
    private func formatIngredientQuantity(_ ingredient: AggregatedIngredient) -> String {
        // Localize unit (translate "unité" to "unit" if in English)
        let localizedUnit = UnitConverter.localizeUnit(ingredient.unit)
        
        // Check if this is produce with weight (g or kg)
        if UnitConverter.isProduce(ingredient.name) {
            let lowercasedUnit = ingredient.unit.lowercased()
            
            // If it's in grams or kilograms, show approximate unit count
            if lowercasedUnit.contains("g") && !lowercasedUnit.contains("kg") {
                // Weight in grams
                if let unitCount = UnitConverter.weightToUnitCount(
                    ingredientName: ingredient.name,
                    weightInGrams: ingredient.totalQuantity
                ) {
                    // Format: 300.0 g ≈ 2 unités
                    let unitLabel = Locale.current.language.languageCode?.identifier == "fr" ? "unités" : "units"
                    return String(format: "%.1f %@ ≈ %.0f %@",
                                 ingredient.totalQuantity, localizedUnit,
                                 unitCount, unitLabel)
                }
            } else if lowercasedUnit.contains("kg") {
                // Weight in kilograms - convert to grams for calculation
                if let unitCount = UnitConverter.weightToUnitCount(
                    ingredientName: ingredient.name,
                    weightInGrams: ingredient.totalQuantity * 1000
                ) {
                    let unitLabel = Locale.current.language.languageCode?.identifier == "fr" ? "unités" : "units"
                    return String(format: "%.1f %@ ≈ %.0f %@",
                                 ingredient.totalQuantity, localizedUnit,
                                 unitCount, unitLabel)
                }
            }
        }
        
        // Default format: quantity unit
        return "\(formatQuantity(ingredient.totalQuantity)) \(localizedUnit)"
    }
    
    // MARK: - NEW Action-Based Preparation Section
    
    private var actionBasedPreparationSection: some View {
        // Use cached sections or build them once
        let sections = cachedActionSections.isEmpty ? kit.buildActionBasedPrep() : cachedActionSections
        
        guard !sections.isEmpty else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey("meal_prep.detail.mise_en_place_title"))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(LocalizedStringKey("meal_prep.detail.prep_checklist_subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Progress Bar
                preparationProgressBar(sections: sections)
                
                // Action Sections
                ForEach(sections) { section in
                    actionSectionCard(section)
                }
            }
            .onAppear {
                if cachedActionSections.isEmpty {
                    cachedActionSections = sections
                }
                loadPrepProgress()
            }
        )
    }
    
    // MARK: - Preparation Progress Bar
    
    private func preparationProgressBar(sections: [ActionBasedPrepSection]) -> some View {
        let completedSectionsCount = sections.filter { completedPrepSections.contains($0.id) }.count
        let totalSections = sections.count
        let progress = totalSections > 0 ? Double(completedSectionsCount) / Double(totalSections) : 0
        
        // Calculate remaining time
        let remainingMinutes = sections.filter { !completedPrepSections.contains($0.id) }
            .reduce(0) { $0 + $1.estimatedMinutes }
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completedSectionsCount)/\(totalSections)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if remainingMinutes > 0 {
                    Text("~\(remainingMinutes) min " + LocalizedStringKey("meal_prep.detail.remaining").stringValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Action Section Card
    
    private func actionSectionCard(_ section: ActionBasedPrepSection) -> some View {
        let sectionCompleted = completedPrepSections.contains(section.id)
        let allItemsCompleted = section.items.allSatisfy { completedPrepItems.contains($0.id) }
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header with section checkbox
            HStack(alignment: .top, spacing: 12) {
                // Section Checkbox
                Button(action: {
                    toggleSectionCompletion(section)
                }) {
                    Image(systemName: sectionCompleted ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundColor(sectionCompleted ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    // Action type with emoji and icon
                    HStack(spacing: 8) {
                        Text(section.actionType.emoji)
                            .font(.title3)
                        
                        Image(systemName: section.actionType.sfSymbol)
                            .foregroundColor(.accentColor)
                        
                        Text(section.actionType.localizedName)
                            .font(.headline)
                            .foregroundColor(sectionCompleted ? .secondary : .primary)
                        
                        Spacer()
                        
                        // Time estimate
                        Label("\(section.estimatedMinutes) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Items list
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(section.items) { item in
                            prepItemRow(item, sectionCompleted: sectionCompleted)
                        }
                    }
                    
                    // Used in recipes footer
                    if section.usedInRecipeCount > 0 {
                        Divider()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if section.usedInRecipeCount == 1 {
                                Text("Used in: \(section.usedInRecipeTitles[0])")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Used in: \(section.usedInRecipeCount) meals")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .opacity(sectionCompleted ? 0.6 : 1.0)
        )
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: sectionCompleted)
    }
    
    // MARK: - Prep Item Row
    
    private func prepItemRow(_ item: PrepItem, sectionCompleted: Bool) -> some View {
        let itemCompleted = completedPrepItems.contains(item.id) || sectionCompleted
        
        return HStack(alignment: .top, spacing: 12) {
            // Item Checkbox
            Button(action: {
                if !sectionCompleted {
                    toggleItemCompletion(item.id)
                }
            }) {
                Image(systemName: itemCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundColor(itemCompleted ? .accentColor : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(sectionCompleted)
            
            // Item content
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(item.ingredientName)
                    .font(.subheadline)
                    .foregroundColor(itemCompleted ? .secondary : .primary)
                    .strikethrough(itemCompleted)
                
                Text(" — ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(item.quantity)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(itemCompleted ? .secondary : .primary)
                
                if !item.action.isEmpty {
                    Text(", ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(item.action)
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.secondary)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: itemCompleted)
    }
    
    // MARK: - NEW Cooking Phases Section
    
    @State private var selectedPhase = 0  // 0=Cook, 1=Assemble, 2=Cool Down, 3=Store
    @State private var completedPhaseSteps: Set<UUID> = []
    
    private var phaseStepsKey: String {
        "mealprep_phase_steps_\(kit.id.uuidString)"
    }
    
    private func cookingPhasesSection(_ phases: CookingPhasesSet) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("meal_prep.detail.cooking_phases_title"))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(LocalizedStringKey("meal_prep.detail.cooking_phases_subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: resetPhaseSteps) {
                    Label("meal_prep.detail.reset", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            // Phase Selector
            Picker("", selection: $selectedPhase) {
                Text(phases.cook.title).tag(0)
                Text(phases.assemble.title).tag(1)
                Text(phases.coolDown.title).tag(2)
                Text(phases.store.title).tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Selected Phase Content
            let currentPhase = [phases.cook, phases.assemble, phases.coolDown, phases.store][selectedPhase]
            
            // Phase Progress
            phaseProgressBar(phase: currentPhase)
            
            // Phase Steps
            ForEach(Array(currentPhase.steps.enumerated()), id: \.element.id) { index, step in
                phaseStepCard(step, index: index + 1)
            }
        }
        .onAppear {
            loadPhaseProgress()
        }
    }
    
    private func phaseProgressBar(phase: CookingPhase) -> some View {
        let completedCount = phase.steps.filter { completedPhaseSteps.contains($0.id) }.count
        let totalCount = phase.steps.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        
        // Calculate remaining time
        let remainingMinutes = phase.steps
            .filter { !completedPhaseSteps.contains($0.id) }
            .compactMap { $0.estimatedMinutes }
            .reduce(0, +)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if remainingMinutes > 0 {
                    Text("~\(remainingMinutes) min " + LocalizedStringKey("meal_prep.detail.remaining").stringValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if phase.totalMinutes > 0 {
                    Text("~\(phase.totalMinutes) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
    
    private func phaseStepCard(_ step: PhaseStep, index: Int) -> some View {
        let isCompleted = completedPhaseSteps.contains(step.id)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                Button(action: {
                    togglePhaseStepCompletion(step.id)
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isCompleted ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    // Step number and description
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index).")
                            .font(.headline)
                            .foregroundColor(isCompleted ? .secondary : .primary)
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(isCompleted ? .secondary : .primary)
                            .strikethrough(isCompleted)
                    }
                    
                    // Recipe badge and additional info
                    HStack(spacing: 12) {
                        // Recipe badge
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.caption2)
                            Text(step.recipeTitle)
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(recipeColor(for: step.recipeTitle))
                        )
                        
                        // Time estimate
                        if let minutes = step.estimatedMinutes {
                            Label("\(minutes)min", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Parallel note
                    if step.isParallel, let note = step.parallelNote {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.caption2)
                            Text(note)
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .opacity(isCompleted ? 0.6 : 1.0)
        )
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
    
    private func togglePhaseStepCompletion(_ stepId: UUID) {
        if completedPhaseSteps.contains(stepId) {
            completedPhaseSteps.remove(stepId)
        } else {
            completedPhaseSteps.insert(stepId)
        }
        savePhaseProgress()
    }
    
    private func resetPhaseSteps() {
        completedPhaseSteps.removeAll()
        savePhaseProgress()
    }
    
    private func loadPhaseProgress() {
        if let data = UserDefaults.standard.data(forKey: phaseStepsKey),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            completedPhaseSteps = decoded
        }
    }
    
    private func savePhaseProgress() {
        if let encoded = try? JSONEncoder().encode(completedPhaseSteps) {
            UserDefaults.standard.set(encoded, forKey: phaseStepsKey)
        }
    }
    
    // MARK: - Checkbox State Management
    
    private func toggleSectionCompletion(_ section: ActionBasedPrepSection) {
        if completedPrepSections.contains(section.id) {
            // Uncheck section and all items
            completedPrepSections.remove(section.id)
            for item in section.items {
                completedPrepItems.remove(item.id)
            }
        } else {
            // Check section and all items
            completedPrepSections.insert(section.id)
            for item in section.items {
                completedPrepItems.insert(item.id)
            }
        }
        savePrepProgress()
    }
    
    private func toggleItemCompletion(_ itemId: UUID) {
        if completedPrepItems.contains(itemId) {
            completedPrepItems.remove(itemId)
        } else {
            completedPrepItems.insert(itemId)
        }
        savePrepProgress()
    }
    
    private func loadPrepProgress() {
        // Load sections
        if let data = UserDefaults.standard.data(forKey: prepSectionsKey),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            completedPrepSections = decoded
        }
        
        // Load items
        if let data = UserDefaults.standard.data(forKey: prepItemsKey),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            completedPrepItems = decoded
        }
    }
    
    private func savePrepProgress() {
        // Save sections
        if let encoded = try? JSONEncoder().encode(completedPrepSections) {
            UserDefaults.standard.set(encoded, forKey: prepSectionsKey)
        }
        
        // Save items
        if let encoded = try? JSONEncoder().encode(completedPrepItems) {
            UserDefaults.standard.set(encoded, forKey: prepItemsKey)
        }
    }
    
    // MARK: - Cuisson Tab - NEW Format Functions
    
    private func globalCookingProgressBar(recipeGroups: [RecipeCookingGroup]) -> some View {
        let allSteps = recipeGroups.flatMap { $0.steps }
        let completedCount = allSteps.filter { completedCookingSteps.contains($0.id) }.count
        let totalCount = allSteps.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedStringKey("meal_prep.detail.global_cooking_progress"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
    
    private func recipeGroupCookingCard(_ recipeGroup: RecipeCookingGroup) -> some View {
        let completedCount = recipeGroup.steps.filter { completedCookingSteps.contains($0.id) }.count
        let totalCount = recipeGroup.steps.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        
        return VStack(alignment: .leading, spacing: 12) {
            // Recipe header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipeGroup.recipeTitle)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Label("\(recipeGroup.estimatedMinutes)min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(completedCount)/\(totalCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Recipe progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(recipeColor(for: recipeGroup.recipeId))
                        .frame(width: geometry.size.width * progress, height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal)
            
            // Steps
            ForEach(Array(recipeGroup.steps.enumerated()), id: \.element.id) { index, step in
                cookingStepCard(step, index: index + 1)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func cookingStepCard(_ step: PhaseStep, index: Int) -> some View {
        let isCompleted = completedCookingSteps.contains(step.id)
        
        return HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: {
                toggleCookingStepCompletion(step.id)
            }) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isCompleted ? .accentColor : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index).")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isCompleted ? .secondary : .primary)
                    
                    Text(step.description)
                        .font(.subheadline)
                        .foregroundColor(isCompleted ? .secondary : .primary)
                        .strikethrough(isCompleted)
                }
                
                if let minutes = step.estimatedMinutes {
                    Label("\(minutes)min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if step.isParallel, let note = step.parallelNote {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                        Text(note)
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
    
    // MARK: - Cuisson Tab - Legacy Format Functions
    
    private func globalCookingProgressBarLegacy(steps: [PhaseStep]) -> some View {
        let completedCount = steps.filter { completedCookingSteps.contains($0.id) }.count
        let totalCount = steps.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedStringKey("meal_prep.detail.global_cooking_progress"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
    
    private func recipeGroupCookingCardLegacy(recipeTitle: String, steps: [PhaseStep]) -> some View {
        let completedCount = steps.filter { completedCookingSteps.contains($0.id) }.count
        let totalCount = steps.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        let estimatedMinutes = steps.compactMap { $0.estimatedMinutes }.reduce(0, +)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Recipe header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipeTitle)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        if estimatedMinutes > 0 {
                            Label("\(estimatedMinutes)min", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("\(completedCount)/\(totalCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Recipe progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(recipeColor(for: recipeTitle))
                        .frame(width: geometry.size.width * progress, height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal)
            
            // Steps
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                cookingStepCard(step, index: index + 1)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Assemblage Tab Functions
    
    private func assemblyProgressBar(steps: [PhaseStep]) -> some View {
        let completedCount = steps.filter { completedAssemblySteps.contains($0.id) }.count
        let totalCount = steps.count
        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completedCount)/\(totalCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(LocalizedStringKey("meal_prep.detail.steps_completed"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal)
    }
    
    private func assemblyStepCard(_ step: PhaseStep, index: Int) -> some View {
        let isCompleted = completedAssemblySteps.contains(step.id)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                Button(action: {
                    toggleAssemblyStepCompletion(step.id)
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isCompleted ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    // Step number and description
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index).")
                            .font(.headline)
                            .foregroundColor(isCompleted ? .secondary : .primary)
                        
                        Text(step.description)
                            .font(.body)
                            .foregroundColor(isCompleted ? .secondary : .primary)
                            .strikethrough(isCompleted)
                    }
                    
                    // Additional info
                    HStack(spacing: 12) {
                        // Recipe badge
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.caption2)
                            Text(step.recipeTitle)
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(recipeColor(for: step.recipeTitle))
                        )
                        
                        // Time estimate
                        if let minutes = step.estimatedMinutes {
                            Label("\(minutes)min", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .opacity(isCompleted ? 0.6 : 1.0)
        )
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
    
    // MARK: - Cooking & Assembly Persistence
    
    private var cookingStepsKey: String {
        "mealprep_cooking_steps_\(kit.id.uuidString)"
    }
    
    private var assemblyStepsKey: String {
        "mealprep_assembly_steps_\(kit.id.uuidString)"
    }
    
    private func toggleCookingStepCompletion(_ stepId: UUID) {
        if completedCookingSteps.contains(stepId) {
            completedCookingSteps.remove(stepId)
        } else {
            completedCookingSteps.insert(stepId)
        }
        saveCookingProgress()
    }
    
    private func toggleAssemblyStepCompletion(_ stepId: UUID) {
        if completedAssemblySteps.contains(stepId) {
            completedAssemblySteps.remove(stepId)
        } else {
            completedAssemblySteps.insert(stepId)
        }
        saveAssemblyProgress()
    }
    
    private func loadCookingProgress() {
        if let data = UserDefaults.standard.data(forKey: cookingStepsKey),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            completedCookingSteps = decoded
        }
    }
    
    private func saveCookingProgress() {
        if let encoded = try? JSONEncoder().encode(completedCookingSteps) {
            UserDefaults.standard.set(encoded, forKey: cookingStepsKey)
        }
    }
    
    private func loadAssemblyProgress() {
        if let data = UserDefaults.standard.data(forKey: assemblyStepsKey),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            completedAssemblySteps = decoded
        }
    }
    
    private func saveAssemblyProgress() {
        if let encoded = try? JSONEncoder().encode(completedAssemblySteps) {
            UserDefaults.standard.set(encoded, forKey: assemblyStepsKey)
        }
    }


// MARK: - LocalizedStringKey Extension

extension LocalizedStringKey {
    var stringValue: String {
        let mirror = Mirror(reflecting: self)
        let key = mirror.children.first(where: { $0.label == "key" })?.value as? String
        return NSLocalizedString(key ?? "", comment: "")
    }
}

