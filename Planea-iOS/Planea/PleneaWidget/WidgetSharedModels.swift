//
//  WidgetSharedModels.swift
//  PleneaWidget
//
//  Shared models between the app and widget
//

import Foundation

// MARK: - Widget-specific simplified models

struct WidgetMealItem: Identifiable, Codable {
    let id: UUID
    let weekday: String  // Raw value from Weekday enum
    let mealType: String // Raw value from MealType enum
    let recipeTitle: String
    let recipeServings: Int
    let recipeTotalMinutes: Int
    
    // Helper computed properties
    var weekdayEnum: WidgetWeekday? {
        WidgetWeekday(rawValue: weekday)
    }
    
    var mealTypeEnum: WidgetMealType? {
        WidgetMealType(rawValue: mealType)
    }
}

enum WidgetWeekday: String, Codable {
    case monday = "Mon"
    case tuesday = "Tue"
    case wednesday = "Wed"
    case thursday = "Thu"
    case friday = "Fri"
    case saturday = "Sat"
    case sunday = "Sun"
    
    var displayName: String {
        switch self {
        case .monday: return "Lundi"
        case .tuesday: return "Mardi"
        case .wednesday: return "Mercredi"
        case .thursday: return "Jeudi"
        case .friday: return "Vendredi"
        case .saturday: return "Samedi"
        case .sunday: return "Dimanche"
        }
    }
}

enum WidgetMealType: String, Codable {
    case breakfast = "BREAKFAST"
    case lunch = "LUNCH"
    case dinner = "DINNER"
    case snack = "SNACK"
    
    var sortOrder: Int {
        switch self {
        case .breakfast: return 0
        case .lunch: return 1
        case .snack: return 2
        case .dinner: return 3
        }
    }
    
    var displayName: String {
        switch self {
        case .breakfast: return "Déjeuner"
        case .lunch: return "Dîner"
        case .dinner: return "Souper"
        case .snack: return "Collation"
        }
    }
}

// MARK: - Helper for date calculations

extension Date {
    var weekdayString: String {
        let weekday = Calendar.current.component(.weekday, from: self)
        switch weekday {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return "Mon"
        }
    }
    
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    func dayName(relativeTo today: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Aujourd'hui"
        } else if calendar.isDateInTomorrow(self) {
            return "Demain"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "fr_CA")
            formatter.dateFormat = "EEEE"
            return formatter.string(from: self).capitalized
        }
    }
}
