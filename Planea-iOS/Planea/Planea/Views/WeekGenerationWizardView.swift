import SwiftUI

struct WeekGenerationWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var familyVM: FamilyViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    @StateObject private var viewModel: WeekGenerationConfigViewModel
    
    init(planViewModel: PlanViewModel) {
        _viewModel = StateObject(wrappedValue: WeekGenerationConfigViewModel(planViewModel: planViewModel))
    }
    
    var body: some View {
        NavigationStack {
            // Show wizard steps (success view removed - auto-dismiss on success)
            VStack(spacing: 0) {
                // Progress indicator
                ProgressBar(
                    currentStep: viewModel.currentStep,
                    totalSteps: viewModel.totalSteps
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Content
                TabView(selection: $viewModel.currentStep) {
                    // Step 1: Day Selection
                    DaySelectionStepView(viewModel: viewModel)
                        .tag(0)
                    
                    // Step 2: Meal Prep Config (only if meal prep selected)
                    if viewModel.config.hasMealPrep {
                        MealPrepConfigStepView(viewModel: viewModel)
                            .tag(1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons
                NavigationButtons(viewModel: viewModel, dismiss: dismiss)
            }
            .navigationTitle(NSLocalizedString("wizard.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("action.cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
            .overlay {
                if viewModel.isGenerating {
                    GeneratingLoadingView(totalItems: viewModel.selectedDaysCount)
                }
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
            .onChange(of: viewModel.generationSuccess) { oldValue, newValue in
                // Auto-dismiss wizard when generation succeeds
                if newValue {
                    // Use a small delay to ensure the save completes
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                        await MainActor.run {
                            viewModel.resetSuccessState()
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Progress Bar

private struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    // Progress
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(
                            width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps),
                            height: 6
                        )
                        .cornerRadius(3)
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .frame(height: 6)
        }
    }
}

//

private struct NavigationButtons: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    let dismiss: DismissAction
    
    var body: some View {
        HStack(spacing: 16) {
            // Back button
            if viewModel.canGoBack() {
                Button {
                    withAnimation {
                        viewModel.previousStep()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(NSLocalizedString("wizard.button.back", comment: ""))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            // Next/Generate button
            if viewModel.currentStep < viewModel.totalSteps - 1 {
                Button {
                    withAnimation {
                        viewModel.nextStep()
                    }
                } label: {
                    HStack {
                        Text(NSLocalizedString("wizard.button.continue", comment: ""))
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canProceed)
            } else {
                Button {
                    Task {
                        await viewModel.generate(
                            familyVM: familyVM,
                            unitSystem: unitSystem,
                            appLanguage: appLanguage
                        )
                        // Dismiss after successful generation
                        print("🔍 After generation - generationSuccess: \(viewModel.generationSuccess)")
                        if viewModel.generationSuccess {
                            print("🚪 Calling dismiss() from button")
                            dismiss()
                        } else {
                            print("⚠️ generationSuccess is false, not dismissing")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(NSLocalizedString("wizard.button.generate", comment: ""))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canProceed || viewModel.isGenerating)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Step 1: Day Selection

struct DaySelectionStepView: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel

    private var weekdays: [Weekday] {
        PreferencesService.shared.loadPreferences().sortedWeekdays()
    }

    private let availableMealTypes: [MealType] = [.lunch, .dinner]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(NSLocalizedString("wizard.step1.subtitle", comment: ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 4)

                ForEach(weekdays, id: \.self) { weekday in
                    WizardDayRow(
                        weekday: weekday,
                        mealTypes: availableMealTypes,
                        selectedSlots: $viewModel.config.selectedSlots,
                        mealPrepGroupId: viewModel.config.mealPrepGroupId
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Wizard Day Row

private struct WizardDayRow: View {
    let weekday: Weekday
    let mealTypes: [MealType]
    @Binding var selectedSlots: [SlotSelection]
    let mealPrepGroupId: UUID

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.planeaTertiary)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                Text(weekday.displayName)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.planeaTextPrimary)

                ForEach(mealTypes, id: \.self) { mealType in
                    WizardMealTypeRow(
                        weekday: weekday,
                        mealType: mealType,
                        selectedSlots: $selectedSlots,
                        mealPrepGroupId: mealPrepGroupId
                    )
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: PlaneaRadius.card)
                .fill(Color.planeaCard)
                .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
        )
    }
}

private struct WizardMealTypeRow: View {
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
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .planeaPrimary : .gray)
                HStack(spacing: 4) {
                    Text(mealIcon).font(.caption)
                    Text(mealType.localizedName).font(.subheadline)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { toggleSelection() }

            Spacer()

            if isSelected {
                Toggle(isOn: Binding(
                    get: { isMealPrep },
                    set: { newValue in setMealPrep(newValue) }
                )) {
                    HStack(spacing: 4) {
                        Image(systemName: isMealPrep ? "takeoutbag.and.cup.and.straw.fill" : "takeoutbag.and.cup.and.straw")
                            .foregroundColor(isMealPrep ? .orange : .gray)
                        Text("plan.mealPrep".localized).font(.caption)
                            .foregroundColor(isMealPrep ? .orange : .secondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
        }
        .padding(8)
        .background(isSelected ? Color.planeaSecondary.opacity(0.05) : Color.clear)
        .cornerRadius(8)
    }

    private func toggleSelection() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let index = selectedSlots.firstIndex(where: { $0.weekday == weekday && $0.mealType == mealType }) {
                selectedSlots.remove(at: index)
            } else {
                selectedSlots.append(SlotSelection(weekday: weekday, mealType: mealType, isMealPrep: false, mealPrepGroupId: nil))
            }
        }
    }

    private func setMealPrep(_ isMealPrep: Bool) {
        if let index = selectedSlots.firstIndex(where: { $0.weekday == weekday && $0.mealType == mealType }) {
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

// MARK: - Step 2: Meal Prep Config

struct MealPrepConfigStepView: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel

    private var mealPrepSlots: [SlotSelection] {
        viewModel.config.selectedSlots.filter { $0.isMealPrep }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Info banner
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("wizard.mealprep.title", comment: ""))
                            .font(.subheadline).bold()
                        Text(NSLocalizedString("wizard.mealprep.description", comment: ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: PlaneaRadius.card))
                .padding(.horizontal)

                // Selected meal prep slots
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("wizard.mealprep.slots", comment: ""))
                        .font(.subheadline).bold()
                        .padding(.horizontal)

                    ForEach(mealPrepSlots, id: \.id) { slot in
                        HStack(spacing: 12) {
                            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                                .foregroundColor(.orange)
                            Text("\(slot.weekday.displayName) – \(slot.mealType.localizedName)")
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: PlaneaRadius.sm))
                        .padding(.horizontal)
                    }
                }

                Text(NSLocalizedString("wizard.mealprep.hint", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Preview

#Preview {
    WeekGenerationWizardView(planViewModel: PlanViewModel())
}
