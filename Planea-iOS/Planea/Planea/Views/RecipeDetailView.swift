import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe = Recipe(title: "Exemple", servings: 4, totalMinutes: 30, ingredients: [], steps: [])
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @EnvironmentObject var shoppingVM: ShoppingViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @State private var showAddedAlert = false
    @State private var showCreatedAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero section with main info
                VStack(alignment: .leading, spacing: 12) {
                    Text(recipe.title)
                        .font(.title2)
                        .bold()
                    
                    HStack(spacing: 24) {
                        Label("\(recipe.servings)", systemImage: "person.2.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Label("\(recipe.totalMinutes) min", systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
                
                // Ingredients section
                VStack(alignment: .leading, spacing: 12) {
                    Text("recipe.ingredients".localized)
                        .font(.headline)
                        .bold()
                    
                    VStack(spacing: 8) {
                        ForEach(recipe.ingredients) { ing in
                            let converted = convertIngredientWithBothSystems(ing)
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 6) {
                                    Text(ing.name.capitalized)
                                        .font(.body)
                                    
                                    if ing.isOnSale {
                                        Image(systemName: "tag.fill")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(converted)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Steps section
                VStack(alignment: .leading, spacing: 12) {
                    Text("recipe.steps".localized)
                        .font(.headline)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(idx+1)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(Color.accentColor))
                                
                                Text(step)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {
                        let units = UnitSystem(rawValue: unitSystem) ?? .metric
                        if shoppingVM.currentList != nil {
                            shoppingVM.addRecipeToList(recipe: recipe)
                            showAddedAlert = true
                        } else {
                            shoppingVM.createListFromRecipe(recipe: recipe, units: units)
                            showCreatedAlert = true
                        }
                    }) {
                        Image(systemName: "cart.badge.plus")
                            .foregroundStyle(.primary)
                    }
                    
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
        .sheet(isPresented: $favoritesVM.showPaywall) {
            SubscriptionPaywallView(limitReached: false)
        }
        .alert("recipe.addedToList".localized, isPresented: $showAddedAlert) {
            Button("action.done".localized, role: .cancel) { }
        } message: {
            Text("recipe.addedToList.message".localized)
        }
        .alert("recipe.listCreated".localized, isPresented: $showCreatedAlert) {
            Button("action.done".localized, role: .cancel) { }
        } message: {
            Text("recipe.listCreated.message".localized)
        }
    }
    
    // MARK: - Helper Functions
    
    private func convertIngredientWithBothSystems(_ ingredient: RecipeIngredient) -> String {
        let currentSystem = UnitSystem(rawValue: unitSystem) ?? .metric
        let otherSystem: UnitSystem = currentSystem == .metric ? .imperial : .metric
        
        // Convert to primary system
        let primary = UnitConverter.convertIngredient(
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            from: .metric,
            to: currentSystem
        )
        
        // Convert to secondary system
        let secondary = UnitConverter.convertIngredient(
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            from: .metric,
            to: otherSystem
        )
        
        // Format: primary unit (secondary unit)
        return String(format: "%.1f %@ (%.1f %@)", 
                     primary.quantity, primary.unit,
                     secondary.quantity, secondary.unit)
    }
}
