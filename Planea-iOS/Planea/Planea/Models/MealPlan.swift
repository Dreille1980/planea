import Foundation

enum PlanStatus: String, Codable {
    case draft      // Plan en cours de création/modification
    case active     // Plan de la semaine actif
    case archived   // Plans précédents (historique)
}

struct SlotSelection: Codable, Identifiable, Hashable {
    var weekday: Weekday
    var mealType: MealType
    var isMealPrep: Bool = false
    var mealPrepGroupId: UUID? = nil
    
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
    var isMealPrep: Bool = false
    var mealPrepGroupId: UUID? = nil
    
    enum CodingKeys: String, CodingKey {
        case id
        case weekday
        case mealType = "meal_type"
        case recipe
        case isMealPrep = "is_meal_prep"
        case mealPrepGroupId = "meal_prep_group_id"
    }
}
