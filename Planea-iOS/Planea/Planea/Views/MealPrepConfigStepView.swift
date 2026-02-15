import SwiftUI

struct MealPrepConfigStepView: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    @State private var showEditPortions = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.stepNumber(for: 1))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(NSLocalizedString("wizard.step2.title", comment: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("wizard.step2.subtitle", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Portions Section
                PortionsSection(
                    viewModel: viewModel,
                    showEditPortions: $showEditPortions
                )
                .padding(.horizontal)
                
                // Meal Type Section
                MealTypeSection(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Info Card
                InfoCard()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showEditPortions) {
            EditPortionsSheet(
                portions: Binding(
                    get: { viewModel.config.mealPrepPortions },
                    set: { viewModel.updateMealPrepPortions($0) }
                )
            )
        }
    }
}

// MARK: - Portions Section

private struct PortionsSection: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    @Binding var showEditPortions: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("wizard.step2.portions.title", comment: ""))
                .font(.headline)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("\(viewModel.config.familySize) \(NSLocalizedString("wizard.step2.portions.people", comment: ""))")
                    } icon: {
                        Image(systemName: "person.2.fill")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(viewModel.config.mealPrepPortions)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.accentColor)
                        
                        Text(NSLocalizedString("wizard.step2.portions.label", comment: ""))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(portionsCalculation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    showEditPortions = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title)
                        Text(NSLocalizedString("wizard.step2.portions.edit", comment: ""))
                            .font(.caption)
                    }
                }
                .foregroundColor(.accentColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
    
    private var portionsCalculation: String {
        let days = viewModel.mealPrepDaysCount
        let meals = viewModel.config.mealPrepMealTypes.count
        let people = viewModel.config.familySize
        
        return "\(days) \(NSLocalizedString("wizard.days", comment: "")) × \(meals) \(NSLocalizedString("wizard.step2.portions.meals", comment: "")) × \(people) \(NSLocalizedString("wizard.step2.portions.people", comment: ""))"
    }
}

// MARK: - Meal Type Section

private struct MealTypeSection: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("wizard.step2.mealtype.title", comment: ""))
                .font(.headline)
            
            Text(NSLocalizedString("wizard.step2.mealtype.subtitle", comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("", selection: Binding(
                get: { viewModel.config.mealPrepMealTypeSelection },
                set: { viewModel.updateMealPrepMealTypeSelection($0) }
            )) {
                ForEach(MealPrepMealTypeSelection.allCases, id: \.self) { selection in
                    Text(selection.displayName).tag(selection)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Info Card

private struct InfoCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("wizard.step2.info.title", comment: ""))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(NSLocalizedString("wizard.step2.info.message", comment: ""))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

// MARK: - Edit Portions Sheet

private struct EditPortionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var portions: Int
    @State private var tempPortions: Int
    
    init(portions: Binding<Int>) {
        self._portions = portions
        self._tempPortions = State(initialValue: portions.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Current value display
                VStack(spacing: 8) {
                    Text("\(tempPortions)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.accentColor)
                    
                    Text(NSLocalizedString("wizard.step2.portions.label", comment: ""))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // Stepper
                HStack(spacing: 40) {
                    Button {
                        if tempPortions > 1 {
                            tempPortions -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(tempPortions > 1 ? .accentColor : .gray)
                    }
                    .disabled(tempPortions <= 1)
                    
                    Button {
                        tempPortions += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle(NSLocalizedString("wizard.step2.edit.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("action.cancel", comment: "")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("action.save", comment: "")) {
                        portions = tempPortions
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    MealPrepConfigStepView(viewModel: WeekGenerationConfigViewModel(planViewModel: PlanViewModel()))
}
