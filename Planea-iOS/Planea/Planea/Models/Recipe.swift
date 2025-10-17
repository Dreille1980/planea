import Foundation

struct Recipe: Identifiable, Codable {
    var id: UUID = .init()
    var title: String
    var servings: Int
    var totalMinutes: Int
    var ingredients: [RecipeIngredient]
    var steps: [String]
    var equipment: [String] = []
    var tags: [String] = []
    var detectedIngredients: String? = nil  // Optional: ingredients detected from fridge photo
    
    enum CodingKeys: String, CodingKey {
        case title
        case servings
        case totalMinutes = "total_minutes"
        case ingredients
        case steps
        case equipment
        case tags
        case detectedIngredients = "detected_ingredients"
    }
}

struct RecipeIngredient: Identifiable, Codable {
    var id: UUID = .init()
    var name: String
    var quantity: Double
    var unit: String
    var category: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case quantity
        case unit
        case category
    }
}
