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
    
    // MARK: - MealPlan → MealPrepKit
    
    /// Convert MealPlan meal prep items to MealPrepKit
    /// - Parameter mealPlan: The meal plan containing meal prep items
    /// - Returns: A MealPrepKit if there are meal prep items, nil otherwise
    static func toMealPrepKit(_ mealPlan: MealPlan) -> MealPrepKit? {
        let mealPrepItems = mealPlan.items.filter { $0.isMealPrep }
        guard !mealPrepItems.isEmpty else { return nil }
        
        // Group by mealPrepGroupId
        let grouped = Dictionary(grouping: mealPrepItems) { $0.mealPrepGroupId }
        
        // For now, take the first group (in future could handle multiple kits)
        guard let groupId = grouped.keys.compactMap({ $0 }).first,
              let groupItems = grouped[groupId] else { return nil }
        
        // Create recipe refs
        let recipeRefs = groupItems.map { item in
            MealPrepRecipeRef(
                id: item.id,
                recipeId: item.id.uuidString,
                title: item.recipe.title,
                shelfLifeDays: item.recipe.shelfLifeDays ?? 3,
                isFreezable: item.recipe.isFreezable ?? false,
                storageNote: item.recipe.storageNote,
                recipe: item.recipe
            )
        }
        
        // Parse steps from stored kit data (NOT from recipe steps)
        let (todayPrep, weeklyReheating) = parseMealPrepSteps(groupId: groupId)
        
        // Calculate totals
        let totalPortions = groupItems.reduce(0) { $0 + $1.recipe.servings }
        let estimatedMinutes = todayPrep?.totalMinutes ?? groupItems.reduce(0) { $0 + $1.recipe.totalMinutes }
        
        return MealPrepKit(
            id: groupId,
            name: "Meal Prep - \(WeekDateHelper.formatWeekRange(startDate: mealPlan.weekStart))",
            description: "Préparation pour \(groupItems.count) repas",
            totalPortions: totalPortions,
            estimatedPrepMinutes: estimatedMinutes,
            recipes: recipeRefs,
            groupedPrepSteps: nil,
            optimizedRecipeSteps: nil,
            cookingPhases: nil,
            todayPreparation: todayPrep,
            weeklyReheating: weeklyReheating
        )
    }
    
    /// Parse meal prep steps from backend stored kit
    static func parseMealPrepSteps(groupId: UUID) -> (todayPreparation: TodayPreparation?, weeklyReheating: WeeklyReheating?) {
        print("🔍 parseMealPrepSteps called for group: \(groupId.uuidString)")
        
        // Load kit from storage
        guard let kitData = MealPrepStorageService.shared.loadMealPrepKit(groupId: groupId.uuidString) else {
            print("  ❌ No kit found in storage for group: \(groupId.uuidString)")
            return (nil, nil)
        }
        
        print("  ✅ Found kit data in storage")
        
        // Parse today_preparation - try Codable decoding
        var todayPrep: TodayPreparation? = nil
        if let todayData = kitData["today_preparation"] as? [String: Any],
           let jsonData = try? JSONSerialization.data(withJSONObject: todayData) {
            todayPrep = try? JSONDecoder().decode(TodayPreparation.self, from: jsonData)
            if todayPrep != nil {
                print("  ✅ Parsed today_preparation")
            } else {
                print("  ❌ Failed to decode today_preparation")
            }
        }
        
        // Parse weekly_reheating - try Codable decoding
        var weeklyReheating: WeeklyReheating? = nil
        if let weeklyData = kitData["weekly_reheating"] as? [String: Any],
           let jsonData = try? JSONSerialization.data(withJSONObject: weeklyData) {
            weeklyReheating = try? JSONDecoder().decode(WeeklyReheating.self, from: jsonData)
            if weeklyReheating != nil {
                print("  ✅ Parsed weekly_reheating")
            } else {
                print("  ❌ Failed to decode weekly_reheating")
            }
        }
        
        return (todayPrep, weeklyReheating)
    }
    
    /// Parse recipe steps to extract TODAY and TONIGHT sections
    private static func parseMealPrepSteps(_ items: [MealItem]) -> (TodayPreparation?, WeeklyReheating?) {
        let commonPreps: [CommonPrepStep] = []  // Empty for now, could be populated later
        var recipePreps: [RecipePrep] = []
        var dailyReheating: [DailyReheating] = []
        
        for item in items {
            let steps = item.recipe.steps
            var todaySteps: [String] = []
            var tonightSteps: [String] = []
            var inTodaySection = false
            var inTonightSection = false
            
            // Parse steps to separate TODAY and TONIGHT
            for step in steps {
                let trimmed = step.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if trimmed.contains("📅") || trimmed.uppercased().contains("AUJOURD'HUI") || trimmed.uppercased().contains("TODAY") {
                    inTodaySection = true
                    inTonightSection = false
                    continue
                } else if trimmed.contains("🌙") || trimmed.uppercased().contains("CE SOIR") || trimmed.uppercased().contains("TONIGHT") {
                    inTodaySection = false
                    inTonightSection = true
                    continue
                }
                
                if inTodaySection && !trimmed.isEmpty {
                    todaySteps.append(trimmed)
                } else if inTonightSection && !trimmed.isEmpty {
                    tonightSteps.append(trimmed)
                }
            }
            
            // Create RecipePrep for today
            if !todaySteps.isEmpty {
                recipePreps.append(RecipePrep(
                    id: UUID(),
                    recipeName: item.recipe.title,
                    emoji: mealTypeEmoji(item.mealType),
                    prepToday: todaySteps,
                    dontPrepToday: nil,
                    estimatedMinutes: item.recipe.totalMinutes / 2, // Rough estimate
                    eveningMinutes: tonightSteps.isEmpty ? nil : 10
                ))
            }
            
            // Create DailyReheating for tonight/later
            if !tonightSteps.isEmpty {
                dailyReheating.append(DailyReheating(
                    id: UUID(),
                    dayNumber: dailyReheating.count + 1,
                    dayLabel: item.weekday.displayName,
                    recipeName: item.recipe.title,
                    emoji: mealTypeEmoji(item.mealType),
                    steps: tonightSteps,
                    estimatedMinutes: 10
                ))
            }
        }
        
        let todayPrep = !recipePreps.isEmpty ? TodayPreparation(
            consolidatedIngredients: nil,
            commonPreps: commonPreps,
            recipePreps: recipePreps,
            totalMinutes: recipePreps.reduce(0) { $0 + ($1.estimatedMinutes ?? 0) }
        ) : nil
        
        let weeklyReheating = !dailyReheating.isEmpty ? WeeklyReheating(
            days: dailyReheating.sorted { $0.dayLabel < $1.dayLabel }
        ) : nil
        
        return (todayPrep, weeklyReheating)
    }
    
    private static func mealTypeEmoji(_ mealType: MealType) -> String {
        switch mealType {
        case .breakfast: return "☀️"
        case .lunch: return "🍽️"
        case .dinner: return "🌙"
        case .snack: return "🥤"
        }
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
