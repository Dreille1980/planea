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
    
    enum CodingKeys: String, CodingKey {
        case weekday
        case mealType = "meal_type"
        case isMealPrep = "is_meal_prep"
        case mealPrepGroupId = "meal_prep_group_id"
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
    var date: Date? = nil  // Real calendar date for this meal (e.g., 2026-03-18)
    
    enum CodingKeys: String, CodingKey {
        case id
        case weekday
        case mealType = "meal_type"
        case recipe
        case isMealPrep = "is_meal_prep"
        case mealPrepGroupId = "meal_prep_group_id"
        case date
    }
    
    /// Returns the real date for this meal, calculating from weekStart if not stored
    func resolvedDate(weekStart: Date) -> Date {
        if let date = date {
            return date
        }
        // Fallback: calculate from weekStart + weekday offset
        return MealItem.calculateDate(for: weekday, weekStart: weekStart)
    }
    
    /// Calculate a real date from a weekStart and weekday
    static func calculateDate(for weekday: Weekday, weekStart: Date) -> Date {
        let calendar = Calendar.current
        let startWeekdayIndex = calendar.component(.weekday, from: weekStart) // 1=Sun, 2=Mon, etc.
        
        let targetWeekdayIndex: Int
        switch weekday {
        case .sunday: targetWeekdayIndex = 1
        case .monday: targetWeekdayIndex = 2
        case .tuesday: targetWeekdayIndex = 3
        case .wednesday: targetWeekdayIndex = 4
        case .thursday: targetWeekdayIndex = 5
        case .friday: targetWeekdayIndex = 6
        case .saturday: targetWeekdayIndex = 7
        }
        
        var daysDifference = targetWeekdayIndex - startWeekdayIndex
        if daysDifference < 0 {
            daysDifference += 7
        }
        
        return calendar.date(byAdding: .day, value: daysDifference, to: weekStart) ?? weekStart
    }
}
