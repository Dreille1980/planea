import SwiftUI
import FirebaseCore
import FirebaseCrashlytics
import UserNotifications

@main
struct PlaneaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Enable Crashlytics collection
        #if DEBUG
        // Disable Crashlytics in debug builds to avoid test crashes
        // Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #endif
    }
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
                    
                    // Log app open to Analytics
                    AnalyticsService.shared.logAppOpen()
                    
                    // Set user properties for Analytics & Crashlytics
                    setupAnalyticsUserProperties()
                }
                .onChange(of: appLanguage) {
                    // Update LocalizationHelper when language changes
                    LocalizationHelper.shared.currentLanguage = appLanguage
                    
                    // Update Analytics & Crashlytics
                    AnalyticsService.shared.setUserProperty(appLanguage, forName: "app_language")
                    CrashlyticsService.shared.setLanguage(appLanguage)
                }
        }
    }
    
    // MARK: - Analytics Setup
    
    private func setupAnalyticsUserProperties() {
        // Set language
        AnalyticsService.shared.setUserProperty(appLanguage, forName: "app_language")
        CrashlyticsService.shared.setLanguage(appLanguage)
        
        // Set unit system
        AnalyticsService.shared.setUserProperty(unitSystem, forName: "unit_system")
        CrashlyticsService.shared.setUnitSystem(unitSystem)
        
        // Set subscription status
        let subscriptionStatus = storeManager.hasActiveSubscription ? "subscribed" : "free"
        AnalyticsService.shared.setUserProperty(subscriptionStatus, forName: "subscription_status")
        CrashlyticsService.shared.setSubscriptionStatus(subscriptionStatus)
        
        // Set family member count
        let memberCount = familyVM.members.count
        AnalyticsService.shared.setUserProperty("\(memberCount)", forName: "family_member_count")
        CrashlyticsService.shared.setFamilyMemberCount(memberCount)
    }
}

struct RootView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var usageVM: UsageViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding = false
    @State private var showFreeTrialExpiration = false
    @State private var showWhatsNew = false
    @State private var selectedTab: Int = 0
    
    private var hasActiveSubscription: Bool {
        storeManager.hasActiveSubscription
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Free trial banner at the top
            if !Config.isFreeVersion {
                FreeTrialBanner()
            }
            
            TabView(selection: $selectedTab) {
                // Recipes tab - combines Plan and Ad hoc generation
                RecipesView()
                    .tabItem { Label("tab.recipes".localized, systemImage: "fork.knife") }
                    .tag(0)
                
                // Shopping tab - freemium access with export restrictions
                ShoppingListView()
                    .tabItem { Label("tab.shopping".localized, systemImage: "cart") }
                    .tag(1)
                
                // Favorites tab - freemium access with save restrictions
                SavedRecipesView()
                    .tabItem { Label("tab.favorites".localized, systemImage: "heart.fill") }
                    .tag(2)
                
                // Settings tab - always accessible
                SettingsView()
                    .tabItem { Label("tab.settings".localized, systemImage: "gearshape") }
                    .tag(3)
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingContainerView(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showFreeTrialExpiration) {
            if !Config.isFreeVersion {
                FreeTrialExpirationView()
            }
        }
        .sheet(isPresented: $showWhatsNew) {
            let version = "1.2.1"
            let features = WhatsNewService.shared.getWhatsNewItems(for: version)
            WhatsNewView(version: version, features: features)
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            } else {
                // Check if we should show What's New (only if onboarding is complete)
                checkWhatsNew()
            }
            // Preload legal documents for offline use
            LegalDocumentService.shared.preloadDocuments()
            
            // Check if trial just expired
            checkTrialExpiration()
            
            // Listen for notification to open Recipes tab
            setupNotificationObserver()
        }
        .onChange(of: storeManager.subscriptionInfo?.status) { oldValue, newValue in
            // Check for trial expiration when status changes
            checkTrialExpiration()
        }
    }
    
    private func checkTrialExpiration() {
        let freeTrialService = FreeTrialService.shared
        if freeTrialService.shouldShowExpirationMessage {
            showFreeTrialExpiration = true
            freeTrialService.markExpirationMessageShown()
        }
    }
    
    private func checkWhatsNew() {
        // Use version 1.2.1 as the target version for this release
        let targetVersion = "1.2.1"
        if WhatsNewService.shared.shouldShowWhatsNew(for: targetVersion) {
            // Delay showing What's New to avoid conflict with other sheets
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showWhatsNew = true
                // Log What's New view
                AnalyticsService.shared.logWhatsNewViewed(version: targetVersion)
            }
        }
    }
    
    // MARK: - Notification Observer
    
    private func setupNotificationObserver() {
        // Listen for notification to open Recipes tab
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenRecipesTab"),
            object: nil,
            queue: .main
        ) { [self] _ in
            // Switch to Recipes tab (tab 0)
            selectedTab = 0
        }
    }
}

// MARK: - AppDelegate for Notifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @AppStorage("weeklyMealPrepReminder") private var weeklyMealPrepReminder: Bool = true
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Schedule weekly reminder if enabled
        if weeklyMealPrepReminder {
            NotificationService.shared.scheduleWeeklyMealPrepReminder()
        }
        
        return true
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Called when notification is received while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Called when user taps on notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Check if this is a meal prep reminder notification
        if let action = userInfo["action"] as? String, action == "openRecipesTab" {
            // Post notification to open Recipes tab
            NotificationCenter.default.post(name: NSNotification.Name("OpenRecipesTab"), object: nil)
            
            // Log analytics
            AnalyticsService.shared.logEvent(name: "notification_tapped", parameters: [
                "type": "weekly_meal_prep"
            ])
        }
        
        completionHandler()
    }
}
