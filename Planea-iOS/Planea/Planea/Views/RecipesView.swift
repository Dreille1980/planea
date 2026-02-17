import SwiftUI
import PhotosUI

struct RecipesView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var recipeHistoryVM: RecipeHistoryViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @StateObject private var storeManager = StoreManager.shared
    
    @State private var selectedAction: RecipesAction? = nil
    @State private var showRecentRecipes = false
    @State private var showWizard = false
    
    var body: some View {
        ZStack {
            NavigationStack {
                Group {
                    switch selectedAction {
                    case .none:
                        // Hub d'accueil
                        RecipesHubView(selectedAction: $selectedAction)
                            .environmentObject(planVM)
                            .environmentObject(familyVM)
                            .environmentObject(usageVM)
                    
                    case .viewPlan:
                        // Vue du plan de la semaine
                        PlanWeekView()
                            .navigationBarBackButtonHidden(true)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        withAnimation {
                                            selectedAction = nil
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                            Text("recipes.back_to_hub".localized)
                                        }
                                    }
                                }
                            }
                    
                    case .generatePlan:
                        // Wizard de génération
                        WeekGenerationWizardView(planViewModel: planVM)
                            .environmentObject(familyVM)
                            .environmentObject(planVM)
                            .onDisappear {
                                // Après le wizard, aller voir le plan si généré
                                if planVM.currentPlan != nil {
                                    selectedAction = .viewPlan
                                } else {
                                    selectedAction = nil
                                }
                            }
                    
                    case .adHoc:
                        // Vue Ad Hoc
                        AdHocRecipeContentView()
                            .navigationBarBackButtonHidden(true)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        withAnimation {
                                            selectedAction = nil
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                            Text("recipes.back_to_hub".localized)
                                        }
                                    }
                                }
                                
                                if !recipeHistoryVM.recentRecipes.isEmpty {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button {
                                            showRecentRecipes = true
                                        } label: {
                                            Image(systemName: "clock")
                                                .font(.title3)
                                        }
                                    }
                                }
                            }
                    }
                }
                .navigationTitle("tab.recipes".localized)
                .navigationBarTitleDisplayMode(.inline)
            }
            .sheet(isPresented: $showRecentRecipes) {
                RecentRecipesView()
            }
            
            // Bouton flottant de chat
            FloatingChatButton()
                .environmentObject(usageVM)
        }
    }
}

// MARK: - Ad Hoc Content View

struct AdHocRecipeContentView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var recipeVM: RecipeViewModel
    @EnvironmentObject var recipeHistoryVM: RecipeHistoryViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    @State private var mode: AdHocMode = .text
    @State private var prompt: String = ""
    @State private var servings: Int = 4
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingRecipe = false
    @State private var showPaywall = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var photoInstructions: String = ""
    @State private var useConstraints: Bool = true
    @State private var complexity: RecipeComplexity = .simple
    @State private var isLoadingImage = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            Form {
                // Mode Picker
                Section {
                    Picker("", selection: $mode) {
                        Text("adhoc.modeText".localized).tag(AdHocMode.text)
                        Text("adhoc.pantryScan".localized).tag(AdHocMode.photo)
                    }
                    .pickerStyle(.segmented)
                }
                
                // Text Mode
                if mode == .text {
                    Section(header: Text("adhoc.recipeIdea".localized)) {
                        TextField("adhoc.promptPlaceholder".localized, text: $prompt, axis: .vertical)
                            .lineLimit(3...6)
                            .focused($isTextFieldFocused)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("action.done".localized) {
                                        isTextFieldFocused = false
                                    }
                                }
                            }
                    }
                }
                
                // Photo Mode
                if mode == .photo {
                    Section(header: Text("adhoc.fridgePhoto".localized)) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: { showCamera = true }) {
                                Label("adhoc.takePhoto".localized, systemImage: "camera.fill")
                            }
                            .buttonStyle(.bordered)
                            
                            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                                Label("adhoc.choosePhoto".localized, systemImage: "photo.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        TextField("adhoc.photoInstructionsPlaceholder".localized, text: $photoInstructions, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    
                    Section {
                        Toggle("adhoc.useConstraints".localized, isOn: $useConstraints)
                    } footer: {
                        Text("adhoc.useConstraints.footer".localized)
                            .font(.caption)
                    }
                }
                
                Section(header: Text("adhoc.servings".localized)) {
                    Stepper("\(servings) \("adhoc.servingsCount".localized)", value: $servings, in: 1...12)
                }
                
                Section(header: Text("adhoc.complexity".localized)) {
                    Picker("adhoc.complexity".localized, selection: $complexity) {
                        ForEach(RecipeComplexity.allCases) { complexity in
                            Text(complexity.displayName).tag(complexity)
                        }
                    }
                    .pickerStyle(.segmented)
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
                        if !usageVM.canGenerate(count: 1) {
                            showPaywall = true
                        } else {
                            if mode == .text {
                                Task { await generateRecipe() }
                            } else {
                                Task { await generateRecipeFromPhoto() }
                            }
                        }
                    }) {
                        if isLoadingImage {
                            HStack {
                                Text("adhoc.loadingImage".localized)
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        } else {
                            Text("action.generateRecipe".localized)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled((mode == .text && prompt.isEmpty) || (mode == .photo && selectedImage == nil && !isLoadingImage) || isGenerating)
                    .frame(maxWidth: .infinity)
                    
                    if isGenerating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
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
        .navigationDestination(isPresented: $showingRecipe) {
            if let recipe = recipeVM.currentRecipe {
                RecipeDetailView(recipe: recipe)
            }
        }
        .sheet(isPresented: $showPaywall) {
            UsageLimitReachedView()
                .environmentObject(usageVM)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .onChange(of: photoPickerItem) {
            Task { @MainActor in
                isLoadingImage = true
                if let data = try? await photoPickerItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
                isLoadingImage = false
            }
        }
        .onAppear {
            if familyVM.members.count > 0 {
                servings = familyVM.members.count
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
            let dislikedProteins = familyVM.aggregatedDislikedProteins()
            let constraintsDict: [String: Any] = [
                "diet": constraints.diet,
                "evict": constraints.evict,
                "excludedProteins": dislikedProteins
            ]
            
            let language = AppLanguage.currentLocale(appLanguage).prefix(2).lowercased()
            
            let recipe = try await service.generateRecipe(
                prompt: prompt,
                constraints: constraintsDict,
                servings: servings,
                units: units,
                language: String(language),
                maxMinutes: complexity.rawValue
            )
            
            recipeVM.currentRecipe = recipe
            
            // Auto-save to recent recipes
            recipeHistoryVM.saveRecipe(recipe, source: "adhoc-text")
            
            // Record generation
            usageVM.recordGenerations(count: 1)
            
            showingRecipe = true
        } catch {
            errorMessage = "\("plan.error".localized): \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
    
    func generateRecipeFromPhoto() async {
        guard let image = selectedImage else { return }
        
        isGenerating = true
        errorMessage = nil
        
        do {
            let service = IAService(baseURL: URL(string: Config.baseURL)!)
            let units = UnitSystem(rawValue: unitSystem) ?? .metric
            
            // Load generation preferences
            let prefs = PreferencesService.shared.loadPreferences()
            
            // Build constraints based on toggle and instructions
            var constraintsDict: [String: Any]
            if useConstraints {
                let constraints = familyVM.aggregatedConstraints()
                let dislikedProteins = familyVM.aggregatedDislikedProteins()
                constraintsDict = [
                    "diet": constraints.diet,
                    "evict": constraints.evict,
                    "excludedProteins": dislikedProteins
                ]
                // Add user instructions if present
                if !photoInstructions.isEmpty {
                    constraintsDict["extra"] = photoInstructions
                }
            } else {
                // No family constraints, but may still have user instructions
                if !photoInstructions.isEmpty {
                    constraintsDict = ["extra": photoInstructions]
                } else {
                    constraintsDict = [:]
                }
            }
            
            // Add generation preferences to constraints
            if !prefs.preferredProteins.isEmpty {
                let proteins = prefs.preferredProteins.map { $0.rawValue }.joined(separator: ", ")
                let currentExtra = (constraintsDict["extra"] as? String) ?? ""
                let newExtra = currentExtra.isEmpty ? "Preferred proteins: \(proteins)" : "\(currentExtra). Preferred proteins: \(proteins)"
                constraintsDict["extra"] = newExtra
            }
            
            let language = AppLanguage.currentLocale(appLanguage).prefix(2).lowercased()
            
            // Compress and resize image
            let maxSize: CGFloat = 1024
            let resizedImage: UIImage
            if image.size.width > maxSize || image.size.height > maxSize {
                let ratio = min(maxSize / image.size.width, maxSize / image.size.height)
                let newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
            } else {
                resizedImage = image
            }
            
            guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
                errorMessage = "adhoc.imageError".localized
                isGenerating = false
                return
            }
            
            let recipe = try await service.generateRecipeFromImage(
                imageData: imageData,
                servings: servings,
                constraints: constraintsDict,
                units: units,
                language: String(language),
                maxMinutes: complexity.rawValue
            )
            
            recipeVM.currentRecipe = recipe
            
            // Auto-save to recent recipes
            recipeHistoryVM.saveRecipe(recipe, source: "adhoc-photo")
            
            // Record generation
            usageVM.recordGenerations(count: 1)
            
            // Reset image and instructions after successful generation
            selectedImage = nil
            photoInstructions = ""
            photoPickerItem = nil
            
            showingRecipe = true
        } catch {
            errorMessage = "\("plan.error".localized): \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
}

// MARK: - Legacy Segments (kept for reference)

enum RecipesSegment: String, CaseIterable {
    case recipes = "recipes.segment.recipes"
    case mealPrep = "recipes.segment.mealPrep"
    case adHoc = "recipes.segment.adHoc"
}

// MARK: - Meal Prep Coming Soon View (kept for reference)

struct MealPrepComingSoonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Coming soon placeholder
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Coming Soon")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text("Meal prep feature is being developed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
            }
        }
    }
}
