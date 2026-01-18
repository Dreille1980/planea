import SwiftUI

struct AddFavoriteToWeekSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var planVM: PlanViewModel
    
    let recipe: Recipe
    
    @State private var selectedDay: Weekday?
    @State private var selectedMealType: MealType?
    @State private var showConflictAlert: Bool = false
    @State private var conflictAction: ConflictAction = .replace
    
    enum ConflictAction {
        case replace, add
    }
    
    var weekdays: [Weekday] {
        // Use all weekdays in order
        return [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
    let mealTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 16) {
                    // Recipe preview
                    HStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 40))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            HStack(spacing: 12) {
                                Label("\(recipe.servings)", systemImage: "person.2")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Label("\(recipe.totalMinutes) min", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Instructions
                    Text("favorites.select_slot_instruction".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Day and meal selection
                    LazyVStack(spacing: 12) {
                        ForEach(weekdays, id: \.self) { day in
                            DaySlotSelectionRow(
                                day: day,
                                dayLabel: dayLabel(for: day),
                                mealTypes: mealTypes,
                                selectedDay: $selectedDay,
                                selectedMealType: $selectedMealType,
                                planVM: planVM,
                                mealLabel: mealLabel,
                                iconName: iconName,
                                iconColor: iconColor
                            )
                        }
                    }
                }
                .padding()
                }
            }
            .navigationTitle("favorites.add_to_plan".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.add".localized) {
                        addRecipeToSelectedSlot()
                    }
                    .disabled(selectedDay == nil || selectedMealType == nil)
                    .bold()
                }
            }
            .alert("favorites.conflict_title".localized, isPresented: $showConflictAlert) {
                Button("favorites.replace".localized, role: .destructive) {
                    conflictAction = .replace
                    performAddToSlot()
                }
                Button("favorites.add_anyway".localized) {
                    conflictAction = .add
                    performAddToSlot()
                }
                Button("action.cancel".localized, role: .cancel) {}
            } message: {
                Text("favorites.conflict_message".localized)
            }
        }
    }
    
    private func addRecipeToSelectedSlot() {
        guard let day = selectedDay, let mealType = selectedMealType else { return }
        
        // Check for conflict
        if planVM.hasMealInSlot(weekday: day, mealType: mealType) {
            showConflictAlert = true
        } else {
            performAddToSlot()
        }
    }
    
    private func performAddToSlot() {
        guard let day = selectedDay, let mealType = selectedMealType else { return }
        
        withAnimation {
            planVM.addFavoriteRecipeToSlot(
                recipe: recipe,
                weekday: day,
                mealType: mealType,
                replaceIfExists: conflictAction == .replace
            )
        }
        
        dismiss()
    }
    
    private func dayLabel(for day: Weekday) -> String {
        switch day {
        case .monday: return "week.monday".localized
        case .tuesday: return "week.tuesday".localized
        case .wednesday: return "week.wednesday".localized
        case .thursday: return "week.thursday".localized
        case .friday: return "week.friday".localized
        case .saturday: return "week.saturday".localized
        case .sunday: return "week.sunday".localized
        }
    }
    
    private func mealLabel(for type: MealType) -> String {
        switch type {
        case .breakfast: return "meal.breakfast".localized
        case .lunch: return "meal.lunch".localized
        case .dinner: return "meal.dinner".localized
        case .snack: return "meal.snack".localized
        }
    }
    
    private func iconName(for type: MealType) -> String {
        switch type {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
    
    private func iconColor(for type: MealType) -> Color {
        switch type {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        case .snack: return .green
        }
    }
}

// MARK: - Day Slot Selection Row
struct DaySlotSelectionRow: View {
    let day: Weekday
    let dayLabel: String
    let mealTypes: [MealType]
    @Binding var selectedDay: Weekday?
    @Binding var selectedMealType: MealType?
    @ObservedObject var planVM: PlanViewModel
    let mealLabel: (MealType) -> String
    let iconName: (MealType) -> String
    let iconColor: (MealType) -> Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dayLabel)
                .font(.subheadline)
                .bold()
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                ForEach(mealTypes, id: \.self) { mealType in
                    SlotButton(
                        day: day,
                        mealType: mealType,
                        label: mealLabel(mealType),
                        icon: iconName(mealType),
                        color: iconColor(mealType),
                        isSelected: selectedDay == day && selectedMealType == mealType,
                        isOccupied: planVM.hasMealInSlot(weekday: day, mealType: mealType),
                        action: {
                            selectedDay = day
                            selectedMealType = mealType
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Slot Button
struct SlotButton: View {
    let day: Weekday
    let mealType: MealType
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let isOccupied: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .cornerRadius(8)
                
                // Label
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Status indicator
                if isOccupied {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("favorites.slot_occupied".localized)
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .green : .secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
