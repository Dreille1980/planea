import SwiftUI

struct WeekOverviewView: View {
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @Binding var selectedSegment: RecipesSegment
    @State private var regeneratingMealId: UUID?
    @State private var showUsageLimitReached = false
    @State private var showAddMealSheet = false
    @State private var selectedDay: Weekday?
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
        .toolbar {
            if planVM.activePlan != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        showAddMealSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddMealSheet) {
            AddMealSheet()
                .environmentObject(familyVM)
                .environmentObject(planVM)
                .environmentObject(usageVM)
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
                .foregroundColor(.planeaSecondaryAccessible)
            
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
                withAnimation {
                    selectedSegment = .generatePlan
                }
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
            // Horizontal week calendar strip
            WeekCalendarStrip(
                weekdays: weekdays,
                weekStart: plan.weekStart,
                selectedDay: $selectedDay,
                mealCounts: weekdays.reduce(into: [:]) { counts, day in
                    counts[day] = plan.items.filter { $0.weekday == day }.count
                }
            )
            .padding(.vertical, PlaneaSpacing.sm)
            
            // Week calendar view
            ScrollViewReader { proxy in
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
                .onChange(of: selectedDay) { newDay in
                    if let day = newDay {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(day, anchor: .top)
                        }
                    }
                }
            }
        }
    }
    
    func weekCalendarGrid(plan: MealPlan) -> some View {
        VStack(spacing: 12) {
            ForEach(weekdays.indices, id: \.self) { index in
                let day = weekdays[index]
                if let dayMeals = mealsForDay(day, in: plan) {
                    // Use real date from first meal item if available, otherwise calculate
                    let dayDate = dayMeals.first?.0.resolvedDate(weekStart: plan.weekStart) ?? dateForWeekday(day, startingFrom: plan.weekStart)
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
                    .id(day) // Add ID for ScrollViewReader
                }
            }
        }
    }
    
    func weekSections(plan: MealPlan) -> some View {
        VStack(spacing: 24) {
            // Meal prep section with prominent button (only if meal prep recipes exist)
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
                Divider()
                    .padding(.vertical, 8)
                
                mealPrepMainSection(plan: plan, items: mealPrepRecipes)
            }
        }
    }
    
    func recipeSection(title: String, icon: String, color: Color, items: [MealItem]) -> some View {
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
    
    func mealPrepMainSection(plan: MealPlan, items: [MealItem]) -> some View {
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
                let countKey = items.count == 1 ? "plan.mealPrepCount.singular" : "plan.mealPrepCount.plural"
                Text(String(format: countKey.localized, items.count))
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
                                    Text("📅 " + "plan.mealPrep.viewDayPrep".localized)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "list.clipboard")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text("🌙 " + "plan.mealPrep.weekReheatingPlan".localized)
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
    
    func mealPrepStepsSection(items: [MealItem]) -> some View {
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
    
    func mealsForDay(_ day: Weekday, in plan: MealPlan) -> [(MealItem, String)]? {
        let meals = plan.items.filter { $0.weekday == day }
        guard !meals.isEmpty else { return nil }
        
        return meals.map { item in
            (item, label(for: item.mealType))
        }
    }
    
    func dateForWeekday(_ weekday: Weekday, startingFrom weekStart: Date) -> Date {
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
                Button(action: {
                    // Haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onRegenerate()
                }) {
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
                .accessibilityLabel("Régénérer cette recette")
                .accessibilityHint("Génère une nouvelle recette pour ce repas")
                
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

// MARK: - Week Calendar Strip (NEW)

struct WeekCalendarStrip: View {
    let weekdays: [Weekday]
    let weekStart: Date
    @Binding var selectedDay: Weekday?
    let mealCounts: [Weekday: Int]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(weekdays, id: \.self) { day in
                    let dayDate = dateForWeekday(day, startingFrom: weekStart)
                    let isToday = Calendar.current.isDateInToday(dayDate)
                    let isSelected = selectedDay == day
                    let mealCount = mealCounts[day] ?? 0
                    
                    WeekDayCell(
                        weekday: day,
                        date: dayDate,
                        mealCount: mealCount,
                        isToday: isToday,
                        isSelected: isSelected
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDay = day
                            // TODO: Scroll to day in list
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color.planeaBackground)
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
}

// MARK: - Week Day Cell

struct WeekDayCell: View {
    let weekday: Weekday
    let date: Date
    let mealCount: Int
    let isToday: Bool
    let isSelected: Bool
    
    private var dayName: String {
        weekday.localizedShortName
    }
    
    private var dateNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Day name
            Text(dayName)
                .font(.planeaCaption)
                .fontWeight(isToday || isSelected ? .bold : .regular)
                .foregroundColor(textColor)
            
            // Date number in circle
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 44, height: 44)
                
                if isToday && !isSelected {
                    Circle()
                        .stroke(Color.planeaPrimary, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
                
                Text(dateNumber)
                    .font(.planeaBody)
                    .fontWeight(isToday || isSelected ? .bold : .semibold)
                    .foregroundColor(isSelected ? .white : (isToday ? .planeaPrimary : .planeaTextPrimary))
            }
            
            // Meal count indicator
            if mealCount > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<min(mealCount, 4), id: \.self) { _ in
                        Circle()
                            .fill(dotColor)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 8)
            } else {
                Spacer()
                    .frame(height: 8)
            }
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.clear : Color.clear)
        )
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .planeaPrimary
        } else if isToday {
            return Color.planeaPrimary.opacity(0.1)
        } else {
            return Color.planeaChipDefault
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .planeaPrimary
        } else {
            return .planeaTextSecondary
        }
    }
    
    private var dotColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .planeaPrimary
        } else {
            return .planeaSecondary
        }
    }
}
