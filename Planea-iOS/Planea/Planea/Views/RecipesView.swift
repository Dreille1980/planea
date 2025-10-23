import SwiftUI
import PhotosUI

enum RecipeTab: String, CaseIterable {
    case weekPlan = "recipes.weekPlan"
    case adhoc = "recipes.adhoc"
}

struct RecipesView: View {
    @EnvironmentObject var recipeHistoryVM: RecipeHistoryViewModel
    @State private var selectedTab: RecipeTab = .weekPlan
    @State private var showRecentRecipes = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    ForEach(RecipeTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue.localized).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGroupedBackground))
                
                // Tab content
                TabView(selection: $selectedTab) {
                    PlanWeekView()
                        .tag(RecipeTab.weekPlan)
                    
                    AdHocRecipeContentView()
                        .tag(RecipeTab.adhoc)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("tab.recipes".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if selectedTab == .adhoc && !recipeHistoryVM.recentRecipes.isEmpty {
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
            .sheet(isPresented: $showRecentRecipes) {
                RecentRecipesView()
            }
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
                        if usageVM.hasFreePlanRestrictions {
                            showPaywall = true
                        } else {
                            if mode == .text {
                                Task { await generateRecipe() }
                            } else {
                                Task { await generateRecipeFromPhoto() }
                            }
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
                    .disabled((mode == .text && prompt.isEmpty) || (mode == .photo && selectedImage == nil) || isGenerating)
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
            SubscriptionPaywallView(limitReached: false)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .onChange(of: photoPickerItem) {
            Task { @MainActor in
                if let data = try? await photoPickerItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
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
                language: String(language),
                maxMinutes: complexity.rawValue
            )
            
            recipeVM.currentRecipe = recipe
            
            // Auto-save to recent recipes
            recipeHistoryVM.saveRecipe(recipe, source: "adhoc-text")
            
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
            
            // Build constraints based on toggle and instructions
            var constraintsDict: [String: Any]
            if useConstraints {
                let constraints = familyVM.aggregatedConstraints()
                constraintsDict = [
                    "diet": constraints.diet,
                    "evict": constraints.evict
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
            
            showingRecipe = true
        } catch {
            errorMessage = "\("plan.error".localized): \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
}
