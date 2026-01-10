import Foundation

struct MealPrepService {
    var baseURL: URL
    
    // Custom URLSession with extended timeout
    private static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 180
        return URLSession(configuration: configuration)
    }()
    
    // Helper to perform requests with retry logic
    private func performRequest(request: URLRequest, maxRetries: Int = 2) async throws -> (Data, URLResponse) {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await Self.urlSession.data(for: request)
                return (data, response)
            } catch let error as URLError {
                lastError = error
                
                if error.code == .timedOut || error.code == .cannotConnectToHost || error.code == .networkConnectionLost {
                    print("⚠️ Request attempt \(attempt + 1) failed with: \(error.localizedDescription)")
                    
                    if attempt < maxRetries - 1 {
                        let delay = pow(2.0, Double(attempt)) * 5.0
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
    
    /// Generate meal prep concepts for user selection
    @MainActor
    func generateConcepts(
        constraints: [String: Any],
        language: String
    ) async throws -> [MealPrepConcept] {
        let url = baseURL.appendingPathComponent("/ai/meal-prep-concepts")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "language": language,
            "constraints": constraints
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🎨 Generating meal prep concepts...")
        print("📍 URL: \(url.absoluteString)")
        print("📦 Payload: \(payload)")
        
        let (data, response) = try await performRequest(request: req)
        
        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Response status: \(httpResponse.statusCode)")
        }
        
        // Log raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Raw response: \(jsonString.prefix(500))")
        }
        
        // Decode response
        struct ConceptsResponse: Codable {
            let concepts: [MealPrepConcept]
        }
        
        do {
            let conceptsResponse = try JSONDecoder().decode(ConceptsResponse.self, from: data)
            print("✅ Successfully decoded \(conceptsResponse.concepts.count) concepts")
            return conceptsResponse.concepts
        } catch {
            print("❌ Decoding error: \(error)")
            print("❌ Failed data: \(String(data: data, encoding: .utf8) ?? "Unable to decode data")")
            throw error
        }
    }
    
    /// Generate meal prep kits based on parameters
    @MainActor
    func generateMealPrepKits(
        params: MealPrepGenerationParams,
        constraints: [String: Any],
        units: UnitSystem,
        language: String,
        selectedConcept: MealPrepConcept? = nil,
        customConceptText: String? = nil
    ) async throws -> [MealPrepKit] {
        let url = baseURL.appendingPathComponent("/ai/meal-prep-kits")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert params to dictionary
        var payload: [String: Any] = [
            "days": params.days.map { $0.rawValue },
            "meals": params.meals.map { $0.rawValue },
            "servings_per_meal": params.servingsPerMeal,
            "total_prep_time_preference": params.totalPrepTimePreference.rawValue,
            "skill_level": params.skillLevel.rawValue,
            "avoid_rare_ingredients": params.avoidRareIngredients,
            "prefer_long_shelf_life": params.preferLongShelfLife,
            "constraints": constraints,
            "units": units.rawValue,
            "language": language
        ]
        
        // Add concept if provided
        if let concept = selectedConcept {
            payload["selected_concept"] = [
                "id": concept.id.uuidString,
                "name": concept.name,
                "description": concept.description,
                "cuisine": concept.cuisine as Any,
                "tags": concept.tags
            ]
        } else if let customText = customConceptText, !customText.isEmpty {
            payload["selected_concept"] = [
                "id": UUID().uuidString,
                "name": "Custom",
                "description": customText
            ]
        }
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🍽️ Generating meal prep kits...")
        print("📍 URL: \(url.absoluteString)")
        print("📦 Payload keys: \(payload.keys.joined(separator: ", "))")
        
        let (data, response) = try await performRequest(request: req)
        
        // Log response details
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ Response status: \(httpResponse.statusCode)")
        }
        
        // Log raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Raw response: \(jsonString.prefix(1000))")
        }
        
        // Try to decode the response
        do {
            let kitsResponse = try JSONDecoder().decode(MealPrepKitsResponse.self, from: data)
            print("✅ Successfully decoded \(kitsResponse.kits.count) kits")
            return kitsResponse.kits
        } catch let decodingError {
            print("❌ Decoding error as MealPrepKitsResponse: \(decodingError)")
            
            // Try to decode as direct array
            do {
                let kits = try JSONDecoder().decode([MealPrepKit].self, from: data)
                print("✅ Successfully decoded as direct array: \(kits.count) kits")
                return kits
            } catch let arrayError {
                print("❌ Also failed to decode as array: \(arrayError)")
                print("❌ Full response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                throw decodingError
            }
        }
    }
    
    /// Generate a single recipe for meal prep with storage metadata
    @MainActor
    func generateMealPrepRecipe(
        mealType: MealType,
        servings: Int,
        constraints: [String: Any],
        units: UnitSystem,
        language: String,
        preferences: [String: Any] = [:]
    ) async throws -> Recipe {
        let url = baseURL.appendingPathComponent("/ai/meal-prep-recipe")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "meal_type": mealType.rawValue,
            "servings": servings,
            "constraints": constraints,
            "units": units.rawValue,
            "language": language,
            "preferences": preferences
        ]
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🍳 Generating meal prep recipe...")
        let (data, _) = try await performRequest(request: req)
        
        let recipe = try JSONDecoder().decode(Recipe.self, from: data)
        return recipe
    }
}

// MARK: - Response Models

private struct MealPrepKitsResponse: Codable {
    let kits: [MealPrepKit]
}
