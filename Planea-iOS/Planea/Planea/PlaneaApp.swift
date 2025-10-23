import SwiftUI

@main
struct PlaneaApp: App {
    @StateObject private var familyVM = FamilyViewModel()
    @StateObject private var planVM = PlanViewModel()
    @StateObject private var recipeVM = RecipeViewModel()
    @StateObject private var recipeHistoryVM = RecipeHistoryViewModel()
    @StateObject private var shoppingVM = ShoppingViewModel()
    @StateObject private var favoritesVM = FavoritesViewModel()
    @StateObject private var usageVM = UsageViewModel()
    @StateObject private var storeManager = StoreManager.shared
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(familyVM)
                .environmentObject(planVM)
                .environmentObject(recipeVM)
                .environmentObject(recipeHistoryVM)
                .environmentObject(shoppingVM)
                .environmentObject(favoritesVM)
                .environmentObject(usageVM)
                .environmentObject(storeManager)
                .environment(\.locale, Locale(identifier: AppLanguage.currentLocale(appLanguage)))
                .id(appLanguage) // Force view to rebuild when language changes
                .onAppear {
                    // Sync LocalizationHelper with AppStorage
                    LocalizationHelper.shared.currentLanguage = appLanguage
                    // Connect UsageViewModel to FavoritesViewModel
                    favoritesVM.setUsageViewModel(usageVM)
                }
                .onChange(of: appLanguage) {
                    // Update LocalizationHelper when language changes
                    LocalizationHelper.shared.currentLanguage = appLanguage
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var storeManager: StoreManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding = false
    
    private var hasActiveSubscription: Bool {
        storeManager.hasActiveSubscription
    }
    
    var body: some View {
        TabView {
            // Recipes tab - combines Plan and Ad hoc generation
            RecipesView()
                .tabItem { Label("tab.recipes".localized, systemImage: "fork.knife") }
            
            // Shopping tab - freemium access with export restrictions
            ShoppingListView()
                .tabItem { Label("tab.shopping".localized, systemImage: "cart") }
            
            // Favorites tab - freemium access with save restrictions
            SavedRecipesView()
                .tabItem { Label("tab.favorites".localized, systemImage: "heart.fill") }
            
            // Settings tab - always accessible
            SettingsView()
                .tabItem { Label("tab.settings".localized, systemImage: "gearshape") }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingContainerView(isPresented: $showOnboarding)
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
            // Preload legal documents for offline use
            LegalDocumentService.shared.preloadDocuments()
        }
    }
}
