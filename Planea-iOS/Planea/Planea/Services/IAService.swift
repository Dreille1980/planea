import Foundation

// Response models that match the API
private struct PlanResponse: Codable {
    let items: [PlanItemResponse]
}

private struct PlanItemResponse: Codable {
    let weekday: Weekday
    let mealType: MealType
    let recipe: Recipe
    let isMealPrep: Bool?
    let mealPrepGroupId: String?
    
    enum CodingKeys: String, CodingKey {
        case weekday
        case mealType = "meal_type"
        case recipe
        case isMealPrep = "is_meal_prep"
        case mealPrepGroupId = "meal_prep_group_id"
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
        
        // Weekly flyers / grocery discounts
        dict["useWeeklyFlyers"] = prefs.useWeeklyFlyers
        if prefs.useWeeklyFlyers {
            if !prefs.postalCode.isEmpty {
                dict["postalCode"] = prefs.postalCode
            }
            if !prefs.preferredGroceryStore.isEmpty {
                dict["preferredGroceryStore"] = prefs.preferredGroceryStore
            }
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
            "slots": slots.map { slot in
                var slotDict: [String: Any] = [
                    "weekday": slot.weekday.rawValue,
                    "meal_type": slot.mealType.rawValue,
                    "is_meal_prep": slot.isMealPrep
                ]
                if let groupId = slot.mealPrepGroupId {
                    slotDict["meal_prep_group_id"] = groupId.uuidString
                }
                return slotDict
            },
            "constraints": constraints,
            "servings": servings,
            "language": language,
            "preferences": preferencesDict
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🚀 Generating meal plan...")
        print("📍 URL: \(url.absoluteString)")
        print("📦 Payload keys: \(payload.keys.joined(separator: ", "))")
        
        let (data, response) = try await performRequest(request: req)
        
        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Response status: \(httpResponse.statusCode)")
        }
        
        // Log raw response preview
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Raw response preview: \(jsonString.prefix(500))")
        }
        
        // Decode the API response
        let planResponse = try JSONDecoder().decode(PlanResponse.self, from: data)
        
        // Convert to MealPlan
        let mealItems = planResponse.items.map { item in
            var mealItem = MealItem(
                id: UUID(),
                weekday: item.weekday,
                mealType: item.mealType,
                recipe: item.recipe
            )
            
            // Transfer meal prep properties from backend response
            mealItem.isMealPrep = item.isMealPrep ?? false
            if let groupIdString = item.mealPrepGroupId, let groupId = UUID(uuidString: groupIdString) {
                mealItem.mealPrepGroupId = groupId
            }
            
            return mealItem
        }
        
        print("✅ Successfully generated plan with \(mealItems.count) items")
        
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
        print("📍 URL: \(url.absoluteString)")
        print("📦 Meal: \(weekday.rawValue) - \(mealType.rawValue)")
        
        let (data, response) = try await performRequest(request: req)
        
        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Response status: \(httpResponse.statusCode)")
        }
        
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        print("✅ Successfully regenerated: \(decoded.title)")
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
        print("📍 URL: \(url.absoluteString)")
        print("💡 Prompt: \(prompt)")
        
        let (data, response) = try await performRequest(request: req)
        
        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Response status: \(httpResponse.statusCode)")
        }
        
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        print("✅ Successfully generated: \(decoded.title)")
        return decoded
    }
    
    @MainActor
    func generateRecipeFromImage(imageData: Data, servings: Int, constraints: [String: Any], units: UnitSystem, language: String, maxMinutes: Int? = nil) async throws -> Recipe {
        let url = baseURL.appendingPathComponent("/ai/recipe-from-image")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert image to base64
        let base64Image = imageData.base64EncodedString()
        
        // For ad hoc recipes, only use maxMinutes preference if provided
        var preferencesDict: [String: Any] = [:]
        if let maxMinutes = maxMinutes {
            preferencesDict["maxMinutes"] = maxMinutes
        }
        
        let payload: [String: Any] = [
            "image_base64": base64Image,
            "servings": servings,
            "constraints": constraints,
            "units": units.rawValue,
            "language": language,
            "preferences": preferencesDict
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("📸 Generating recipe from fridge photo...")
        print("📍 URL: \(url.absoluteString)")
        print("🖼️ Image size: \(imageData.count) bytes")
        
        let (data, response) = try await performRequest(request: req)
        
        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Response status: \(httpResponse.statusCode)")
        }
        
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        print("✅ Successfully generated from image: \(decoded.title)")
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
        print("📍 URL: \(url.absoluteString)")
        print("📄 Title: \(title)")
        
        let (data, response) = try await performRequest(request: req)
        
        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Response status: \(httpResponse.statusCode)")
        }
        
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        print("✅ Successfully generated from title: \(decoded.title)")
        return decoded
    }
}
