import SwiftUI

struct TodayView: View {
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @Binding var selectedSegment: RecipesSegment
    @State private var regeneratingMealId: UUID?
    @State private var showUsageLimitReached = false
    @State private var showAddMealSheet = false
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    
    var body: some View {
        Group {
            if let activePlan = planVM.activePlan {
                let todayMeals = mealsForToday(in: activePlan)
                
                if !todayMeals.isEmpty {
                    todayMealsView(meals: todayMeals)
                } else {
                    noMealsToday
                }
            } else {
                noActivePlan
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
    
    // MARK: - Today's Meals View
    
    private func todayMealsView(meals: [(MealItem, String)]) -> some View {
        ScrollView {
            VStack(spacing: PlaneaSpacing.lg) {
                // Header
                VStack(spacing: PlaneaSpacing.sm) {
                    HStack {
                        Image(systemName: "calendar.circle.fill")
                            .font(.planeaTitle2)
                            .foregroundColor(.planeaPrimary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("today.title".localized)
                                .font(.planeaTitle2)
                                .bold()
                            
                            Text(todayDateString())
                                .font(.planeaSubheadline)
                                .foregroundColor(.planeaTextSecondary)
                        }
                        
                        Spacer()
                        
                        // Meal count badge
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.planeaCaption)
                            Text("\(meals.count)")
                                .font(.planeaCaption)
                                .bold()
                        }
                        .foregroundColor(.planeaTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.planeaChipDefault)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, PlaneaSpacing.sm)
                
                // All meals for today
                VStack(spacing: PlaneaSpacing.md) {
                    ForEach(meals, id: \.0.id) { mealTuple in
                        TodayMealCard(
                            mealItem: mealTuple.0,
                            mealLabel: mealTuple.1,
                            isRegenerating: regeneratingMealId == mealTuple.0.id,
                            onStartCooking: {
                                // Navigate to recipe detail
                            },
                            onRegenerate: {
                                Task {
                                    await regenerateMeal(mealTuple.0)
                                }
                            },
                            onRemove: {
                                withAnimation {
                                    planVM.removeMeal(mealItem: mealTuple.0)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Next Meal Card
    
    private func nextMealCard(meal: (MealItem, String)) -> some View {
        VStack(alignment: .leading, spacing: PlaneaSpacing.sm) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.planeaSecondary)
                Text("today.nextMeal".localized)
                    .font(.planeaCaption)
                    .foregroundColor(.planeaTextSecondary)
                    .bold()
                Spacer()
            }
            
            HStack(spacing: PlaneaSpacing.sm) {
                Image(systemName: iconName(for: meal.0.mealType))
                    .font(.planeaTitle2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconColor(for: meal.0.mealType))
                    .frame(width: 48, height: 48)
                    .background(iconColor(for: meal.0.mealType).opacity(0.15))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.1)
                        .font(.planeaCaption)
                        .foregroundColor(.planeaTextSecondary)
                    
                    Text(meal.0.recipe.title)
                        .font(.planeaHeadline)
                        .bold()
                        .foregroundColor(.planeaTextPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "clock")
                        .font(.planeaCaption2)
                    Text("\(meal.0.recipe.totalMinutes) min")
                        .font(.planeaCaption2)
                }
                .foregroundColor(.planeaTextSecondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.planeaSecondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.planeaSecondary.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    // MARK: - No Meals Today
    
    private var noMealsToday: some View {
        VStack(spacing: PlaneaSpacing.xl) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.planeaTextSecondary)
            
            VStack(spacing: PlaneaSpacing.sm) {
                Text("today.noMeals".localized)
                    .font(.planeaTitle2)
                    .bold()
                    .foregroundColor(.planeaTextPrimary)
                
                Text("today.noMeals.message".localized)
                    .font(.planeaBody)
                    .foregroundColor(.planeaTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PlaneaSpacing.xl)
            }
            
            Button(action: {
                withAnimation {
                    selectedSegment = .generatePlan
                }
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("today.planMeals".localized)
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
    
    // MARK: - No Active Plan
    
    private var noActivePlan: some View {
        VStack(spacing: PlaneaSpacing.xl) {
            Spacer()
            
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.planeaSecondaryAccessible)
            
            VStack(spacing: PlaneaSpacing.sm) {
                Text("plan.noActiveWeek.title".localized)
                    .font(.planeaTitle2)
                    .bold()
                    .foregroundColor(.planeaTextPrimary)
                
                Text("plan.noActiveWeek.message".localized)
                    .font(.planeaBody)
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
    
    // MARK: - Helper Methods
    
    private func mealsForToday(in plan: MealPlan) -> [(MealItem, String)] {
        let calendar = Calendar.current
        let today = Date()
        
        // Filter meals that have a real date matching today, or fallback to weekday matching
        let meals = plan.items.filter { item in
            if let itemDate = item.date {
                // Use real date comparison (same calendar day)
                return calendar.isDate(itemDate, inSameDayAs: today)
            } else {
                // Fallback for legacy items without dates: compare weekday
                let todayWeekday = today.toWeekday()
                return item.weekday == todayWeekday
            }
        }
        .sorted { $0.mealType.sortOrder < $1.mealType.sortOrder }
        
        return meals.map { item in
            (item, label(for: item.mealType))
        }
    }
    
    private func nextMeal(from meals: [(MealItem, String)]) -> (MealItem, String)? {
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Determine next meal based on time
        // Breakfast: 5-11, Lunch: 11-17, Dinner: 17-23
        for meal in meals {
            switch meal.0.mealType {
            case .breakfast:
                if currentHour < 11 { return meal }
            case .lunch:
                if currentHour < 17 { return meal }
            case .dinner:
                if currentHour < 23 { return meal }
            case .snack:
                continue
            }
        }
        
        // If no upcoming meal, return first meal
        return meals.first
    }
    
    private func label(for mt: MealType) -> String {
        mt.localizedName
    }
    
    private func iconName(for mealType: MealType) -> String {
        switch mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
    
    private func iconColor(for mealType: MealType) -> Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        case .snack: return .green
        }
    }
    
    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: Date())
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

// MARK: - Today Meal Card

struct TodayMealCard: View {
    let mealItem: MealItem
    let mealLabel: String
    let isRegenerating: Bool
    let onStartCooking: () -> Void
    let onRegenerate: () -> Void
    let onRemove: () -> Void
    
    var iconName: String {
        switch mealItem.mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
    
    var iconColor: Color {
        switch mealItem.mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        case .snack: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Left accent bar
                Rectangle()
                    .fill(iconColor)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: PlaneaSpacing.md) {
                    // Header
                    HStack {
                        Image(systemName: iconName)
                            .font(.planeaTitle3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(iconColor)
                            .frame(width: 40, height: 40)
                            .background(iconColor.opacity(0.15))
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mealLabel)
                                .font(.planeaCaption)
                                .foregroundColor(.planeaTextSecondary)
                            
                            Text(mealItem.recipe.title)
                                .font(.planeaHeadline)
                                .bold()
                                .foregroundColor(.planeaTextPrimary)
                        }
                        
                        Spacer()
                    }
                    
                    // Recipe info
                    HStack(spacing: PlaneaSpacing.lg) {
                        Label("\(mealItem.recipe.servings)", systemImage: "person.2.fill")
                            .font(.planeaCaption)
                            .foregroundColor(.planeaTextSecondary)
                        
                        Label("\(mealItem.recipe.totalMinutes) min", systemImage: "clock.fill")
                            .font(.planeaCaption)
                            .foregroundColor(.planeaTextSecondary)
                    }
                    
                    // Actions
                    HStack(spacing: PlaneaSpacing.sm) {
                        // View recipe button
                        NavigationLink(destination: RecipeDetailView(recipe: mealItem.recipe)) {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("today.viewRecipe".localized)
                            }
                            .font(.planeaSubheadline)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.planeaPrimary)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        
                        // Regenerate button
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            onRegenerate()
                        }) {
                            if isRegenerating {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                                    .frame(width: 44, height: 44)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.planeaTitle3)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(Color.planeaPrimary.opacity(0.1))
                        .foregroundColor(.planeaPrimary)
                        .cornerRadius(10)
                        .disabled(isRegenerating)
                        
                        // Remove button
                        Button(action: onRemove) {
                            Image(systemName: "trash.fill")
                                .font(.planeaTitle3)
                        }
                        .frame(width: 44, height: 44)
                        .background(Color.planeaDanger.opacity(0.1))
                        .foregroundColor(.planeaDanger)
                        .cornerRadius(10)
                    }
                }
                .padding(PlaneaSpacing.md)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.planeaCard)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Date Extension

extension Date {
    func toWeekday() -> Weekday {
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: self)
        
        // Calendar.current.component(.weekday) returns:
        // 1 = Sunday, 2 = Monday, 3 = Tuesday, etc.
        switch weekdayIndex {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}
