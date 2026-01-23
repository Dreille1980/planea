import SwiftUI

struct OnboardingGenerationPreferencesView: View {
    @Binding var progress: OnboardingProgress
    let onContinue: () -> Void
    
    @State private var preferences: GenerationPreferences
    
    init(progress: Binding<OnboardingProgress>, onContinue: @escaping () -> Void) {
        self._progress = progress
        self.onContinue = onContinue
        _preferences = State(initialValue: PreferencesService.shared.loadPreferences())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.purple.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)
                }
                .padding(.top, 32)
                
                Text("onboarding.prefs.title".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("onboarding.prefs.subtitle".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 24)
            
            // Preferences Form
            Form {
                // Time Section (Free)
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("prefs.weekday".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Text("\(preferences.weekdayMaxMinutes) min")
                                .frame(width: 70, alignment: .leading)
                            Slider(value: Binding(
                                get: { Double(preferences.weekdayMaxMinutes) },
                                set: { preferences.weekdayMaxMinutes = Int($0) }
                            ), in: 15...90, step: 5)
                        }
                        
                        Text("prefs.weekend".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        
                        HStack {
                            Text("\(preferences.weekendMaxMinutes) min")
                                .frame(width: 70, alignment: .leading)
                            Slider(value: Binding(
                                get: { Double(preferences.weekendMaxMinutes) },
                                set: { preferences.weekendMaxMinutes = Int($0) }
                            ), in: 15...120, step: 5)
                        }
                    }
                } header: {
                    Label("prefs.time".localized, systemImage: "clock")
                }
                
                // Spice Level Section (Free)
                Section {
                    Picker("prefs.spice".localized, selection: $preferences.spiceLevel) {
                        ForEach(SpiceLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("prefs.spice".localized, systemImage: "flame")
                }
                
                // Proteins Section (Free)
                Section {
                    ForEach(Protein.allCases) { protein in
                        Toggle(protein.displayName, isOn: Binding(
                            get: { preferences.preferredProteins.contains(protein) },
                            set: { isOn in
                                if isOn {
                                    preferences.preferredProteins.insert(protein)
                                } else {
                                    preferences.preferredProteins.remove(protein)
                                }
                            }
                        ))
                    }
                } header: {
                    Label("prefs.proteins".localized, systemImage: "fork.knife")
                }
                
                // Appliances Section (Free)
                Section {
                    ForEach(Appliance.allCases) { appliance in
                        Toggle(isOn: Binding(
                            get: { preferences.availableAppliances.contains(appliance) },
                            set: { isOn in
                                if isOn {
                                    preferences.availableAppliances.insert(appliance)
                                } else {
                                    preferences.availableAppliances.remove(appliance)
                                }
                            }
                        )) {
                            Label(appliance.displayName, systemImage: appliance.icon)
                        }
                    }
                } header: {
                    Label("prefs.appliances".localized, systemImage: "cooktop")
                }
                
                // Kid-Friendly Section (Free)
                Section {
                    Toggle("prefs.kidfriendly".localized, isOn: $preferences.kidFriendly)
                } header: {
                    Label("prefs.options".localized, systemImage: "star")
                }
                
                // Weekly Flyers Section
                Section {
                    Toggle("prefs.flyers.enabled".localized, isOn: $preferences.useWeeklyFlyers)
                    
                    if preferences.useWeeklyFlyers {
                        TextField("prefs.flyers.postalcode".localized, text: $preferences.postalCode)
                            .textContentType(.postalCode)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                        
                        TextField("prefs.flyers.store".localized, text: $preferences.preferredGroceryStore)
                            .textContentType(.organizationName)
                            .autocapitalization(.words)
                    }
                } header: {
                    Label("prefs.flyers.title".localized, systemImage: "tag")
                } footer: {
                    Text("prefs.flyers.footer".localized)
                }
            }
            
            // Continue Button
            Button(action: saveAndContinue) {
                Text("action.continue".localized)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
    
    private func saveAndContinue() {
        PreferencesService.shared.savePreferences(preferences)
        progress.hasCompletedPreferences = true
        progress.save()
        onContinue()
    }
}

#Preview {
    OnboardingGenerationPreferencesView(
        progress: .constant(OnboardingProgress()),
        onContinue: { print("Continue") }
    )
}
