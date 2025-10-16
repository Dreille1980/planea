import SwiftUI

struct PlanWeekView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var regeneratingMealId: UUID?
    @State private var showAddMealSheet = false
    @State private var showPaywall = false
    
    let weekdays: [Weekday] = [.monday,.tuesday,.wednesday,.thursday,.friday,.saturday,.sunday]
    let mealTypes: [MealType] = [.breakfast,.lunch,.dinner]
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if let plan = planVM.currentPlan {
                        // Show generated plan with modern card design
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(weekdays, id: \.self) { day in
                                    if let dayMeals = mealsForDay(day, in: plan) {
                                        DayCardView(
                                            day: dayLabel(for: day),
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
                                Label("action.newPlan".localized, systemImage: "arrow.counterclockwise")
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
                                    Text("plan.planYourWeek".localized)
                                        .font(.title3)
                                        .bold()
                                    
                                    Text("plan.selectMeals".localized)
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
                                        Text(isGenerating ? "plan.generating".localized : "action.generatePlan".localized)
                                            .bold()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(planVM.slots.isEmpty || isGenerating)
                                
                                if !planVM.slots.isEmpty {
                                    Text("\(planVM.slots.count) \("plan.mealsSelected".localized)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                        }
                    }
                }
                
                // Loading overlay
                if isGenerating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    GeneratingLoadingView(totalItems: planVM.slots.count)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Floating add button - only visible when plan exists
                if planVM.currentPlan != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showAddMealSheet = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        Circle()
                                            .fill(Color.accentColor.gradient)
                                            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                                    )
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 90)
                        }
                    }
                }
            }
            .navigationTitle("plan.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddMealSheet) {
                AddMealSheet()
                    .environmentObject(familyVM)
                    .environmentObject(planVM)
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallView(limitReached: true)
            }
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
        // Check if user can generate this many recipes
        let slotCount = planVM.slots.count
        guard usageVM.canGenerate(count: slotCount) else {
            showPaywall = true
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        do {
            let service = IAService(baseURL: URL(string: Config.baseURL)!)
            let units = UnitSystem(rawValue: unitSystem) ?? .metric
            let constraints = familyVM.aggregatedConstraints()
            let constraintsDict: [String: Any] = [
                "diet": constraints.diet,
                "evict": constraints.evict
            ]
            
            let language = AppLanguage.currentLocale(appLanguage).prefix(2).lowercased()
            
            let plan = try await service.generatePlan(
                weekStart: Date(),
                slots: Array(planVM.slots),
                constraints: constraintsDict,
                units: units,
                language: String(language)
            )
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                planVM.currentPlan = plan
            }
            
            // Record generation usage
            usageVM.recordGenerations(count: plan.items.count)
        } catch {
            errorMessage = "\("plan.error".localized): \(error.localizedDescription)"
        }
        
        isGenerating = false
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
    
    func regenerateMeal(_ mealItem: MealItem) async {
        // Check if user can regenerate
        guard usageVM.canGenerate(count: 1) else {
            showPaywall = true
            return
        }
        
        regeneratingMealId = mealItem.id
        
        do {
            let service = IAService(baseURL: URL(string: Config.baseURL)!)
            let units = UnitSystem(rawValue: unitSystem) ?? .metric
            let constraints = familyVM.aggregatedConstraints()
            let constraintsDict: [String: Any] = [
                "diet": constraints.diet,
                "evict": constraints.evict
            ]
            
            let language = AppLanguage.currentLocale(appLanguage).prefix(2).lowercased()
            
            let newRecipe = try await service.regenerateMeal(
                weekday: mealItem.weekday,
                mealType: mealItem.mealType,
                constraints: constraintsDict,
                servings: 4,
                units: units,
                language: String(language),
                diversitySeed: Int.random(in: 0...1000)
            )
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                planVM.regenerateMeal(mealItem: mealItem, newRecipe: newRecipe)
            }
            
            // Record generation usage
            usageVM.recordGenerations(count: 1)
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
        
        regeneratingMealId = nil
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
    let regeneratingMealId: UUID?
    let onRegenerateMeal: (MealItem) -> Void
    let onRemoveMeal: (MealItem) -> Void
    
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
                ForEach(meals, id: \.0.id) { mealTuple in
                    MealRowView(
                        mealItem: mealTuple.0,
                        mealType: mealTuple.0.mealType,
                        mealLabel: mealTuple.1,
                        recipeName: mealTuple.0.recipe.title,
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Meal Row View
struct MealRowView: View {
    let mealItem: MealItem
    let mealType: MealType
    let mealLabel: String
    let recipeName: String
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
        VStack(spacing: 0) {
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
                
                // Remove button
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.red.opacity(0.8))
                }
                
                // Regenerate button
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
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(8)
                }
                .disabled(isRegenerating)
                
                // Navigate icon
                NavigationLink(destination: RecipeDetailView(recipe: mealItem.recipe)) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(width: 20)
                }
            }
            .padding(12)
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
