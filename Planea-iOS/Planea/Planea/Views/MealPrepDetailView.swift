import SwiftUI

struct MealPrepDetailView: View {
    let kit: MealPrepKit
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Tab Picker
            Picker("", selection: $selectedTab) {
                Text(LocalizedStringKey("meal_prep.detail.recipes_tab"))
                    .tag(0)
                Text(LocalizedStringKey("meal_prep.detail.preparation_tab"))
                    .tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            TabView(selection: $selectedTab) {
                recipesTab
                    .tag(0)
                
                preparationTab
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(kit.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Recipes Tab
    
    private var recipesTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Kit Summary
                kitSummarySection
                
                Divider()
                
                // Recipes List
                VStack(alignment: .leading, spacing: 16) {
                    Text(LocalizedStringKey("meal_prep.detail.recipes_section"))
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(kit.recipes) { recipeRef in
                        recipeCard(recipeRef)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    private var kitSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let description = kit.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Statistics
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(kit.recipes.count)", systemImage: "fork.knife")
                        .font(.headline)
                    Text(LocalizedStringKey("meal_prep.detail.recipes_count"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(kit.totalPortions)", systemImage: "person.2")
                        .font(.headline)
                    Text(LocalizedStringKey("meal_prep.detail.portions_count"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Label(formatPrepTime(minutes: kit.estimatedPrepMinutes), systemImage: "clock")
                        .font(.headline)
                    Text(LocalizedStringKey("meal_prep.total_time"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private func recipeCard(_ recipeRef: MealPrepRecipeRef) -> some View {
        Group {
            if let recipe = recipeRef.recipe {
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    recipeCardContent(recipeRef, recipe: recipe)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                recipeCardContent(recipeRef, recipe: nil)
            }
        }
    }
    
    private func recipeCardContent(_ recipeRef: MealPrepRecipeRef, recipe: Recipe?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Recipe Title & Storage Info
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipeRef.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Storage information
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text("\(recipeRef.shelfLifeDays)j")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: recipeRef.isFreezable ? "snowflake" : "snowflake.slash")
                                .font(.caption)
                            Text(LocalizedStringKey(recipeRef.isFreezable ? "meal_prep.freezable" : "meal_prep.not_freezable"))
                                .font(.caption)
                        }
                        .foregroundColor(recipeRef.isFreezable ? .blue : .orange)
                    }
                    
                    if let storageNote = recipeRef.storageNote {
                        Text(storageNote)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                Spacer()
                
                // Add chevron if recipe is available
                if recipe != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Recipe Details (if available)
            if let recipe = recipe {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("\(recipe.servings)", systemImage: "person.2")
                            .font(.caption)
                        Spacer()
                        Label("\(recipe.totalMinutes)min", systemImage: "clock")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Preparation Tab
    
    private var preparationTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let groupedSteps = kit.groupedPrepSteps, !groupedSteps.isEmpty {
                    // Grouped prep steps from backend
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizedStringKey("meal_prep.detail.grouped_prep_title"))
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(Array(groupedSteps.enumerated()), id: \.element.id) { index, step in
                            groupedStepCard(step, index: index + 1)
                        }
                    }
                } else {
                    // Fallback: No grouped steps available
                    VStack(spacing: 16) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text(LocalizedStringKey("meal_prep.detail.no_grouped_steps"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(LocalizedStringKey("meal_prep.detail.no_grouped_steps_hint"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding(.vertical)
        }
    }
    
    private func groupedStepCard(_ step: GroupedPrepStep, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step header
            HStack {
                Text("\(index)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.accentColor))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.actionType)
                        .font(.headline)
                    
                    if let estimatedMinutes = step.estimatedMinutes {
                        Label("\(estimatedMinutes)min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Description
            Text(step.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Ingredients by recipe
            if !step.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("meal_prep.detail.ingredients"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(step.ingredients) { ingredient in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(ingredient.name) (\(ingredient.quantity))")
                                    .font(.caption)
                                
                                Text(ingredient.recipeTitle)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(8)
            }
            
            // Detailed steps
            if !step.detailedSteps.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("meal_prep.detail.instructions"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(step.detailedSteps.enumerated()), id: \.offset) { index, detailStep in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(detailStep)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    
    private func formatPrepTime(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h\(mins)"
            }
        }
    }
}
