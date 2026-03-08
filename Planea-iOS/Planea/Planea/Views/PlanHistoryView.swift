import SwiftUI

struct PlanHistoryView: View {
    @EnvironmentObject var planVM: PlanViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if planVM.archivedPlans.isEmpty {
                    ContentUnavailableView(
                        "plan.history.empty".localized,
                        systemImage: "tray.fill",
                        description: Text("Activez vos plans pour créer un historique")
                    )
                } else {
                    List {
                        ForEach(planVM.archivedPlans) { plan in
                            PlanHistoryRow(plan: plan)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            planVM.deletePlan(plan: plan)
                                        }
                                    } label: {
                                        Label("action.delete".localized, systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("plan.history.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("action.done".localized) {
                dismiss()
            })
        }
    }
}

struct PlanHistoryRow: View {
    let plan: MealPlan
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    var body: some View {
        NavigationLink(destination: PlanHistoryDetailView(plan: plan)) {
            HStack(spacing: PlaneaSpacing.sm) {
                // Icon
                Image(systemName: "book.closed.fill")
                    .font(.planeaTitle2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Display plan name if available, otherwise show "Week of date"
                    if let name = plan.name, !name.isEmpty {
                        Text(name)
                            .font(.planeaHeadline)
                            .lineLimit(1)
                        
                        Text(dateFormatter.string(from: plan.weekStart))
                            .font(.planeaCaption)
                            .foregroundColor(.planeaTextSecondary)
                    } else {
                        Text("plan.history.weekOf".localized)
                            .font(.planeaCaption)
                            .foregroundColor(.planeaTextSecondary)
                        
                        Text(dateFormatter.string(from: plan.weekStart))
                            .font(.planeaHeadline)
                    }
                    
                    // Stats
                    HStack(spacing: PlaneaSpacing.sm) {
                        Label("\(plan.items.count)", systemImage: "fork.knife")
                            .font(.planeaCaption)
                            .foregroundColor(.planeaTextSecondary)
                        
                        if let confirmedDate = plan.confirmedDate {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(confirmedDate, style: .relative)
                                .font(.planeaCaption)
                                .foregroundColor(.planeaTextSecondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

struct PlanHistoryDetailView: View {
    let plan: MealPlan
    @EnvironmentObject var planVM: PlanViewModel
    @Environment(\.dismiss) var dismiss
    
    var weekdays: [Weekday] {
        PreferencesService.shared.loadPreferences().sortedWeekdays()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: PlaneaSpacing.sm) {
                ForEach(weekdays, id: \.self) { day in
                    if let dayMeals = mealsForDay(day) {
                        DayHistoryCard(day: dayLabel(for: day), meals: dayMeals)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(dateFormatter.string(from: plan.weekStart))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func mealsForDay(_ day: Weekday) -> [(MealItem, String)]? {
        let meals = plan.items.filter { $0.weekday == day }
        guard !meals.isEmpty else { return nil }
        
        return meals.map { item in
            (item, label(for: item.mealType))
        }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    func dayLabel(for wd: Weekday) -> String {
        switch wd {
        case .monday: return "week.monday".localized
        case .tuesday: return "week.tuesday".localized
        case .wednesday: return "week.wednesday".localized
        case .thursday: return "week.thursday".localized
        case .friday: return "week.friday".localized
        case .saturday: return "week.saturday".localized
        case .sunday: return "week.sunday".localized
        }
    }
    
    func label(for mt: MealType) -> String {
        switch mt {
        case .breakfast: return "meal.breakfast".localized
        case .lunch: return "meal.lunch".localized
        case .dinner: return "meal.dinner".localized
        case .snack: return "meal.snack".localized
        }
    }
}

struct DayHistoryCard: View {
    let day: String
    let meals: [(MealItem, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: PlaneaSpacing.sm) {
            // Header
            HStack {
                Text(day)
                    .font(.planeaHeadline)
                    .bold()
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .font(.planeaCaption)
                    Text("\(meals.count)")
                        .font(.planeaCaption)
                        .bold()
                }
                .foregroundColor(.planeaTextSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            
            Divider()
            
            // Meals list (read-only)
            VStack(spacing: PlaneaSpacing.sm) {
                ForEach(meals, id: \.0.id) { mealTuple in
                    NavigationLink(destination: RecipeDetailView(recipe: mealTuple.0.recipe)) {
                        MealHistoryRow(
                            mealType: mealTuple.0.mealType,
                            mealLabel: mealTuple.1,
                            recipeName: mealTuple.0.recipe.title
                        )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        )
    }
}

struct MealHistoryRow: View {
    let mealType: MealType
    let mealLabel: String
    let recipeName: String
    
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
        HStack(spacing: PlaneaSpacing.sm) {
            // Icon
            Image(systemName: iconName)
                .font(.planeaTitle3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .cornerRadius(8)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(mealLabel)
                    .font(.planeaCaption)
                    .foregroundColor(.planeaTextSecondary)
                
                Text(recipeName)
                    .font(.planeaSubheadline)
                    .bold()
                    .foregroundColor(.planeaTextPrimary)
            }
            
            Spacer()
            
            // Navigate icon
            Image(systemName: "chevron.right")
                .font(.planeaCaption)
                .foregroundStyle(.tertiary)
                .frame(width: 20)
        }
        .padding(PlaneaSpacing.sm)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
