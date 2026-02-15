import SwiftUI

struct DaySelectionStepView: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.stepNumber(for: 0))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(NSLocalizedString("wizard.step1.title", comment: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("wizard.step1.subtitle", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Days list
                VStack(spacing: 12) {
                    ForEach(viewModel.config.days.indices, id: \.self) { index in
                        DayConfigRow(
                            day: viewModel.config.days[index],
                            onToggle: {
                                viewModel.config.days[index].selected.toggle()
                                if viewModel.config.hasMealPrep {
                                    viewModel.config.recalculateMealPrepPortions()
                                }
                            },
                            onTypeChange: { newType in
                                viewModel.config.days[index].mealType = newType
                                viewModel.config.recalculateMealPrepPortions()
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Summary card
                if viewModel.selectedDaysCount > 0 {
                    SummaryCard(viewModel: viewModel)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Day Config Row

private struct DayConfigRow: View {
    let day: DayConfig
    let onToggle: () -> Void
    let onTypeChange: (DayMealType) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                onToggle()
            } label: {
                Image(systemName: day.selected ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(day.selected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            
            // Day name
            Text(day.weekday.displayName)
                .font(.headline)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            // Type picker (only if selected)
            if day.selected {
                Picker("", selection: Binding(
                    get: { day.mealType },
                    set: { onTypeChange($0) }
                )) {
                    Label {
                        Text(NSLocalizedString("wizard.day_type.normal", comment: ""))
                    } icon: {
                        Image(systemName: "fork.knife")
                    }
                    .tag(DayMealType.normal)
                    
                    Label {
                        Text(NSLocalizedString("wizard.day_type.mealprep", comment: ""))
                    } icon: {
                        Image(systemName: "takeoutbag.and.cup.and.straw")
                    }
                    .tag(DayMealType.mealPrep)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            } else {
                Text(NSLocalizedString("wizard.day_type.skip", comment: ""))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(day.selected ? Color(UIColor.secondarySystemBackground) : Color(UIColor.tertiarySystemBackground))
        )
        .animation(.easeInOut(duration: 0.2), value: day.selected)
        .animation(.easeInOut(duration: 0.2), value: day.mealType)
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("wizard.step1.summary.title", comment: ""))
                .font(.headline)
            
            // Normal days
            if viewModel.normalDaysCount > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("wizard.step1.summary.normal_days", comment: ""))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(viewModel.normalDaysCount) \(viewModel.normalDaysCount > 1 ? NSLocalizedString("wizard.days", comment: "") : NSLocalizedString("wizard.day", comment: ""))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Meal prep days
            if viewModel.mealPrepDaysCount > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("wizard.step1.summary.mealprep_days", comment: ""))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(viewModel.mealPrepDaysCount) \(viewModel.mealPrepDaysCount > 1 ? NSLocalizedString("wizard.days", comment: "") : NSLocalizedString("wizard.day", comment: ""))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Divider()
            
            // Total
            HStack {
                Text(NSLocalizedString("wizard.step1.summary.total", comment: ""))
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.selectedDaysCount) \(viewModel.selectedDaysCount > 1 ? NSLocalizedString("wizard.days", comment: "") : NSLocalizedString("wizard.day", comment: ""))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    DaySelectionStepView(viewModel: WeekGenerationConfigViewModel(planViewModel: PlanViewModel()))
}
