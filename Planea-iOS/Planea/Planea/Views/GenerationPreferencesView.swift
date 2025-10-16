import SwiftUI

struct GenerationPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var preferences: GenerationPreferences
    @State private var hasChanges = false
    
    init() {
        _preferences = State(initialValue: PreferencesService.shared.loadPreferences())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Time Section
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
                                set: { preferences.weekdayMaxMinutes = Int($0); hasChanges = true }
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
                                set: { preferences.weekendMaxMinutes = Int($0); hasChanges = true }
                            ), in: 15...120, step: 5)
                        }
                    }
                } header: {
                    Label("prefs.time".localized, systemImage: "clock")
                } footer: {
                    Text("prefs.time.footer".localized)
                }
                
                // Spice Level Section
                Section {
                    Picker("prefs.spice".localized, selection: Binding(
                        get: { preferences.spiceLevel },
                        set: { preferences.spiceLevel = $0; hasChanges = true }
                    )) {
                        ForEach(SpiceLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("prefs.spice".localized, systemImage: "flame")
                }
                
                // Proteins Section
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
                                hasChanges = true
                            }
                        ))
                    }
                } header: {
                    Label("prefs.proteins".localized, systemImage: "fork.knife")
                } footer: {
                    Text("prefs.proteins.footer".localized)
                }
                
                // Appliances Section
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
                                hasChanges = true
                            }
                        )) {
                            Label(appliance.displayName, systemImage: appliance.icon)
                        }
                    }
                } header: {
                    Label("prefs.appliances".localized, systemImage: "cooktop")
                } footer: {
                    Text("prefs.appliances.footer".localized)
                }
                
                // Kid-Friendly Section
                Section {
                    Toggle("prefs.kidfriendly".localized, isOn: Binding(
                        get: { preferences.kidFriendly },
                        set: { preferences.kidFriendly = $0; hasChanges = true }
                    ))
                } header: {
                    Label("prefs.options".localized, systemImage: "slider.horizontal.3")
                } footer: {
                    Text("prefs.kidfriendly.footer".localized)
                }
                
                // Reset Section
                Section {
                    Button(role: .destructive, action: resetToDefaults) {
                        Label("prefs.reset".localized, systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("prefs.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save".localized) {
                        savePreferences()
                    }
                    .disabled(!hasChanges)
                }
            }
        }
    }
    
    private func savePreferences() {
        PreferencesService.shared.savePreferences(preferences)
        dismiss()
    }
    
    private func resetToDefaults() {
        preferences = .default
        hasChanges = true
    }
}

#Preview {
    GenerationPreferencesView()
}
