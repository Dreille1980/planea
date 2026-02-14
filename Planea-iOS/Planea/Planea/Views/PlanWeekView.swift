import SwiftUI

// MARK: - Date Formatting Extension
extension Date {
    /// Format date as "Lundi 10 mars" (respects locale)
    func dayWithDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: self)
    }
    
    /// Format short date range: "10 au 16 mars" or "10 to 16 March"
    static func weekRange(from startDate: Date) -> String {
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) else {
            return ""
        }
        
        let formatter = DateFormatter()
        let startDay = calendar.component(.day, from: startDate)
        let endDay = calendar.component(.day, from: endDate)
        
        // Format month
        formatter.dateFormat = "MMMM"
        let month = formatter.string(from: endDate)
        
        let separator = "week.range.separator".localized
        return "\(startDay) \(separator) \(endDay) \(month)"
    }
}

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
    @State private var showUsageLimitReached = false
    @State private var showNewPlanAlert = false
    @State private var showPlanHistory = false
    @State private var showNamePlanDialog = false
    @State private var planName = ""
    @State private var showTemplates = false
    @State private var showSaveAsTemplateDialog = false
    @State private var templateName = ""
    
    var weekdays: [Weekday] {
        PreferencesService.shared.loadPreferences().sortedWeekdays()
    }
    let mealTypes: [MealType] = [.breakfast,.lunch,.dinner]
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if let plan = planVM.currentPlan {
                        // Show generated plan with modern card design
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                // Week range header
                                WeekRangeHeader(weekStart: plan.weekStart)
                                    .padding(.horizontal)
                                
                                // Calculate dates for each day
                                ForEach(weekdays.indices, id: \.self) { index in
                                    let day = weekdays[index]
                                    if let dayMeals = mealsForDay(day, in: plan) {
                                        let dayDate = dateForWeekday(day, startingFrom: plan.weekStart)
                                        DayCardView(
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
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        
                        // Bottom action buttons
                        VStack(spacing: 12) {
                            Divider()
                            
                            // Show status badge
                            if plan.status == .draft {
                                HStack {
                                    Image(systemName: "pencil.circle.fill")
                                    Text("plan.draft".localized)
                                }
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(12)
                            } else if plan.status == .active {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("plan.active.badge".localized)
                                }
                                .font(.caption)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(12)
                            }
                            
                            HStack(spacing: 12) {
                                // Activate Plan button (only if draft)
                                if plan.status == .draft {
                                    Button(action: {
                                        // Pre-populate plan name with week range
                                        planName = String(format: "week.range".localized, Date.weekRange(from: plan.weekStart))
                                        showNamePlanDialog = true
                                    }) {
                                        Text("plan.activate.button".localized)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                
                                // New Plan button
                                Button(action: {
                                    if planVM.activePlan != nil {
                                        showNewPlanAlert = true
                                    } else {
                                        withAnimation {
                                            planVM.currentPlan = nil
                                            planVM.slots.removeAll()
                                        }
                                    }
                                }) {
                                    Text("action.newPlan".localized)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                                .buttonStyle(.bordered)
                                .tint(.accentColor)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    } else {
                        // Modern slot selection UI
                        ScrollView {
                            VStack(spacing: 12) {
                                // Header with styled title
                                VStack(spacing: 4) {
                                    // Styled title with "Planifiez" in orange
                                    Text(attributedPlanTitle())
                                        .font(.title3)
                                        .bold()
                                    
                                    Text("plan.selectMeals".localized)
                                        .font(.caption)
                                        .foregroundColor(.planeaTextSecondary)
                                }
                                .padding(.top, 4)
                                
                                // Days list
                                LazyVStack(spacing: 8) {
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
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)
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
                                                .foregroundStyle(.white)
                                        }
                                        Text(isGenerating ? "plan.generating".localized : "action.generatePlan".localized)
                                            .bold()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(planVM.slots.isEmpty || isGenerating ? Color.planeaPrimary.opacity(0.4) : Color.planeaPrimary)
                                    .foregroundStyle(planVM.slots.isEmpty || isGenerating ? Color.white.opacity(0.6) : Color.white)
                                    .cornerRadius(12)
                                }
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
                
            }
            .navigationTitle("plan.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showPlanHistory = true
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title3)
                        }
                        
                        Button(action: {
                            showTemplates = true
                        }) {
                            Image(systemName: "bookmark.fill")
                                .font(.title3)
                        }
                    }
                }
                
                if planVM.currentPlan != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button(action: {
                                showSaveAsTemplateDialog = true
                            }) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title3)
                            }
                            
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
            }
            .sheet(isPresented: $showAddMealSheet) {
                AddMealSheet()
                    .environmentObject(familyVM)
                    .environmentObject(planVM)
            }
            .sheet(isPresented: $showUsageLimitReached) {
                UsageLimitReachedView()
                    .environmentObject(usageVM)
            }
            .sheet(isPresented: $showPlanHistory) {
                PlanHistoryView()
                    .environmentObject(planVM)
            }
            .sheet(isPresented: $showTemplates) {
                TemplatesListView()
                    .environmentObject(planVM)
            }
            .alert("Sauvegarder comme template", isPresented: $showSaveAsTemplateDialog) {
                TextField("Nom du template", text: $templateName)
                Button("Annuler", role: .cancel) {
                    templateName = ""
                }
                Button("Sauvegarder") {
                    if !templateName.isEmpty {
                        planVM.saveCurrentPlanAsTemplate(name: templateName)
                        templateName = ""
                    }
                }
            } message: {
                Text("Donnez un nom à ce template pour le réutiliser plus tard")
            }
            .alert("plan.namePlan.title".localized, isPresented: $showNamePlanDialog) {
                TextField("plan.namePlan.placeholder".localized, text: $planName)
                Button("action.cancel".localized, role: .cancel) {
                    planName = ""
                }
                Button("plan.activate.button".localized) {
                    withAnimation {
                        planVM.activateCurrentPlan(withName: planName.isEmpty ? nil : planName)
                        planName = ""
                    }
                }
            } message: {
                Text("plan.namePlan.message".localized)
            }
            .alert("plan.archive.alert.title".localized, isPresented: $showNewPlanAlert) {
                Button("action.cancel".localized, role: .cancel) { }
                Button("plan.archive.alert.confirm".localized, role: .destructive) {
                    withAnimation {
                        planVM.archiveAndStartNew()
                    }
                }
            } message: {
                Text("plan.archive.alert.message".localized)
            }
        }
    }
    
    private func mealsForDay(_ day: Weekday, in plan: MealPlan) -> [(MealItem, String)]? {
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
            showUsageLimitReached = true
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
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
            
            // Calculate servings based on number of family members (minimum 1)
            let servings = max(1, familyVM.members.count)
            
            let plan = try await service.generatePlan(
                weekStart: Date(),
                slots: Array(planVM.slots),
                constraints: constraintsDict,
                servings: servings,
                units: units,
                language: String(language)
            )
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                planVM.savePlan(plan)
            }
            
            // Record generation usage
            usageVM.recordGenerations(count: plan.items.count)
        } catch {
            // Provide more helpful error messages
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    errorMessage = "Aucune connexion Internet. Vérifiez votre WiFi ou données cellulaires."
                case .timedOut:
                    errorMessage = "Le serveur ne répond pas. Réessayez dans quelques instants."
                case .cannotFindHost, .cannotConnectToHost:
                    errorMessage = "Impossible de contacter le serveur. Vérifiez votre connexion."
                default:
                    errorMessage = "Erreur réseau: \(urlError.localizedDescription)"
                }
            } else {
                errorMessage = "\("plan.error".localized): \(error.localizedDescription)"
            }
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
            
            // Calculate servings based on number of family members (minimum 1)
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
            
            // Record generation usage
            usageVM.recordGenerations(count: 1)
        } catch {
            errorMessage = "Erreur: \(error.localizedDescription)"
        }
        
        regeneratingMealId = nil
    }
    
    // MARK: - Date Helper
    private func dateForWeekday(_ weekday: Weekday, startingFrom weekStart: Date) -> Date {
        let calendar = Calendar.current
        let startWeekday = calendar.component(.weekday, from: weekStart)
        
        // Convert Weekday enum to calendar weekday (1=Sunday, 2=Monday, etc.)
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
        
        // Calculate days difference
        var daysDifference = targetWeekday - startWeekday
        if daysDifference < 0 {
            daysDifference += 7
        }
        
        return calendar.date(byAdding: .day, value: daysDifference, to: weekStart) ?? weekStart
    }
    
    // MARK: - Attributed Title Helper
    private func attributedPlanTitle() -> AttributedString {
        let fullText = "plan.planYourWeek".localized // "Planifiez votre semaine"
        var attributed = AttributedString(fullText)
        
        // Color "Planifiez" in orange (first word)
        if let range = attributed.range(of: "Planifiez") {
            attributed[range].foregroundColor = .planeaSecondary
        }
        
        return attributed
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
        HStack(spacing: 0) {
            // Barre verticale verte à gauche (4px, vert sauge foncé)
            Rectangle()
                .fill(Color.planeaTertiary)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(dayLabel)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.planeaTextPrimary)
                
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
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.planeaCard)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Meal Pill Button
struct MealPillButton: View {
    let mealType: MealType
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    // Icônes contextuelles pour chaque type de repas
    var mealIcon: String {
        switch mealType {
        case .breakfast: return "☀️"
        case .lunch: return "🍽️"
        case .dinner: return "🌙"
        case .snack: return "🥤"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Text(mealIcon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? 
                          Color.planeaSecondary.opacity(0.15) : 
                          Color.planeaChipDefault)
            )
            .foregroundColor(.planeaTextPrimary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Week Range Header
struct WeekRangeHeader: View {
    let weekStart: Date
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.subheadline)
                .foregroundColor(.planeaSecondary)
            
            Text(String(format: "week.range".localized, Date.weekRange(from: weekStart)))
                .font(.subheadline)
                .bold()
                .foregroundColor(.planeaTextPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.planeaSecondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.planeaSecondary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Day Card View
struct DayCardView: View {
    let day: String
    let date: Date
    let meals: [(MealItem, String)]
    let regeneratingMealId: UUID?
    let onRegenerateMeal: (MealItem) -> Void
    let onRemoveMeal: (MealItem) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Barre verticale verte à gauche (4px, vert sauge foncé)
            Rectangle()
                .fill(Color.planeaTertiary)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 12) {
                // Header with date
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
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.planeaCard)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
        )
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
        NavigationLink(destination: RecipeDetailView(recipe: mealItem.recipe)) {
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
                
                // Navigate icon
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
                    .background(Color.planeaPrimary.opacity(0.1))
                    .foregroundColor(.planeaPrimary)
                    .cornerRadius(8)
                }
                .disabled(isRegenerating)
                
                // Remove button
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
