import Foundation
import Combine

final class RecipeViewModel: ObservableObject {
    @Published var currentRecipe: Recipe?
}
