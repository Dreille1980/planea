import SwiftUI

struct AssignMealPrepSheet: View {
    let mealPrepKit: MealPrepKit
    let onAssign: (Date, MealType, Int, String?) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedMealType: MealType = .dinner
    @State private var portionsToAssign = 1
    @State private var selectedRecipeId: String? = nil
    @State private var showRecipeSelection = false
    
    var availableRecipes: [RecipePortionTracker] {
        mealPrepKit.recipePortions?.filter { $0.remainingPortions > 0 } ?? []
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Date selection
                Section {
                    DatePicker(
                        NSLocalizedString("mealprep.assign.date", comment: ""),
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                } header: {
                    Text(LocalizedStringKey("mealprep.assign.date_section"))
                }
                
                // Meal type
                Section {
                    Picker(
                        NSLocalizedString("mealprep.assign.meal_type", comment: ""),
                        selection: $selectedMealType
                    ) {
                        ForEach(MealType.allCases) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(LocalizedStringKey("mealprep.assign.meal_type_section"))
                }
                
                // Portions
                Section {
                    Stepper(
                        value: $portionsToAssign,
                        in: 1...mealPrepKit.remainingPortions
                    ) {
                        HStack {
                            Text(LocalizedStringKey("mealprep.assign.portions"))
                            Spacer()
                            Text("\(portionsToAssign)")
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Text(String(format: NSLocalizedString("mealprep.portions_available", comment: ""), mealPrepKit.remainingPortions))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text(LocalizedStringKey("mealprep.assign.portions_section"))
                }
                
                // Optional: specific recipe selection
                if availableRecipes.count > 1 {
                    Section {
                        Toggle(
                            NSLocalizedString("mealprep.assign.specify_recipe", comment: ""),
                            isOn: $showRecipeSelection
                        )
                        
                        if showRecipeSelection {
                            Picker(
                                NSLocalizedString("mealprep.assign.recipe", comment: ""),
                                selection: $selectedRecipeId
                            ) {
                                Text(LocalizedStringKey("mealprep.assign.any_recipe"))
                                    .tag(nil as String?)
                                
                                ForEach(availableRecipes) { tracker in
                                    Text("\(tracker.recipeTitle) (\(tracker.remainingPortions) " + NSLocalizedString("mealprep.portions", comment: "") + ")")
                                        .tag(tracker.recipeId as String?)
                                }
                            }
                        }
                    } header: {
                        Text(LocalizedStringKey("mealprep.assign.recipe_section"))
                    } footer: {
                        Text(LocalizedStringKey("mealprep.assign.recipe_footer"))
                            .font(.caption)
                    }
                }
                
                // Preview
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedDate, style: .date)
                                    .font(.headline)
                                Text(selectedMealType.localizedName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(portionsToAssign)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentColor)
                                Text(portionsToAssign > 1 ? NSLocalizedString("mealprep.portions", comment: "") : NSLocalizedString("mealprep.portion", comment: ""))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if showRecipeSelection, let recipeId = selectedRecipeId,
                           let recipe = availableRecipes.first(where: { $0.recipeId == recipeId }) {
                            Divider()
                            HStack {
                                Image(systemName: "fork.knife")
                                    .foregroundColor(.accentColor)
                                Text(recipe.recipeTitle)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(LocalizedStringKey("mealprep.assign.preview"))
                }
            }
            .navigationTitle(LocalizedStringKey("mealprep.assign.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("mealprep.assign.add", comment: "")) {
                        onAssign(selectedDate, selectedMealType, portionsToAssign, showRecipeSelection ? selectedRecipeId : nil)
                        dismiss()
                    }
                    .disabled(portionsToAssign < 1 || portionsToAssign > mealPrepKit.remainingPortions)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AssignMealPrepSheet(
        mealPrepKit: MealPrepKit(
            name: "Chili Week",
            description: "Meal prep for the week",
            totalPortions: 12,
            estimatedPrepMinutes: 90,
            recipes: [],
            remainingPortions: 8
        ),
        onAssign: { _, _, _, _ in }
    )
}
