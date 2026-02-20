import SwiftUI

struct WeekOverviewView: View {
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @State private var selectedSegment: Int = 0
    @State private var regeneratingMealId: UUID?
    @State private var showUsageLimitReached = false
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    
    var weekdays: [Weekday] {
        PreferencesService.shared.loadPreferences().sortedWeekdays()
    }
    
    var body: some View {
        Group {
            if let activePlan = planVM.activePlan {
                // Show active week
                activeWeekView(plan: activePlan)
            } else {
                // No active week
                noActiveWeekView
            }
        }
        .sheet(isPresented: $showUsageLimitReached) {
            UsageLimitReachedView()
                .environmentObject(usageVM)
        }
    }
    
    // MARK: - No Active Week View
    
    private var noActiveWeekView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.planeaSecondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("plan.noActiveWeek.title".localized)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.planeaTextPrimary)
                
                Text("plan.noActiveWeek.message".localized)
                    .font(.subheadline)
                    .foregroundColor(.planeaTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                // Switch to generate plan tab would need to be handled by parent
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("plan.noActiveWeek.button".localized)
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.planeaPrimary)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - Active Week View
    
    private func activeWeekView(plan: MealPlan) -> some View {
        VStack(spacing: 0) {
            // Week calendar view
            ScrollView {
                VStack(spacing: 16) {
                    // Week range header
                    WeekRangeHeader(weekStart: plan.weekStart)
                        .padding(.horizontal)
                    
                    // Calendar grid
                    weekCalendarGrid(plan: plan)
                        .padding(.horizontal)
                    
                    // Sections: Simple recipes, Meal Prep, Steps
                    weekSections(plan: plan)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
    }
    
    private func weekCalendarGrid(plan: MealPlan) -> some View {
        VStack(spacing: 12) {
            ForEach(weekdays.indices, id: \.self) { index in
                let day = weekdays[index]
                if let dayMeals = mealsForDay(day, in: plan) {
                    let dayDate = dateForWeekday(day, startingFrom: plan.weekStart)
                    WeekDayCard(
                        day: dayLabel(for: day),
                        date: dayDate,
                        meals: dayMeals,
                        regeneratingMealId: regeneratingMealId,
                        onRegenerateMeal: { mealItem in
                            Task {
                                await regenerateMeal(mealItem)
                            }
                        },
                        onRemoveMeal: { mealItem in
                            withAnimation {
                                planVM.removeMeal(mealItem: mealItem)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func weekSections(plan: MealPlan) -> some View {
        VStack(spacing: 24) {
            Divider()
                .padding(.vertical, 8)
            
            // Simple recipes section
            let simpleRecipes = plan.items.filter { !$0.isMealPrep }
            if !simpleRecipes.isEmpty {
                recipeSection(
                    title: "plan.simpleRecipes.title".localized,
                    icon: "fork.knife",
                    color: .planeaPrimary,
                    items: simpleRecipes
                )
            }
            
            // Meal prep section with prominent button
            let mealPrepRecipes = plan.items.filter { $0.isMealPrep }
            let _ = {
                print("🥡 DEBUG WeekOverviewView: Total items=\(plan.items.count), MealPrep items=\(mealPrepRecipes.count)")
                for item in plan.items.prefix(3) {
                    print("  - \(item.recipe.title): isMealPrep=\(item.isMealPrep), groupId=\(item.mealPrepGroupId?.uuidString ?? "nil")")
                }
                if !mealPrepRecipes.isEmpty {
                    print("🥡 Showing meal prep section with \(mealPrepRecipes.count) items")
                } else {
                    print("⚠️ No meal prep recipes found - button will NOT be shown")
                }
            }()
            if !mealPrepRecipes.isEmpty {
                mealPrepMainSection(plan: plan, items: mealPrepRecipes)
            }
        }
    }
    
    private func recipeSection(title: String, icon: String, color: Color, items: [MealItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .bold()
            }
            
            VStack(spacing: 8) {
                ForEach(items) { item in
                    NavigationLink(destination: RecipeDetailView(recipe: item.recipe)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.recipe.title)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.planeaTextPrimary)
                                
                                HStack(spacing: 8) {
                                    Text(dayLabel(for: item.weekday))
                                        .font(.caption)
                                        .foregroundColor(.planeaTextSecondary)
                                    
                                    Text("•")
                                        .foregroundColor(.planeaTextSecondary)
                                    
                                    Text(label(for: item.mealType))
                                        .font(.caption)
                                        .foregroundColor(.planeaTextSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            if item.isMealPrep {
                                Text("🥡")
                                    .font(.title3)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.planeaTextSecondary)
                        }
                        .padding()
                        .background(Color.planeaCard)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Meal Prep Main Section (NEW)
    
    private func mealPrepMainSection(plan: MealPlan, items: [MealItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                    .foregroundColor(.orange)
                Text("plan.mealPrepRecipes.title".localized)
                    .font(.headline)
                    .bold()
            }
            
            // Summary card
            VStack(alignment: .leading, spacing: 12) {
                Text("\(items.count) repas en meal prep")
                    .font(.subheadline)
                    .foregroundColor(.planeaTextSecondary)
                
                // Call-to-action button
                if let mealPrepKit = MealPlanAdapter.toMealPrepKit(plan) {
                    NavigationLink(destination: MealPrepDetailView(kit: mealPrepKit)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.orange)
                                    Text("📅 Voir la préparation du jour")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "list.clipboard")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("🌙 + Plan de réchauffage de la semaine")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.orange)
                                .font(.title3)
                                .bold()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.orange, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Recipe list
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        NavigationLink(destination: RecipeDetailView(recipe: item.recipe)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.recipe.title)
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.planeaTextPrimary)
                                    
                                    HStack(spacing: 8) {
                                        Text(dayLabel(for: item.weekday))
                                            .font(.caption)
                                            .foregroundColor(.planeaTextSecondary)
                                        
                                        Text("•")
                                            .foregroundColor(.planeaTextSecondary)
                                        
                                        Text(label(for: item.mealType))
                                            .font(.caption)
                                            .foregroundColor(.planeaTextSecondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("🥡")
                                    .font(.title3)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.planeaTextSecondary)
                            }
                            .padding()
                            .background(Color.planeaCard)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func mealPrepStepsSection(items: [MealItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.clipboard")
                    .foregroundColor(.orange)
                Text("plan.mealPrepSteps.title".localized)
                    .font(.headline)
                    .bold()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("plan.mealPrepSteps.description".localized)
                    .font(.subheadline)
                    .foregroundColor(.planeaTextSecondary)
                
                // Group meal prep items by groupId
                let groupedItems = Dictionary(grouping: items) { $0.mealPrepGroupId }
                
                ForEach(Array(groupedItems.keys.compactMap { $0 }), id: \.self) { groupId in
                    if let groupItems = groupedItems[groupId], let firstItem = groupItems.first {
                        MealPrepStepsCard(
                            recipe: firstItem.recipe,
                            relatedMeals: groupItems
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func mealsForDay(_ day: Weekday, in plan: MealPlan) -> [(MealItem, String)]? {
        let meals = plan.items.filter { $0.weekday == day }
        guard !meals.isEmpty else { return nil }
        
        return meals.map { item in
            (item, label(for: item.mealType))
        }
    }
    
    private func dateForWeekday(_ weekday: Weekday, startingFrom weekStart: Date) -> Date {
        let calendar = Calendar.current
        let startWeekday = calendar.component(.weekday, from: weekStart)
        
        let targetWeekday: Int
        switch weekday {
        case .sunday: targetWeekday = 1
        case .monday: targetWeekday = 2
        case .tuesday: targetWeekday = 3
        case .wednesday: targetWeekday = 4
        case .thursday: targetWeekday = 5
        case .friday: targetWeekday = 6
        case .saturday: targetWeekday = 7
        }
        
        var daysDifference = targetWeekday - startWeekday
        if daysDifference < 0 {
            daysDifference += 7
        }
        
        return calendar.date(byAdding: .day, value: daysDifference, to: weekStart) ?? weekStart
    }
    
    func dayLabel(for wd: Weekday) -> String {
        wd.displayName
    }
    
    func label(for mt: MealType) -> String {
        mt.localizedName
    }
    
    func regenerateMeal(_ mealItem: MealItem) async {
        guard usageVM.canGenerate(count: 1) else {
            showUsageLimitReached = true
            return
        }
        
        regeneratingMealId = mealItem.id
        
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
            
            let language = AppLanguage.currentLocale(appLanguage).prefix(2).lowercased()
            let servings = max(1, familyVM.members.count)
            
            let newRecipe = try await service.regenerateMeal(
                weekday: mealItem.weekday,
                mealType: mealItem.mealType,
                constraints: constraintsDict,
                servings: servings,
                units: units,
                language: String(language),
                diversitySeed: Int.random(in: 0...1000)
            )
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                planVM.regenerateMeal(mealItem: mealItem, newRecipe: newRecipe)
            }
            
            usageVM.recordGenerations(count: 1)
        } catch {
            // Handle error silently or show toast
        }
        
        regeneratingMealId = nil
    }
}

// MARK: - Week Day Card

struct WeekDayCard: View {
    let day: String
    let date: Date
    let meals: [(MealItem, String)]
    let regeneratingMealId: UUID?
    let onRegenerateMeal: (MealItem) -> Void
    let onRemoveMeal: (MealItem) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.planeaTertiary)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(date.dayWithDate())
                            .font(.headline)
                            .bold()
                            .foregroundColor(.planeaTextPrimary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "fork.knife")
                            .font(.caption)
                        Text("\(meals.count)")
                            .font(.caption)
                            .bold()
                    }
                    .foregroundColor(.planeaTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.planeaChipDefault)
                    .cornerRadius(8)
                }
                
                Divider()
                    .background(Color.planeaBorder)
                
                VStack(spacing: 12) {
                    ForEach(meals, id: \.0.id) { mealTuple in
                        WeekMealRow(
                            mealItem: mealTuple.0,
                            mealType: mealTuple.0.mealType,
                            mealLabel: mealTuple.1,
                            recipeName: mealTuple.0.recipe.title,
                            isMealPrep: mealTuple.0.isMealPrep,
                            isRegenerating: regeneratingMealId == mealTuple.0.id,
                            onRegenerate: {
                                onRegenerateMeal(mealTuple.0)
                            },
                            onRemove: {
                                onRemoveMeal(mealTuple.0)
                            }
                        )
                    }
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.planeaCard)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Week Meal Row

struct WeekMealRow: View {
    let mealItem: MealItem
    let mealType: MealType
    let mealLabel: String
    let recipeName: String
    let isMealPrep: Bool
    let isRegenerating: Bool
    let onRegenerate: () -> Void
    let onRemove: () -> Void
    
    var iconName: String {
        switch mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
    
    var iconColor: Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        case .snack: return .green
        }
    }
    
    var body: some View {
        NavigationLink(destination: RecipeDetailView(recipe: mealItem.recipe)) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(mealLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if isMealPrep {
                            Text("🥡")
                                .font(.caption)
                        }
                    }
                    
                    Text(recipeName)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 20)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 8) {
                Button(action: onRegenerate) {
                    HStack(spacing: 4) {
                        if isRegenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14))
                        }
                    }
                    .frame(width: 32, height: 32)
                    .background(Color.planeaPrimary.opacity(0.1))
                    .foregroundColor(.planeaPrimary)
                    .cornerRadius(8)
                }
                .disabled(isRegenerating)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.planeaDanger)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Meal Prep Steps Card

struct MealPrepStepsCard: View {
    let recipe: Recipe
    let relatedMeals: [MealItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(recipe.title)
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                Text("🥡")
            }
            
            // Related meals
            Text("plan.mealPrepSteps.covers".localized + ": \(relatedMeals.count) repas")
                .font(.caption)
                .foregroundColor(.planeaTextSecondary)
            
            // Instructions would come from meal prep data
            if !recipe.steps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(recipe.steps.prefix(3).enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .bold()
                            
                            Text(instruction)
                                .font(.caption)
                                .foregroundColor(.planeaTextSecondary)
                        }
                    }
                    
                    if recipe.steps.count > 3 {
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            Text("plan.mealPrepSteps.viewAll".localized)
                                .font(.caption)
                                .foregroundColor(.planeaPrimary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
