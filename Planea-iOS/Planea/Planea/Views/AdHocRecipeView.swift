import SwiftUI
import PhotosUI

enum AdHocMode: String, CaseIterable {
    case text = "adhoc.modeText"
    case photo = "adhoc.modePhoto"
}

struct AdHocRecipeView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var recipeVM: RecipeViewModel
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
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    // Mode Picker
                    Section {
                        Picker("", selection: $mode) {
                            ForEach(AdHocMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue.localized).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Text Mode
                    if mode == .text {
                        Section(header: Text("adhoc.recipeIdea".localized)) {
                            TextField("adhoc.promptPlaceholder".localized, text: $prompt, axis: .vertical)
                                .lineLimit(3...6)
                                .focused($isTextFieldFocused)
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
                        }
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
                
                // Loading overlay
                if isGenerating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    GeneratingLoadingView(totalItems: 1)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle("adhoc.title".localized)
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
            .onChange(of: photoPickerItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
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
    
    func generateRecipeFromPhoto() async {
        guard let image = selectedImage else { return }
        
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
            
            // Compress and resize image before sending
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
            
            // Convert to JPEG with compression
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

// MARK: - Image Picker Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
