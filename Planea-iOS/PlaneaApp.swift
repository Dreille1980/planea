import SwiftUI

@main
struct PlaneaApp: App {
    @StateObject private var familyVM = FamilyViewModel()
    @StateObject private var planVM = PlanViewModel()
    @StateObject private var recipeVM = RecipeViewModel()
    @StateObject private var shoppingVM = ShoppingViewModel()
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(familyVM)
                .environmentObject(planVM)
                .environmentObject(recipeVM)
                .environmentObject(shoppingVM)
                .environment(\.locale, Locale(identifier: AppLanguage.currentLocale(appLanguage)))
        }
    }
}

struct RootView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding = false
    
    var body: some View {
        TabView {
            PlanWeekView()
                .tabItem { Label(String(localized: "tab.plan"), systemImage: "calendar") }
            ShoppingListView()
                .tabItem { Label(String(localized: "tab.shopping"), systemImage: "cart") }
            AdHocRecipeView()
                .tabItem { Label(String(localized: "adhoc.title"), systemImage: "fork.knife") }
            SettingsView()
                .tabItem { Label(String(localized: "tab.settings"), systemImage: "gearshape") }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
    }
}
