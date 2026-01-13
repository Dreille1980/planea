import SwiftUI

struct HomeView: View {
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var familyVM: FamilyViewModel
    @Binding var showHome: Bool
    @Binding var selectedTab: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                VStack(spacing: 8) {
                    Text("home.welcome".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("home.subtitle".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                
                // Main Action Buttons
                VStack(spacing: 12) {
                    Button {
                        selectedTab = 0 // Recipes tab
                        showHome = false
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.title3)
                            Text("home.plan_week".localized)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor.gradient)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    
                    Button {
                        selectedTab = 0 // Will navigate to Ad hoc in RecipesView
                        showHome = false
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title3)
                            Text("home.find_recipe_now".localized)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .foregroundStyle(.primary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                
                // Meal of the Day Section
                mealOfTheDayCard
                    .padding(.horizontal)
                
                // This Week Section (if plan exists)
                if let plan = planVM.activePlan ?? planVM.currentPlan {
                    upcomingMealsSection(plan: plan)
                        .padding(.horizontal)
                }
                
                // Quick Shortcuts Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("home.quick_shortcuts".localized)
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ShortcutCard(
                            icon: "calendar",
                            title: "home.shortcut.planning".localized,
                            color: .blue
                        ) {
                            selectedTab = 0
                            showHome = false
                        }
                        
                        ShortcutCard(
                            icon: "cart",
                            title: "home.shortcut.groceries".localized,
                            color: .green
                        ) {
                            selectedTab = 1
                            showHome = false
                        }
                        
                        ShortcutCard(
                            icon: "heart.fill",
                            title: "tab.favorites".localized,
                            color: .red
                        ) {
                            selectedTab = 2
                            showHome = false
                        }
                        
                        ShortcutCard(
                            icon: "gearshape.fill",
                            title: "tab.settings".localized,
                            color: .gray
                        ) {
                            selectedTab = 3
                            showHome = false
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Meal of the Day Card
    
    private var mealOfTheDayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentMealTimeLabel)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if let meal = currentMeal {
                mealCardContent(meal: meal)
            } else {
                noMealCardContent
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(currentMealColor.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(currentMealColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func mealCardContent(meal: (item: MealItem, timeLabel: String)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForMealType(meal.item.mealType))
                    .font(.title2)
                    .foregroundStyle(currentMealColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.item.recipe.title)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if meal.item.recipe.totalMinutes > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("\(meal.item.recipe.totalMinutes) min")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            Button {
                selectedTab = 0
                showHome = false
            } label: {
                Text("home.view_recipe".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(currentMealColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(currentMealColor.opacity(0.15))
                    .cornerRadius(8)
            }
        }
    }
    
    private var noMealCardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text("home.no_meal".localized)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Button {
                selectedTab = 0 // Navigate to Ad hoc
                showHome = false
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("action.generateRecipe".localized)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Upcoming Meals Section
    
    private func upcomingMealsSection(plan: MealPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.this_week".localized)
                .font(.headline)
            
            let upcomingMeals = getUpcomingMeals(from: plan)
            
            if upcomingMeals.isEmpty {
                Text("home.no_upcoming_meals".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(upcomingMeals.prefix(3), id: \.item.id) { meal in
                        upcomingMealRow(meal: meal)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func upcomingMealRow(meal: (item: MealItem, day: String, mealLabel: String)) -> some View {
        Button {
            selectedTab = 0
            showHome = false
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconForMealType(meal.item.mealType))
                    .font(.title3)
                    .foregroundStyle(colorForMealType(meal.item.mealType))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(meal.day) - \(meal.mealLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(meal.item.recipe.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                if meal.item.recipe.totalMinutes > 0 {
                    Text("\(meal.item.recipe.totalMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Computed Properties
    
    private var currentMealTimeLabel: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        
        if hour >= 5 && hour < 11 {
            timeOfDay = "home.morning".localized
        } else if hour >= 11 && hour < 16 {
            timeOfDay = "home.noon".localized
        } else {
            timeOfDay = "home.evening".localized
        }
        
        return String(format: "home.meal_of_day".localized, timeOfDay)
    }
    
    private var currentMeal: (item: MealItem, timeLabel: String)? {
        guard let plan = planVM.activePlan ?? planVM.currentPlan else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        let weekday = Weekday.from(date: now)
        let hour = calendar.component(.hour, from: now)
        
        let targetMealType: MealType
        if hour >= 5 && hour < 11 {
            targetMealType = .breakfast
        } else if hour >= 11 && hour < 16 {
            targetMealType = .lunch
        } else {
            targetMealType = .dinner
        }
        
        if let meal = plan.items.first(where: { $0.weekday == weekday && $0.mealType == targetMealType }) {
            return (meal, currentMealTimeLabel)
        }
        
        return nil
    }
    
    private var currentMealColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 5 && hour < 11 {
            return .orange
        } else if hour >= 11 && hour < 16 {
            return .yellow
        } else {
            return .indigo
        }
    }
    
    // MARK: - Helper Functions
    
    private func getUpcomingMeals(from plan: MealPlan) -> [(item: MealItem, day: String, mealLabel: String)] {
        let now = Date()
        let calendar = Calendar.current
        let currentWeekday = Weekday.from(date: now)
        let currentHour = calendar.component(.hour, from: now)
        
        let currentMealType: MealType
        if currentHour >= 5 && currentHour < 11 {
            currentMealType = .breakfast
        } else if currentHour >= 11 && currentHour < 16 {
            currentMealType = .lunch
        } else {
            currentMealType = .dinner
        }
        
        let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        let mealTypes: [MealType] = [.breakfast, .lunch, .dinner]
        
        var upcomingMeals: [(item: MealItem, day: String, mealLabel: String)] = []
        
        for meal in plan.items {
            let mealWeekdayIndex = weekdays.firstIndex(of: meal.weekday) ?? 0
            let currentWeekdayIndex = weekdays.firstIndex(of: currentWeekday) ?? 0
            let mealTypeIndex = mealTypes.firstIndex(of: meal.mealType) ?? 0
            let currentMealTypeIndex = mealTypes.firstIndex(of: currentMealType) ?? 0
            
            let isUpcoming = mealWeekdayIndex > currentWeekdayIndex || 
                            (mealWeekdayIndex == currentWeekdayIndex && mealTypeIndex >= currentMealTypeIndex)
            
            if isUpcoming {
                upcomingMeals.append((
                    item: meal,
                    day: dayLabel(for: meal.weekday),
                    mealLabel: mealTypeLabel(for: meal.mealType)
                ))
            }
        }
        
        return upcomingMeals.sorted { meal1, meal2 in
            let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
            let mealTypes: [MealType] = [.breakfast, .lunch, .dinner]
            
            let day1 = weekdays.firstIndex(of: meal1.item.weekday) ?? 0
            let day2 = weekdays.firstIndex(of: meal2.item.weekday) ?? 0
            
            if day1 != day2 {
                return day1 < day2
            }
            
            let type1 = mealTypes.firstIndex(of: meal1.item.mealType) ?? 0
            let type2 = mealTypes.firstIndex(of: meal2.item.mealType) ?? 0
            return type1 < type2
        }
    }
    
    private func iconForMealType(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
    
    private func colorForMealType(_ type: MealType) -> Color {
        switch type {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        case .snack: return .green
        }
    }
    
    private func dayLabel(for weekday: Weekday) -> String {
        switch weekday {
        case .monday: return "week.monday".localized
        case .tuesday: return "week.tuesday".localized
        case .wednesday: return "week.wednesday".localized
        case .thursday: return "week.thursday".localized
        case .friday: return "week.friday".localized
        case .saturday: return "week.saturday".localized
        case .sunday: return "week.sunday".localized
        }
    }
    
    private func mealTypeLabel(for type: MealType) -> String {
        switch type {
        case .breakfast: return "meal.breakfast".localized
        case .lunch: return "meal.lunch".localized
        case .dinner: return "meal.dinner".localized
        case .snack: return "meal.snack".localized
        }
    }
}

// MARK: - Shortcut Card

struct ShortcutCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weekday Extension

extension Weekday {
    static func from(date: Date) -> Weekday {
        let weekdayIndex = Calendar.current.component(.weekday, from: date)
        // Calendar.current.weekday: 1=Sunday, 2=Monday, ..., 7=Saturday
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
