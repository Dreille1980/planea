import SwiftUI

struct SavedRecipesView: View {
    @StateObject private var favoritesVM = FavoritesViewModel()
    
    var body: some View {
        ZStack {
            NavigationStack {
                Group {
                if favoritesVM.savedRecipes.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("favorites.empty".localized)
                                .font(.title3)
                                .bold()
                            
                            Text("favorites.empty_description".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // List of saved recipes
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(favoritesVM.savedRecipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    SavedRecipeCard(recipe: recipe, onRemove: {
                                        withAnimation {
                                            favoritesVM.removeRecipe(recipe)
                                        }
                                    })
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("favorites.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            }
            
            FloatingChatButton()
        }
    }
}

// MARK: - Saved Recipe Card
struct SavedRecipeCard: View {
    let recipe: Recipe
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 40))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
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
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.red)
            }
            .padding(.leading, 8)
            
            // Navigate icon
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
