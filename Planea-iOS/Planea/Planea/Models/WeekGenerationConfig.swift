import Foundation

// MARK: - Day Meal Type

enum DayMealType: String, Codable, CaseIterable {
    case normal
    case mealPrep
    case skip  // Jour non sélectionné
    
    var displayName: String {
        switch self {
        case .normal:
            return NSLocalizedString("wizard.day_type.normal", comment: "")
        case .mealPrep:
            return NSLocalizedString("wizard.day_type.mealprep", comment: "")
        case .skip:
            return NSLocalizedString("wizard.day_type.skip", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .normal:
            return "fork.knife"
        case .mealPrep:
            return "takeoutbag.and.cup.and.straw"
        case .skip:
            return "minus.circle"
        }
    }
}

// MARK: - Day Configuration

struct DayConfig: Identifiable, Equatable {
    let id = UUID()
    let weekday: Weekday
    var mealType: DayMealType
    var selected: Bool
    
    static func == (lhs: DayConfig, rhs: DayConfig) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Meal Prep Meal Type Selection

enum MealPrepMealTypeSelection: String, CaseIterable {
    case lunch
    case dinner
    case both
    
    var displayName: String {
        switch self {
        case .lunch:
            return NSLocalizedString("wizard.mealprep_type.lunch", comment: "")
        case .dinner:
            return NSLocalizedString("wizard.mealprep_type.dinner", comment: "")
        case .both:
            return NSLocalizedString("wizard.mealprep_type.both", comment: "")
        }
    }
    
    var mealTypes: Set<MealType> {
        switch self {
        case .lunch:
            return [.lunch]
        case .dinner:
            return [.dinner]
        case .both:
            return [.lunch, .dinner]
        }
    }
}

// MARK: - Week Generation Configuration

struct WeekGenerationConfig {
    var days: [DayConfig]
    
    // Meal Prep config
    var familySize: Int
    var mealPrepPortions: Int  // Auto-calculé mais modifiable
    var mealPrepMealTypeSelection: MealPrepMealTypeSelection = .both
    
    // Preferences (optional)
    var preferences: GenerationPreferences
    
    // Start date
    var startDate: Date
    
    // MARK: - Computed Properties
    
    var mealPrepDays: [Weekday] {
        days.filter { $0.selected && $0.mealType == .mealPrep }
            .map { $0.weekday }
    }
    
    var normalDays: [Weekday] {
        days.filter { $0.selected && $0.mealType == .normal }
            .map { $0.weekday }
    }
    
    var selectedDays: [Weekday] {
        days.filter { $0.selected }
            .map { $0.weekday }
    }
    
    var hasMealPrep: Bool {
        !mealPrepDays.isEmpty
    }
    
    var hasNormalDays: Bool {
        !normalDays.isEmpty
    }
    
    var mealPrepMealTypes: Set<MealType> {
        mealPrepMealTypeSelection.mealTypes
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        // Au moins un jour sélectionné
        return !selectedDays.isEmpty
    }
    
    func canProceedFromStep(_ step: Int) -> Bool {
        switch step {
        case 0:
            // Step 1: Au moins un jour sélectionné
            return !selectedDays.isEmpty
        case 1:
            // Step 2: Meal prep config (si applicable)
            if hasMealPrep {
                return mealPrepPortions > 0
            }
            return true
        case 2:
            // Step 3: Preferences (toujours OK)
            return true
        default:
            return false
        }
    }
    
    // MARK: - Auto-calculation
    
    mutating func recalculateMealPrepPortions() {
        let daysCount = mealPrepDays.count
        let mealsPerDay = mealPrepMealTypes.count
        mealPrepPortions = daysCount * familySize * mealsPerDay
    }
    
    // MARK: - Factory
    
    static func `default`(familySize: Int, weekStartDay: Weekday) -> WeekGenerationConfig {
        // Create days starting from weekStartDay
        let orderedWeekdays = Weekday.allCases.sorted { lhs, rhs in
            let lhsIndex = (Weekday.allCases.firstIndex(of: lhs)! - Weekday.allCases.firstIndex(of: weekStartDay)! + 7) % 7
            let rhsIndex = (Weekday.allCases.firstIndex(of: rhs)! - Weekday.allCases.firstIndex(of: weekStartDay)! + 7) % 7
            return lhsIndex < rhsIndex
        }
        
        let days = orderedWeekdays.map { weekday in
            DayConfig(weekday: weekday, mealType: .normal, selected: true)
        }
        
        let startDate = Date() // Will be adjusted based on weekStartDay
        
        return WeekGenerationConfig(
            days: days,
            familySize: familySize,
            mealPrepPortions: 0,
            mealPrepMealTypeSelection: .both,
            preferences: PreferencesService.shared.loadPreferences(),
            startDate: startDate
        )
    }
}
