import SwiftUI

struct RecentRecipesView: View {
    @EnvironmentObject var recipeHistoryVM: RecipeHistoryViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @State private var showAddToPlanSheet = false
    @State private var selectedRecipe: Recipe?
    
    var body: some View {
        NavigationStack {
            Group {
                if recipeHistoryVM.recentRecipes.isEmpty {
                    ContentUnavailableView(
                        "recent.recipes.empty".localized,
                        systemImage: "clock",
                        description: Text("Générez des recettes ad hoc pour créer un historique")
                    )
                } else {
                    List {
                        ForEach(recipeHistoryVM.recentRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(recipe.title)
                                        .font(.headline)
                                    
                                    HStack(spacing: 12) {
                                        Label("\(recipe.servings)", systemImage: "person.2")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Label("\(recipe.totalMinutes) min", systemImage: "clock")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        recipeHistoryVM.deleteRecipe(id: recipe.id)
                                    }
                                } label: {
                                    Label("action.delete".localized, systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    selectedRecipe = recipe
                                    showAddToPlanSheet = true
                                } label: {
                                    Label("recent.recipes.addToPlan".localized, systemImage: "calendar.badge.plus")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("recent.recipes.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddToPlanSheet) {
                if let recipe = selectedRecipe {
                    AddToPlanSheet(recipe: recipe)
                        .environmentObject(planVM)
                }
            }
        }
    }
}

struct AddToPlanSheet: View {
    let recipe: Recipe
    @EnvironmentObject var planVM: PlanViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedWeekday: Weekday = .monday
    @State private var selectedMealType: MealType = .dinner
    
    let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    let mealTypes: [MealType] = [.breakfast, .lunch, .dinner]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("week.day".localized, selection: $selectedWeekday) {
                        ForEach(weekdays, id: \.self) { day in
                            Text(dayLabel(for: day)).tag(day)
                        }
                    }
                    
                    Picker("meal.type".localized, selection: $selectedMealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(mealLabel(for: type)).tag(type)
                        }
                    }
                } header: {
                    Text("meal.selectSlot".localized)
                }
                
                Section {
                    if planVM.hasMealInSlot(weekday: selectedWeekday, mealType: selectedMealType) {
                        Text("Cette période contient déjà un repas. Il sera remplacé.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Section {
                    Button("action.add".localized) {
                        addRecipeToPlan()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(planVM.draftPlan == nil)
                }
                
                if planVM.draftPlan == nil {
                    Section {
                        Text("Veuillez créer un plan de semaine avant d'ajouter des repas")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(recipe.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("action.cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
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
    
    func mealLabel(for mt: MealType) -> String {
        switch mt {
        case .breakfast: return "meal.breakfast".localized
        case .lunch: return "meal.lunch".localized
        case .dinner: return "meal.dinner".localized
        case .snack: return "meal.snack".localized
        }
    }
    
    private func addRecipeToPlan() {
        let mealItem = MealItem(
            weekday: selectedWeekday,
            mealType: selectedMealType,
            recipe: recipe
        )
        
        // Remove existing meal in that slot if any
        if let existingPlan = planVM.draftPlan,
           let existingMeal = existingPlan.items.first(where: { 
               $0.weekday == selectedWeekday && $0.mealType == selectedMealType 
           }) {
            planVM.removeMeal(mealItem: existingMeal)
        }
        
        planVM.addMeal(mealItem: mealItem)
        dismiss()
    }
}
