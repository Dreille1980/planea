import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var speechService = SpeechRecognitionService()
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var recipeHistoryVM: RecipeHistoryViewModel
    @EnvironmentObject var favoritesVM: FavoritesViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var shoppingVM: ShoppingViewModel
    @EnvironmentObject var familyVM: FamilyViewModel
    
    @State private var messageText = ""
    @State private var showPaywall = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages ScrollView
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // Welcome message if conversation is empty
                            if viewModel.currentConversation.messages.isEmpty {
                                welcomeView
                                    .padding(.top, 40)
                            }
                            
                            // Messages
                            ForEach(Array(viewModel.currentConversation.messages.enumerated()), id: \.element.id) { index, message in
                                let isLastAgentMessage = !message.isFromUser && index == viewModel.currentConversation.messages.lastIndex(where: { !$0.isFromUser })
                                ChatMessageBubble(
                                    message: message,
                                    isLastAgentMessage: isLastAgentMessage,
                                    chatViewModel: viewModel
                                )
                                .id(message.id)
                            }
                            
                            // Loading indicator
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.currentConversation.messages.count) {
                        // Auto-scroll to bottom when new message arrives
                        if let lastMessage = viewModel.currentConversation.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Pending Recipe Modification
                if let pendingRecipe = viewModel.pendingRecipeModification {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.blue)
                            Text("chat.pending_recipe.title".localized)
                                .font(.planeaHeadline)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(pendingRecipe.title)
                                .font(.planeaSubheadline)
                            
                            HStack {
                                Label("\(pendingRecipe.servings) portions", systemImage: "person.2")
                                Spacer()
                                Label("\(pendingRecipe.totalMinutes) min", systemImage: "clock")
                            }
                            .font(.planeaCaption)
                            .foregroundColor(.planeaTextSecondary)
                            
                            NavigationLink(destination: RecipeDetailView(recipe: pendingRecipe)) {
                                HStack {
                                    Text("chat.pending_recipe.view".localized)
                                        .font(.caption)
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(PlaneaRadius.card)
                        
                        HStack(spacing: PlaneaSpacing.sm) {
                            Button(action: {
                                Task {
                                    await viewModel.confirmRecipeModification()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("chat.pending_recipe.confirm".localized)
                                }
                                .font(.planeaSubheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PlaneaSpacing.sm)
                                .background(Color.green)
                                .cornerRadius(PlaneaRadius.button)
                            }
                            .disabled(viewModel.isLoading)
                            
                            Button(action: {
                                viewModel.cancelRecipeModification()
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("chat.pending_recipe.cancel".localized)
                                }
                                .font(.planeaSubheadline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, PlaneaSpacing.sm)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(PlaneaRadius.button)
                            }
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Offline warning
                if !viewModel.isOnline {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("chat.offline.message".localized)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Error message
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text(error)
                        Spacer()
                        Button(action: { viewModel.clearError() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Suggested actions
                if !viewModel.suggestedActions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.suggestedActions, id: \.self) { action in
                                Button(action: {
                                    Task {
                                        await viewModel.useSuggestedAction(action)
                                    }
                                }) {
                                    Text(action)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                }
                                .disabled(viewModel.isLoading)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
                
                // Input field
                HStack(spacing: 12) {
                    TextField("chat.input.placeholder".localized, text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .disabled(viewModel.isLoading || !viewModel.isOnline)
                    
                    Button(action: toggleRecording) {
                        Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                            .font(.title2)
                            .foregroundColor(speechService.isRecording ? .red : .blue)
                    }
                    .disabled(viewModel.isLoading || !viewModel.isOnline)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(canSendMessage ? .blue : .gray)
                    }
                    .disabled(!canSendMessage)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("chat.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.startNewConversation() }) {
                            Label("chat.action.new".localized, systemImage: "plus.message")
                        }
                        
                        Button(role: .destructive, action: { viewModel.deleteCurrentConversation() }) {
                            Label("chat.action.delete".localized, systemImage: "trash")
                        }
                        .disabled(viewModel.currentConversation.messages.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                setupViewModel()
            }
            .onChange(of: speechService.recognizedText) { oldValue, newValue in
                // Update message text with recognized speech
                if !newValue.isEmpty && newValue != oldValue {
                    messageText = newValue
                }
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallView()
            }
        }
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(spacing: PlaneaSpacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            
            Text("chat.welcome.title".localized)
                .font(.planeaTitle2)
                .foregroundColor(.planeaTextPrimary)
            
            Text("chat.welcome.subtitle".localized)
                .font(.planeaBody)
                .foregroundColor(.planeaTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 12) {
                // Guided Setup - Temporarily hidden but kept for future use
                // FeatureBadge(
                //     icon: "person.crop.circle.badge.checkmark",
                //     title: "chat.feature.onboarding".localized,
                //     description: "chat.feature.onboarding.desc".localized
                // )
                
                FeatureBadge(
                    icon: "book.closed",
                    title: "chat.feature.recipeqa".localized,
                    description: "chat.feature.recipeqa.desc".localized
                )
                
                FeatureBadge(
                    icon: "heart.text.square",
                    title: "chat.feature.coach".localized,
                    description: "chat.feature.coach.desc".localized
                )
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Helper Views
    
    private struct FeatureBadge: View {
        let icon: String
        let title: String
        let description: String
        
        var body: some View {
            HStack(alignment: .top, spacing: PlaneaSpacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.planeaSubheadline)
                    Text(description)
                        .font(.planeaCaption)
                        .foregroundColor(.planeaTextSecondary)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.isLoading &&
        viewModel.isOnline
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        isInputFocused = false
        
        Task {
            await viewModel.sendMessage(text)
        }
    }
    
    private func setupViewModel() {
        // Inject context providers
        viewModel.getRecentRecipes = { [weak recipeHistoryVM] in
            recipeHistoryVM?.recentRecipes ?? []
        }
        
        viewModel.getFavoriteRecipes = { [weak favoritesVM] in
            favoritesVM?.savedRecipes ?? []
        }
        
        viewModel.getPreferences = {
            PreferencesService.shared.loadPreferences()
        }
        
        viewModel.getCurrentPlan = { [weak planVM] in
            planVM?.currentPlan
        }
        
        viewModel.updateRecipe = { [weak planVM, weak shoppingVM] recipe, weekdayStr, mealTypeStr in
            // Update recipe in plan if it exists
            guard let plan = planVM?.currentPlan else { return }
            
            // If we have weekday and meal_type metadata, use them for precise matching
            if let wdStr = weekdayStr, let mtStr = mealTypeStr,
               let weekday = Weekday(rawValue: wdStr),
               let mealType = MealType(rawValue: mtStr) {
                // Find the specific meal by weekday and meal_type
                if let index = plan.items.firstIndex(where: { 
                    $0.weekday == weekday && $0.mealType == mealType 
                }) {
                    var updatedPlan = plan
                    updatedPlan.items[index].recipe = recipe
                    planVM?.currentPlan = updatedPlan
                    print("✅ Updated recipe at \(weekday.rawValue) \(mealType.rawValue)")
                }
            } else {
                // Fallback: Find by recipe ID if no metadata available
                if let index = plan.items.firstIndex(where: { $0.recipe.id == recipe.id }) {
                    var updatedPlan = plan
                    updatedPlan.items[index].recipe = recipe
                    planVM?.currentPlan = updatedPlan
                    print("✅ Updated recipe by ID")
                }
            }
        }
        
        viewModel.addMealToPlan = { [weak planVM] recipe, weekdayStr, mealTypeStr in
            // Add a new meal to the plan
            print("🔍 addMealToPlan callback called:")
            print("   weekdayStr: '\(weekdayStr)'")
            print("   mealTypeStr: '\(mealTypeStr)'")
            print("   Recipe: '\(recipe.title)'")
            
            guard var plan = planVM?.currentPlan else {
                print("⚠️ Cannot add meal: no current plan available")
                return
            }
            
            guard let weekday = Weekday(rawValue: weekdayStr) else {
                print("⚠️ Cannot add meal: invalid weekday '\(weekdayStr)'")
                print("   Valid values: Mon, Tue, Wed, Thu, Fri, Sat, Sun")
                return
            }
            
            guard let mealType = MealType(rawValue: mealTypeStr) else {
                print("⚠️ Cannot add meal: invalid meal type '\(mealTypeStr)'")
                print("   Valid values: BREAKFAST, LUNCH, DINNER")
                return
            }
            
            print("🍽️ Adding meal to plan:")
            print("   Recipe: \(recipe.title)")
            print("   Weekday: \(weekday.rawValue)")
            print("   MealType: \(mealType.rawValue)")
            
            // Create new meal item
            let newItem = MealItem(
                weekday: weekday,
                mealType: mealType,
                recipe: recipe
            )
            
            // Add to plan
            plan.items.append(newItem)
            planVM?.currentPlan = plan
            
            print("✅ Meal added successfully to plan")
            print("   Total items in plan: \(plan.items.count)")
        }
        
        viewModel.refreshShoppingList = { [weak planVM, weak shoppingVM] in
            // Regenerate shopping list with updated recipes
            if let plan = planVM?.currentPlan {
                let units = UnitSystem(rawValue: UserDefaults.standard.string(forKey: "unitSystem") ?? "metric") ?? .metric
                _ = shoppingVM?.generateList(from: plan.items, units: units)
            }
        }
        
        // Inject FamilyViewModel for adding members
        viewModel.familyViewModel = familyVM
    }
    
    private func toggleRecording() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            Task {
                do {
                    try await speechService.startRecording()
                } catch {
                    if let speechError = error as? SpeechRecognitionError {
                        viewModel.showError(speechError.localizedDescription)
                    } else {
                        viewModel.showError("speech.error.generic".localized)
                    }
                }
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(StoreManager.shared)
        .environmentObject(RecipeHistoryViewModel())
        .environmentObject(FavoritesViewModel())
}
