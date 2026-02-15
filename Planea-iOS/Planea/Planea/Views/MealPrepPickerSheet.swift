import SwiftUI

struct MealPrepPickerSheet: View {
    let date: Date
    let mealType: MealType
    let onSelect: (MealPrepKit) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MealPrepViewModel()
    
    var availableKits: [MealPrepKit] {
        viewModel.kits.filter { $0.hasAvailablePortions && !$0.isExpired }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if availableKits.isEmpty {
                    emptyState
                } else {
                    kitsList
                }
            }
            .navigationTitle(LocalizedStringKey("mealprep.picker.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("common.cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadMealPreps()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                NSLocalizedString("mealprep.picker.empty_title", comment: ""),
                systemImage: "takeoutbag.and.cup.and.straw"
            )
        } description: {
            Text(LocalizedStringKey("mealprep.picker.empty_message"))
        } actions: {
            Button {
                dismiss()
            } label: {
                Text(LocalizedStringKey("mealprep.picker.create_new"))
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Kits List
    
    private var kitsList: some View {
        List {
            // Info header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.accentColor)
                        Text(date, style: .date)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(mealType.localizedName)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Available kits
            Section {
                ForEach(availableKits) { kit in
                    Button {
                        onSelect(kit)
                        dismiss()
                    } label: {
                        kitRow(kit)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text(LocalizedStringKey("mealprep.picker.available_kits"))
            }
        }
    }
    
    // MARK: - Kit Row
    
    private func kitRow(_ kit: MealPrepKit) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(kit.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Metadata
                HStack(spacing: 12) {
                    // Portions
                    Label {
                        Text(String(format: NSLocalizedString("mealprep.portions_count", comment: ""), kit.remainingPortions))
                    } icon: {
                        Image(systemName: "person.2")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    // Prepared date
                    Label {
                        Text(kit.preparedDate, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // Expiration warning if applicable
                if let warning = kit.expirationWarning {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(warning)
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.top, 2)
                }
                
                // Recipes preview
                if !kit.recipes.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(kit.recipes.prefix(3)) { recipe in
                                Text(recipe.title)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .foregroundColor(.secondary)
                                    .cornerRadius(6)
                            }
                            
                            if kit.recipes.count > 3 {
                                Text("+\(kit.recipes.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    MealPrepPickerSheet(
        date: Date(),
        mealType: .dinner,
        onSelect: { _ in }
    )
}
