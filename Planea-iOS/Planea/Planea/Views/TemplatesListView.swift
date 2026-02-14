import SwiftUI

struct TemplatesListView: View {
    @EnvironmentObject var planVM: PlanViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    @State private var templateToDelete: TemplateWeek?
    @State private var selectedTemplate: TemplateWeek?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if planVM.templates.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("Aucun template")
                            .font(.title2)
                            .bold()
                        
                        Text("Créez un plan que vous aimez, puis sauvegardez-le comme template pour le réutiliser!")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    // Templates list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(planVM.templates) { template in
                                TemplateCard(
                                    template: template,
                                    onSelect: {
                                        selectedTemplate = template
                                        planVM.selectedTemplate = template
                                        planVM.showApplyTemplateSheet = true
                                    },
                                    onDelete: {
                                        templateToDelete = template
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mes Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                planVM.loadTemplates()
            }
            .alert("Supprimer le template?", isPresented: $showDeleteConfirmation) {
                Button("Annuler", role: .cancel) {
                    templateToDelete = nil
                }
                Button("Supprimer", role: .destructive) {
                    if let template = templateToDelete {
                        withAnimation {
                            planVM.deleteTemplate(id: template.id)
                        }
                        templateToDelete = nil
                    }
                }
            } message: {
                if let template = templateToDelete {
                    Text("Êtes-vous sûr de vouloir supprimer '\(template.name)'?")
                }
            }
        }
        .sheet(isPresented: $planVM.showApplyTemplateSheet) {
            if let template = planVM.selectedTemplate {
                ApplyTemplateSheet(template: template) { startDate in
                    planVM.applyTemplate(template, startDate: startDate)
                    planVM.showApplyTemplateSheet = false
                    dismiss()
                }
                .presentationDetents([.height(650)])
            }
        }
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: TemplateWeek
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var mealCount: Int {
        template.days.reduce(0) { $0 + $1.meals.count }
    }
    
    var dayCount: Int {
        template.days.count
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Barre verticale verte
            Rectangle()
                .fill(Color.planeaTertiary)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .bold()
                            .foregroundColor(.planeaTextPrimary)
                        
                        Text("Créé le \(formattedDate(template.createdDate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundColor(.planeaDanger)
                            .frame(width: 32, height: 32)
                    }
                }
                
                Divider()
                
                // Stats
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("\(dayCount) jours")
                            .font(.caption)
                            .bold()
                    }
                    .foregroundColor(.planeaTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.planeaChipDefault)
                    .cornerRadius(8)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "fork.knife")
                            .font(.caption)
                        Text("\(mealCount) repas")
                            .font(.caption)
                            .bold()
                    }
                    .foregroundColor(.planeaTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.planeaChipDefault)
                    .cornerRadius(8)
                    
                    Spacer()
                }
                
                // Apply button
                Button(action: onSelect) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Appliquer")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.planeaPrimary)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.planeaCard)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
