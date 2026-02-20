import Foundation

// Response models that match the API
private struct PlanResponse: Codable {
    let items: [PlanItemResponse]
    let mealPrepKits: [[String: AnyCodable]]?
    
    enum CodingKeys: String, CodingKey {
        case items
        case mealPrepKits = "meal_prep_kits"
    }
}

// Helper to handle Any in Codable
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrayVal as [Any]:
            try container.encode(arrayVal.map { AnyCodable($0) })
        case let dictVal as [String: Any]:
            try container.encode(dictVal.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
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
        
        // Format date as YYYY-MM-DD using Calendar to avoid timezone issues
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: weekStart)
        let weekStartString = String(format: "%04d-%02d-%02d", 
                                    components.year ?? 2024, 
                                    components.month ?? 1, 
                                    components.day ?? 1)
        
        // Load preferences if Premium user
        let hasPremium = StoreManager.shared.hasActiveSubscription
        let preferencesDict = preferencesToDict(hasPremium: hasPremium)
        
        // Create a strongly-typed payload structure for reliable encoding
        struct PlanRequest: Encodable {
            let week_start: String
            let units: String
            let slots: [[String: AnyCodable]]
            let constraints: [String: AnyCodable]
            let servings: Int
            let language: String
            let preferences: [String: AnyCodable]
        }
        
        let payload = PlanRequest(
            week_start: weekStartString,
            units: units.rawValue,
            slots: slots.map { slot in
                var slotDict: [String: AnyCodable] = [
                    "weekday": AnyCodable(slot.weekday.rawValue),
                    "meal_type": AnyCodable(slot.mealType.rawValue),
                    "is_meal_prep": AnyCodable(slot.isMealPrep)
                ]
                if let groupId = slot.mealPrepGroupId {
                    slotDict["meal_prep_group_id"] = AnyCodable(groupId.uuidString)
                }
                return slotDict
            },
            constraints: constraints.mapValues { AnyCodable($0) },
            servings: servings,
            language: language,
            preferences: preferencesDict.mapValues { AnyCodable($0) }
        )
        
        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(payload)
        
        print("🚀 Generating meal plan...")
        print("📍 URL: \(url.absoluteString)")
        print("📦 Language: \(language), Servings: \(servings)")
        
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
        
        // CRITICAL: Store meal prep kits if present
        if let kitsData = planResponse.mealPrepKits, !kitsData.isEmpty {
            print("🍱 Received \(kitsData.count) meal prep kits from backend")
            
            // Convert AnyCodable dictionaries to plain dictionaries
            let kits = kitsData.map { kitDict -> [String: Any] in
                var plainDict: [String: Any] = [:]
                for (key, value) in kitDict {
                    plainDict[key] = value.value
                }
                return plainDict
            }
            
            // Store in MealPrepStorageService for retrieval
            for kit in kits {
                if let groupId = kit["group_id"] as? String {
                    print("  📦 Storing kit for group: \(groupId)")
                    MealPrepStorageService.shared.saveMealPrepKit(groupId: groupId, kitData: kit)
                }
            }
            
            print("✅ Stored \(kits.count) meal prep kits successfully")
        } else {
            print("ℹ️ No meal prep kits in response")
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
