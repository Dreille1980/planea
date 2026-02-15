import SwiftUI

struct MealPrepDetailView: View {
    let kit: MealPrepKit
    @State private var selectedTab = 0
    @State private var showAssignSheet = false
    @StateObject private var viewModel: MealPrepViewModel
    
    init(kit: MealPrepKit) {
        self.kit = kit
        _viewModel = StateObject(wrappedValue: MealPrepViewModel(baseURL: URL(string: Config.baseURL)!))
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAssignSheet = true
                } label: {
                    Label(
                        NSLocalizedString("mealprep.assign_to_plan", comment: ""),
                        systemImage: "calendar.badge.plus"
                    )
                }
                .disabled(!kit.hasAvailablePortions)
            }
        }
        .sheet(isPresented: $showAssignSheet) {
            AssignMealPrepSheet(
                mealPrepKit: kit,
                onAssign: { date, mealType, portions, recipeId in
                    viewModel.assignToWeek(
                        kit: kit,
                        date: date,
                        mealType: mealType,
                        portions: portions,
                        recipeId: recipeId
                    )
                }
            )
        }
        .alert(
            NSLocalizedString("common.error", comment: ""),
            isPresented: .constant(viewModel.errorMessage != nil),
            presenting: viewModel.errorMessage
        ) { _ in
            Button(NSLocalizedString("common.ok", comment: "")) {
                viewModel.errorMessage = nil
            }
        } message: { error in
            Text(error)
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
            
            // ✨ NEW - Portions availability banner
            if kit.hasAvailablePortions {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(String(format: NSLocalizedString("mealprep.portions_available", comment: ""), kit.remainingPortions))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(kit.remainingPortions)/\(kit.totalPortions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            } else if !kit.assignments.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gray)
                    Text(LocalizedStringKey("mealprep.all_portions_assigned"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // ✨ NEW - Expiration warning
            if let warning = kit.expirationWarning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(warning)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
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
                    Text(LocalizedStringKey("meal_prep.detail.total_portions"))
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
            
            // ✨ NEW - Assignments list
            if !kit.assignments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(LocalizedStringKey("mealprep.assignments_title"))
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(kit.assignments) { assignment in
                        assignmentRow(assignment)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // ✨ NEW - Assignment Row
    private func assignmentRow(_ assignment: MealPrepAssignment) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(assignment.mealType.localizedName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                    
                    if let recipeTitle = assignment.specificRecipeTitle {
                        Text(recipeTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text("\(assignment.portionsUsed)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
            
            Text(assignment.portionsUsed > 1 ? NSLocalizedString("mealprep.portions", comment: "") : NSLocalizedString("mealprep.portion", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
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
                    
                    // Nutritional information (if available)
                    if let calories = recipe.caloriesPerServing,
                       let protein = recipe.proteinPerServing,
                       let carbs = recipe.carbsPerServing,
                       let fat = recipe.fatPerServing {
                        
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(calories) cal")
                            Text("|")
                                .foregroundColor(.secondary)
                            Text("P: \(protein)g")
                            Text("G: \(carbs)g")
                            Text("L: \(fat)g")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Preparation Tab - REDESIGNED with NEW Structure
    
    @State private var prepSubTab = 0  // 0 = Aujourd'hui, 1 = Cette semaine
    
    private var preparationTab: some View {
        VStack(spacing: 0) {
            // Sub-tab picker
            Picker("", selection: $prepSubTab) {
                Text(LocalizedStringKey("meal_prep.detail.today_tab"))
                    .tag(0)
                Text(LocalizedStringKey("meal_prep.detail.weekly_tab"))
                    .tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content based on selected sub-tab
            if prepSubTab == 0 {
                todayPreparationTab
            } else {
                weeklyReheatingTab
            }
        }
    }
    
    // MARK: - TODAY PREPARATION Tab (Nouveau format simplifié)
    
    @State private var completedCommonPreps: Set<UUID> = []
    @State private var completedRecipePreps: Set<UUID> = []
    
    private var commonPrepsKey: String {
        "mealprep_common_preps_\(kit.id.uuidString)"
    }
    
    private var recipePrepsKey: String {
        "mealprep_recipe_preps_\(kit.id.uuidString)"
    }
    
    private var todayPreparationTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Check if new structure is available
                if let todayPrep = kit.todayPreparation {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("meal_prep.detail.today_title"))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .foregroundColor(.accentColor)
                            Text("~\(todayPrep.totalMinutes) minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Progress bar
                    todayProgressBar(todayPrep: todayPrep)
                    
                    // Consolidated Ingredients Section (NEW - BEFORE common preps)
                    if let consolidatedIngredients = todayPrep.consolidatedIngredients, !consolidatedIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedStringKey("meal_prep.detail.shopping_list_title"))
                                .font(.headline)
                                .padding(.horizontal)
                            
                            consolidatedIngredientsCard(consolidatedIngredients)
                        }
                    }
                    
                    // Common Preparations Section
                    if !todayPrep.commonPreps.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedStringKey("meal_prep.detail.common_preps_title"))
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(todayPrep.commonPreps) { commonPrep in
                                commonPrepCard(commonPrep)
                            }
                        }
                    }
                    
                    // Recipe Preparations Section
                    if !todayPrep.recipePreps.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedStringKey("meal_prep.detail.recipe_preps_title"))
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(todayPrep.recipePreps) { recipePrep in
                                recipePrepCard(recipePrep)
                            }
                        }
                    }
                } else {
                    // Fallback to old structure or empty state
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text(LocalizedStringKey("meal_prep.detail.no_today_prep"))
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
            loadTodayProgress()
        }
    }
    
    // Today Progress Bar
    private func todayProgressBar(todayPrep: TodayPreparation) -> some View {
        let totalSections = todayPrep.commonPreps.count + todayPrep.recipePreps.count
        let completedSections = completedCommonPreps.count + completedRecipePreps.count
        let progress = totalSections > 0 ? Double(completedSections) / Double(totalSections) : 0
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completedSections)/\(totalSections)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(LocalizedStringKey("meal_prep.detail.sections_completed"))
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
    
    // Common Prep Card
    private func commonPrepCard(_ commonPrep: CommonPrepStep) -> some View {
        let isCompleted = completedCommonPreps.contains(commonPrep.id)
        
        return HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: {
                toggleCommonPrep(commonPrep.id)
            }) {
                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .accentColor : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 8) {
                // Category header
                Text(commonPrep.category)
                    .font(.headline)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                
                // Items list
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(commonPrep.items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(isCompleted ? .secondary : .primary)
                                .strikethrough(isCompleted)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .opacity(isCompleted ? 0.6 : 1.0)
        )
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
    
    // Recipe Prep Card
    private func recipePrepCard(_ recipePrep: RecipePrep) -> some View {
        let isCompleted = completedRecipePreps.contains(recipePrep.id)
        
        return HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: {
                toggleRecipePrep(recipePrep.id)
            }) {
                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .accentColor : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 10) {
                // Recipe header with emoji
                HStack(spacing: 8) {
                    Text(recipePrep.emoji)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipePrep.recipeName)
                            .font(.headline)
                            .foregroundColor(isCompleted ? .secondary : .primary)
                        
                        if let minutes = recipePrep.estimatedMinutes {
                            HStack(spacing: 12) {
                                Label("\(minutes)min", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let eveningMinutes = recipePrep.eveningMinutes {
                                    Label("\(eveningMinutes)min soir", systemImage: "moon")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
                
                // Warning banner if present
                if let warning = recipePrep.dontPrepToday {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text(warning)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Prep steps
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(recipePrep.prepToday.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(isCompleted ? .secondary : .primary)
                            
                            Text(step)
                                .font(.subheadline)
                                .foregroundColor(isCompleted ? .secondary : .primary)
                                .strikethrough(isCompleted)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .opacity(isCompleted ? 0.6 : 1.0)
        )
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
    
    // Consolidated Ingredients Card (NEW)
    private func consolidatedIngredientsCard(_ ingredients: [ConsolidatedIngredient]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: "cart.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 8) {
                // Header
                Text(LocalizedStringKey("meal_prep.detail.shopping_list_header"))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Ingredients grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                    ForEach(ingredients) { ingredient in
                        HStack(alignment: .top, spacing: 6) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ingredient.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(ingredient.quantity)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - WEEKLY REHEATING Tab (Nouveau format simplifié)
    
    @State private var completedDays: Set<UUID> = []
    
    private var weeklyDaysKey: String {
        "mealprep_weekly_days_\(kit.id.uuidString)"
    }
    
    private var weeklyReheatingTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Check if new structure is available
                if let weeklyReheating = kit.weeklyReheating, !weeklyReheating.days.isEmpty {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("meal_prep.detail.weekly_title"))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(LocalizedStringKey("meal_prep.detail.weekly_subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Progress bar
                    weeklyProgressBar(weeklyReheating: weeklyReheating)
                    
                    // Days list
                    ForEach(weeklyReheating.days) { day in
                        dailyReheatingCard(day)
                    }
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text(LocalizedStringKey("meal_prep.detail.no_weekly_reheating"))
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
            loadWeeklyProgress()
        }
    }
    
    // Weekly Progress Bar
    private func weeklyProgressBar(weeklyReheating: WeeklyReheating) -> some View {
        let totalDays = weeklyReheating.days.count
        let completedDaysCount = completedDays.count
        let progress = totalDays > 0 ? Double(completedDaysCount) / Double(totalDays) : 0
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completedDaysCount)/\(totalDays)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(LocalizedStringKey("meal_prep.detail.days_completed"))
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
    
    // Daily Reheating Card
    private func dailyReheatingCard(_ day: DailyReheating) -> some View {
        let isCompleted = completedDays.contains(day.id)
        
        return HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: {
                toggleDay(day.id)
            }) {
                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .accentColor : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 10) {
                // Day header with emoji
                HStack(spacing: 8) {
                    Text(day.emoji)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(day.dayLabel)
                            .font(.headline)
                            .foregroundColor(isCompleted ? .secondary : .accentColor)
                        
                        Text(day.recipeName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isCompleted ? .secondary : .primary)
                        
                        Label("\(day.estimatedMinutes)min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Steps
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(day.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(isCompleted ? .secondary : .primary)
                            
                            Text(step)
                                .font(.subheadline)
                                .foregroundColor(isCompleted ? .secondary : .primary)
                                .strikethrough(isCompleted)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .opacity(isCompleted ? 0.6 : 1.0)
        )
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
    
    // MARK: - Persistence for Today Preparation
    
    private func toggleCommonPrep(_ id: UUID) {
        if completedCommonPreps.contains(id) {
            completedCommonPreps.remove(id)
        } else {
            completedCommonPreps.insert(id)
        }
        saveTodayProgress()
    }
    
    private func toggleRecipePrep(_ id: UUID) {
        if completedRecipePreps.contains(id) {
            completedRecipePreps.remove(id)
        } else {
            completedRecipePreps.insert(id)
        }
        saveTodayProgress()
    }
    
    private func loadTodayProgress() {
        if let data = UserDefaults.standard.data(forKey: commonPrepsKey),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            completedCommonPreps = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: recipePrepsKey),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            completedRecipePreps = decoded
        }
    }
    
    private func saveTodayProgress() {
        if let encoded = try? JSONEncoder().encode(completedCommonPreps) {
            UserDefaults.standard.set(encoded, forKey: commonPrepsKey)
        }
        
        if let encoded = try? JSONEncoder().encode(completedRecipePreps) {
            UserDefaults.standard.set(encoded, forKey: recipePrepsKey)
        }
    }
    
    // MARK: - Persistence for Weekly Reheating
    
    private func toggleDay(_ id: UUID) {
        if completedDays.contains(id) {
            completedDays.remove(id)
        } else {
            completedDays.insert(id)
        }
        saveWeeklyProgress()
    }
    
    private func loadWeeklyProgress() {
        if let data = UserDefaults.standard.data(forKey: weeklyDaysKey),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            completedDays = decoded
        }
    }
    
    private func saveWeeklyProgress() {
        if let encoded = try? JSONEncoder().encode(completedDays) {
            UserDefaults.standard.set(encoded, forKey: weeklyDaysKey)
        }
    }
    
    // MARK: - Helpers
    
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

// MARK: - LocalizedStringKey Extension

extension LocalizedStringKey {
    var stringValue: String {
        let mirror = Mirror(reflecting: self)
        let key = mirror.children.first(where: { $0.label == "key" })?.value as? String
        return NSLocalizedString(key ?? "", comment: "")
    }
}
