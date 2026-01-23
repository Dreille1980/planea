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
                    
                    // Nutritional information (if available)
                    if let calories = recipe.caloriesPerServing,
                       let protein = recipe.proteinPerServing,
                       let carbs = recipe.carbsPerServing,
                       let fat = recipe.fatPerServing {
                        
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(calories) cal")
                            Text("|")
                                .foregroundColor(.secondary)
                            Text("P: \(protein)g")
                            Text("G: \(carbs)g")
                            Text("L: \(fat)g")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.planeaPrimary.opacity(0.1))
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
                                    .background(Circle().fill(Color.planeaPrimary))
                                
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
                            .foregroundStyle(favoritesVM.isRecipeSaved(recipe) ? .planeaSecondary : .primary)
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
        
        // Localize unit (translate "unité" to "unit" if in English)
        let localizedPrimaryUnit = UnitConverter.localizeUnit(primary.unit)
        let localizedSecondaryUnit = UnitConverter.localizeUnit(secondary.unit)
        
        // Check if this is produce with weight (g or kg)
        if UnitConverter.isProduce(ingredient.name) {
            let lowercasedUnit = ingredient.unit.lowercased()
            
            // If it's in grams or kilograms, show approximate unit count
            if lowercasedUnit.contains("g") && !lowercasedUnit.contains("kg") {
                // Weight in grams
                if let unitCount = UnitConverter.weightToUnitCount(
                    ingredientName: ingredient.name,
                    weightInGrams: ingredient.quantity
                ) {
                    // Format: 300.0 g (5.3 oz) ≈ 2 units
                    let unitLabel = Locale.current.language.languageCode?.identifier == "fr" ? "unités" : "units"
                    return String(format: "%.1f %@ (%.1f %@) ≈ %.0f %@",
                                 primary.quantity, localizedPrimaryUnit,
                                 secondary.quantity, localizedSecondaryUnit,
                                 unitCount, unitLabel)
                }
            } else if lowercasedUnit.contains("kg") {
                // Weight in kilograms - convert to grams for calculation
                if let unitCount = UnitConverter.weightToUnitCount(
                    ingredientName: ingredient.name,
                    weightInGrams: ingredient.quantity * 1000
                ) {
                    let unitLabel = Locale.current.language.languageCode?.identifier == "fr" ? "unités" : "units"
                    return String(format: "%.1f %@ (%.1f %@) ≈ %.0f %@",
                                 primary.quantity, localizedPrimaryUnit,
                                 secondary.quantity, localizedSecondaryUnit,
                                 unitCount, unitLabel)
                }
            }
        }
        
        // Format: primary unit (secondary unit)
        return String(format: "%.1f %@ (%.1f %@)", 
                     primary.quantity, localizedPrimaryUnit,
                     secondary.quantity, localizedSecondaryUnit)
    }
}
