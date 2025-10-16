import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe = Recipe(title: "Exemple", servings: 4, totalMinutes: 30, ingredients: [], steps: [])
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    
    var body: some View {
        List {
            Section(header: Text("recipe.info".localized)) {
                HStack { Text("recipe.servings".localized); Spacer(); Text("\(recipe.servings)") }
                HStack { Text("recipe.time".localized); Spacer(); Text("\(recipe.totalMinutes) min") }
            }
            Section(header: Text("recipe.ingredients".localized)) {
                ForEach(recipe.ingredients) { ing in
                    HStack {
                        Text(ing.name.capitalized)
                        Spacer()
                        Text("\(ing.quantity, specifier: "%.0f") \(ing.unit)")
                    }
                }
            }
            Section(header: Text("recipe.steps".localized)) {
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
        .sheet(isPresented: $favoritesVM.showPaywall) {
            SubscriptionPaywallView(limitReached: false)
        }
    }
}
