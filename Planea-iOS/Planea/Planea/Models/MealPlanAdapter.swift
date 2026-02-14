import Foundation

/// Adapter to make legacy MealPlan compatible with new PlannedWeek and TemplateWeek architecture
/// This allows backward compatibility without destructive data migration
struct MealPlanAdapter {
    
    // MARK: - Legacy MealPlan → PlannedWeek
    
    /// Convert legacy MealPlan to PlannedWeek with real dates
    /// - Parameter mealPlan: The legacy meal plan
    /// - Returns: A PlannedWeek with calculated real dates
    static func toPlannedWeek(_ mealPlan: MealPlan) -> PlannedWeek {
        let calendar = Calendar.current
        
        // Group items by weekday
        var dayGroups: [Weekday: [MealItem]] = [:]
        for item in mealPlan.items {
            dayGroups[item.weekday, default: []].append(item)
        }
        
        // Create PlannedDays with real dates
        let plannedDays: [PlannedDay] = dayGroups.compactMap { weekday, meals in
            // Calculate actual date based on weekStart and weekday
            let weekdayIndex = WeekDateHelper.weekdayToIndex(weekday)
            guard let date = calendar.date(byAdding: .day, value: weekdayIndex, to: mealPlan.weekStart) else {
                return nil
            }
            
            // Convert MealItems to PlannedMeals
            let plannedMeals = meals.map { mealItem in
                PlannedMeal(
                    id: mealItem.id,
                    mealType: mealItem.mealType,
                    recipe: mealItem.recipe
                )
            }
            
            return PlannedDay(
                id: UUID(),
                date: date,
                meals: plannedMeals
            )
        }
        
        return PlannedWeek(
            id: mealPlan.id,
            familyId: mealPlan.familyId,
            startDate: mealPlan.weekStart,
            days: plannedDays.sorted { $0.date < $1.date },
            status: mealPlan.status,
            confirmedDate: mealPlan.confirmedDate,
            name: mealPlan.name,
            sourceTemplateId: nil
        )
    }
    
    // MARK: - PlannedWeek → Legacy MealPlan
    
    /// Convert PlannedWeek back to legacy MealPlan (for backward compatibility)
    /// - Parameter plannedWeek: The planned week
    /// - Returns: A legacy MealPlan
    static func toMealPlan(_ plannedWeek: PlannedWeek) -> MealPlan {
        // Flatten PlannedDays back to MealItems
        let items: [MealItem] = plannedWeek.days.flatMap { day in
            let weekdayIndex = WeekDateHelper.weekdayIndex(from: day.date)
            let weekday = WeekDateHelper.indexToWeekday(weekdayIndex)
            
            return day.meals.map { plannedMeal in
                MealItem(
                    id: plannedMeal.id,
                    weekday: weekday,
                    mealType: plannedMeal.mealType,
                    recipe: plannedMeal.recipe
                )
            }
        }
        
        return MealPlan(
            id: plannedWeek.id,
            familyId: plannedWeek.familyId,
            weekStart: plannedWeek.startDate,
            items: items,
            status: plannedWeek.status,
            confirmedDate: plannedWeek.confirmedDate,
            name: plannedWeek.name
        )
    }
    
    // MARK: - PlannedWeek → TemplateWeek
    
    /// Convert PlannedWeek to TemplateWeek (save as template)
    /// - Parameters:
    ///   - plannedWeek: The planned week to convert
    ///   - name: Name for the template
    /// - Returns: A new TemplateWeek
    static func toTemplate(_ plannedWeek: PlannedWeek, name: String) -> TemplateWeek {
        let templateDays = plannedWeek.days.map { day in
            let weekdayIndex = WeekDateHelper.weekdayIndex(from: day.date)
            
            let templateMeals = day.meals.map { plannedMeal in
                TemplateMeal(
                    id: UUID(),  // Generate new ID for template
                    mealType: plannedMeal.mealType,
                    recipe: plannedMeal.recipe
                )
            }
            
            return TemplateDay(
                id: UUID(),
                weekdayIndex: weekdayIndex,
                meals: templateMeals
            )
        }
        
        return TemplateWeek(
            id: UUID(),
            familyId: plannedWeek.familyId,
            name: name,
            days: templateDays
        )
    }
    
    // MARK: - Legacy MealPlan → TemplateWeek
    
    /// Convert legacy MealPlan to TemplateWeek
    /// - Parameters:
    ///   - mealPlan: The legacy meal plan
    ///   - name: Name for the template
    /// - Returns: A new TemplateWeek
    static func mealPlanToTemplate(_ mealPlan: MealPlan, name: String) -> TemplateWeek {
        // Group items by weekday
        var dayGroups: [Int: [MealItem]] = [:]
        for item in mealPlan.items {
            let weekdayIndex = WeekDateHelper.weekdayToIndex(item.weekday)
            dayGroups[weekdayIndex, default: []].append(item)
        }
        
        // Create TemplateDays
        let templateDays: [TemplateDay] = dayGroups.map { weekdayIndex, meals in
            let templateMeals = meals.map { mealItem in
                TemplateMeal(
                    id: UUID(),
                    mealType: mealItem.mealType,
                    recipe: mealItem.recipe
                )
            }
            
            return TemplateDay(
                id: UUID(),
                weekdayIndex: weekdayIndex,
                meals: templateMeals
            )
        }.sorted { $0.weekdayIndex < $1.weekdayIndex }
        
        return TemplateWeek(
            id: UUID(),
            familyId: mealPlan.familyId,
            name: name,
            days: templateDays
        )
    }
    
    // MARK: - Validation
    
    /// Validate that a MealPlan can be safely converted
    /// - Parameter mealPlan: The meal plan to validate
    /// - Returns: True if conversion is safe
    static func canConvert(_ mealPlan: MealPlan) -> Bool {
        // Check that we have items
        guard !mealPlan.items.isEmpty else { return false }
        
        // Check that all items have valid recipes
        for item in mealPlan.items {
            if item.recipe.title.isEmpty || item.recipe.ingredients.isEmpty {
                return false
            }
        }
        
        return true
    }
    
    /// Validate that a PlannedWeek can be converted to a template
    /// - Parameter plannedWeek: The planned week to validate
    /// - Returns: True if conversion is safe
    static func canConvertToTemplate(_ plannedWeek: PlannedWeek) -> Bool {
        // Check that we have days with meals
        guard !plannedWeek.days.isEmpty else { return false }
        
        // Check that at least one day has meals
        let hasAnyMeals = plannedWeek.days.contains { !$0.meals.isEmpty }
        guard hasAnyMeals else { return false }
        
        // Check that all meals have valid recipes
        for day in plannedWeek.days {
            for meal in day.meals {
                if meal.recipe.title.isEmpty || meal.recipe.ingredients.isEmpty {
                    return false
                }
            }
        }
        
        return true
    }
}
