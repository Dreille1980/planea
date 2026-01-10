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
        
        // Step 2: Consolidate duplicate ingredients within each action group
        var consolidatedGroups: [PrepActionType: [PrepItem]] = [:]
        
        for (actionType, items) in actionGroups {
            // Group by ingredient name + action
            var itemsByKey: [String: [PrepItem]] = [:]
            
            for item in items {
                let key = "\(item.ingredientName.lowercased())_\(item.action.lowercased())"
                if itemsByKey[key] == nil {
                    itemsByKey[key] = []
                }
                itemsByKey[key]?.append(item)
            }
            
            // Consolidate items with same key
            var consolidatedItems: [PrepItem] = []
            
            for (_, duplicates) in itemsByKey {
                if duplicates.count == 1 {
                    // No duplicates, keep as is
                    consolidatedItems.append(duplicates[0])
                } else {
                    // Multiple occurrences - consolidate
                    let firstItem = duplicates[0]
                    
                    // Collect all quantities
                    let quantities = duplicates.map { $0.quantity }
                    
                    // Collect all recipe titles
                    let allRecipeTitles = duplicates.map { $0.recipeTitle }
                    let uniqueRecipeTitles = Array(Set(allRecipeTitles))
                    
                    // Create consolidated quantity string
                    let consolidatedQuantity: String
                    if Set(quantities).count == 1 {
                        // All same quantity - show it once with count
                        consolidatedQuantity = "\(quantities[0]) × \(duplicates.count)"
                    } else {
                        // Different quantities - show sum or list
                        consolidatedQuantity = quantities.joined(separator: " + ")
                    }
                    
                    // Create consolidated recipe title
                    let consolidatedRecipeTitle = uniqueRecipeTitles.joined(separator: ", ")
                    
                    let consolidatedItem = PrepItem(
                        id: firstItem.id,
                        ingredientName: firstItem.ingredientName,
                        quantity: consolidatedQuantity,
                        action: firstItem.action,
                        recipeTitle: consolidatedRecipeTitle,
                        recipeId: duplicates.map { $0.recipeId }.joined(separator: ",")
                    )
                    
                    consolidatedItems.append(consolidatedItem)
                }
            }
            
            consolidatedGroups[actionType] = consolidatedItems
        }
        
        // Step 3: Build sections from consolidated groups
        var sections: [ActionBasedPrepSection] = []
        
        for (actionType, items) in consolidatedGroups {
            // Calculate unique recipes
            let allRecipeIds = items.flatMap { $0.recipeId.split(separator: ",").map(String.init) }
            let uniqueRecipeIds = Set(allRecipeIds)
            
            let allRecipeTitles = items.flatMap { $0.recipeTitle.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
            let uniqueRecipeTitles = Array(Set(allRecipeTitles))
            
            // Estimate time (2 min per unique item, max 30 min)
            let estimatedTime = min(30, max(5, items.count * 2))
            
            let section = ActionBasedPrepSection(
                actionType: actionType,
                estimatedMinutes: estimatedTime,
                items: items,
                usedInRecipeCount: uniqueRecipeIds.count,
                usedInRecipeTitles: uniqueRecipeTitles
            )
            
            sections.append(section)
        }
        
        // Step 3: Sort by priority (chop first, then others)
        sections.sort { $0.actionType.sortOrder < $1.actionType.sortOrder }
        
        return sections
    }
}
