import Foundation

// MARK: - Meal Prep Kit

struct MealPrepKit: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let totalPortions: Int
    let estimatedPrepMinutes: Int
    let recipes: [MealPrepRecipeRef]
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case totalPortions = "total_portions"
        case estimatedPrepMinutes = "estimated_prep_minutes"
        case recipes
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), name: String, description: String? = nil, totalPortions: Int, estimatedPrepMinutes: Int, recipes: [MealPrepRecipeRef], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.totalPortions = totalPortions
        self.estimatedPrepMinutes = estimatedPrepMinutes
        self.recipes = recipes
        self.createdAt = createdAt
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
    
    // Full recipe for convenience (not sent to backend)
    var recipe: Recipe?
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case title
        case imageUrl = "image_url"
        case shelfLifeDays = "shelf_life_days"
        case isFreezable = "is_freezable"
        case storageNote = "storage_note"
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
