import SwiftUI

struct MealPrepView: View {
    @StateObject private var viewModel: MealPrepViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var planViewModel: PlanViewModel
    @EnvironmentObject var usageViewModel: UsageViewModel
    @EnvironmentObject var shoppingViewModel: ShoppingViewModel
    @State private var showingWizard = false
    
    init(baseURL: URL) {
        _viewModel = StateObject(wrappedValue: MealPrepViewModel(baseURL: baseURL))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // CTA Button
                createButton
                
                // Recommended Kits Section
                if !viewModel.recommendedKits.isEmpty {
                    recommendedKitsSection
                }
                
                // History Section
                if !viewModel.history.isEmpty {
                    historySection
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey("meal_prep_title"))
        .sheet(isPresented: $showingWizard) {
            MealPrepWizardView(
                viewModel: viewModel,
                familyViewModel: familyViewModel,
                planViewModel: planViewModel,
                usageViewModel: usageViewModel,
                shoppingViewModel: shoppingViewModel
            )
        }
        .task {
            // Load recommended kits on appear
            let familySize = familyViewModel.members.count
            let constraints = buildConstraints()
            await viewModel.generateRecommendedKits(
                familySize: familySize,
                constraints: constraints,
                units: .metric,
                language: LocalizationHelper.currentLanguageCode()
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func buildConstraints() -> [String: Any] {
        let familyConstraints = familyViewModel.aggregatedConstraints()
        let generationPrefs = PreferencesService.shared.loadPreferences()
        
        var constraintsDict: [String: Any] = [
            "diet": familyConstraints.diet,
            "evict": familyConstraints.evict
        ]
        
        // Add generation preferences as a string that the backend can use to enrich the prompt
        constraintsDict["preferences_string"] = generationPrefs.toPromptString()
        
        return constraintsDict
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey("meal_prep_title"))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(LocalizedStringKey("meal_prep_subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Button(action: {
            showingWizard = true
        }) {
            HStack {
                Image(systemName: "calendar.badge.plus")
                    .font(.title3)
                
                Text(LocalizedStringKey("meal_prep_create_button"))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Recommended Kits Section
    
    private var recommendedKitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("meal_prep_recommended_kits"))
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(viewModel.recommendedKits) { kit in
                NavigationLink(destination: MealPrepDetailView(kit: kit)) {
                    MealPrepKitCard(
                        kit: kit,
                        onChoose: {
                            // TODO: Navigate to kit details or directly confirm
                            print("Chose kit: \(kit.name)")
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - History Section
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("meal_prep_history_title"))
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(viewModel.history) { instance in
                MealPrepHistoryRow(
                    instance: instance,
                    onViewDetails: {
                        // Navigation handled by NavigationLink wrapper
                    },
                    onReplay: {
                        Task {
                            // Extract params from instance (use defaults for replay)
                            let params = MealPrepGenerationParams(
                                days: [.monday, .tuesday, .wednesday, .thursday, .friday],
                                meals: [.lunch, .dinner],
                                servingsPerMeal: 4,
                                totalPrepTimePreference: .oneHourThirty,
                                skillLevel: .intermediate,
                                avoidRareIngredients: false,
                                preferLongShelfLife: false
                            )
                            
                            await viewModel.replayMealPrep(
                                instance: instance,
                                params: params,
                                planViewModel: planViewModel
                            )
                        }
                    },
                    onDelete: {
                        viewModel.deleteHistoryItem(id: instance.id)
                    }
                )
            }
        }
    }
}

// MARK: - Kit Card

struct MealPrepKitCard: View {
    let kit: MealPrepKit
    let onChoose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Kit header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(kit.name)
                        .font(.headline)
                    
                    if let description = kit.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Kit stats
            HStack(spacing: 16) {
                Label("\(kit.recipes.count) recettes", systemImage: "fork.knife")
                    .font(.caption)
                Label("\(kit.totalPortions) portions", systemImage: "person.2")
                    .font(.caption)
                Label("~\(kit.estimatedPrepMinutes/60)h\(kit.estimatedPrepMinutes%60)", systemImage: "clock")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            // Recipe list preview
            VStack(alignment: .leading, spacing: 4) {
                ForEach(kit.recipes.prefix(3)) { recipe in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 6, height: 6)
                        
                        Text(recipe.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Storage indicator
                        if !recipe.isFreezable {
                            Image(systemName: "snowflake.slash")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                if kit.recipes.count > 3 {
                    Text("+\(kit.recipes.count - 3) more...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 14)
                }
            }
            
            // Choose button
            Button(action: onChoose) {
                Text(LocalizedStringKey("meal_prep_choose_kit"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - History Row

struct MealPrepHistoryRow: View {
    let instance: MealPrepInstance
    let onViewDetails: () -> Void
    let onReplay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        NavigationLink(destination: MealPrepDetailView(kit: instance.kit)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(instance.kit.name)
                        .font(.headline)
                    
                    Text("\(instance.kit.totalPortions) portions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(instance.appliedWeekStart))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onReplay) {
                        Label(LocalizedStringKey("meal_prep_replay"), systemImage: "arrow.clockwise")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return String(format: NSLocalizedString("meal_prep_completed_date", comment: ""), formatter.string(from: date))
    }
}
