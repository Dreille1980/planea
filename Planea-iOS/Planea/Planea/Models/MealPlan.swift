import Foundation

enum PlanStatus: String, Codable {
    case draft      // Plan en cours de création/modification
    case active     // Plan de la semaine actif
    case archived   // Plans précédents (historique)
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
    
    // Meal prep session ID (if this plan has meal preps)
    var mealPrepSessionId: UUID?
    
    // MARK: - Computed Properties
    
    /// All meal prep items in this plan
    var mealPrepItems: [MealItem] {
        items.filter { $0.isMealPrep }
    }
    
    /// All simple recipe items in this plan
    var simpleItems: [MealItem] {
        items.filter { !$0.isMealPrep }
    }
    
    /// Check if this plan has any meal preps
    var hasMealPreps: Bool {
        !mealPrepItems.isEmpty
    }
}

struct MealItem: Identifiable, Codable {
    var id: UUID = .init()
    var weekday: Weekday
    var mealType: MealType
    var recipe: Recipe
    
    // MARK: - Meal Prep Properties
    
    /// Whether this item is a meal prep (prepared in advance)
    var isMealPrep: Bool = false
    
    /// The meal prep session this item belongs to (if isMealPrep is true)
    var mealPrepSessionId: UUID?
    
    /// Steps to do on the day of consumption (e.g., "Réchauffer 3 min", "Ajouter garniture fraîche")
    var dayOfSteps: [String]?
    
    /// Whether this meal prep has been prepared already
    var isPrepared: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case weekday
        case mealType = "meal_type"
        case recipe
        case isMealPrep = "is_meal_prep"
        case mealPrepSessionId = "meal_prep_session_id"
        case dayOfSteps = "day_of_steps"
        case isPrepared = "is_prepared"
    }
    
    init(id: UUID = .init(), weekday: Weekday, mealType: MealType, recipe: Recipe, isMealPrep: Bool = false, mealPrepSessionId: UUID? = nil, dayOfSteps: [String]? = nil, isPrepared: Bool = false) {
        self.id = id
        self.weekday = weekday
        self.mealType = mealType
        self.recipe = recipe
        self.isMealPrep = isMealPrep
        self.mealPrepSessionId = mealPrepSessionId
        self.dayOfSteps = dayOfSteps
        self.isPrepared = isPrepared
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        weekday = try container.decode(Weekday.self, forKey: .weekday)
        mealType = try container.decode(MealType.self, forKey: .mealType)
        recipe = try container.decode(Recipe.self, forKey: .recipe)
        isMealPrep = try container.decodeIfPresent(Bool.self, forKey: .isMealPrep) ?? false
        mealPrepSessionId = try container.decodeIfPresent(UUID.self, forKey: .mealPrepSessionId)
        dayOfSteps = try container.decodeIfPresent([String].self, forKey: .dayOfSteps)
        isPrepared = try container.decodeIfPresent(Bool.self, forKey: .isPrepared) ?? false
    }
}

// MARK: - Meal Prep Session

/// Represents a meal prep session that groups multiple meal items together
struct MealPrepSession: Identifiable, Codable {
    var id: UUID = .init()
    var planId: UUID
    var preparationDate: Date
    var items: [MealItem]
    var isCompleted: Bool = false
    
    /// All unique ingredients across all meal prep items
    var consolidatedIngredients: [Ingredient] {
        var ingredientMap: [String: Ingredient] = [:]
        
        for item in items {
            for ingredient in item.recipe.ingredients {
                let key = "\(ingredient.name.lowercased())-\(ingredient.unit)"
                if var existing = ingredientMap[key] {
                    existing.quantity += ingredient.quantity
                    ingredientMap[key] = existing
                } else {
                    ingredientMap[key] = ingredient
                }
            }
        }
        
        return Array(ingredientMap.values).sorted { $0.name < $1.name }
    }
    
    /// All preparation steps across all meal prep items
    var allPreparationSteps: [(recipeName: String, steps: [String])] {
        items.map { item in
            (recipeName: item.recipe.title, steps: item.recipe.steps)
        }
    }
    
    /// Total estimated preparation time (sum of all recipes)
    var totalPrepTime: Int {
        items.reduce(0) { $0 + $1.recipe.prepTime }
    }
    
    /// Total estimated cooking time (sum of all recipes)
    var totalCookTime: Int {
        items.reduce(0) { $0 + $1.recipe.cookTime }
    }
}
