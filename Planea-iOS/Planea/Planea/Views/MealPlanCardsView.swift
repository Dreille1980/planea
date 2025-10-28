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
            
            // Horizontal scrolling cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(planData) { dayData in
                        MealPlanDayCard(dayData: dayData)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
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
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Meals list
            VStack(alignment: .leading, spacing: 10) {
                ForEach(dayData.meals) { meal in
                    Button(action: {
                        selectedMeal = meal
                        showingRecipeDetail = true
                    }) {
                        mealRow(meal: meal)
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 6) {
            // Meal type badge
            HStack {
                Text(meal.mealType)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(mealTypeColor(meal.mealType))
                    .cornerRadius(6)
                Spacer()
            }
            
            // Recipe title
            Text(meal.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Meta info
            if let servings = meal.servings, let time = meal.time {
                HStack(spacing: 12) {
                    Label("\(servings)", systemImage: "person.2")
                    Label("\(time)'", systemImage: "clock")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func mealTypeColor(_ mealType: String) -> Color {
        switch mealType.lowercased() {
        case let type where type.contains("déjeuner") || type.contains("breakfast"):
            return Color.orange
        case let type where type.contains("dîner") || type.contains("lunch"):
            return Color.green
        case let type where type.contains("souper") || type.contains("dinner"):
            return Color.blue
        default:
            return Color.gray
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
