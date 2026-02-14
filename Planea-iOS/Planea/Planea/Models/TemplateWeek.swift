import Foundation

/// Represents a reusable weekly meal template without specific dates
struct TemplateWeek: Identifiable, Codable {
    var id: UUID
    var familyId: UUID
    var name: String
    var days: [TemplateDay]
    var createdDate: Date
    var lastModifiedDate: Date
    
    init(id: UUID = UUID(), familyId: UUID, name: String, days: [TemplateDay]) {
        self.id = id
        self.familyId = familyId
        self.name = name
        self.days = days
        self.createdDate = Date()
        self.lastModifiedDate = Date()
    }
}

/// A day in a template with weekday index (0-6) instead of real dates
struct TemplateDay: Identifiable, Codable {
    var id: UUID
    var weekdayIndex: Int  // 0-6 (Sunday=0, Monday=1, ..., Saturday=6)
    var meals: [TemplateMeal]
    
    init(id: UUID = UUID(), weekdayIndex: Int, meals: [TemplateMeal]) {
        self.id = id
        self.weekdayIndex = weekdayIndex
        self.meals = meals
    }
}

/// A meal in a template
struct TemplateMeal: Identifiable, Codable {
    var id: UUID
    var mealType: MealType
    var recipe: Recipe
    
    init(id: UUID = UUID(), mealType: MealType, recipe: Recipe) {
        self.id = id
        self.mealType = mealType
        self.recipe = recipe
    }
}
