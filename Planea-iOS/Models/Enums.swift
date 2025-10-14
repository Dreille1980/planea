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
