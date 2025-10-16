import SwiftUI

struct AdHocRecipeView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var recipeVM: RecipeViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    @State private var prompt: String = ""
    @State private var servings: Int = 4
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingRecipe = false
    @State private var showPaywall = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("adhoc.recipeIdea".localized)) {
                        TextField("adhoc.promptPlaceholder".localized, text: $prompt, axis: .vertical)
                            .lineLimit(3...6)
                            .focused($isTextFieldFocused)
                    }
                    
                    Section(header: Text("adhoc.servings".localized)) {
                        Stepper("\(servings) \("adhoc.servingsCount".localized)", value: $servings, in: 1...12)
                    }
                    
                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                    
                    Section {
                        Button(action: {
                            if usageVM.hasFreePlanRestrictions {
                                showPaywall = true
                            } else {
                                Task { await generateRecipe() }
                            }
                        }) {
                            HStack {
                                Text("action.generateRecipe".localized)
                                if usageVM.hasFreePlanRestrictions {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                }
                            }
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
            .navigationTitle(Text("adhoc.title".localized))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("action.done".localized) {
                        isTextFieldFocused = false
                    }
                }
            }
            .navigationDestination(isPresented: $showingRecipe) {
                if let recipe = recipeVM.currentRecipe {
                    RecipeDetailView(recipe: recipe)
                }
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallView(limitReached: false)
            }
        }
    }
    
    func generateRecipe() async {
        isGenerating = true
        errorMessage = nil
        
        do {
            let service = IAService(baseURL: URL(string: Config.baseURL)!)
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
            errorMessage = "\("plan.error".localized): \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
}
