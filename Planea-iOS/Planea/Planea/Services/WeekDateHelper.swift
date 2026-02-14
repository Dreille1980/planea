import Foundation

/// Helper utilities for working with week dates and converting between templates and planned weeks
struct WeekDateHelper {
    
    // MARK: - Date Generation
    
    /// Generate 7 consecutive dates starting from startDate
    /// - Parameter startDate: The first day of the week
    /// - Returns: Array of 7 consecutive dates
    static func generateWeekDates(from startDate: Date) -> [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startDate)
        }
    }
    
    /// Get the next occurrence of a specific weekday
    /// - Parameters:
    ///   - weekday: The weekday to find (1=Sunday, 2=Monday, ..., 7=Saturday)
    ///   - date: Starting date (defaults to today)
    /// - Returns: Next occurrence of that weekday
    static func nextWeekday(_ weekday: Int, from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = weekday
        
        guard let nextDate = calendar.nextDate(
            after: date,
            matching: components,
            matchingPolicy: .nextTime
        ) else {
            return date
        }
        
        return nextDate
    }
    
    /// Get next Sunday (default week start)
    /// - Parameter date: Starting date (defaults to today)
    /// - Returns: Next Sunday at midnight
    static func nextSunday(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        
        // If today is Sunday, return today
        let todayWeekday = calendar.component(.weekday, from: startOfToday)
        if todayWeekday == 1 {
            return startOfToday
        }
        
        // Otherwise, find next Sunday
        return nextWeekday(1, from: startOfToday)
    }
    
    /// Get today at midnight
    /// - Returns: Today's date at 00:00:00
    static func todayAtMidnight() -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }
    
    // MARK: - Weekday Conversion
    
    /// Convert Weekday enum to weekdayIndex (0-6)
    /// - Parameter weekday: The Weekday enum
    /// - Returns: Index (0=Sunday, 1=Monday, ..., 6=Saturday)
    static func weekdayToIndex(_ weekday: Weekday) -> Int {
        switch weekday {
        case .sunday: return 0
        case .monday: return 1
        case .tuesday: return 2
        case .wednesday: return 3
        case .thursday: return 4
        case .friday: return 5
        case .saturday: return 6
        }
    }
    
    /// Convert weekdayIndex to Weekday enum
    /// - Parameter index: Index (0-6)
    /// - Returns: Corresponding Weekday enum
    static func indexToWeekday(_ index: Int) -> Weekday {
        switch index {
        case 0: return .sunday
        case 1: return .monday
        case 2: return .tuesday
        case 3: return .wednesday
        case 4: return .thursday
        case 5: return .friday
        case 6: return .saturday
        default: return .monday
        }
    }
    
    /// Get weekday index from a Date (0=Sunday, 1=Monday, ..., 6=Saturday)
    /// - Parameter date: The date to analyze
    /// - Returns: Weekday index (0-6)
    static func weekdayIndex(from date: Date) -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        return weekday - 1  // Convert from 1-7 to 0-6
    }
    
    // MARK: - Formatting
    
    /// Format week range string (e.g., "March 11 – March 17")
    /// - Parameter startDate: Start date of the week
    /// - Returns: Formatted string showing week range
    static func formatWeekRange(startDate: Date) -> String {
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        
        return "\(startString) – \(endString)"
    }
    
    // MARK: - Template Application
    
    /// Apply a TemplateWeek to a specific start date to create a PlannedWeek
    /// - Parameters:
    ///   - template: The template to apply
    ///   - startDate: The start date for the planned week
    /// - Returns: A new PlannedWeek with real dates
    static func applyTemplate(_ template: TemplateWeek, to startDate: Date) -> PlannedWeek {
        // Generate 7 dates starting from startDate
        let weekDates = generateWeekDates(from: startDate)
        
        // Convert template days to planned days
        let plannedDays: [PlannedDay] = template.days.compactMap { templateDay in
            // Validate weekdayIndex
            guard templateDay.weekdayIndex >= 0 && templateDay.weekdayIndex < 7 else {
                print("⚠️ Invalid weekdayIndex: \(templateDay.weekdayIndex)")
                return nil
            }
            
            let date = weekDates[templateDay.weekdayIndex]
            
            // Convert template meals to planned meals
            let plannedMeals = templateDay.meals.map { templateMeal in
                PlannedMeal(
                    id: UUID(),  // Generate new ID for each meal
                    mealType: templateMeal.mealType,
                    recipe: templateMeal.recipe
                )
            }
            
            return PlannedDay(
                id: UUID(),
                date: date,
                meals: plannedMeals
            )
        }
        
        // Sort days by date to ensure chronological order
        let sortedDays = plannedDays.sorted { $0.date < $1.date }
        
        // Create and return PlannedWeek
        return PlannedWeek(
            id: UUID(),
            familyId: template.familyId,
            startDate: startDate,
            days: sortedDays,
            status: .draft,
            confirmedDate: nil,
            name: nil,
            sourceTemplateId: template.id
        )
    }
    
    // MARK: - Validation
    
    /// Check if a date is in the past (before today)
    /// - Parameter date: Date to check
    /// - Returns: True if date is before today
    static func isInPast(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let comparisonDate = calendar.startOfDay(for: date)
        return comparisonDate < today
    }
    
    /// Check if weekdayIndex is valid (0-6)
    /// - Parameter index: Index to validate
    /// - Returns: True if valid
    static func isValidWeekdayIndex(_ index: Int) -> Bool {
        return index >= 0 && index <= 6
    }
}
