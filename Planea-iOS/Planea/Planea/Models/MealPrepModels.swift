import Foundation

// MARK: - Meal Prep Concept

struct MealPrepConcept: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let cuisine: String?
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case cuisine
        case tags
    }
    
    init(id: UUID = UUID(), name: String, description: String, cuisine: String? = nil, tags: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.cuisine = cuisine
        self.tags = tags
    }
}

// MARK: - Optimized Recipe Step

struct OptimizedRecipeStep: Identifiable, Codable {
    let id: UUID
    let recipeId: String
    let recipeTitle: String
    let stepNumber: Int
    let stepDescription: String
    let estimatedMinutes: Int?
    let isParallel: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case recipeTitle = "recipe_title"
        case stepNumber = "step_number"
        case stepDescription = "step_description"
        case estimatedMinutes = "estimated_minutes"
        case isParallel = "is_parallel"
    }
    
    init(id: UUID = UUID(), recipeId: String, recipeTitle: String, stepNumber: Int, stepDescription: String, estimatedMinutes: Int? = nil, isParallel: Bool = false) {
        self.id = id
        self.recipeId = recipeId
        self.recipeTitle = recipeTitle
        self.stepNumber = stepNumber
        self.stepDescription = stepDescription
        self.estimatedMinutes = estimatedMinutes
        self.isParallel = isParallel
    }
}

// MARK: - Meal Prep Kit

struct MealPrepKit: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let totalPortions: Int
    let estimatedPrepMinutes: Int
    let recipes: [MealPrepRecipeRef]
    let groupedPrepSteps: [GroupedPrepStep]?
    let optimizedRecipeSteps: [OptimizedRecipeStep]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case totalPortions = "total_portions"
        case estimatedPrepMinutes = "estimated_prep_minutes"
        case recipes
        case groupedPrepSteps = "grouped_prep_steps"
        case optimizedRecipeSteps = "optimized_recipe_steps"
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), name: String, description: String? = nil, totalPortions: Int, estimatedPrepMinutes: Int, recipes: [MealPrepRecipeRef], groupedPrepSteps: [GroupedPrepStep]? = nil, optimizedRecipeSteps: [OptimizedRecipeStep]? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.totalPortions = totalPortions
        self.estimatedPrepMinutes = estimatedPrepMinutes
        self.recipes = recipes
        self.groupedPrepSteps = groupedPrepSteps
        self.optimizedRecipeSteps = optimizedRecipeSteps
        self.createdAt = createdAt
    }
    
    // Custom decoding to handle ISO date strings from backend
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        totalPortions = try container.decode(Int.self, forKey: .totalPortions)
        estimatedPrepMinutes = try container.decode(Int.self, forKey: .estimatedPrepMinutes)
        recipes = try container.decode([MealPrepRecipeRef].self, forKey: .recipes)
        groupedPrepSteps = try container.decodeIfPresent([GroupedPrepStep].self, forKey: .groupedPrepSteps)
        optimizedRecipeSteps = try container.decodeIfPresent([OptimizedRecipeStep].self, forKey: .optimizedRecipeSteps)
        
        // Try to decode created_at as ISO string first, then fall back to Date
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                createdAt = date
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: dateString) {
                    createdAt = date
                } else {
                    createdAt = Date()
                }
            }
        } else {
            // Fall back to direct Date decoding
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
    }
}

// MARK: - Meal Prep Recipe Reference

struct MealPrepRecipeRef: Identifiable, Codable {
    let id: UUID
    let recipeId: String
    let title: String
    let imageUrl: String?
    let shelfLifeDays: Int
    let isFreezable: Bool
    let storageNote: String?
    
    // Full recipe from backend
    let recipe: Recipe?
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case title
        case imageUrl = "image_url"
        case shelfLifeDays = "shelf_life_days"
        case isFreezable = "is_freezable"
        case storageNote = "storage_note"
        case recipe  // NOW INCLUDED!
    }
    
    init(id: UUID = UUID(), recipeId: String, title: String, imageUrl: String? = nil, shelfLifeDays: Int, isFreezable: Bool, storageNote: String? = nil, recipe: Recipe? = nil) {
        self.id = id
        self.recipeId = recipeId
        self.title = title
        self.imageUrl = imageUrl
        self.shelfLifeDays = shelfLifeDays
        self.isFreezable = isFreezable
        self.storageNote = storageNote
        self.recipe = recipe
    }
}

// MARK: - Grouped Prep Steps

struct GroupedPrepStep: Identifiable, Codable {
    let id: UUID
    let actionType: String
    let description: String
    let ingredients: [PrepIngredient]
    let detailedSteps: [String]
    let estimatedMinutes: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case actionType = "action_type"
        case description
        case ingredients
        case detailedSteps = "detailed_steps"
        case estimatedMinutes = "estimated_minutes"
    }
    
    init(id: UUID = UUID(), actionType: String, description: String, ingredients: [PrepIngredient], detailedSteps: [String], estimatedMinutes: Int? = nil) {
        self.id = id
        self.actionType = actionType
        self.description = description
        self.ingredients = ingredients
        self.detailedSteps = detailedSteps
        self.estimatedMinutes = estimatedMinutes
    }
}

struct PrepIngredient: Identifiable, Codable {
    let id: UUID
    let name: String
    let quantity: String
    let recipeTitle: String
    let recipeId: String
    let usage: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantity
        case recipeTitle = "recipe_title"
        case recipeId = "recipe_id"
        case usage
    }
    
    init(id: UUID = UUID(), name: String, quantity: String, recipeTitle: String, recipeId: String, usage: String) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.recipeTitle = recipeTitle
        self.recipeId = recipeId
        self.usage = usage
    }
}

// MARK: - Meal Prep Instance (History)

struct MealPrepInstance: Identifiable, Codable {
    let id: UUID
    let kit: MealPrepKit
    let appliedWeekStart: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case kit
        case appliedWeekStart = "applied_week_start"
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), kit: MealPrepKit, appliedWeekStart: Date, createdAt: Date = Date()) {
        self.id = id
        self.kit = kit
        self.appliedWeekStart = appliedWeekStart
        self.createdAt = createdAt
    }
}

// MARK: - Generation Parameters

struct MealPrepGenerationParams: Codable {
    let days: [Weekday]
    let meals: [MealType]
    let servingsPerMeal: Int
    let totalPrepTimePreference: PrepTimePreference
    let skillLevel: SkillLevel
    let avoidRareIngredients: Bool
    let preferLongShelfLife: Bool
    
    enum CodingKeys: String, CodingKey {
        case days
        case meals
        case servingsPerMeal = "servings_per_meal"
        case totalPrepTimePreference = "total_prep_time_preference"
        case skillLevel = "skill_level"
        case avoidRareIngredients = "avoid_rare_ingredients"
        case preferLongShelfLife = "prefer_long_shelf_life"
    }
}

enum PrepTimePreference: String, Codable, CaseIterable, Identifiable {
    case oneHour = "1h"
    case oneHourThirty = "1h30"
    case twoHoursPlus = "2h+"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .oneHour: return "mealprep.time.1h".localized
        case .oneHourThirty: return "mealprep.time.1h30".localized
        case .twoHoursPlus: return "mealprep.time.2h+".localized
        }
    }
    
    var minutes: Int {
        switch self {
        case .oneHour: return 60
        case .oneHourThirty: return 90
        case .twoHoursPlus: return 120
        }
    }
}

enum SkillLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case quickEfficient = "quick_efficient"
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .beginner: return "mealprep.skill.beginner".localized
        case .intermediate: return "mealprep.skill.intermediate".localized
        case .quickEfficient: return "mealprep.skill.quick".localized
        }
    }
}

// MARK: - Days Preset

enum DaysPreset: String, CaseIterable, Identifiable {
    case mondayToFriday = "monday_to_friday"
    case mondayToSunday = "monday_to_sunday"
    case custom
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .mondayToFriday: return "mealprep.days.monToFri".localized
        case .mondayToSunday: return "mealprep.days.monToSun".localized
        case .custom: return "mealprep.days.custom".localized
        }
    }
    
    var days: [Weekday] {
        switch self {
        case .mondayToFriday:
            return [.monday, .tuesday, .wednesday, .thursday, .friday]
        case .mondayToSunday:
            return Weekday.allCases
        case .custom:
            return []
        }
    }
}
