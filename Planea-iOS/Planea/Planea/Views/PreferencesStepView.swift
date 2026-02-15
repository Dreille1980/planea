import SwiftUI

struct PreferencesStepView: View {
    @ObservedObject var viewModel: WeekGenerationConfigViewModel
    @State private var showAllPreferences = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.stepNumber(for: 2))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(NSLocalizedString("wizard.step3.title", comment: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(NSLocalizedString("wizard.step3.subtitle", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                // Quick preferences (collapsed by default)
                VStack(alignment: .leading, spacing: 16) {
                    Button {
                        withAnimation {
                            showAllPreferences.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text(NSLocalizedString("wizard.step3.preferences.toggle", comment: ""))
                            Spacer()
                            Image(systemName: showAllPreferences ? "chevron.up" : "chevron.down")
                        }
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                    }
                    .padding(.horizontal)
                    
                    if showAllPreferences {
                        PreferencesForm(preferences: $viewModel.config.preferences)
                            .padding(.horizontal)
                    }
                }
                
                // Summary card (if preferences have been modified)
                if !showAllPreferences {
                    PreferencesSummaryCard(preferences: viewModel.config.preferences)
                        .padding(.horizontal)
                }
                
                // Info
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                    
                    Text(NSLocalizedString("wizard.step3.info", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Preferences Form

private struct PreferencesForm: View {
    @Binding var preferences: GenerationPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Time Section (simplified)
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("prefs.time", comment: ""))
                    .font(.headline)
                
                HStack {
                    Text(NSLocalizedString("prefs.weekday", comment: ""))
                        .font(.subheadline)
                    Spacer()
                    Text("\(preferences.weekdayMaxMinutes) min")
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(preferences.weekdayMaxMinutes) },
                    set: { preferences.weekdayMaxMinutes = Int($0) }
                ), in: 15...90, step: 5)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // Spice Level
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("prefs.spice", comment: ""))
                    .font(.headline)
                
                Picker("", selection: $preferences.spiceLevel) {
                    ForEach(SpiceLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // Kid-Friendly
            Toggle(NSLocalizedString("prefs.kidfriendly", comment: ""), isOn: $preferences.kidFriendly)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
        }
    }
}

// MARK: - Preferences Summary Card

private struct PreferencesSummaryCard: View {
    let preferences: GenerationPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("wizard.step3.summary.title", comment: ""))
                .font(.headline)
            
            HStack {
                Label("\(preferences.weekdayMaxMinutes) min", systemImage: "clock")
                Spacer()
                Label(preferences.spiceLevel.displayName, systemImage: "flame")
                Spacer()
                if preferences.kidFriendly {
                    Label(NSLocalizedString("prefs.kidfriendly", comment: ""), systemImage: "figure.2.and.child.holdinghands")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Preview

#Preview {
    PreferencesStepView(viewModel: WeekGenerationConfigViewModel(planViewModel: PlanViewModel()))
}
