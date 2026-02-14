import SwiftUI

/// Sheet view for applying a template to a specific start date
struct ApplyTemplateSheet: View {
    let template: TemplateWeek
    let onApply: (Date) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate: Date
    
    init(template: TemplateWeek, onApply: @escaping (Date) -> Void) {
        self.template = template
        self.onApply = onApply
        // Default to next Sunday
        _selectedDate = State(initialValue: WeekDateHelper.nextSunday())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Template info
                VStack(spacing: 8) {
                    Text("Appliquer le template")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(template.name)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.planeaPrimary)
                }
                .padding(.top)
                
                // Date picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choisir la date de début")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    DatePicker(
                        "Date de début",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .tint(.planeaPrimary)
                    
                    // Week range preview
                    HStack {
                        Image(systemName: "calendar")
                        Text("Semaine: \(WeekDateHelper.formatWeekRange(startDate: selectedDate))")
                            .font(.subheadline)
                    }
                    .foregroundColor(.planeaSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.planeaChipDefault)
                    .cornerRadius(10)
                }
                .padding()
                
                // Quick action button
                Button(action: {
                    selectedDate = WeekDateHelper.todayAtMidnight()
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                        Text("Commencer aujourd'hui")
                    }
                    .font(.subheadline)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.planeaSecondary)
                .padding(.horizontal)
                
                Spacer()
                
                // Apply button
                Button(action: {
                    onApply(selectedDate)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Créer le plan")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.planeaPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Preview provider for ApplyTemplateSheet
#if DEBUG
struct ApplyTemplateSheet_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTemplate = TemplateWeek(
            id: UUID(),
            familyId: UUID(),
            name: "Ma semaine favorite",
            days: [
                TemplateDay(
                    weekdayIndex: 1,
                    meals: [
                        TemplateMeal(
                            mealType: .dinner,
                            recipe: Recipe(
                                id: UUID(),
                                title: "Poulet rôti",
                                servings: 4,
                                totalMinutes: 60,
                                ingredients: [],
                                steps: []
                            )
                        )
                    ]
                )
            ]
        )
        
        ApplyTemplateSheet(template: sampleTemplate) { date in
            print("Selected date: \(date)")
        }
    }
}
#endif
