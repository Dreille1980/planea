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
    
    // Custom URLSession with extended timeout for serverless environments
    private static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120 // 2 minutes for cold starts
        configuration.timeoutIntervalForResource = 180 // 3 minutes total
        return URLSession(configuration: configuration)
    }()
    
    // Helper to perform requests with retry logic for cold starts
    private func performRequest(request: URLRequest, maxRetries: Int = 2) async throws -> (Data, URLResponse) {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await Self.urlSession.data(for: request)
                return (data, response)
            } catch let error as URLError {
                lastError = error
                
                // Retry on timeout or network errors (likely cold start)
                if error.code == .timedOut || error.code == .cannotConnectToHost || error.code == .networkConnectionLost {
                    print("⚠️ Request attempt \(attempt + 1) failed with: \(error.localizedDescription)")
                    
                    if attempt < maxRetries - 1 {
                        // Wait before retrying (exponential backoff)
                        let delay = pow(2.0, Double(attempt)) * 5.0 // 5s, 10s
                        print("⏳ Waiting \(delay)s before retry...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                throw error
            }
        }
        
        throw lastError ?? URLError(.unknown)
    }
    
    // Helper to convert preferences to dictionary for backend
    private func preferencesToDict(hasPremium: Bool) -> [String: Any] {
        guard hasPremium else { return [:] }
        
        let prefs = PreferencesService.shared.loadPreferences()
        
        var dict: [String: Any] = [
            "weekdayMaxMinutes": prefs.weekdayMaxMinutes,
            "weekendMaxMinutes": prefs.weekendMaxMinutes,
            "spiceLevel": prefs.spiceLevel.rawValue,
            "kidFriendly": prefs.kidFriendly
        ]
        
        // Convert Set<Protein> to [String]
        if !prefs.preferredProteins.isEmpty {
            dict["preferredProteins"] = prefs.preferredProteins.map { $0.rawValue }
        }
        
        // Convert Set<Appliance> to [String]
        if !prefs.availableAppliances.isEmpty {
            dict["availableAppliances"] = prefs.availableAppliances.map { $0.rawValue }
        }
        
        return dict
    }
    
    @MainActor
    func generatePlan(weekStart: Date, slots: [SlotSelection], constraints: [String: Any], servings: Int, units: UnitSystem, language: String) async throws -> MealPlan {
        let url = baseURL.appendingPathComponent("/ai/plan")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Format date as YYYY-MM-DD only (Python expects date, not datetime)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Load preferences if Premium user
        let hasPremium = StoreManager.shared.hasActiveSubscription
        let preferencesDict = preferencesToDict(hasPremium: hasPremium)
        
        let payload: [String: Any] = [
            "week_start": dateFormatter.string(from: weekStart),
            "units": units.rawValue,
            "slots": slots.map { ["weekday": $0.weekday.rawValue, "meal_type": $0.mealType.rawValue] },
            "constraints": constraints,
            "servings": servings,
            "language": language,
            "preferences": preferencesDict
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🚀 Generating meal plan...")
        let (data, _) = try await performRequest(request: req)
        
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
        
        // Load preferences if Premium user
        let hasPremium = StoreManager.shared.hasActiveSubscription
        let preferencesDict = preferencesToDict(hasPremium: hasPremium)
        
        let payload: [String: Any] = [
            "weekday": weekday.rawValue,
            "meal_type": mealType.rawValue,
            "constraints": constraints,
            "servings": servings,
            "units": units.rawValue,
            "language": language,
            "diversity_seed": diversitySeed,
            "preferences": preferencesDict
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🔄 Regenerating meal...")
        let (data, _) = try await performRequest(request: req)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        return decoded
    }
    
    @MainActor
    func generateRecipe(prompt: String, constraints: [String: Any], servings: Int, units: UnitSystem, language: String, maxMinutes: Int? = nil) async throws -> Recipe {
        let url = baseURL.appendingPathComponent("/ai/recipe")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // For ad hoc recipes, only use maxMinutes preference if provided
        var preferencesDict: [String: Any] = [:]
        if let maxMinutes = maxMinutes {
            preferencesDict["maxMinutes"] = maxMinutes
        }
        
        let payload: [String: Any] = [
            "idea": prompt,
            "constraints": constraints,
            "servings": servings,
            "units": units.rawValue,
            "language": language,
            "preferences": preferencesDict
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🍳 Generating recipe from prompt...")
        let (data, _) = try await performRequest(request: req)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        return decoded
    }
    
    @MainActor
    func generateRecipeFromImage(imageData: Data, servings: Int, constraints: [String: Any], units: UnitSystem, language: String) async throws -> Recipe {
        let url = baseURL.appendingPathComponent("/ai/recipe-from-image")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert image to base64
        let base64Image = imageData.base64EncodedString()
        
        let payload: [String: Any] = [
            "image_base64": base64Image,
            "servings": servings,
            "constraints": constraints,
            "units": units.rawValue,
            "language": language
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("📸 Generating recipe from fridge photo...")
        let (data, _) = try await performRequest(request: req)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        return decoded
    }
    
    @MainActor
    func generateRecipeFromTitle(title: String, servings: Int, constraints: [String: Any], units: UnitSystem, language: String, maxMinutes: Int? = nil) async throws -> Recipe {
        let url = baseURL.appendingPathComponent("/ai/recipe-from-title")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // For ad hoc recipes, only use maxMinutes preference if provided
        var preferencesDict: [String: Any] = [:]
        if let maxMinutes = maxMinutes {
            preferencesDict["maxMinutes"] = maxMinutes
        }
        
        let payload: [String: Any] = [
            "title": title,
            "servings": servings,
            "constraints": constraints,
            "units": units.rawValue,
            "language": language,
            "preferences": preferencesDict
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("📝 Generating recipe from title...")
        let (data, _) = try await performRequest(request: req)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        return decoded
    }
}
