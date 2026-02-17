import SwiftUI

struct WizardSuccessView: View {
    let config: WeekGenerationConfig
    let generatedPlan: MealPlan
    let onViewMealPreps: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Success Header
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text(NSLocalizedString("wizard.success.title", comment: ""))
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(NSLocalizedString("wizard.success.subtitle", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Summary Cards
                VStack(spacing: 16) {
                    // Total meals generated
                    SummaryCard(
                        icon: "fork.knife",
                        iconColor: .accentColor,
                        title: NSLocalizedString("wizard.success.total_meals", comment: ""),
                        value: "\(generatedPlan.items.count)",
                        subtitle: NSLocalizedString("wizard.success.meals_generated", comment: "")
                    )
                    
                    // Meal Prep section (if applicable)
                    if config.hasMealPrep {
                        SummaryCard(
                            icon: "takeoutbag.and.cup.and.straw.fill",
                            iconColor: .orange,
                            title: NSLocalizedString("wizard.success.meal_prep_days", comment: ""),
                            value: "\(config.mealPrepDays.count)",
                            subtitle: "\(config.mealPrepPortions) \(NSLocalizedString("wizard.success.portions_prepared", comment: ""))"
                        )
                    }
                    
                    // Normal days section (if applicable)
                    if config.hasNormalDays {
                        SummaryCard(
                            icon: "calendar",
                            iconColor: .blue,
                            title: NSLocalizedString("wizard.success.normal_days", comment: ""),
                            value: "\(config.normalDays.count)",
                            subtitle: NSLocalizedString("wizard.success.regular_meals", comment: "")
                        )
                    }
                }
                .padding(.horizontal)
                
                // Meal Prep List (if applicable)
                if config.hasMealPrep {
                    MealPrepListSection(
                        config: config,
                        generatedPlan: generatedPlan
                    )
                    .padding(.horizontal)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    // View Meal Preps button (if applicable)
                    if config.hasMealPrep {
                        Button {
                            onViewMealPreps()
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                Text(NSLocalizedString("wizard.success.view_meal_preps", comment: ""))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Done button
                    Button {
                        onDismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text(NSLocalizedString("wizard.success.done", comment: ""))
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Summary Card

private struct SummaryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(iconColor)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Meal Prep List Section

private struct MealPrepListSection: View {
    let config: WeekGenerationConfig
    let generatedPlan: MealPlan
    
    private func mealTypeIcon(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "sun.horizon"
        case .lunch: return "fork.knife"
        case .dinner: return "moon.stars"
        case .snack: return "leaf"
        }
    }
    
    private var mealPrepRecipes: [MealItem] {
        generatedPlan.items
            .filter { item in
                config.mealPrepDays.contains(item.weekday)
            }
            .sorted { first, second in
                let allDays = Weekday.allCases
                guard let firstIndex = allDays.firstIndex(of: first.weekday),
                      let secondIndex = allDays.firstIndex(of: second.weekday) else {
                    return false
                }
                return firstIndex < secondIndex
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("wizard.success.meal_prep_recipes", comment: ""))
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(mealPrepRecipes) { item in
                    HStack(spacing: 12) {
                        // Day indicator
                        VStack {
                            Text(item.weekday.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.orange)
                        )
                        
                        // Recipe info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.recipe.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 8) {
                                Label(item.mealType.localizedName, systemImage: mealTypeIcon(item.mealType))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Label("\(item.recipe.totalMinutes) min", systemImage: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.tertiarySystemBackground))
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WizardSuccessView(
            config: WeekGenerationConfig.default(familySize: 4, weekStartDay: .monday),
            generatedPlan: MealPlan(
                id: UUID(),
                familyId: UUID(),
                weekStart: Date(),
                items: [],
                status: .draft,
                confirmedDate: nil,
                name: nil
            ),
            onViewMealPreps: {},
            onDismiss: {}
        )
    }
}
