import SwiftUI

struct ChatMessageBubble: View {
    let message: ChatMessage
    let isLastAgentMessage: Bool
    @ObservedObject var chatViewModel: ChatViewModel
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                // Check if message contains meal plan data
                if !message.isFromUser, let planData = parseMealPlanData(from: message.content) {
                    // Show meal plan cards
                    mealPlanView(planData: planData)
                }
                // Check if message contains pending recipe card (📋)
                else if !message.isFromUser, message.content.contains("📋"), let recipeData = parsePendingRecipeData(from: message.content) {
                    // Show recipe card
                    pendingRecipeCardView(recipeData: recipeData)
                }
                else {
                    // Show regular message bubble
                    messageContentView
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(message.isFromUser ? Color.blue : Color(.systemGray5))
                        .foregroundColor(message.isFromUser ? .white : .primary)
                        .cornerRadius(16)
                }
                
                // Show confirmation buttons for pending add meal
                if !message.isFromUser && isLastAgentMessage && chatViewModel.pendingMealToAdd != nil {
                    addMealConfirmationButtons
                }
                // Show confirmation buttons if this is the last agent message and there's a pending modification
                else if !message.isFromUser && isLastAgentMessage && chatViewModel.pendingRecipeModification != nil {
                    confirmationButtons
                }
                
                // Show mode indicator for agent messages
                if !message.isFromUser, let mode = message.detectedMode {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.caption2)
                        Text(mode.displayName)
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var messageContentView: some View {
        let lines = message.content.components(separatedBy: "\n")
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                if line.hasPrefix("ℹ️") {
                    // Disclaimer line - smaller font
                    Text(line)
                        .font(.caption2)
                        .foregroundColor(message.isFromUser ? .white.opacity(0.8) : .secondary)
                } else if !line.isEmpty {
                    // Regular content
                    Text(line)
                }
            }
        }
    }
    
    @ViewBuilder
    private func mealPlanView(planData: [DayPlanData]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text response before cards (if any)
            if let textBefore = extractTextBeforePlan(from: message.content) {
                Text(textBefore)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    .padding(.bottom, 12)
            }
            
            // Meal plan cards
            MealPlanCardsView(planData: planData)
            
            // Text response after cards (if any)
            if let textAfter = extractTextAfterPlan(from: message.content) {
                Text(textAfter)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    .padding(.top, 12)
            }
        }
    }
    
    // MARK: - Meal Plan Parsing
    
    private func parseMealPlanData(from content: String) -> [DayPlanData]? {
        // Check if message contains meal plan markers
        guard content.contains("📅") || content.contains("PLAN ACTUEL") || 
              content.contains("Lundi:") || content.contains("Monday:") else {
            return nil
        }
        
        // Get current plan from chat view model
        guard let currentPlan = chatViewModel.getCurrentPlan?() else {
            return nil
        }
        
        var dayPlans: [DayPlanData] = []
        
        // Define day order and names
        let dayMapping: [(abbr: String, fullNameFR: String, fullNameEN: String)] = [
            ("Mon", "Lundi", "Monday"),
            ("Tue", "Mardi", "Tuesday"),
            ("Wed", "Mercredi", "Wednesday"),
            ("Thu", "Jeudi", "Thursday"),
            ("Fri", "Vendredi", "Friday"),
            ("Sat", "Samedi", "Saturday"),
            ("Sun", "Dimanche", "Sunday")
        ]
        
        // Parse each day in order
        for (dayAbbr, dayNameFR, dayNameEN) in dayMapping {
            // Find meals for this day in the current plan
            let dayMeals = currentPlan.items.filter { $0.weekday.rawValue == dayAbbr }
            
            guard !dayMeals.isEmpty else { continue }
            
            // Determine day name based on language in message
            let dayName = content.contains("Lundi") || content.contains("Mardi") ? dayNameFR : dayNameEN
            
            var meals: [MealData] = []
            for planItem in dayMeals {
                let mealTypeDisplay: String
                if content.contains("Déjeuner") || content.contains("Dîner") || content.contains("Souper") {
                    // French
                    switch planItem.mealType {
                    case .breakfast: mealTypeDisplay = "Déjeuner"
                    case .lunch: mealTypeDisplay = "Dîner"
                    case .dinner: mealTypeDisplay = "Souper"
                    case .snack: mealTypeDisplay = "Collation"
                    }
                } else {
                    // English
                    switch planItem.mealType {
                    case .breakfast: mealTypeDisplay = "Breakfast"
                    case .lunch: mealTypeDisplay = "Lunch"
                    case .dinner: mealTypeDisplay = "Dinner"
                    case .snack: mealTypeDisplay = "Snack"
                    }
                }
                
                let mealData = MealData(
                    mealType: mealTypeDisplay,
                    title: planItem.recipe.title,
                    servings: planItem.recipe.servings,
                    time: planItem.recipe.totalMinutes,
                    fullRecipe: planItem.recipe
                )
                meals.append(mealData)
            }
            
            if !meals.isEmpty {
                dayPlans.append(DayPlanData(dayName: dayName, meals: meals))
            }
        }
        
        return dayPlans.isEmpty ? nil : dayPlans
    }
    
    private func extractTextBeforePlan(from content: String) -> String? {
        // Extract text before the plan section
        if let range = content.range(of: "📅") {
            let before = String(content[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            return before.isEmpty ? nil : before
        }
        return nil
    }
    
    private func extractTextAfterPlan(from content: String) -> String? {
        // For now, we'll show any text after the plan section
        // This can be enhanced based on specific markers
        return nil
    }
    
    // MARK: - Pending Recipe Parsing & View
    
    struct PendingRecipeData {
        let title: String
        let dayMeal: String
        let servings: Int
        let time: Int
    }
    
    private func parsePendingRecipeData(from content: String) -> PendingRecipeData? {
        // Parse format:
        // 📋 **Titre de la recette**
        // 🍽️ Pour: Lundi dîner
        // 👥 Portions: 4
        // ⏱️ Temps: 30 minutes
        
        let lines = content.components(separatedBy: "\n")
        var title: String?
        var dayMeal: String?
        var servings: Int?
        var time: Int?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("📋") {
                // Extract title between ** **
                if let startRange = trimmed.range(of: "**"),
                   let endRange = trimmed.range(of: "**", range: startRange.upperBound..<trimmed.endIndex) {
                    title = String(trimmed[startRange.upperBound..<endRange.lowerBound])
                }
            } else if trimmed.hasPrefix("🍽️") {
                // Extract day and meal
                if let colonRange = trimmed.range(of: ":") {
                    dayMeal = String(trimmed[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
            } else if trimmed.hasPrefix("👥") {
                // Extract servings
                let numbers = trimmed.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                servings = Int(numbers)
            } else if trimmed.hasPrefix("⏱️") {
                // Extract time
                let numbers = trimmed.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                time = Int(numbers)
            }
        }
        
        guard let title = title, let dayMeal = dayMeal, let servings = servings, let time = time else {
            return nil
        }
        
        return PendingRecipeData(title: title, dayMeal: dayMeal, servings: servings, time: time)
    }
    
    @ViewBuilder
    private func pendingRecipeCardView(recipeData: PendingRecipeData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.orange)
                Text(recipeData.title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text(recipeData.dayMeal)
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    Text("\(recipeData.servings) portions")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.purple)
                        .frame(width: 20)
                    Text("\(recipeData.time) min")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
        )
    }
    
    @ViewBuilder
    private var addMealConfirmationButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                chatViewModel.confirmAddMeal()
            }) {
                Label("Ajouter au plan", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(20)
            }
            
            Button(action: {
                chatViewModel.cancelAddMeal()
            }) {
                Label("Annuler", systemImage: "xmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(20)
            }
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var confirmationButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                Task {
                    await chatViewModel.confirmRecipeModification()
                }
            }) {
                Label("chat.confirm.button".localized, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(20)
            }
            
            Button(action: {
                chatViewModel.cancelRecipeModification()
            }) {
                Label("chat.cancel.button".localized, systemImage: "xmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(20)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    let viewModel = ChatViewModel()
    
    return VStack(spacing: 16) {
        ChatMessageBubble(
            message: ChatMessage(
                content: "Bonjour! Comment puis-je vous aider avec vos repas aujourd'hui?",
                isFromUser: false,
                detectedMode: .nutritionCoach
            ),
            isLastAgentMessage: true,
            chatViewModel: viewModel
        )
        
        ChatMessageBubble(
            message: ChatMessage(
                content: "Je voudrais des conseils pour des repas équilibrés",
                isFromUser: true
            ),
            isLastAgentMessage: false,
            chatViewModel: viewModel
        )
        
        ChatMessageBubble(
            message: ChatMessage(
                content: "ℹ️ Cette information est à titre général seulement et ne remplace pas un avis médical professionnel.\n\nPour des repas équilibrés, voici quelques conseils...",
                isFromUser: false,
                detectedMode: .nutritionCoach
            ),
            isLastAgentMessage: true,
            chatViewModel: viewModel
        )
    }
    .padding()
}
