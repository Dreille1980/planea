import Foundation

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case metric = "METRIC"
    case imperial = "IMPERIAL"
    var id: String { rawValue }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "BREAKFAST"
    case lunch = "LUNCH"
    case dinner = "DINNER"
    case snack = "SNACK"
    var id: String { rawValue }
}

enum Weekday: String, Codable, CaseIterable, Identifiable {
    case monday = "Mon", tuesday = "Tue", wednesday = "Wed", thursday = "Thu", friday = "Fri", saturday = "Sat", sunday = "Sun"
    var id: String { rawValue }
}

enum PreferenceType: String, Codable {
    case diet, dislike, allergen
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, fr, en
    var id: String { rawValue }
    static func currentLocale(_ stored: String) -> String {
        switch AppLanguage(rawValue: stored) ?? .system {
        case .system: return Locale.current.identifier
        case .fr: return "fr"
        case .en: return "en"
        }
    }
}

// MARK: - Generation Preferences (Premium Feature)

enum SpiceLevel: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case mild = "mild"
    case medium = "medium"
    case hot = "hot"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "spice.none".localized
        case .mild: return "spice.mild".localized
        case .medium: return "spice.medium".localized
        case .hot: return "spice.hot".localized
        }
    }
}

enum Appliance: String, Codable, CaseIterable, Identifiable {
    case oven = "oven"
    case bbq = "bbq"
    case airfryer = "airfryer"
    case slowcooker = "slowcooker"
    case instapot = "instapot"
    case microwave = "microwave"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .oven: return "appliance.oven".localized
        case .bbq: return "appliance.bbq".localized
        case .airfryer: return "appliance.airfryer".localized
        case .slowcooker: return "appliance.slowcooker".localized
        case .instapot: return "appliance.instapot".localized
        case .microwave: return "appliance.microwave".localized
        }
    }
    
    var icon: String {
        switch self {
        case .oven: return "oven"
        case .bbq: return "flame"
        case .airfryer: return "fan"
        case .slowcooker: return "timer"
        case .instapot: return "bolt.circle"
        case .microwave: return "wave.3.right"
        }
    }
}

enum Protein: String, Codable, CaseIterable, Identifiable {
    case chicken = "chicken"
    case beef = "beef"
    case pork = "pork"
    case fish = "fish"
    case seafood = "seafood"
    case tofu = "tofu"
    case legumes = "legumes"
    case eggs = "eggs"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .chicken: return "protein.chicken".localized
        case .beef: return "protein.beef".localized
        case .pork: return "protein.pork".localized
        case .fish: return "protein.fish".localized
        case .seafood: return "protein.seafood".localized
        case .tofu: return "protein.tofu".localized
        case .legumes: return "protein.legumes".localized
        case .eggs: return "protein.eggs".localized
        }
    }
}

struct GenerationPreferences: Codable {
    // Time constraints
    var weekdayMaxMinutes: Int
    var weekendMaxMinutes: Int
    
    // Spice level
    var spiceLevel: SpiceLevel
    
    // Preferred proteins
    var preferredProteins: Set<Protein>
    
    // Available appliances
    var availableAppliances: Set<Appliance>
    
    // Kid-friendly option
    var kidFriendly: Bool
    
    // Weekly flyer integration
    var useWeeklyFlyers: Bool
    var postalCode: String
    var preferredGroceryStore: String
    
    static let `default` = GenerationPreferences(
        weekdayMaxMinutes: 30,
        weekendMaxMinutes: 60,
        spiceLevel: .mild,
        preferredProteins: [.chicken, .beef, .fish],
        availableAppliances: [.oven, .microwave],
        kidFriendly: false,
        useWeeklyFlyers: false,
        postalCode: "",
        preferredGroceryStore: ""
    )
    
    func toPromptString() -> String {
        var constraints: [String] = []
        
        // Time constraints - BE VERY EXPLICIT
        constraints.append("IMPORTANT TIMING CONSTRAINTS: Monday through Friday recipes must take NO MORE than \(weekdayMaxMinutes) minutes total cooking time. Saturday and Sunday recipes can take up to \(weekendMaxMinutes) minutes. This is a strict requirement.")
        
        // Spice level
        if spiceLevel != .none {
            constraints.append("Spice level: \(spiceLevel.rawValue)")
        }
        
        // Preferred proteins
        if !preferredProteins.isEmpty {
            let proteins = preferredProteins.map { $0.rawValue }.joined(separator: ", ")
            constraints.append("Preferred proteins: \(proteins)")
        }
        
        // Available appliances
        if !availableAppliances.isEmpty {
            let appliances = availableAppliances.map { $0.rawValue }.joined(separator: ", ")
            constraints.append("Available cooking equipment: \(appliances)")
        }
        
        // Kid-friendly
        if kidFriendly {
            constraints.append("Kid-friendly meals preferred")
        }
        
        return constraints.joined(separator: ". ")
    }
}
