import Foundation

struct IAService {
    var baseURL: URL
    
    // Helper struct to decode the server response
    private struct PlanResponse: Codable {
        var items: [MealItem]
    }
    
    func generatePlan(weekStart: Date, slots: [SlotSelection], constraints: [String: Any], units: UnitSystem) async throws -> MealPlan {
        let url = baseURL.appendingPathComponent("/ai/plan")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Format date as YYYY-MM-DD only (Python expects date, not datetime)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let payload: [String: Any] = [
            "week_start": dateFormatter.string(from: weekStart),
            "units": units.rawValue,
            "slots": slots.map { ["weekday": $0.weekday.rawValue, "meal_type": $0.mealType.rawValue] },
            "constraints": constraints
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        
        // Decode the server response
        let response = try JSONDecoder().decode(PlanResponse.self, from: data)
        
        // Create a MealPlan from the response
        let plan = MealPlan(
            id: UUID(),
            familyId: UUID(), // This will be set by the ViewModel if needed
            weekStart: weekStart,
            items: response.items
        )
        
        return plan
    }
    
    func generateRecipe(prompt: String, constraints: [String: Any], servings: Int, units: UnitSystem) async throws -> Recipe {
        let url = baseURL.appendingPathComponent("/ai/recipe")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "idea": prompt,
            "constraints": constraints,
            "servings": servings,
            "units": units.rawValue
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        let decoded = try JSONDecoder().decode(Recipe.self, from: data)
        return decoded
    }
}
