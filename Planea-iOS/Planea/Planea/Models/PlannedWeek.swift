import Foundation

// MARK: - Meal Source (NEW - unified meal source)

/// Source d'un repas dans le plan
enum MealSource: Codable {
    case recipe(Recipe)
    case mealPrep(MealPrepAssignment, MealPrepKit)
    
    enum CodingKeys: String, CodingKey {
        case type, recipe, assignment, kit
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .recipe(let recipe):
            try container.encode("recipe", forKey: .type)
            try container.encode(recipe, forKey: .recipe)
        case .mealPrep(let assignment, let kit):
            try container.encode("mealPrep", forKey: .type)
            try container.encode(assignment, forKey: .assignment)
            try container.encode(kit, forKey: .kit)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "recipe":
            let recipe = try container.decode(Recipe.self, forKey: .recipe)
            self = .recipe(recipe)
        case "mealPrep":
            let assignment = try container.decode(MealPrepAssignment.self, forKey: .assignment)
            let kit = try container.decode(MealPrepKit.self, forKey: .kit)
            self = .mealPrep(assignment, kit)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type")
        }
    }
    
    // MARK: - Helper computed properties
    
    /// Get the recipe if source is a recipe
    var recipe: Recipe? {
        if case .recipe(let recipe) = self {
            return recipe
        }
        return nil
    }
    
    /// Get the meal prep info if source is a meal prep
    var mealPrepInfo: (assignment: MealPrepAssignment, kit: MealPrepKit)? {
        if case .mealPrep(let assignment, let kit) = self {
            return (assignment, kit)
        }
        return nil
    }
    
    /// Get the title of the meal (works for both sources)
    var title: String {
        switch self {
        case .recipe(let recipe):
            return recipe.title
        case .mealPrep(_, let kit):
            return kit.name
        }
    }
    
    /// Check if this is a meal prep source
    var isMealPrep: Bool {
        if case .mealPrep = self {
            return true
        }
        return false
    }
}

// MARK: - Planned Week

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
    var source: MealSource  // ← NOUVEAU: Source unifiée
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case mealType = "meal_type"
        case source
        // Legacy support
        case recipe
    }
    
    // MARK: - Initializers
    
    init(id: UUID = UUID(), mealType: MealType, source: MealSource) {
        self.id = id
        self.mealType = mealType
        self.source = source
    }
    
    /// Legacy initializer for backward compatibility
    init(id: UUID = UUID(), mealType: MealType, recipe: Recipe) {
        self.id = id
        self.mealType = mealType
        self.source = .recipe(recipe)
    }
    
    // MARK: - Decoding (with backward compatibility)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        mealType = try container.decode(MealType.self, forKey: .mealType)
        
        // Try to decode new format first
        if let source = try? container.decode(MealSource.self, forKey: .source) {
            self.source = source
        }
        // Fallback to legacy format
        else if let recipe = try? container.decode(Recipe.self, forKey: .recipe) {
            self.source = .recipe(recipe)
        }
        // If neither works, throw error
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "PlannedMeal must have either source or recipe"
                )
            )
        }
    }
    
    // MARK: - Encoding
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(mealType, forKey: .mealType)
        try container.encode(source, forKey: .source)
    }
    
    // MARK: - Convenience Properties
    
    /// Get recipe (deprecated, use source.recipe instead)
    @available(*, deprecated, message: "Use source.recipe instead")
    var recipe: Recipe? {
        source.recipe
    }
}
