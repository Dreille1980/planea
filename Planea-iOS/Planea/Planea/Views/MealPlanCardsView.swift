import SwiftUI

/// Displays meal plan data as interactive cards in the chat
struct MealPlanCardsView: View {
    let planData: [DayPlanData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Intro text
            Text("chat.meal_plan.current_plan".localized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            // Vertical stacked cards
            VStack(spacing: 12) {
                ForEach(planData) { dayData in
                    MealPlanDayCard(dayData: dayData)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 8)
    }
}

/// Single day card showing meals
struct MealPlanDayCard: View {
    let dayData: DayPlanData
    @State private var showingRecipeDetail = false
    @State private var selectedMeal: MealData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            HStack {
                Text(dayData.dayName)
                    .font(.headline)
                    .bold()
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .font(.caption)
                    Text("\(dayData.meals.count)")
                        .font(.caption)
                        .bold()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            
            Divider()
            
            // Meals list
            VStack(spacing: 12) {
                ForEach(dayData.meals) { meal in
                    Button(action: {
                        selectedMeal = meal
                        showingRecipeDetail = true
                    }) {
                        mealRow(meal: meal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        )
        .sheet(item: $selectedMeal) { meal in
            if let recipe = meal.fullRecipe {
                NavigationView {
                    RecipeDetailView(recipe: recipe)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("chat.close".localized) {
                                    showingRecipeDetail = false
                                    selectedMeal = nil
                                }
                            }
                        }
                }
            } else {
                // Fallback if recipe data not available
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(meal.title)
                        .font(.headline)
                    if let servings = meal.servings, let time = meal.time {
                        HStack {
                            Label("\(servings) portions", systemImage: "person.2")
                            Spacer()
                            Label("\(time) min", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    Button("chat.close".localized) {
                        showingRecipeDetail = false
                        selectedMeal = nil
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
    
    @ViewBuilder
    private func mealRow(meal: MealData) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconName(for: meal.mealType))
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.mealType)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(meal.title)
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
    
    private func iconName(for mealType: String) -> String {
        switch mealType.lowercased() {
        case let type where type.contains("déjeuner") || type.contains("breakfast"):
            return "sunrise.fill"
        case let type where type.contains("dîner") || type.contains("lunch"):
            return "sun.max.fill"
        case let type where type.contains("souper") || type.contains("dinner"):
            return "moon.stars.fill"
        case let type where type.contains("collation") || type.contains("snack"):
            return "cup.and.saucer.fill"
        default:
            return "fork.knife"
        }
    }
}

// MARK: - Data Models

struct DayPlanData: Identifiable {
    let id = UUID()
    let dayName: String
    let meals: [MealData]
}

struct MealData: Identifiable {
    let id = UUID()
    let mealType: String
    let title: String
    let servings: Int?
    let time: Int?
    let fullRecipe: Recipe?
}

// MARK: - Preview

#Preview {
    let sampleData = [
        DayPlanData(
            dayName: "Lundi",
            meals: [
                MealData(
                    mealType: "Dîner",
                    title: "Poulet aux légumes",
                    servings: 4,
                    time: 30,
                    fullRecipe: nil
                ),
                MealData(
                    mealType: "Souper",
                    title: "Saumon grillé avec salade",
                    servings: 4,
                    time: 25,
                    fullRecipe: nil
                )
            ]
        ),
        DayPlanData(
            dayName: "Mardi",
            meals: [
                MealData(
                    mealType: "Dîner",
                    title: "Pâtes carbonara",
                    servings: 4,
                    time: 20,
                    fullRecipe: nil
                ),
                MealData(
                    mealType: "Souper",
                    title: "Bœuf aux brocolis",
                    servings: 4,
                    time: 35,
                    fullRecipe: nil
                )
            ]
        ),
        DayPlanData(
            dayName: "Mercredi",
            meals: [
                MealData(
                    mealType: "Dîner",
                    title: "Salade César au poulet",
                    servings: 4,
                    time: 15,
                    fullRecipe: nil
                ),
                MealData(
                    mealType: "Souper",
                    title: "Curry de légumes",
                    servings: 4,
                    time: 40,
                    fullRecipe: nil
                )
            ]
        )
    ]
    
    return ScrollView {
        VStack {
            Text("Aperçu des cartes de plan")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
            
            MealPlanCardsView(planData: sampleData)
        }
    }
    .background(Color(.systemGray6))
}
