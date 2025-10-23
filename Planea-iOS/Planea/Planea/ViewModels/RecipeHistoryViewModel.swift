import Foundation
import Combine

final class RecipeHistoryViewModel: ObservableObject {
    @Published var recentRecipes: [Recipe] = []
    
    private let persistence = PersistenceController.shared
    
    init() {
        loadRecentRecipes()
    }
    
    func loadRecentRecipes() {
        recentRecipes = persistence.loadRecentRecipes(limit: 15)
    }
    
    func saveRecipe(_ recipe: Recipe, source: String) {
        persistence.saveRecentRecipe(recipe, source: source)
        loadRecentRecipes()
    }
    
    func deleteRecipe(id: UUID) {
        persistence.deleteRecentRecipe(id: id)
        loadRecentRecipes()
    }
}
