import SwiftUI

struct GenerateMealPlanView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    @Binding var selectedSegment: RecipesSegment
    
    @State private var selectedSlots: [SlotSelection] = []
    @State private var mealPrepGroupId: UUID = UUID()
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showUsageLimitReached = false
    
    var weekdays: [Weekday] {
        PreferencesService.shared.loadPreferences().sortedWeekdays()
    }
    
    let availableMealTypes: [MealType] = [.lunch, .dinner]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Meal grid
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(weekdays, id: \.self) { weekday in
                            DayMealRow(
                                weekday: weekday,
                                mealTypes: availableMealTypes,
                                selectedSlots: $selectedSlots,
                                mealPrepGroupId: mealPrepGroupId
                            )
                        }
                    }
                    .padding()
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
                        
                        // Summary
                        if !selectedSlots.isEmpty {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(selectedSlots.count) \("plan.mealsSelected".localized)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    let mealPrepCount = selectedSlots.filter { $0.isMealPrep }.count
                                    if mealPrepCount > 0 {
                                        Text("\(mealPrepCount) meal prep")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                
                                Spacer()
                            }
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
                            .background(selectedSlots.isEmpty || isGenerating ? Color.planeaPrimary.opacity(0.4) : Color.planeaPrimary)
                            .foregroundStyle(selectedSlots.isEmpty || isGenerating ? Color.white.opacity(0.6) : Color.white)
                            .cornerRadius(12)
                        }
                        .disabled(selectedSlots.isEmpty || isGenerating)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
            
            // Loading overlay
            if isGenerating {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                GeneratingLoadingView(totalItems: selectedSlots.count)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showUsageLimitReached) {
            UsageLimitReachedView()
                .environmentObject(usageVM)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("plan.selectMeals".localized)
                .font(.subheadline)
                .foregroundColor(.planeaTextSecondary)
            
            Text("plan.selectMealsHint".localized)
                .font(.caption)
                .foregroundColor(.planeaTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.planeaBackground)
    }
    
    func generatePlan() async {
        // Check if user can generate this many recipes
        let slotCount = selectedSlots.count
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
                slots: selectedSlots,
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
            
            // Clear selections after successful generation
            selectedSlots.removeAll()
            
            // Switch to view week tab
            withAnimation {
                selectedSegment = .viewWeek
            }
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
}

// MARK: - Day Meal Row

struct DayMealRow: View {
    let weekday: Weekday
    let mealTypes: [MealType]
    @Binding var selectedSlots: [SlotSelection]
    let mealPrepGroupId: UUID
    
    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            Rectangle()
                .fill(Color.planeaTertiary)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 12) {
                // Day label
                Text(weekday.displayName)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.planeaTextPrimary)
                
                // Meal type buttons
                VStack(spacing: 8) {
                    ForEach(mealTypes, id: \.self) { mealType in
                        MealTypeSelector(
                            weekday: weekday,
                            mealType: mealType,
                            selectedSlots: $selectedSlots,
                            mealPrepGroupId: mealPrepGroupId
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

// MARK: - Meal Type Selector

struct MealTypeSelector: View {
    let weekday: Weekday
    let mealType: MealType
    @Binding var selectedSlots: [SlotSelection]
    let mealPrepGroupId: UUID
    
    private var isSelected: Bool {
        selectedSlots.contains { $0.weekday == weekday && $0.mealType == mealType }
    }
    
    private var isMealPrep: Bool {
        selectedSlots.first { $0.weekday == weekday && $0.mealType == mealType }?.isMealPrep ?? false
    }
    
    private var mealIcon: String {
        switch mealType {
        case .breakfast: return "☀️"
        case .lunch: return "🍽️"
        case .dinner: return "🌙"
        case .snack: return "🥤"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox + Label
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .planeaPrimary : .gray)
                
                HStack(spacing: 4) {
                    Text(mealIcon)
                        .font(.caption)
                    Text(mealType.localizedName)
                        .font(.subheadline)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                toggleSelection()
            }
            
            Spacer()
            
            // Meal Prep toggle (only if selected)
            if isSelected {
                Toggle(isOn: Binding(
                    get: { isMealPrep },
                    set: { newValue in
                        setMealType(isMealPrep: newValue)
                    }
                )) {
                    HStack(spacing: 4) {
                        Image(systemName: isMealPrep ? "takeoutbag.and.cup.and.straw.fill" : "takeoutbag.and.cup.and.straw")
                            .foregroundColor(isMealPrep ? .orange : .gray)
                        Text("plan.mealPrep".localized)
                            .font(.caption)
                            .foregroundColor(isMealPrep ? .orange : .planeaTextSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
        }
        .padding(10)
        .background(isSelected ? Color.planeaSecondary.opacity(0.05) : Color.clear)
        .cornerRadius(8)
    }
    
    private func toggleSelection() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let index = selectedSlots.firstIndex(where: { $0.weekday == weekday && $0.mealType == mealType }) {
                selectedSlots.remove(at: index)
            } else {
                let newSlot = SlotSelection(
                    weekday: weekday,
                    mealType: mealType,
                    isMealPrep: false,
                    mealPrepGroupId: nil
                )
                selectedSlots.append(newSlot)
            }
        }
    }
    
    private func setMealType(isMealPrep: Bool) {
        if let index = selectedSlots.firstIndex(where: { $0.weekday == weekday && $0.mealType == mealType }) {
            // Force immediate UI update by using objectWillChange
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSlots[index] = SlotSelection(
                    weekday: selectedSlots[index].weekday,
                    mealType: selectedSlots[index].mealType,
                    isMealPrep: isMealPrep,
                    mealPrepGroupId: isMealPrep ? mealPrepGroupId : nil
                )
            }
        }
    }
}
