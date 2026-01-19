import Foundation
import FirebasePerformance

/// Service centralisé pour gérer Firebase Performance Monitoring
class PerformanceService {
    static let shared = PerformanceService()
    
    private init() {}
    
    // MARK: - Custom Traces
    
    func startTrace(name: String) -> Trace? {
        let trace = Performance.startTrace(name: name)
        return trace
    }
    
    func stopTrace(_ trace: Trace?) {
        trace?.stop()
    }
    
    // MARK: - Common Traces
    
    func traceRecipeGeneration(type: String, completion: @escaping () -> Void) {
        let traceName = "recipe_generation_\(type)"
        let trace = Performance.startTrace(name: traceName)
        trace?.setValue(type, forAttribute: "generation_type")
        
        completion()
        
        trace?.stop()
    }
    
    func traceMealPrepGeneration(completion: @escaping () -> Void) {
        let trace = Performance.startTrace(name: "meal_prep_generation")
        
        completion()
        
        trace?.stop()
    }
    
    func traceAPICall(endpoint: String, completion: @escaping () -> Void) {
        let trace = Performance.startTrace(name: "api_call")
        trace?.setValue(endpoint, forAttribute: "endpoint")
        
        completion()
        
        trace?.stop()
    }
    
    // MARK: - HTTP Metric (Automatic for URLSession)
    // Firebase Performance automatically tracks URLSession requests
    // No manual implementation needed for basic HTTP monitoring
}
