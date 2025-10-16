import Foundation

// Response models that match the API
private struct PlanResponse: Codable {
    let items: [PlanItemResponse]
}

private struct PlanItemResponse: Codable {
    let weekday: Weekday
    let mealType: MealType
    let recipe: Recipe
    
    enum CodingKeys: String, CodingKey {
        case weekday
        case mealType = "meal_type"
        case recipe
    }
}

struct IAService {
    var baseURL: URL
    
    // Helper to merge preferences into constraints
    private func mergePreferences(into constraints: [String: Any], weekday: Weekday? = nil, hasPremium: Bool) -> [String: Any] {
        var merged = constraints
        
        // Load user preferences if Premium user
        if hasPremium {
            let prefs = PreferencesService.shared.loadPreferences()
            
            // Add preferences string to constraints
            if let existingExtra = merged["extra"] as? String {
                merged["extra"] = "\(existingExtra). \(prefs.toPromptString())"
            } else {
                merged["extra"] = prefs.toPromptString()
            }
            
            // Add time constraint based on weekday (if provided)
            if let weekday = weekday {
                let isWeekend = weekday == .saturday || weekday == .sunday
                let maxTime = isWeekend ? prefs.weekendMaxMinutes : prefs.weekdayMaxMinutes
                
                if let existingExtra = merged["extra"] as? String {
                    merged["extra"] = "\(existingExtra). Max \(maxTime) minutes"
                } else {
                    merged["extra"] = "Max \(maxTime) minutes"
                }
            }
        }
        
        return merged
    }
    
    @MainActor
    func generatePlan(weekStart: Date, slots: [SlotSelection], constraints: [String: Any], units: UnitSystem, language: String) async throws -> MealPlan {
        let url = baseURL.appendingPathComponent("/ai/plan")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Format date as YYYY-MM-DD only (Python expects date, not datetime)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Merge preferences into constraints
        let hasPremium = StoreManager.shared.hasActiveSubscription
        let mergedConstraints = mergePreferences(into: constraints, hasPremium: hasPremium)
        
        let payload: [String: Any] = [
            "week_start": dateFormatter.string(from: weekStart),
            "units": units.rawValue,
            "slots": slots.map { ["weekday": $0.weekday.rawValue, "meal_type": $0.mealType.rawValue] },
            "constraints": mergedConstraints,
            "language": language
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        
        // Decode the API response
        let response = try JSONDecoder().decode(PlanResponse.self, from: data)
        
        // Convert to MealPlan
        let mealItems = response.items.map { item in
            MealItem(
                id: UUID(),
                weekday: item.weekday,
                mealType: item.mealType,
                recipe: item.recipe
            )
        }
        
        return MealPlan(
            id: UUID(),
            familyId: UUID(), // Will be set by the caller if needed
            weekStart: weekStart,
            items: mealItems
        )
    }
    
    @MainActor
    func regenerateMeal(weekday: Weekday, mealType: MealType, constraints: [String: Any], servings: Int, units: UnitSystem, language: String, diversitySeed: Int = 0) async throws -> Recipe {
        let url = baseURL.appendingPathComponent("/ai/regenerate-meal")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Merge preferences with weekday context
        let hasPremium = StoreManager.shared.hasActiveSubscription
        let mergedConstraints = mergePreferences(into: constraints, weekday: weekday, hasPremium: hasPremium)
        
        let payload: [String: Any] = [
            "weekday": weekday.rawValue,
            "meal_type": mealType.rawValue,
            "constraints": mergedConstraints,
            "servings": servings,
            "units": units.rawValue,
            "language": language,
            "diversity_seed": diversitySeed
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        return decoded
    }
    
    @MainActor
    func generateRecipe(prompt: String, constraints: [String: Any], servings: Int, units: UnitSystem, language: String) async throws -> Recipe {
        let url = baseURL.appendingPathComponent("/ai/recipe")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Merge preferences into constraints
        let hasPremium = StoreManager.shared.hasActiveSubscription
        let mergedConstraints = mergePreferences(into: constraints, hasPremium: hasPremium)
        
        let payload: [String: Any] = [
            "idea": prompt,
            "constraints": mergedConstraints,
            "servings": servings,
            "units": units.rawValue,
            "language": language
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        return decoded
    }
    
    @MainActor
    func generateRecipeFromTitle(title: String, servings: Int, constraints: [String: Any], units: UnitSystem, language: String) async throws -> Recipe {
        let url = baseURL.appendingPathComponent("/ai/recipe-from-title")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Merge preferences into constraints
        let hasPremium = StoreManager.shared.hasActiveSubscription
        let mergedConstraints = mergePreferences(into: constraints, hasPremium: hasPremium)
        
        let payload: [String: Any] = [
            "title": title,
            "servings": servings,
            "constraints": mergedConstraints,
            "units": units.rawValue,
            "language": language
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        return decoded
    }
}
