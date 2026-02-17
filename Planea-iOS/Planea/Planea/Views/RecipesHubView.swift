import SwiftUI

/// Écran d'accueil de la section Recettes avec 3 options principales
struct RecipesHubView: View {
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    
    @Binding var selectedAction: RecipesAction?
    @State private var showNoPlanAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.planeaPrimary)
                    
                    Text("recipes.hub.title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("recipes.hub.subtitle".localized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // Options cards
                VStack(spacing: 16) {
                    // Option 1: Consulter le plan
                    ActionCard(
                        icon: "calendar",
                        iconColor: .planeaPrimary,
                        title: "recipes.hub.viewPlan.title".localized,
                        subtitle: planVM.activePlan != nil 
                            ? "recipes.hub.viewPlan.subtitle.active".localized
                            : "recipes.hub.viewPlan.subtitle.none".localized,
                        badge: planVM.activePlan != nil ? "recipes.hub.viewPlan.badge".localized : nil
                    ) {
                        if planVM.activePlan != nil {
                            selectedAction = .viewPlan
                        } else {
                            showNoPlanAlert = true
                        }
                    }
                    
                    // Option 2: Générer un nouveau plan
                    ActionCard(
                        icon: "wand.and.stars",
                        iconColor: .planeaSecondary,
                        title: "recipes.hub.generatePlan.title".localized,
                        subtitle: "recipes.hub.generatePlan.subtitle".localized,
                        badge: nil
                    ) {
                        selectedAction = .generatePlan
                    }
                    
                    // Option 3: Recette Ad Hoc
                    ActionCard(
                        icon: "sparkles",
                        iconColor: .purple,
                        title: "recipes.hub.adHoc.title".localized,
                        subtitle: "recipes.hub.adHoc.subtitle".localized,
                        badge: nil
                    ) {
                        selectedAction = .adHoc
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.planeaBackground)
        .alert("recipes.hub.noPlan.title".localized, isPresented: $showNoPlanAlert) {
            Button("recipes.hub.noPlan.create".localized) {
                selectedAction = .generatePlan
            }
            Button("action.cancel".localized, role: .cancel) {}
        } message: {
            Text("recipes.hub.noPlan.message".localized)
        }
    }
}

// MARK: - Recipes Action Enum

enum RecipesAction: Identifiable {
    case viewPlan
    case generatePlan
    case adHoc
    
    var id: String {
        switch self {
        case .viewPlan: return "viewPlan"
        case .generatePlan: return "generatePlan"
        case .adHoc: return "adHoc"
        }
    }
}

// MARK: - Action Card

private struct ActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.planeaCard)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecipesHubView(selectedAction: .constant(nil))
            .environmentObject(PlanViewModel())
            .environmentObject(FamilyViewModel())
            .environmentObject(UsageViewModel())
    }
}
