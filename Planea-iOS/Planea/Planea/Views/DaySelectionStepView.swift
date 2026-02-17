import SwiftUI

struct DaySelectionStepView: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    
    // Group slots by weekday
    private var weekdayGroups: [(Weekday, [Int])] {
        var groups: [(Weekday, [Int])] = []
        var currentWeekday: Weekday? = nil
        var currentIndices: [Int] = []
        
        for (index, slot) in viewModel.config.mealSlots.enumerated() {
            if slot.weekday != currentWeekday {
                if let weekday = currentWeekday {
                    groups.append((weekday, currentIndices))
                }
                currentWeekday = slot.weekday
                currentIndices = [index]
            } else {
                currentIndices.append(index)
            }
        }
        
        // Add last group
        if let weekday = currentWeekday {
            groups.append((weekday, currentIndices))
        }
        
        return groups
    }
    
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
                    
                    Text(NSLocalizedString("wizard.step1.subtitle.new", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Quick actions
                QuickActionsView(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Days list with granular slots
                VStack(spacing: 12) {
                    ForEach(weekdayGroups, id: \.0) { weekday, indices in
                        DaySlotCard(
                            weekday: weekday,
                            slotIndices: indices,
                            viewModel: viewModel
                        )
                    }
                }
                .padding(.horizontal)
                
                // Summary card
                if viewModel.selectedSlotsCount > 0 {
                    NewSummaryCard(viewModel: viewModel)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Quick Actions View

private struct QuickActionsView: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("wizard.quick_actions.title", comment: ""))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: NSLocalizedString("wizard.quick_action.select_all", comment: ""),
                    icon: "checkmark.circle.fill"
                ) {
                    viewModel.selectAllSlots()
                }
                
                QuickActionButton(
                    title: NSLocalizedString("wizard.quick_action.deselect_all", comment: ""),
                    icon: "circle"
                ) {
                    viewModel.deselectAllSlots()
                }
                
                QuickActionButton(
                    title: NSLocalizedString("wizard.quick_action.all_mealprep", comment: ""),
                    icon: "takeoutbag.and.cup.and.straw"
                ) {
                    viewModel.setAllSlotsToMealPrep()
                }
                
                QuickActionButton(
                    title: NSLocalizedString("wizard.quick_action.all_simple", comment: ""),
                    icon: "fork.knife"
                ) {
                    viewModel.setAllSlotsToSimple()
                }
            }
        }
    }
}

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}

// MARK: - Day Slot Card

private struct DaySlotCard: View {
    let weekday: Weekday
    let slotIndices: [Int]
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    
    private var daySlots: [MealSlotConfig] {
        slotIndices.map { viewModel.config.mealSlots[$0] }
    }
    
    private var hasSelectedSlot: Bool {
        daySlots.contains { $0.selected }
    }
    
    private var hasMealPrepSlot: Bool {
        daySlots.contains { $0.selected && $0.slotType == .mealPrep }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Day header
            HStack {
                Text(weekday.displayName)
                    .font(.headline)
                    .foregroundStyle(hasSelectedSlot ? .primary : .secondary)
                
                Spacer()
                
                if hasMealPrepSlot {
                    HStack(spacing: 4) {
                        Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                            .font(.caption)
                        Text(NSLocalizedString("wizard.badge.mealprep", comment: ""))
                            .font(.caption2)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 12)
            
            // Meal slots
            VStack(spacing: 8) {
                ForEach(slotIndices, id: \.self) { index in
                    MealSlotRow(
                        slot: viewModel.config.mealSlots[index],
                        onToggle: {
                            viewModel.toggleSlot(at: index)
                        },
                        onTypeChange: { newType in
                            viewModel.setSlotType(at: index, to: newType)
                        }
                    )
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(hasSelectedSlot ? Color(UIColor.secondarySystemBackground) : Color(UIColor.tertiarySystemBackground))
        )
    }
}

// MARK: - Meal Slot Row

private struct MealSlotRow: View {
    let slot: MealSlotConfig
    let onToggle: () -> Void
    let onTypeChange: (SlotType) -> Void
    
    private var mealIcon: String {
        switch slot.mealType {
        case .lunch:
            return "sun.max.fill"
        case .dinner:
            return "moon.stars.fill"
        default:
            return "fork.knife"
        }
    }
    
    private var mealIconColor: Color {
        switch slot.mealType {
        case .lunch:
            return .orange
        case .dinner:
            return .indigo
        default:
            return .accentColor
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: slot.selected ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(slot.selected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            
            // Meal type icon
            Image(systemName: mealIcon)
                .font(.system(size: 18))
                .foregroundStyle(slot.selected ? mealIconColor : .secondary)
                .frame(width: 24)
            
            // Meal name
            Text(slot.mealType.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(slot.selected ? .primary : .secondary)
            
            Spacer()
            
            // Type selector (only if selected)
            if slot.selected {
                SlotTypePicker(
                    selectedType: slot.slotType,
                    onChange: onTypeChange
                )
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: slot.selected)
    }
}

// MARK: - Slot Type Picker

private struct SlotTypePicker: View {
    let selectedType: SlotType
    let onChange: (SlotType) -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            SlotTypeButton(
                type: .simple,
                isSelected: selectedType == .simple,
                action: { onChange(.simple) }
            )
            
            SlotTypeButton(
                type: .mealPrep,
                isSelected: selectedType == .mealPrep,
                action: { onChange(.mealPrep) }
            )
        }
    }
}

private struct SlotTypeButton: View {
    let type: SlotType
    let isSelected: Bool
    let action: () -> Void
    
    private var buttonColor: Color {
        switch type {
        case .simple:
            return .accentColor
        case .mealPrep:
            return .orange
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.system(size: 12))
                Text(type.displayName)
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? buttonColor.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? buttonColor : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundStyle(isSelected ? buttonColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - New Summary Card

private struct NewSummaryCard: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("wizard.step1.summary.title", comment: ""))
                .font(.headline)
            
            // Simple recipes
            if viewModel.simpleSlotsCount > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("wizard.step1.summary.simple", comment: ""))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(viewModel.simpleSlotsCount) \(viewModel.simpleSlotsCount > 1 ? NSLocalizedString("wizard.meals", comment: "") : NSLocalizedString("wizard.meal", comment: ""))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Meal prep
            if viewModel.mealPrepSlotsCount > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("wizard.step1.summary.mealprep", comment: ""))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("\(viewModel.mealPrepSlotsCount) \(viewModel.mealPrepSlotsCount > 1 ? NSLocalizedString("wizard.meals", comment: "") : NSLocalizedString("wizard.meal", comment: ""))")
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
                
                Text("\(viewModel.selectedSlotsCount) \(viewModel.selectedSlotsCount > 1 ? NSLocalizedString("wizard.meals", comment: "") : NSLocalizedString("wizard.meal", comment: ""))")
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
