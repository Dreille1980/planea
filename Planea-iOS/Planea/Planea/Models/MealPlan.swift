import Foundation

enum PlanStatus: String, Codable {
    case draft
    case confirmed
}

struct SlotSelection: Codable, Identifiable, Hashable {
    var weekday: Weekday
    var mealType: MealType
    
    var id: String {
        "\(weekday.rawValue)-\(mealType.rawValue)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(weekday)
        hasher.combine(mealType)
    }
    
    static func == (lhs: SlotSelection, rhs: SlotSelection) -> Bool {
        lhs.weekday == rhs.weekday && lhs.mealType == rhs.mealType
    }
}

struct MealPlan: Identifiable, Codable {
    var id: UUID = .init()
    var familyId: UUID
    var weekStart: Date
    var items: [MealItem] = []
    var status: PlanStatus = .draft
    var confirmedDate: Date?
    var name: String?
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
