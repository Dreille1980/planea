import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
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
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(pendingRecipe.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            HStack {
                                Label("\(pendingRecipe.servings) portions", systemImage: "person.2")
                                Spacer()
                                Label("\(pendingRecipe.totalMinutes) min", systemImage: "clock")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
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
                        .cornerRadius(8)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    await viewModel.confirmRecipeModification()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("chat.pending_recipe.confirm".localized)
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                            .disabled(viewModel.isLoading)
                            
                            Button(action: {
                                viewModel.cancelRecipeModification()
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("chat.pending_recipe.cancel".localized)
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
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
                checkPremiumAccess()
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallView()
            }
        }
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("chat.welcome.title".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("chat.welcome.subtitle".localized)
                .font(.body)
                .foregroundColor(.secondary)
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
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.isLoading &&
        viewModel.isOnline &&
        viewModel.hasPremiumAccess
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
            planVM?.draftPlan
        }
        
        viewModel.updateRecipe = { [weak planVM, weak shoppingVM] recipe, weekdayStr, mealTypeStr in
            // Update recipe in plan if it exists
            guard let plan = planVM?.draftPlan else { return }
            
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
                    planVM?.draftPlan = updatedPlan
                    print("✅ Updated recipe at \(weekday.rawValue) \(mealType.rawValue)")
                }
            } else {
                // Fallback: Find by recipe ID if no metadata available
                if let index = plan.items.firstIndex(where: { $0.recipe.id == recipe.id }) {
                    var updatedPlan = plan
                    updatedPlan.items[index].recipe = recipe
                    planVM?.draftPlan = updatedPlan
                    print("✅ Updated recipe by ID")
                }
            }
        }
        
        viewModel.refreshShoppingList = { [weak planVM, weak shoppingVM] in
            // Regenerate shopping list with updated recipes
            if let plan = planVM?.draftPlan {
                let units = UnitSystem(rawValue: UserDefaults.standard.string(forKey: "unitSystem") ?? "metric") ?? .metric
                _ = shoppingVM?.generateList(from: plan.items, units: units)
            }
        }
        
        // Inject FamilyViewModel for adding members
        viewModel.familyViewModel = familyVM
    }
    
    private func checkPremiumAccess() {
        if !viewModel.hasPremiumAccess {
            showPaywall = true
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(StoreManager.shared)
        .environmentObject(RecipeHistoryViewModel())
        .environmentObject(FavoritesViewModel())
}
