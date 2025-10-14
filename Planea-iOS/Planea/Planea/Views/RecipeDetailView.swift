import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe = Recipe(title: "Exemple", servings: 4, totalMinutes: 30, ingredients: [], steps: [])
    @StateObject private var favoritesVM = FavoritesViewModel()
    
    var body: some View {
        List {
            Section(header: Text(String(localized: "recipe.info"))) {
                HStack { Text(String(localized: "recipe.servings")); Spacer(); Text("\(recipe.servings)") }
                HStack { Text(String(localized: "recipe.time")); Spacer(); Text("\(recipe.totalMinutes) min") }
            }
            Section(header: Text(String(localized: "recipe.ingredients"))) {
                ForEach(recipe.ingredients) { ing in
                    HStack {
                        Text(ing.name.capitalized)
                        Spacer()
                        Text("\(ing.quantity, specifier: "%.0f") \(ing.unit)")
                    }
                }
            }
            Section(header: Text(String(localized: "recipe.steps"))) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { idx, step in
                    Text("\(idx+1). \(step)")
                }
            }
        }
        .navigationTitle(recipe.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    withAnimation {
                        if favoritesVM.isRecipeSaved(recipe) {
                            favoritesVM.removeRecipe(recipe)
                        } else {
                            favoritesVM.saveRecipe(recipe)
                        }
                    }
                }) {
                    Image(systemName: favoritesVM.isRecipeSaved(recipe) ? "heart.fill" : "heart")
                        .foregroundStyle(favoritesVM.isRecipeSaved(recipe) ? .red : .primary)
                }
            }
        }
    }
}
