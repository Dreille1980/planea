import SwiftUI

struct AdHocRecipeView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var recipeVM: RecipeViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    @State private var prompt: String = ""
    @State private var servings: Int = 4
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingRecipe = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text(String(localized: "adhoc.recipeIdea"))) {
                        TextField(String(localized: "adhoc.promptPlaceholder"), text: $prompt, axis: .vertical)
                            .lineLimit(3...6)
                            .focused($isTextFieldFocused)
                    }
                    
                    Section(header: Text(String(localized: "adhoc.servings"))) {
                        Stepper("\(servings) \(String(localized: "adhoc.servingsCount"))", value: $servings, in: 1...12)
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
                
                // Loading overlay
                if isGenerating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    GeneratingLoadingView(totalItems: 1)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle(Text(String(localized: "adhoc.title")))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(String(localized: "action.done")) {
                        isTextFieldFocused = false
                    }
                }
            }
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
            
            let language = AppLanguage.currentLocale(appLanguage).prefix(2).lowercased()
            
            let recipe = try await service.generateRecipe(
                prompt: prompt,
                constraints: constraintsDict,
                servings: servings,
                units: units,
                language: String(language)
            )
            
            recipeVM.currentRecipe = recipe
            showingRecipe = true
        } catch {
            errorMessage = "\(String(localized: "plan.error")): \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
}
