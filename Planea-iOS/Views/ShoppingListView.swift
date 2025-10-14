import SwiftUI
import EventKit

struct ShoppingListView: View {
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var shoppingVM: ShoppingViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @State private var shoppingList: ShoppingList?
    @State private var showingSortOptions = false
    @State private var showingExportOptions = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if let list = shoppingList {
                    VStack(spacing: 0) {
                        // Sort picker
                        Picker("Ordre", selection: Binding(
                            get: { list.sortOrder },
                            set: { newValue in
                                shoppingList?.sortOrder = newValue
                                sortItems()
                            }
                        )) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        // Shopping list
                        List {
                            ForEach(getSortedItems().indices, id: \.self) { idx in
                                let item = getSortedItems()[idx]
                                HStack {
                                    Button(action: {
                                        toggleItemChecked(item)
                                    }) {
                                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(item.isChecked ? .green : .gray)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text(item.name)
                                        .strikethrough(item.isChecked)
                                    
                                    Spacer()
                                    
                                    Text("\(item.totalQuantity, specifier: "%.1f") \(item.unit)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .onMove { source, destination in
                                if shoppingList?.sortOrder == .custom {
                                    moveItems(from: source, to: destination)
                                }
                            }
                        }
                        .environment(\.editMode, shoppingList?.sortOrder == .custom ? .constant(.active) : .constant(.inactive))
                        
                        // Export button
                        Button(action: { showingExportOptions = true }) {
                            Label("Exporter", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("Aucune liste d'épicerie")
                            .font(.headline)
                        
                        Text("Générez un plan de repas d'abord, puis revenez ici pour voir votre liste d'épicerie.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if let plan = planVM.currentPlan {
                            Button("Générer la liste") {
                                generateShoppingList(from: plan)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Liste d'épicerie")
            .toolbar {
                if shoppingList != nil {
                    Button("Actualiser") {
                        if let plan = planVM.currentPlan {
                            generateShoppingList(from: plan)
                        }
                    }
                }
            }
            .confirmationDialog("Exporter vers", isPresented: $showingExportOptions, titleVisibility: .visible) {
                Button("Apple Notes") {
                    exportToNotes()
                }
                Button("Apple Reminders") {
                    exportToReminders()
                }
                Button("Partager (Google Keep, etc.)") {
                    exportViaShare()
                }
                Button("Copier le texte") {
                    copyToClipboard()
                }
                Button("Annuler", role: .cancel) { }
            }
            .alert("Exportation", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            if let plan = planVM.currentPlan, shoppingList == nil {
                generateShoppingList(from: plan)
            }
        }
    }
    
    // MARK: - Sorting Functions
    
    func getSortedItems() -> [ShoppingItem] {
        guard let list = shoppingList else { return [] }
        
        switch list.sortOrder {
        case .alphabetical:
            return list.items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            
        case .storeLayout:
            return list.items.sorted { item1, item2 in
                let section1 = StoreSection.section(for: item1.category)
                let section2 = StoreSection.section(for: item2.category)
                
                if section1.sortPriority != section2.sortPriority {
                    return section1.sortPriority < section2.sortPriority
                }
                return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            }
            
        case .custom:
            if list.customOrder.isEmpty {
                return list.items
            }
            // Sort by custom order
            return list.items.sorted { item1, item2 in
                guard let idx1 = list.customOrder.firstIndex(of: item1.id),
                      let idx2 = list.customOrder.firstIndex(of: item2.id) else {
                    return false
                }
                return idx1 < idx2
            }
        }
    }
    
    func sortItems() {
        guard var list = shoppingList else { return }
        
        // Update custom order when switching to custom mode
        if list.sortOrder == .custom && list.customOrder.isEmpty {
            list.customOrder = getSortedItems().map { $0.id }
            shoppingList = list
        }
    }
    
    func moveItems(from source: IndexSet, to destination: Int) {
        guard var list = shoppingList else { return }
        
        var sortedItems = getSortedItems()
        sortedItems.move(fromOffsets: source, toOffset: destination)
        
        // Update custom order
        list.customOrder = sortedItems.map { $0.id }
        shoppingList = list
    }
    
    func toggleItemChecked(_ item: ShoppingItem) {
        guard var list = shoppingList else { return }
        if let idx = list.items.firstIndex(where: { $0.id == item.id }) {
            list.items[idx].isChecked.toggle()
            shoppingList = list
        }
    }
    
    // MARK: - Data Functions
    
    func generateShoppingList(from plan: MealPlan) {
        let units = UnitSystem(rawValue: unitSystem) ?? .metric
        shoppingList = shoppingVM.buildList(from: plan.items, units: units)
    }
    
    // MARK: - Export Functions
    
    func getListText() -> String {
        guard let list = shoppingList else { return "" }
        
        var text = "Liste d'épicerie\n"
        text += "Générée le \(list.generatedAt.formatted(date: .abbreviated, time: .shortened))\n\n"
        
        let sortedItems = getSortedItems()
        var currentSection = ""
        
        for item in sortedItems {
            // Add section header for store layout
            if list.sortOrder == .storeLayout {
                let section = StoreSection.section(for: item.category)
                let sectionName = section.rawValue.capitalized
                if sectionName != currentSection {
                    currentSection = sectionName
                    text += "\n\(currentSection):\n"
                }
            }
            
            let check = item.isChecked ? "✓" : "○"
            text += "\(check) \(item.name) - \(String(format: "%.1f", item.totalQuantity)) \(item.unit)\n"
        }
        
        return text
    }
    
    func exportToNotes() {
        let text = getListText()
        
        // Use URL scheme for Notes app
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mobilenotes://create?note=\(encodedText)") {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback to sharing if URL scheme doesn't work
                    exportViaShare()
                }
            }
        }
    }
    
    func exportToReminders() {
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .reminder) { granted, error in
            DispatchQueue.main.async {
                guard granted, error == nil else {
                    alertMessage = "Accès aux rappels refusé. Veuillez autoriser l'accès dans les Réglages."
                    showingAlert = true
                    return
                }
                
                guard let list = shoppingList else { return }
                
                // Create reminders list if it doesn't exist
                let calendar = eventStore.defaultCalendarForNewReminders()
                var successCount = 0
                
                for item in getSortedItems() where !item.isChecked {
                    let reminder = EKReminder(eventStore: eventStore)
                    reminder.title = "\(item.name) - \(String(format: "%.1f", item.totalQuantity)) \(item.unit)"
                    reminder.calendar = calendar
                    reminder.priority = 1
                    
                    do {
                        try eventStore.save(reminder, commit: false)
                        successCount += 1
                    } catch {
                        print("Error saving reminder: \(error)")
                    }
                }
                
                do {
                    try eventStore.commit()
                    alertMessage = "\(successCount) articles ajoutés aux Rappels"
                    showingAlert = true
                } catch {
                    alertMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    func exportViaShare() {
        let text = getListText()
        
        // This allows sharing to Google Keep, Google Tasks, or any other app
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // For iPad: set popover presentation
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    func copyToClipboard() {
        let text = getListText()
        UIPasteboard.general.string = text
        alertMessage = "Liste copiée dans le presse-papiers"
        showingAlert = true
    }
}
