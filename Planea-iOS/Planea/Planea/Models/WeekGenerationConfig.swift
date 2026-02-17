import Foundation

// MARK: - Slot Type (Simple vs Meal Prep)

enum SlotType: String, Codable, CaseIterable {
    case simple     // Recette individuelle à cuisiner le jour même
    case mealPrep   // Fait partie du batch meal prep (préparé à l'avance)
    
    var displayName: String {
        switch self {
        case .simple:
            return NSLocalizedString("wizard.slot_type.simple", comment: "")
        case .mealPrep:
            return NSLocalizedString("wizard.slot_type.mealprep", comment: "")
        }
    }
    
    var icon: String {
        switch self {
        case .simple:
            return "fork.knife"
        case .mealPrep:
            return "takeoutbag.and.cup.and.straw"
        }
    }
}

// MARK: - Meal Slot Configuration (granular per meal)

struct MealSlotConfig: Identifiable, Equatable, Codable {
    let id: UUID
    let weekday: Weekday
    let mealType: MealType  // .lunch ou .dinner
    var slotType: SlotType  // .simple ou .mealPrep
    var selected: Bool
    
    init(weekday: Weekday, mealType: MealType, slotType: SlotType = .simple, selected: Bool = true) {
        self.id = UUID()
        self.weekday = weekday
        self.mealType = mealType
        self.slotType = slotType
        self.selected = selected
    }
    
    static func == (lhs: MealSlotConfig, rhs: MealSlotConfig) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Day Meal Type (Legacy - kept for compatibility)

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

// MARK: - Day Configuration (Legacy - kept for compatibility)

struct DayConfig: Identifiable, Equatable {
    let id = UUID()
    let weekday: Weekday
    var mealType: DayMealType
    var selected: Bool
    var normalDayMealSelection: NormalDayMealTypeSelection
    
    static func == (lhs: DayConfig, rhs: DayConfig) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Normal Day Meal Type Selection (Legacy)

enum NormalDayMealTypeSelection: String, CaseIterable {
    case lunch
    case dinner
    case both
    
    var displayName: String {
        switch self {
        case .lunch:
            return NSLocalizedString("wizard.normal_type.lunch", comment: "")
        case .dinner:
            return NSLocalizedString("wizard.normal_type.dinner", comment: "")
        case .both:
            return NSLocalizedString("wizard.normal_type.both", comment: "")
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

// MARK: - Meal Prep Meal Type Selection (Legacy)

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
    // New granular meal slots
    var mealSlots: [MealSlotConfig]
    
    // Legacy days (kept for compatibility)
    var days: [DayConfig]
    
    // Meal Prep config
    var familySize: Int
    var mealPrepPortions: Int  // Auto-calculé mais modifiable
    var mealPrepMealTypeSelection: MealPrepMealTypeSelection = .both
    
    // Preferences (optional)
    var preferences: GenerationPreferences
    
    // Start date
    var startDate: Date
    
    // MARK: - Computed Properties (New - Granular)
    
    /// All selected meal slots
    var selectedSlots: [MealSlotConfig] {
        mealSlots.filter { $0.selected }
    }
    
    /// Meal prep slots only
    var mealPrepSlots: [MealSlotConfig] {
        selectedSlots.filter { $0.slotType == .mealPrep }
    }
    
    /// Simple recipe slots only
    var simpleSlots: [MealSlotConfig] {
        selectedSlots.filter { $0.slotType == .simple }
    }
    
    /// Check if there are any meal prep slots
    var hasMealPrepSlots: Bool {
        !mealPrepSlots.isEmpty
    }
    
    /// Count of meal prep slots
    var mealPrepSlotsCount: Int {
        mealPrepSlots.count
    }
    
    /// Count of simple slots
    var simpleSlotsCount: Int {
        simpleSlots.count
    }
    
    /// Total selected slots count
    var selectedSlotsCount: Int {
        selectedSlots.count
    }
    
    // MARK: - Computed Properties (Legacy - for compatibility)
    
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
        hasMealPrepSlots
    }
    
    var hasNormalDays: Bool {
        !normalDays.isEmpty
    }
    
    var mealPrepMealTypes: Set<MealType> {
        mealPrepMealTypeSelection.mealTypes
    }
    
    // Legacy computed properties
    var mealPrepDaysCount: Int {
        mealPrepDays.count
    }
    
    var normalDaysCount: Int {
        normalDays.count
    }
    
    var selectedDaysCount: Int {
        selectedDays.count
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        // Au moins un slot sélectionné
        return !selectedSlots.isEmpty
    }
    
    func canProceedFromStep(_ step: Int) -> Bool {
        switch step {
        case 0:
            // Step 1: Au moins un slot sélectionné
            return !selectedSlots.isEmpty
        case 1:
            // Step 2: Meal prep config (si applicable)
            if hasMealPrepSlots {
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
        // Calculate based on meal prep slots count and family size
        mealPrepPortions = mealPrepSlotsCount * familySize
    }
    
    // MARK: - Slot Management
    
    mutating func toggleSlot(at index: Int) {
        guard index < mealSlots.count else { return }
        mealSlots[index].selected.toggle()
        recalculateMealPrepPortions()
    }
    
    mutating func setSlotType(at index: Int, to type: SlotType) {
        guard index < mealSlots.count else { return }
        mealSlots[index].slotType = type
        recalculateMealPrepPortions()
    }
    
    /// Get slot for specific weekday and meal type
    func slot(for weekday: Weekday, mealType: MealType) -> MealSlotConfig? {
        mealSlots.first { $0.weekday == weekday && $0.mealType == mealType }
    }
    
    /// Get index of slot for specific weekday and meal type
    func slotIndex(for weekday: Weekday, mealType: MealType) -> Int? {
        mealSlots.firstIndex { $0.weekday == weekday && $0.mealType == mealType }
    }
    
    // MARK: - Factory
    
    static func `default`(familySize: Int, weekStartDay: Weekday) -> WeekGenerationConfig {
        // Create days starting from weekStartDay
        let orderedWeekdays = Weekday.allCases.sorted { lhs, rhs in
            let lhsIndex = (Weekday.allCases.firstIndex(of: lhs)! - Weekday.allCases.firstIndex(of: weekStartDay)! + 7) % 7
            let rhsIndex = (Weekday.allCases.firstIndex(of: rhs)! - Weekday.allCases.firstIndex(of: weekStartDay)! + 7) % 7
            return lhsIndex < rhsIndex
        }
        
        // Create granular meal slots (lunch and dinner for each day)
        var mealSlots: [MealSlotConfig] = []
        for weekday in orderedWeekdays {
            mealSlots.append(MealSlotConfig(weekday: weekday, mealType: .lunch, slotType: .simple, selected: true))
            mealSlots.append(MealSlotConfig(weekday: weekday, mealType: .dinner, slotType: .simple, selected: true))
        }
        
        // Legacy days
        let days = orderedWeekdays.map { weekday in
            DayConfig(
                weekday: weekday,
                mealType: .normal,
                selected: true,
                normalDayMealSelection: .both
            )
        }
        
        let startDate = Date()
        
        return WeekGenerationConfig(
            mealSlots: mealSlots,
            days: days,
            familySize: familySize,
            mealPrepPortions: 0,
            mealPrepMealTypeSelection: .both,
            preferences: PreferencesService.shared.loadPreferences(),
            startDate: startDate
        )
    }
}
