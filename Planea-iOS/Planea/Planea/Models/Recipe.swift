import Foundation

struct Recipe: Identifiable, Codable, Hashable {
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

struct RecipeIngredient: Identifiable, Codable, Hashable {
    var id: UUID = .init()
    var name: String
    var quantity: Double
    var unit: String
    var category: String
    var isOnSale: Bool = false  // Indicates if ingredient is on sale in weekly flyers
    
    enum CodingKeys: String, CodingKey {
        case name
        case quantity
        case unit
        case category
        case isOnSale = "is_on_sale"
    }
    
    // Custom decoder for backward compatibility with old data without isOnSale
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(Double.self, forKey: .quantity)
        unit = try container.decode(String.self, forKey: .unit)
        category = try container.decode(String.self, forKey: .category)
        // Decode isOnSale with a default value of false if missing
        isOnSale = try container.decodeIfPresent(Bool.self, forKey: .isOnSale) ?? false
    }
}
