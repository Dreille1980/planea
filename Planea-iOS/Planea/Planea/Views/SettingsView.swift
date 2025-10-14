import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.system.rawValue
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(String(localized: "settings.family"))) {
                    NavigationLink(destination: FamilyManagementView()) {
                        HStack {
                            Label(String(localized: "settings.manageFamily"), systemImage: "person.3.fill")
                            Spacer()
                            Text("\(familyVM.members.count) \(String(localized: "settings.members"))")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
                
                Section(header: Text(String(localized: "settings.preferences"))) {
                    Picker(String(localized: "settings.units"), selection: $unitSystem) {
                        Text(String(localized: "units.metric")).tag(UnitSystem.metric.rawValue)
                        Text(String(localized: "units.imperial")).tag(UnitSystem.imperial.rawValue)
                    }
                    Picker(String(localized: "settings.language"), selection: $appLanguage) {
                        Text(String(localized: "lang.system")).tag(AppLanguage.system.rawValue)
                        Text("Français").tag(AppLanguage.fr.rawValue)
                        Text("English").tag(AppLanguage.en.rawValue)
                    }
                }
            }
            .navigationTitle(Text(String(localized: "tab.settings")))
        }
    }
}
