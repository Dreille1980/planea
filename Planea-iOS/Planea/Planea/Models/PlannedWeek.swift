import Foundation

/// Represents a weekly meal plan with real calendar dates
struct PlannedWeek: Identifiable, Codable {
    var id: UUID
    var familyId: UUID
    var startDate: Date  // Always the first day of the week (respects user's week start preference)
    var days: [PlannedDay]
    var status: PlanStatus
    var confirmedDate: Date?
    var name: String?
    var sourceTemplateId: UUID?  // Optional: tracks if created from template
    
    init(id: UUID = UUID(), familyId: UUID, startDate: Date, days: [PlannedDay], 
         status: PlanStatus = .draft, confirmedDate: Date? = nil, 
         name: String? = nil, sourceTemplateId: UUID? = nil) {
        self.id = id
        self.familyId = familyId
        self.startDate = startDate
        self.days = days
        self.status = status
        self.confirmedDate = confirmedDate
        self.name = name
        self.sourceTemplateId = sourceTemplateId
    }
}

/// A day in a planned week with a real calendar date
struct PlannedDay: Identifiable, Codable {
    var id: UUID
    var date: Date  // Real calendar date
    var meals: [PlannedMeal]
    
    init(id: UUID = UUID(), date: Date, meals: [PlannedMeal]) {
        self.id = id
        self.date = date
        self.meals = meals
    }
    
    /// Convenience: Get weekday name (e.g., "Monday")
    var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    /// Convenience: Get short date format (e.g., "Tue Mar 12")
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return formatter.string(from: date)
    }
}

/// A meal in a planned week
struct PlannedMeal: Identifiable, Codable {
    var id: UUID
    var mealType: MealType
    var recipe: Recipe
    
    init(id: UUID = UUID(), mealType: MealType, recipe: Recipe) {
        self.id = id
        self.mealType = mealType
        self.recipe = recipe
    }
}
