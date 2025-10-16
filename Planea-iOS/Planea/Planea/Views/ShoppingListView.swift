import SwiftUI
import EventKit

struct ShoppingListView: View {
    @EnvironmentObject var planVM: PlanViewModel
    @EnvironmentObject var shoppingVM: ShoppingViewModel
    @EnvironmentObject var usageVM: UsageViewModel
    @AppStorage("unitSystem") private var unitSystem: String = UnitSystem.metric.rawValue
    @State private var shoppingList: ShoppingList?
    @State private var showingSortOptions = false
    @State private var showingExportOptions = false
    @State private var showingAlert = false
    @State private var showPaywall = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if let list = shoppingList {
                    VStack(spacing: 0) {
                        // Sort picker
                        Picker("shopping.order".localized, selection: Binding(
                            get: { list.sortOrder },
                            set: { newValue in
                                shoppingList?.sortOrder = newValue
                                sortItems()
                            }
                        )) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.localizedName.localized).tag(order)
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
                        Button(action: {
                            if usageVM.hasFreePlanRestrictions {
                                showPaywall = true
                            } else {
                                showingExportOptions = true
                            }
                        }) {
                            HStack {
                                Label("action.export".localized, systemImage: "square.and.arrow.up")
                                if usageVM.hasFreePlanRestrictions {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                }
                            }
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
                        
                        Text("shopping.noList".localized)
                            .font(.headline)
                        
                        Text("shopping.generateFirst".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if let plan = planVM.currentPlan {
                            Button("plan.generateList".localized) {
                                generateShoppingList(from: plan)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("shopping.title".localized)
            .toolbar {
                if shoppingList != nil {
                    Button("action.refresh".localized) {
                        if let plan = planVM.currentPlan {
                            generateShoppingList(from: plan)
                        }
                    }
                }
            }
            .confirmationDialog("shopping.export".localized, isPresented: $showingExportOptions, titleVisibility: .visible) {
                Button("shopping.exportAppleNotes".localized) {
                    exportToNotes()
                }
                Button("shopping.exportReminders".localized) {
                    exportToReminders()
                }
                Button("shopping.exportShare".localized) {
                    exportViaShare()
                }
                Button("shopping.exportCopy".localized) {
                    copyToClipboard()
                }
                Button("action.cancel".localized, role: .cancel) { }
            }
            .alert("shopping.exportTitle".localized, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showPaywall) {
                SubscriptionPaywallView(limitReached: false)
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
        
        var text = "\("shopping.title".localized)\n"
        text += "\("shopping.generatedOn".localized) \(list.generatedAt.formatted(date: .abbreviated, time: .shortened))\n\n"
        
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
                    alertMessage = "shopping.accessDenied".localized
                    showingAlert = true
                    return
                }
                
                guard shoppingList != nil else { return }
                
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
                    alertMessage = "\(successCount) \("shopping.itemsAdded".localized)"
                    showingAlert = true
                } catch {
                    alertMessage = "\("shopping.errorSaving".localized): \(error.localizedDescription)"
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
        alertMessage = "shopping.copied".localized
        showingAlert = true
    }
}
