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
    
    private var preparationTab: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Section 1: Grouped Ingredients
                    ingredientsSection
                        .id("ingredients")
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Section 2: Mise en place (Grouped Prep Steps)
                    if let groupedSteps = kit.groupedPrepSteps, !groupedSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStringKey("meal_prep.detail.mise_en_place_title"))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text(LocalizedStringKey("meal_prep.detail.mise_en_place_subtitle"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("mise_en_place")
                            
                            ForEach(Array(groupedSteps.enumerated()), id: \.element.id) { index, step in
                                groupedStepCard(step, index: index + 1)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                    }
                    
                    // Section 3: Individual Recipes (Cooking Steps)
                    if let optimizedSteps = kit.optimizedRecipeSteps, !optimizedSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header with reset button
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(LocalizedStringKey("meal_prep.detail.recipes_title"))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Text("\(optimizedSteps.count) étapes de cuisson")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: resetCompletedSteps) {
                                    Label("meal_prep.detail.reset", systemImage: "arrow.counterclockwise")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Progress bar
                            progressBar(for: optimizedSteps)
                            
                            // Recipe steps (no more filtering - backend already removed prep steps)
                            ForEach(Array(optimizedSteps.enumerated()), id: \.element.id) { index, step in
                                optimizedStepCard(step, overallIndex: index + 1, scrollProxy: proxy)
                            }
                        }
                    }
                    
                    // Fallback if no steps at all
                    if (kit.groupedPrepSteps?.isEmpty ?? true) && (kit.optimizedRecipeSteps?.isEmpty ?? true) {
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
                .padding(.vertical)
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }
    
    // MARK: - Ingredients Section
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingrédients pour la prépa-repas")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Liste complète des ingrédients regroupés par catégorie")
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
                                            Text("\(formatQuantity(ingredient.totalQuantity)) \(ingredient.unit)")
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
}
