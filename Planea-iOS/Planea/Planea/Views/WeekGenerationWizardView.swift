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
            .onChange(of: viewModel.generationSuccess) { success in
                // Auto-dismiss wizard when generation succeeds
                if success {
                    viewModel.resetSuccessState()
                    dismiss()
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

// MARK: - Navigation Buttons

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
                        // Don't dismiss here anymore - success view will handle it
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

// MARK: - Preview

#Preview {
    WeekGenerationWizardView(planViewModel: PlanViewModel())
}
