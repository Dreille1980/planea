import SwiftUI

struct AdHocRecipeView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var recipeVM: RecipeViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @State private var prompt: String = ""
    @State private var servings: Int = 4
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingRecipe = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Recipe Idea")) {
                    TextField(String(localized: "adhoc.promptPlaceholder"), text: $prompt, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Servings")) {
                    Stepper("\(servings) servings", value: $servings, in: 1...12)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(String(localized: "action.generateRecipe")) {
                        Task { await generateRecipe() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(prompt.isEmpty || isGenerating)
                    .frame(maxWidth: .infinity)
                    
                    if isGenerating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(Text(String(localized: "adhoc.title")))
            .navigationDestination(isPresented: $showingRecipe) {
                if let recipe = recipeVM.currentRecipe {
                    RecipeDetailView(recipe: recipe)
                }
            }
        }
    }
    
    func generateRecipe() async {
        isGenerating = true
        errorMessage = nil
        
        do {
            let service = IAService(baseURL: URL(string: "http://localhost:8000")!)
            let units = UnitSystem(rawValue: unitSystem) ?? .metric
            let constraints = familyVM.aggregatedConstraints()
            let constraintsDict: [String: Any] = [
                "diet": constraints.diet,
                "evict": constraints.evict
            ]
            
            let recipe = try await service.generateRecipe(
                prompt: prompt,
                constraints: constraintsDict,
                servings: servings,
                units: units
            )
            
            recipeVM.currentRecipe = recipe
            showingRecipe = true
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
}
