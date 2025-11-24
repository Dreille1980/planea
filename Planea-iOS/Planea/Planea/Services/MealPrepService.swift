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
    
    /// Generate meal prep kits based on parameters
    @MainActor
    func generateMealPrepKits(
        params: MealPrepGenerationParams,
        constraints: [String: Any],
        units: UnitSystem,
        language: String
    ) async throws -> [MealPrepKit] {
        let url = baseURL.appendingPathComponent("/ai/meal-prep-kits")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert params to dictionary
        let payload: [String: Any] = [
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
        
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        print("🍽️ Generating meal prep kits...")
        let (data, _) = try await performRequest(request: req)
        
        // Log raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Raw response: \(jsonString)")
        }
        
        // Try to decode the response
        do {
            let response = try JSONDecoder().decode(MealPrepKitsResponse.self, from: data)
            return response.kits
        } catch {
            print("❌ Decoding error: \(error)")
            // Try to decode as direct array
            do {
                let kits = try JSONDecoder().decode([MealPrepKit].self, from: data)
                print("✅ Successfully decoded as direct array")
                return kits
            } catch {
                print("❌ Also failed to decode as array: \(error)")
                throw error
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
