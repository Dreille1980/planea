import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    @StateObject private var storeManager = StoreManager.shared
    @State private var showDeveloperCodeField = false
    @State private var developerCode = ""
    @State private var versionTapCount = 0
    @State private var showSubscriptionSheet = false
    @State private var showFeatureTour = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Subscription Section
                Section(header: Text("settings.subscription".localized)) {
                    HStack {
                        Label("subscription.status".localized, systemImage: "star.circle.fill")
                        Spacer()
                        subscriptionStatusBadge
                    }
                    
                    // Show usage for free plan users
                    if !storeManager.hasActiveSubscription {
                        HStack {
                            Text("usage.monthly".localized)
                            Spacer()
                            Text(usageVM.usageDisplayString())
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if storeManager.hasActiveSubscription {
                        Button(action: {
                            Task {
                                await storeManager.openSubscriptionManagement()
                            }
                        }) {
                            HStack {
                                Text("subscription.manage".localized)
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                        
                        if let info = storeManager.subscriptionInfo {
                            if info.status == .inTrial, let daysRemaining = info.daysRemainingInTrial {
                                HStack {
                                    Text("subscription.trial.remaining".localized)
                                    Spacer()
                                    Text("\(daysRemaining) \("subscription.trial.daysLeft".localized)")
                                        .foregroundStyle(.secondary)
                                }
                            } else if info.status == .developerAccess {
                                Button(action: {
                                    storeManager.removeDeveloperAccess()
                                }) {
                                    HStack {
                                        Text("subscription.developer.remove".localized)
                                        Spacer()
                                        Image(systemName: "xmark.circle")
                                    }
                                }
                                .foregroundStyle(.red)
                            }
                        }
                    } else {
                        Button(action: {
                            showSubscriptionSheet = true
                        }) {
                            HStack {
                                Text("subscription.subscribe.now".localized)
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                        }
                    }
                    
                    // Hidden developer code field
                    if showDeveloperCodeField {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("subscription.developer.code".localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                TextField("", text: $developerCode)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.allCharacters)
                                    .disableAutocorrection(true)
                                
                                Button(action: validateDeveloperCode) {
                                    Text("action.validate".localized)
                                        .font(.subheadline)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
                
                Section(header: Text("settings.family".localized)) {
                    NavigationLink(destination: FamilyManagementView()) {
                        HStack {
                            Label("settings.manageFamily".localized, systemImage: "person.3.fill")
                            Spacer()
                            Text("\(familyVM.members.count) \("settings.members".localized)")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Generation Preferences Section (Premium Only)
                if storeManager.hasActiveSubscription {
                    Section(header: HStack {
                        Text("prefs.generation".localized)
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }) {
                        NavigationLink(destination: GenerationPreferencesView()) {
                            Label("prefs.title".localized, systemImage: "slider.horizontal.3")
                        }
                    }
                }
                
                Section(header: Text("settings.preferences".localized)) {
                    Picker("settings.units".localized, selection: $unitSystem) {
                        Text("units.metric".localized).tag(UnitSystem.metric.rawValue)
                        Text("units.imperial".localized).tag(UnitSystem.imperial.rawValue)
                    }
                    Picker("settings.language".localized, selection: $appLanguage) {
                        Text("lang.system".localized).tag(AppLanguage.system.rawValue)
                        Text("Français").tag(AppLanguage.fr.rawValue)
                        Text("English").tag(AppLanguage.en.rawValue)
                    }
                }
                
                // Support & Feedback Section
                Section(header: Text("settings.support".localized)) {
                    Button(action: sendFeedback) {
                        HStack {
                            Label("settings.feedback".localized, systemImage: "envelope.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                // Help Section
                Section(header: Text("settings.help".localized)) {
                    Button(action: { showFeatureTour = true }) {
                        HStack {
                            Label("settings.viewTour".localized, systemImage: "play.circle.fill")
                            Spacer()
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                // Legal Section
                Section(header: Text("legal.title".localized)) {
                    NavigationLink(destination: LegalDocumentView(documentType: .termsAndConditions)) {
                        Label("legal.terms.title".localized, systemImage: "doc.text")
                    }
                    
                    NavigationLink(destination: LegalDocumentView(documentType: .privacyPolicy)) {
                        Label("legal.privacy.title".localized, systemImage: "hand.raised.fill")
                    }
                }
                
                // About Section with hidden tap gesture
                Section {
                    HStack {
                        Text("settings.version".localized)
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleVersionTap()
                    }
                }
            }
            .navigationTitle(Text("tab.settings".localized))
            .sheet(isPresented: $showSubscriptionSheet) {
                SubscriptionPaywallView(canDismiss: true)
            }
            .sheet(isPresented: $showFeatureTour) {
                AppFeatureTourView(isOnboarding: false)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var subscriptionStatusBadge: some View {
        Group {
            if let info = storeManager.subscriptionInfo {
                switch info.status {
                case .active:
                    Text("subscription.status.active".localized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.green))
                case .inTrial:
                    Text("subscription.status.trial".localized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue))
                case .developerAccess:
                    Text("subscription.status.developer".localized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.purple))
                case .expired, .notSubscribed:
                    Text("subscription.status.free".localized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.gray))
                }
            } else {
                Text("subscription.status.free".localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.gray))
            }
        }
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    // MARK: - Actions
    
    private func handleVersionTap() {
        versionTapCount += 1
        
        if versionTapCount >= 10 {
            showDeveloperCodeField = true
            versionTapCount = 0
        }
        
        // Reset counter after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if versionTapCount < 10 {
                versionTapCount = 0
            }
        }
    }
    
    private func validateDeveloperCode() {
        if storeManager.validateDeveloperAccessCode(developerCode) {
            developerCode = ""
            showDeveloperCodeField = false
        } else {
            // Show error or shake animation
            developerCode = ""
        }
    }
    
    private func sendFeedback() {
        let systemVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        
        let subject = "feedback.subject".localized
        let body = String(format: "feedback.body".localized, appVersion, systemVersion, deviceModel)
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let mailtoString = "mailto:dreyerfred+planea@gmail.com?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let mailtoURL = URL(string: mailtoString) {
            if UIApplication.shared.canOpenURL(mailtoURL) {
                UIApplication.shared.open(mailtoURL)
            }
        }
    }
}
