import Foundation

struct SlotSelection: Codable, Identifiable, Hashable {
    var id: UUID = .init()
    var weekday: Weekday
    var mealType: MealType
}

struct MealPlan: Identifiable, Codable {
    var id: UUID = .init()
    var familyId: UUID
    var weekStart: Date
    var items: [MealItem] = []
}

struct MealItem: Identifiable, Codable {
    var id: UUID = .init()
    var weekday: Weekday
    var mealType: MealType
    var recipe: Recipe
    
    enum CodingKeys: String, CodingKey {
        case id
        case weekday
        case mealType = "meal_type"
        case recipe
    }
}
