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

// MARK: - Cooking Phases (New Post-Prep Structure)

struct PhaseStep: Identifiable, Codable {
    let id: UUID
    let description: String
    let recipeTitle: String
    let recipeIndex: Int?
    let estimatedMinutes: Int?
    let isParallel: Bool
    let parallelNote: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case recipeTitle = "recipe_title"
        case recipeIndex = "recipe_index"
        case estimatedMinutes = "estimated_minutes"
        case isParallel = "is_parallel"
        case parallelNote = "parallel_note"
    }
    
    init(id: UUID = UUID(), description: String, recipeTitle: String, recipeIndex: Int? = nil, estimatedMinutes: Int? = nil, isParallel: Bool = false, parallelNote: String? = nil) {
        self.id = id
        self.description = description
        self.recipeTitle = recipeTitle
        self.recipeIndex = recipeIndex
        self.estimatedMinutes = estimatedMinutes
        self.isParallel = isParallel
        self.parallelNote = parallelNote
    }
}

// MARK: - Recipe Cooking Group (NEW - for grouped cooking steps by recipe)

struct RecipeCookingGroup: Identifiable, Codable {
    let id: UUID
    let recipeId: String
    let recipeTitle: String
    let estimatedMinutes: Int
    let steps: [PhaseStep]
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case recipeTitle = "recipe_title"
        case estimatedMinutes = "estimated_minutes"
        case steps
    }
    
    init(id: UUID = UUID(), recipeId: String, recipeTitle: String, estimatedMinutes: Int, steps: [PhaseStep]) {
        self.id = id
        self.recipeId = recipeId
        self.recipeTitle = recipeTitle
        self.estimatedMinutes = estimatedMinutes
        self.steps = steps
    }
    
    // Custom init for decoding when id might be missing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ID might not be present in backend response
        if let decodedId = try? container.decode(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID()
        }
        
        recipeId = try container.decode(String.self, forKey: .recipeId)
        recipeTitle = try container.decode(String.self, forKey: .recipeTitle)
        estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
        steps = try container.decode([PhaseStep].self, forKey: .steps)
    }
}

struct CookingPhase: Identifiable, Codable {
    let id: UUID
    let title: String
    let totalMinutes: Int
    let steps: [PhaseStep]  // DEPRECATED - kept for backward compatibility
    let recipes: [RecipeCookingGroup]?  // NEW - grouping by recipe
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case totalMinutes = "total_minutes"
        case steps
        case recipes
    }
    
    init(id: UUID = UUID(), title: String, totalMinutes: Int, steps: [PhaseStep], recipes: [RecipeCookingGroup]? = nil) {
        self.id = id
        self.title = title
        self.totalMinutes = totalMinutes
        self.steps = steps
        self.recipes = recipes
    }
    
    // Custom init for decoding when id might be missing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ID might not be present in backend response for phase objects
        if let decodedId = try? container.decode(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID()
        }
        
        title = try container.decode(String.self, forKey: .title)
        totalMinutes = try container.decode(Int.self, forKey: .totalMinutes)
        
        // New format with recipes grouping
        recipes = try container.decodeIfPresent([RecipeCookingGroup].self, forKey: .recipes)
        
        // Legacy format with flat steps list - fallback if recipes not present
        if let decodedSteps = try? container.decode([PhaseStep].self, forKey: .steps) {
            steps = decodedSteps
        } else {
            steps = []
        }
    }
}

struct CookingPhasesSet: Codable {
    let cook: CookingPhase
    let assemble: CookingPhase
    let coolDown: CookingPhase
    let store: CookingPhase
    
    enum CodingKeys: String, CodingKey {
        case cook
        case assemble
        case coolDown = "cool_down"
        case store
    }
    
    init(cook: CookingPhase, assemble: CookingPhase, coolDown: CookingPhase, store: CookingPhase) {
        self.cook = cook
        self.assemble = assemble
        self.coolDown = coolDown
        self.store = store
    }
}

// MARK: - Optimized Recipe Step (DEPRECATED - Use CookingPhases instead)

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

// MARK: - Meal Prep Assignment (NEW - for portion tracking)

struct MealPrepAssignment: Identifiable, Codable {
    let id: UUID
    let mealPrepKitId: UUID
    let date: Date
    let mealType: MealType
    let portionsUsed: Int
    
    // Optionnel : si on veut tracker quelle recette
    let specificRecipeId: String?
    let specificRecipeTitle: String?
    
    let assignedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case mealPrepKitId = "meal_prep_kit_id"
        case date
        case mealType = "meal_type"
        case portionsUsed = "portions_used"
        case specificRecipeId = "specific_recipe_id"
        case specificRecipeTitle = "specific_recipe_title"
        case assignedAt = "assigned_at"
    }
    
    init(id: UUID = UUID(), mealPrepKitId: UUID, date: Date, mealType: MealType, 
         portionsUsed: Int, specificRecipeId: String? = nil, 
         specificRecipeTitle: String? = nil, assignedAt: Date = Date()) {
        self.id = id
        self.mealPrepKitId = mealPrepKitId
        self.date = date
        self.mealType = mealType
        self.portionsUsed = portionsUsed
        self.specificRecipeId = specificRecipeId
        self.specificRecipeTitle = specificRecipeTitle
        self.assignedAt = assignedAt
    }
}

// MARK: - Recipe Portion Tracker (NEW - for hybrid portion management)

struct RecipePortionTracker: Identifiable, Codable {
    let id: UUID
    let recipeId: String
    let recipeTitle: String
    let totalPortions: Int
    var remainingPortions: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case recipeTitle = "recipe_title"
        case totalPortions = "total_portions"
        case remainingPortions = "remaining_portions"
    }
    
    init(id: UUID = UUID(), recipeId: String, recipeTitle: String, totalPortions: Int) {
        self.id = id
        self.recipeId = recipeId
        self.recipeTitle = recipeTitle
        self.totalPortions = totalPortions
        self.remainingPortions = totalPortions
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
    let optimizedRecipeSteps: [OptimizedRecipeStep]? // DEPRECATED
    let cookingPhases: CookingPhasesSet? // DEPRECATED
    
    // NEW: Simplified ChatGPT-style structure
    let todayPreparation: TodayPreparation?
    let weeklyReheating: WeeklyReheating?
    
    // NEW: Portion management
    var remainingPortions: Int  // Décrémenté lors des assignations
    var assignments: [MealPrepAssignment]  // Historique des assignations
    let preparedDate: Date  // Date de préparation
    var recipePortions: [RecipePortionTracker]?  // Portions par recette (hybride)
    
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
        case cookingPhases = "cooking_phases"
        case todayPreparation = "today_preparation"
        case weeklyReheating = "weekly_reheating"
        case remainingPortions = "remaining_portions"
        case assignments
        case preparedDate = "prepared_date"
        case recipePortions = "recipe_portions"
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), name: String, description: String? = nil, totalPortions: Int, estimatedPrepMinutes: Int, recipes: [MealPrepRecipeRef], groupedPrepSteps: [GroupedPrepStep]? = nil, optimizedRecipeSteps: [OptimizedRecipeStep]? = nil, cookingPhases: CookingPhasesSet? = nil, todayPreparation: TodayPreparation? = nil, weeklyReheating: WeeklyReheating? = nil, remainingPortions: Int? = nil, assignments: [MealPrepAssignment] = [], preparedDate: Date = Date(), recipePortions: [RecipePortionTracker]? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.totalPortions = totalPortions
        self.estimatedPrepMinutes = estimatedPrepMinutes
        self.recipes = recipes
        self.groupedPrepSteps = groupedPrepSteps
        self.optimizedRecipeSteps = optimizedRecipeSteps
        self.cookingPhases = cookingPhases
        self.todayPreparation = todayPreparation
        self.weeklyReheating = weeklyReheating
        self.remainingPortions = remainingPortions ?? totalPortions
        self.assignments = assignments
        self.preparedDate = preparedDate
        self.recipePortions = recipePortions
        self.createdAt = createdAt
    }
    
    // Computed properties
    var hasAvailablePortions: Bool {
        remainingPortions > 0
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
        cookingPhases = try container.decodeIfPresent(CookingPhasesSet.self, forKey: .cookingPhases)
        
        // NEW: Simplified structure
        todayPreparation = try container.decodeIfPresent(TodayPreparation.self, forKey: .todayPreparation)
        weeklyReheating = try container.decodeIfPresent(WeeklyReheating.self, forKey: .weeklyReheating)
        
        // NEW: Portion management (with defaults for backward compatibility)
        remainingPortions = try container.decodeIfPresent(Int.self, forKey: .remainingPortions) ?? totalPortions
        assignments = try container.decodeIfPresent([MealPrepAssignment].self, forKey: .assignments) ?? []
        
        // Decode prepared date
        if let dateString = try? container.decode(String.self, forKey: .preparedDate) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                preparedDate = date
            } else {
                formatter.formatOptions = [.withInternetDateTime]
                preparedDate = formatter.date(from: dateString) ?? Date()
            }
        } else {
            preparedDate = try container.decodeIfPresent(Date.self, forKey: .preparedDate) ?? Date()
        }
        
        recipePortions = try container.decodeIfPresent([RecipePortionTracker].self, forKey: .recipePortions)
        
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

// MARK: - NEW SIMPLIFIED STRUCTURE (ChatGPT-style)

/// Structure pour "CE QUE TU FAIS AUJOURD'HUI"
struct TodayPreparation: Codable {
    let consolidatedIngredients: [ConsolidatedIngredient]?  // NEW: Liste consolidée
    let commonPreps: [CommonPrepStep]
    let recipePreps: [RecipePrep]
    let totalMinutes: Int
    
    enum CodingKeys: String, CodingKey {
        case consolidatedIngredients = "consolidated_ingredients"
        case commonPreps = "common_preps"
        case recipePreps = "recipe_preps"
        case totalMinutes = "total_minutes"
    }
    
    init(consolidatedIngredients: [ConsolidatedIngredient]? = nil, commonPreps: [CommonPrepStep], recipePreps: [RecipePrep], totalMinutes: Int) {
        self.consolidatedIngredients = consolidatedIngredients
        self.commonPreps = commonPreps
        self.recipePreps = recipePreps
        self.totalMinutes = totalMinutes
    }
}

/// Ingrédient consolidé (liste complète pour faire l'épicerie)
struct ConsolidatedIngredient: Identifiable, Codable {
    let id: UUID
    let name: String
    let quantity: String  // "500g", "3 unités", etc.
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case quantity
    }
    
    init(id: UUID = UUID(), name: String, quantity: String) {
        self.id = id
        self.name = name
        self.quantity = quantity
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try? container.decode(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID()
        }
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(String.self, forKey: .quantity)
    }
}

/// Préparations communes (cuire riz, quinoa, etc.)
struct CommonPrepStep: Identifiable, Codable {
    let id: UUID
    let category: String  // "Cuire", "Laver, couper et portionner", etc.
    let items: [String]   // ["Quinoa (pour 2 repas)", "Riz blanc"]
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case items
    }
    
    init(id: UUID = UUID(), category: String, items: [String]) {
        self.id = id
        self.category = category
        self.items = items
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try? container.decode(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID()
        }
        category = try container.decode(String.self, forKey: .category)
        items = try container.decode([String].self, forKey: .items)
    }
}

/// Préparation par repas
struct RecipePrep: Identifiable, Codable {
    let id: UUID
    let recipeName: String
    let emoji: String
    let prepToday: [String]        // Ce qu'on fait aujourd'hui
    let dontPrepToday: String?     // ⚠️ Note importante (ex: "Ne pas cuire le saumon")
    let estimatedMinutes: Int?     // Temps de préparation aujourd'hui
    let eveningMinutes: Int?       // "Temps soir" - temps de réchauffage/finition
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeName = "recipe_name"
        case emoji
        case prepToday = "prep_today"
        case dontPrepToday = "dont_prep_today"
        case estimatedMinutes = "estimated_minutes"
        case eveningMinutes = "evening_minutes"
    }
    
    init(id: UUID = UUID(), recipeName: String, emoji: String, prepToday: [String], dontPrepToday: String? = nil, estimatedMinutes: Int? = nil, eveningMinutes: Int? = nil) {
        self.id = id
        self.recipeName = recipeName
        self.emoji = emoji
        self.prepToday = prepToday
        self.dontPrepToday = dontPrepToday
        self.estimatedMinutes = estimatedMinutes
        self.eveningMinutes = eveningMinutes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try? container.decode(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID()
        }
        recipeName = try container.decode(String.self, forKey: .recipeName)
        emoji = try container.decode(String.self, forKey: .emoji)
        prepToday = try container.decode([String].self, forKey: .prepToday)
        dontPrepToday = try container.decodeIfPresent(String.self, forKey: .dontPrepToday)
        estimatedMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedMinutes)
        eveningMinutes = try container.decodeIfPresent(Int.self, forKey: .eveningMinutes)
    }
}

/// Structure pour "CE QUI RESTE À FAIRE CHAQUE SOIR"
struct WeeklyReheating: Codable {
    let days: [DailyReheating]
    
    init(days: [DailyReheating]) {
        self.days = days
    }
}

/// Réchauffage quotidien
struct DailyReheating: Identifiable, Codable {
    let id: UUID
    let dayNumber: Int
    let dayLabel: String  // "Soir 1", "Soir 2"
    let recipeName: String
    let emoji: String
    let steps: [String]
    let estimatedMinutes: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case dayNumber = "day_number"
        case dayLabel = "day_label"
        case recipeName = "recipe_name"
        case emoji
        case steps
        case estimatedMinutes = "estimated_minutes"
    }
    
    init(id: UUID = UUID(), dayNumber: Int, dayLabel: String, recipeName: String, emoji: String, steps: [String], estimatedMinutes: Int) {
        self.id = id
        self.dayNumber = dayNumber
        self.dayLabel = dayLabel
        self.recipeName = recipeName
        self.emoji = emoji
        self.steps = steps
        self.estimatedMinutes = estimatedMinutes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let decodedId = try? container.decode(UUID.self, forKey: .id) {
            id = decodedId
        } else {
            id = UUID()
        }
        dayNumber = try container.decode(Int.self, forKey: .dayNumber)
        dayLabel = try container.decode(String.self, forKey: .dayLabel)
        recipeName = try container.decode(String.self, forKey: .recipeName)
        emoji = try container.decode(String.self, forKey: .emoji)
        steps = try container.decode([String].self, forKey: .steps)
        estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
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
    case expert
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .beginner: return "mealprep.skill.beginner".localized
        case .intermediate: return "mealprep.skill.intermediate".localized
        case .expert: return "mealprep.skill.expert".localized
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

// MARK: - Action-Based Preparation (New UX)

/// Type of preparation action
enum PrepActionType: String, CaseIterable, Identifiable, Codable {
    case chop = "chop"
    case mix = "mix"
    case pressDrain = "press_drain"
    case marinate = "marinate"
    case prepSauces = "prep_sauces"
    case measure = "measure"
    case peel = "peel"
    case grate = "grate"
    case other = "other"
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .chop: return "🔪"
        case .mix: return "🥣"
        case .pressDrain: return "💧"
        case .marinate: return "🧂"
        case .prepSauces: return "🍯"
        case .measure: return "⚖️"
        case .peel: return "🥕"
        case .grate: return "🧀"
        case .other: return "👨‍🍳"
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .chop: return "scissors"
        case .mix: return "bowl.fill"
        case .pressDrain: return "drop.fill"
        case .marinate: return "sparkles"
        case .prepSauces: return "drop.triangle.fill"
        case .measure: return "scalemass.fill"
        case .peel: return "carrot.fill"
        case .grate: return "square.grid.3x3.fill"
        case .other: return "hand.raised.fill"
        }
    }
    
    var localizedName: String {
        switch self {
        case .chop: return "mealprep.action.chop".localized
        case .mix: return "mealprep.action.mix".localized
        case .pressDrain: return "mealprep.action.press_drain".localized
        case .marinate: return "mealprep.action.marinate".localized
        case .prepSauces: return "mealprep.action.prep_sauces".localized
        case .measure: return "mealprep.action.measure".localized
        case .peel: return "mealprep.action.peel".localized
        case .grate: return "mealprep.action.grate".localized
        case .other: return "mealprep.action.other".localized
        }
    }
    
    /// Whether ingredients from different recipes can be prepared together
    /// True = can consolidate (e.g., chop all carrots together)
    /// False = must separate by recipe (e.g., different marinades)
    var isSeparable: Bool {
        switch self {
        case .chop, .peel, .grate, .measure:
            return true  // Can prepare together regardless of recipe
        case .mix, .marinate, .prepSauces, .pressDrain:
            return false  // Must keep separate by recipe
        case .other:
            return true  // Default to separable
        }
    }
    
    /// Priority order for display (chop first, etc.)
    var sortOrder: Int {
        switch self {
        case .chop: return 1
        case .peel: return 2
        case .grate: return 3
        case .measure: return 4
        case .mix: return 5
        case .prepSauces: return 6
        case .marinate: return 7
        case .pressDrain: return 8
        case .other: return 99
        }
    }
    
    /// Detect action type from text
    static func detect(from text: String) -> PrepActionType {
        let lowercased = text.lowercased()
        
        // Chop variations
        if lowercased.contains("chop") || lowercased.contains("dice") || 
           lowercased.contains("cut") || lowercased.contains("slice") ||
           lowercased.contains("mince") || lowercased.contains("couper") ||
           lowercased.contains("émincer") || lowercased.contains("hacher") ||
           lowercased.contains("trancher") {
            return .chop
        }
        
        // Mix variations
        if lowercased.contains("mix") || lowercased.contains("combine") ||
           lowercased.contains("whisk") || lowercased.contains("beat") ||
           lowercased.contains("mélanger") || lowercased.contains("battre") ||
           lowercased.contains("fouetter") {
            return .mix
        }
        
        // Press/Drain
        if lowercased.contains("press") || lowercased.contains("drain") ||
           lowercased.contains("squeeze") || lowercased.contains("presser") ||
           lowercased.contains("égoutter") {
            return .pressDrain
        }
        
        // Marinate
        if lowercased.contains("marinate") || lowercased.contains("mariner") {
            return .marinate
        }
        
        // Sauces
        if lowercased.contains("sauce") || lowercased.contains("dressing") ||
           lowercased.contains("vinaigrette") {
            return .prepSauces
        }
        
        // Measure
        if lowercased.contains("measure") || lowercased.contains("weigh") ||
           lowercased.contains("mesurer") || lowercased.contains("peser") {
            return .measure
        }
        
        // Peel
        if lowercased.contains("peel") || lowercased.contains("éplucher") {
            return .peel
        }
        
        // Grate
        if lowercased.contains("grate") || lowercased.contains("shred") ||
           lowercased.contains("râper") {
            return .grate
        }
        
        return .other
    }
}

/// A single preparation item (ingredient + action)
struct PrepItem: Identifiable, Codable {
    let id: UUID
    let ingredientName: String
    let quantity: String
    let action: String  // "sliced", "diced", "grated", etc.
    let recipeTitle: String
    let recipeId: String
    
    init(id: UUID = UUID(), ingredientName: String, quantity: String, action: String, recipeTitle: String, recipeId: String) {
        self.id = id
        self.ingredientName = ingredientName
        self.quantity = quantity
        self.action = action
        self.recipeTitle = recipeTitle
        self.recipeId = recipeId
    }
}

/// A section grouping preparation items by action type
struct ActionBasedPrepSection: Identifiable, Codable {
    let id: UUID
    let actionType: PrepActionType
    let estimatedMinutes: Int
    let items: [PrepItem]
    let usedInRecipeCount: Int
    let usedInRecipeTitles: [String]
    
    init(id: UUID = UUID(), actionType: PrepActionType, estimatedMinutes: Int, items: [PrepItem], usedInRecipeCount: Int, usedInRecipeTitles: [String]) {
        self.id = id
        self.actionType = actionType
        self.estimatedMinutes = estimatedMinutes
        self.items = items
        self.usedInRecipeCount = usedInRecipeCount
        self.usedInRecipeTitles = usedInRecipeTitles
    }
}

// MARK: - MealPrepKit Extension for Action-Based Prep

extension MealPrepKit {
    /// Transform grouped prep steps into action-based sections for the new UX
    func buildActionBasedPrep() -> [ActionBasedPrepSection] {
        guard let groupedSteps = self.groupedPrepSteps, !groupedSteps.isEmpty else {
            return []
        }
        
        // Step 1: Group by detected action type
        var actionGroups: [PrepActionType: [PrepItem]] = [:]
        
        for step in groupedSteps {
            // Detect action type from the step's actionType field
            let detectedAction = PrepActionType.detect(from: step.actionType)
            
            // Convert ingredients to PrepItems
            for ingredient in step.ingredients {
                // Try to extract specific action from detailed steps or usage
                var specificAction = ""
                
                // Look in detailed steps for specific action words
                for detailStep in step.detailedSteps {
                    let lowercased = detailStep.lowercased()
                    if lowercased.contains(ingredient.name.lowercased()) {
                        // Extract action (sliced, diced, etc.)
                        if lowercased.contains("slice") || lowercased.contains("tranch") {
                            specificAction = "sliced"
                        } else if lowercased.contains("dice") || lowercased.contains("dé") {
                            specificAction = "diced"
                        } else if lowercased.contains("chop") || lowercased.contains("hach") {
                            specificAction = "chopped"
                        } else if lowercased.contains("mince") || lowercased.contains("éminc") {
                            specificAction = "minced"
                        } else if lowercased.contains("grat") || lowercased.contains("râp") {
                            specificAction = "grated"
                        } else if lowercased.contains("peel") || lowercased.contains("épluch") {
                            specificAction = "peeled"
                        }
                        break
                    }
                }
                
                // Fallback to generic action name
                if specificAction.isEmpty {
                    specificAction = step.actionType.lowercased()
                }
                
                let prepItem = PrepItem(
                    ingredientName: ingredient.name,
                    quantity: ingredient.quantity,
                    action: specificAction,
                    recipeTitle: ingredient.recipeTitle,
                    recipeId: ingredient.recipeId
                )
                
                if actionGroups[detectedAction] == nil {
                    actionGroups[detectedAction] = []
                }
                actionGroups[detectedAction]?.append(prepItem)
            }
        }
        
        // Step 2: For non-separable actions, group by recipe first
        // For separable actions, consolidate across recipes
        var consolidatedGroups: [PrepActionType: [PrepItem]] = [:]
        var recipeSpecificSections: [(actionType: PrepActionType, recipeTitle: String, items: [PrepItem])] = []
        
        for (actionType, items) in actionGroups {
            // Check if this action type should be kept separate by recipe
            if !actionType.isSeparable {
                // Group items by recipe
                let itemsByRecipe = Dictionary(grouping: items) { $0.recipeTitle }
                
                // Create a separate sub-section for each recipe
                for (recipeTitle, recipeItems) in itemsByRecipe {
                    recipeSpecificSections.append((
                        actionType: actionType,
                        recipeTitle: recipeTitle,
                        items: recipeItems
                    ))
                }
                continue  // Skip consolidation for non-separable actions
            }
            
            // For separable actions, proceed with normal consolidation
            // First, group by ingredient name only (not action yet)
            var itemsByIngredient: [String: [PrepItem]] = [:]
            
            for item in items {
                let key = item.ingredientName.lowercased()
                if itemsByIngredient[key] == nil {
                    itemsByIngredient[key] = []
                }
                itemsByIngredient[key]?.append(item)
            }
            
            // Consolidate items for each ingredient
            var consolidatedItems: [PrepItem] = []
            
            for (_, ingredientItems) in itemsByIngredient {
                // Group by action within this ingredient
                var itemsByAction: [String: [PrepItem]] = [:]
                
                for item in ingredientItems {
                    let actionKey = item.action.lowercased()
                    if itemsByAction[actionKey] == nil {
                        itemsByAction[actionKey] = []
                    }
                    itemsByAction[actionKey]?.append(item)
                }
                
                // If only one action type for this ingredient, consolidate quantities
                if itemsByAction.count == 1, let (_, items) = itemsByAction.first {
                    let firstItem = items[0]
                    
                    // Try to sum numeric quantities
                    var totalQuantity: Double = 0
                    var unit: String = ""
                    var canSum = true
                    
                    for item in items {
                        // Parse quantity like "2 unit", "3 gousses", etc.
                        let components = item.quantity.split(separator: " ", maxSplits: 1)
                        if let quantityStr = components.first,
                           let quantity = Double(quantityStr) {
                            totalQuantity += quantity
                            if unit.isEmpty && components.count > 1 {
                                unit = String(components[1])
                            }
                        } else {
                            // Can't parse - fall back to joining
                            canSum = false
                            break
                        }
                    }
                    
                    let consolidatedQuantity: String
                    if canSum && totalQuantity > 0 {
                        // Format the summed quantity
                        let formattedQuantity = totalQuantity.truncatingRemainder(dividingBy: 1) == 0 
                            ? String(format: "%.0f", totalQuantity)
                            : String(format: "%.1f", totalQuantity)
                        consolidatedQuantity = unit.isEmpty ? formattedQuantity : "\(formattedQuantity) \(unit)"
                    } else {
                        // Fall back to joining
                        consolidatedQuantity = items.map { $0.quantity }.joined(separator: " + ")
                    }
                    
                    // Collect unique recipe titles
                    let allRecipeTitles = items.map { $0.recipeTitle }
                    let uniqueRecipeTitles = Array(Set(allRecipeTitles))
                    let consolidatedRecipeTitle = uniqueRecipeTitles.joined(separator: ", ")
                    
                    let consolidatedItem = PrepItem(
                        id: firstItem.id,
                        ingredientName: firstItem.ingredientName,
                        quantity: consolidatedQuantity,
                        action: firstItem.action,
                        recipeTitle: consolidatedRecipeTitle,
                        recipeId: items.map { $0.recipeId }.joined(separator: ",")
                    )
                    
                    consolidatedItems.append(consolidatedItem)
                }
                // Multiple actions for same ingredient - show breakdown
                else if itemsByAction.count > 1 {
                    // Create a master item showing all actions
                    let allItems = itemsByAction.values.flatMap { $0 }
                    let firstItem = allItems[0]
                    
                    // Calculate total quantity across all actions
                    var totalQuantity: Double = 0
                    var unit: String = ""
                    var canCalculateTotal = true
                    
                    for item in allItems {
                        let components = item.quantity.split(separator: " ", maxSplits: 1)
                        if let quantityStr = components.first,
                           let quantity = Double(quantityStr) {
                            totalQuantity += quantity
                            if unit.isEmpty && components.count > 1 {
                                unit = String(components[1])
                            }
                        } else {
                            canCalculateTotal = false
                        }
                    }
                    
                    // Build breakdown by action
                    var actionBreakdowns: [String] = []
                    for (action, items) in itemsByAction.sorted(by: { $0.key < $1.key }) {
                        var actionTotal: Double = 0
                        var actionUnit = ""
                        var canSumAction = true
                        
                        for item in items {
                            let components = item.quantity.split(separator: " ", maxSplits: 1)
                            if let quantityStr = components.first,
                               let quantity = Double(quantityStr) {
                                actionTotal += quantity
                                if actionUnit.isEmpty && components.count > 1 {
                                    actionUnit = String(components[1])
                                }
                            } else {
                                canSumAction = false
                                break
                            }
                        }
                        
                        if canSumAction && actionTotal > 0 {
                            let formattedQuantity = actionTotal.truncatingRemainder(dividingBy: 1) == 0
                                ? String(format: "%.0f", actionTotal)
                                : String(format: "%.1f", actionTotal)
                            actionBreakdowns.append("\(formattedQuantity) \(action)")
                        } else {
                            actionBreakdowns.append(items.map { "\($0.quantity) \($0.action)" }.joined(separator: ", "))
                        }
                    }
                    
                    // Format: "4 units (2 diced, 2 sliced)"
                    let formattedTotal = canCalculateTotal && totalQuantity > 0
                        ? (totalQuantity.truncatingRemainder(dividingBy: 1) == 0 
                            ? String(format: "%.0f", totalQuantity)
                            : String(format: "%.1f", totalQuantity))
                        : ""
                    
                    let consolidatedQuantity: String
                    if !formattedTotal.isEmpty && !unit.isEmpty {
                        consolidatedQuantity = "\(formattedTotal) \(unit) (\(actionBreakdowns.joined(separator: ", ")))"
                    } else {
                        consolidatedQuantity = actionBreakdowns.joined(separator: ", ")
                    }
                    
                    // Collect unique recipe titles
                    let allRecipeTitles = allItems.map { $0.recipeTitle }
                    let uniqueRecipeTitles = Array(Set(allRecipeTitles))
                    let consolidatedRecipeTitle = uniqueRecipeTitles.joined(separator: ", ")
                    
                    let consolidatedItem = PrepItem(
                        id: firstItem.id,
                        ingredientName: firstItem.ingredientName,
                        quantity: consolidatedQuantity,
                        action: "", // No single action when multiple
                        recipeTitle: consolidatedRecipeTitle,
                        recipeId: allItems.map { $0.recipeId }.joined(separator: ",")
                    )
                    
                    consolidatedItems.append(consolidatedItem)
                }
            }
            
            consolidatedGroups[actionType] = consolidatedItems
        }
        
        // Step 3: Build sections from consolidated groups (separable actions)
        var sections: [ActionBasedPrepSection] = []
        
        for (actionType, items) in consolidatedGroups {
            // Calculate unique recipes
            let allRecipeIds = items.flatMap { $0.recipeId.split(separator: ",").map(String.init) }
            let uniqueRecipeIds = Set(allRecipeIds)
            
            let allRecipeTitles = items.flatMap { $0.recipeTitle.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
            let uniqueRecipeTitles = Array(Set(allRecipeTitles))
            
            // Estimate time (2 min per unique item, max 30 min)
            let estimatedTime = min(30, max(5, items.count * 2))
            
            // Generate stable UUID based on actionType and kit.id using namespace UUID approach
            // This ensures the same section always gets the same ID
            let namespace = self.id.uuidString
            let name = actionType.rawValue
            let combinedString = "\(namespace)-\(name)"
            
            // Create a stable hash-based UUID
            var hasher = Hasher()
            hasher.combine(combinedString)
            let hash = abs(hasher.finalize())
            
            // Convert hash to UUID format
            let uuidString = String(format: "%08x-%04x-%04x-%04x-%012x",
                                   (hash >> 96) & 0xFFFFFFFF,
                                   (hash >> 80) & 0xFFFF,
                                   (hash >> 64) & 0xFFFF,
                                   (hash >> 48) & 0xFFFF,
                                   hash & 0xFFFFFFFFFFFF)
            
            let stableId = UUID(uuidString: uuidString) ?? UUID()
            
            let section = ActionBasedPrepSection(
                id: stableId,
                actionType: actionType,
                estimatedMinutes: estimatedTime,
                items: items,
                usedInRecipeCount: uniqueRecipeIds.count,
                usedInRecipeTitles: uniqueRecipeTitles
            )
            
            sections.append(section)
        }
        
        // Step 4: Build sections for recipe-specific (non-separable) actions
        for recipeSpecific in recipeSpecificSections {
            // Estimate time (2 min per item, max 20 min per recipe)
            let estimatedTime = min(20, max(3, recipeSpecific.items.count * 2))
            
            // Generate stable UUID for this action+recipe combination
            let namespace = self.id.uuidString
            let name = "\(recipeSpecific.actionType.rawValue)-\(recipeSpecific.recipeTitle)"
            let combinedString = "\(namespace)-\(name)"
            
            var hasher = Hasher()
            hasher.combine(combinedString)
            let hash = abs(hasher.finalize())
            
            let uuidString = String(format: "%08x-%04x-%04x-%04x-%012x",
                                   (hash >> 96) & 0xFFFFFFFF,
                                   (hash >> 80) & 0xFFFF,
                                   (hash >> 64) & 0xFFFF,
                                   (hash >> 48) & 0xFFFF,
                                   hash & 0xFFFFFFFFFFFF)
            
            let stableId = UUID(uuidString: uuidString) ?? UUID()
            
            let section = ActionBasedPrepSection(
                id: stableId,
                actionType: recipeSpecific.actionType,
                estimatedMinutes: estimatedTime,
                items: recipeSpecific.items,
                usedInRecipeCount: 1,  // Always 1 since it's recipe-specific
                usedInRecipeTitles: [recipeSpecific.recipeTitle]
            )
            
            sections.append(section)
        }
        
        // Step 5: Sort by priority (chop first, then others)
        sections.sort { $0.actionType.sortOrder < $1.actionType.sortOrder }
        
        return sections
    }
}

// MARK: - MealPrepKit Extension - Portion Management Logic

enum MealPrepError: LocalizedError {
    case insufficientPortions(requested: Int, available: Int)
    case insufficientRecipePortions(recipeTitle: String, requested: Int, available: Int)
    case assignmentNotFound
    
    var errorDescription: String? {
        switch self {
        case .insufficientPortions(let requested, let available):
            return String(format: NSLocalizedString("mealprep.error.insufficient_portions", comment: ""), requested, available)
        case .insufficientRecipePortions(let title, let requested, let available):
            return String(format: NSLocalizedString("mealprep.error.insufficient_recipe_portions", comment: ""), title, requested, available)
        case .assignmentNotFound:
            return NSLocalizedString("mealprep.error.assignment_not_found", comment: "")
        }
    }
}

extension MealPrepKit {
    /// Vérifie si on peut assigner X portions
    func canAssign(portions: Int) -> Bool {
        return remainingPortions >= portions
    }
    
    /// Assigne des portions à un jour donné
    mutating func assignPortions(
        date: Date,
        mealType: MealType,
        portions: Int,
        specificRecipeId: String? = nil
    ) throws -> MealPrepAssignment {
        // Validation
        guard canAssign(portions: portions) else {
            throw MealPrepError.insufficientPortions(
                requested: portions,
                available: remainingPortions
            )
        }
        
        // Si on spécifie une recette, vérifier ses portions
        var specificRecipeTitle: String? = nil
        if let recipeId = specificRecipeId {
            if let recipeIndex = recipePortions?.firstIndex(where: { $0.recipeId == recipeId }) {
                let tracker = recipePortions![recipeIndex]
                guard tracker.remainingPortions >= portions else {
                    throw MealPrepError.insufficientRecipePortions(
                        recipeTitle: tracker.recipeTitle,
                        requested: portions,
                        available: tracker.remainingPortions
                    )
                }
                // Décrémenter les portions de cette recette
                recipePortions![recipeIndex].remainingPortions -= portions
                specificRecipeTitle = tracker.recipeTitle
            }
        }
        
        // Créer l'assignment
        let assignment = MealPrepAssignment(
            mealPrepKitId: self.id,
            date: date,
            mealType: mealType,
            portionsUsed: portions,
            specificRecipeId: specificRecipeId,
            specificRecipeTitle: specificRecipeTitle
        )
        
        // Décrémenter les portions globales
        remainingPortions -= portions
        
        // Ajouter à l'historique
        assignments.append(assignment)
        
        return assignment
    }
    
    /// Annule une assignation
    mutating func unassign(_ assignmentId: UUID) throws {
        guard let index = assignments.firstIndex(where: { $0.id == assignmentId }) else {
            throw MealPrepError.assignmentNotFound
        }
        
        let assignment = assignments[index]
        
        // Restituer les portions globales
        remainingPortions += assignment.portionsUsed
        
        // Restituer les portions de la recette si applicable
        if let recipeId = assignment.specificRecipeId,
           let recipeIndex = recipePortions?.firstIndex(where: { $0.recipeId == recipeId }) {
            recipePortions![recipeIndex].remainingPortions += assignment.portionsUsed
        }
        
        // Retirer l'assignment
        assignments.remove(at: index)
    }
    
    // MARK: - Expiration Management (Bonus)
    
    /// Date d'expiration basée sur la recette avec le plus court shelf life
    var expirationDate: Date? {
        guard let minShelfLife = recipes.map({ $0.shelfLifeDays }).min() else {
            return nil
        }
        return Calendar.current.date(byAdding: .day, value: minShelfLife, to: preparedDate)
    }
    
    /// Est-ce que le meal prep est expiré ?
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
    
    /// Jours restants avant expiration
    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }
    
    /// Badge de warning si proche de l'expiration
    var expirationWarning: String? {
        guard let days = daysUntilExpiration else { return nil }
        
        if days < 0 {
            return NSLocalizedString("mealprep.expired", comment: "")
        } else if days == 0 {
            return NSLocalizedString("mealprep.expires_today", comment: "")
        } else if days == 1 {
            return NSLocalizedString("mealprep.expires_tomorrow", comment: "")
        } else if days <= 2 {
            return String(format: NSLocalizedString("mealprep.expires_in_days", comment: ""), days)
        }
        
        return nil
    }
}
