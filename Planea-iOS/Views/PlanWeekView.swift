import SwiftUI

struct PlanWeekView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    let weekdays: [Weekday] = [.monday,.tuesday,.wednesday,.thursday,.friday,.saturday,.sunday]
    let mealTypes: [MealType] = [.breakfast,.lunch,.dinner]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let plan = planVM.currentPlan {
                    // Show generated plan with modern card design
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(weekdays, id: \.self) { day in
                                if let dayMeals = mealsForDay(day, in: plan) {
                                    DayCardView(
                                        day: dayLabel(for: day),
                                        meals: dayMeals
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Bottom action button
                    VStack(spacing: 12) {
                        Divider()
                        
                        Button(action: {
                            withAnimation {
                                planVM.currentPlan = nil
                                planVM.slots.removeAll()
                            }
                        }) {
                            Label("Nouveau plan", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                } else {
                    // Modern slot selection UI
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header
                            VStack(spacing: 4) {
                                Text("Planifiez votre semaine")
                                    .font(.title3)
                                    .bold()
                                
                                Text("Sélectionnez les repas à planifier")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)
                            
                            // Days list
                            VStack(spacing: 8) {
                                ForEach(weekdays, id: \.self) { day in
                                    DaySelectionRow(
                                        day: day,
                                        dayLabel: dayLabel(for: day),
                                        mealTypes: mealTypes,
                                        planVM: planVM,
                                        mealLabel: label
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 100) // Space for bottom button
                    }
                    
                    // Bottom action area
                    VStack(spacing: 0) {
                        Divider()
                        
                        VStack(spacing: 12) {
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: {
                                Task { await generatePlan() }
                            }) {
                                HStack {
                                    if isGenerating {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "sparkles")
                                    }
                                    Text(isGenerating ? "Génération..." : "Générer le plan")
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(planVM.slots.isEmpty || isGenerating)
                            
                            if !planVM.slots.isEmpty {
                                Text("\(planVM.slots.count) repas sélectionnés")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                }
            }
            .navigationTitle("Plan de la semaine")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func mealsForDay(_ day: Weekday, in plan: MealPlan) -> [(MealItem, String)]? {
        let meals = plan.items.filter { $0.weekday == day }
        guard !meals.isEmpty else { return nil }
        
        return meals.map { item in
            (item, label(for: item.mealType))
        }
    }
    
    func generatePlan() async {
        isGenerating = true
        errorMessage = nil
        
        do {
            let service = IAService(baseURL: URL(string: "http://localhost:5555")!)
            let units = UnitSystem(rawValue: unitSystem) ?? .metric
            let constraints = familyVM.aggregatedConstraints()
            let constraintsDict: [String: Any] = [
                "diet": constraints.diet,
                "evict": constraints.evict
            ]
            
            let plan = try await service.generatePlan(
                weekStart: Date(),
                slots: Array(planVM.slots),
                constraints: constraintsDict,
                units: units
            )
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                planVM.currentPlan = plan
            }
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
    
    func dayLabel(for wd: Weekday) -> String {
        switch wd {
        case .monday: return String(localized: "week.monday")
        case .tuesday: return String(localized: "week.tuesday")
        case .wednesday: return String(localized: "week.wednesday")
        case .thursday: return String(localized: "week.thursday")
        case .friday: return String(localized: "week.friday")
        case .saturday: return String(localized: "week.saturday")
        case .sunday: return String(localized: "week.sunday")
        }
    }
    
    func label(for mt: MealType) -> String {
        switch mt {
        case .breakfast: return String(localized: "meal.breakfast")
        case .lunch: return String(localized: "meal.lunch")
        case .dinner: return String(localized: "meal.dinner")
        }
    }
}

// MARK: - Day Selection Row
struct DaySelectionRow: View {
    let day: Weekday
    let dayLabel: String
    let mealTypes: [MealType]
    @ObservedObject var planVM: PlanViewModel
    let mealLabel: (MealType) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dayLabel)
                .font(.subheadline)
                .bold()
                .foregroundStyle(.primary)
            
            HStack(spacing: 6) {
                ForEach(mealTypes, id: \.self) { mealType in
                    MealPillButton(
                        mealType: mealType,
                        label: mealLabel(mealType),
                        isSelected: planVM.slots.contains(SlotSelection(weekday: day, mealType: mealType)),
                        action: {
                            let slot = SlotSelection(weekday: day, mealType: mealType)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if planVM.slots.contains(slot) {
                                    planVM.deselect(slot)
                                } else {
                                    planVM.select(slot)
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Meal Pill Button
struct MealPillButton: View {
    let mealType: MealType
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .bold()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? 
                              AnyShapeStyle(Color.accentColor.gradient) : 
                              AnyShapeStyle(Color(.systemGray6)))
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Day Card View
struct DayCardView: View {
    let day: String
    let meals: [(MealItem, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(day)
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .font(.caption)
                    Text("\(meals.count)")
                        .font(.caption)
                        .bold()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            
            Divider()
            
            // Meals list
            VStack(spacing: 12) {
                ForEach(meals, id: \.0.id) { meal, mealLabel in
                    NavigationLink(destination: RecipeDetailView(recipe: meal.recipe)) {
                        MealRowView(
                            mealType: meal.mealType,
                            mealLabel: mealLabel,
                            recipeName: meal.recipe.title
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Meal Row View
struct MealRowView: View {
    let mealType: MealType
    let mealLabel: String
    let recipeName: String
    
    var iconName: String {
        switch mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        }
    }
    
    var iconColor: Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .cornerRadius(8)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(mealLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(recipeName)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
