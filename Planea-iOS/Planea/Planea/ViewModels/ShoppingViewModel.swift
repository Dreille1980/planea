import Foundation

final class ShoppingViewModel: ObservableObject {
    @Published var currentList: ShoppingList?
    
    func buildList(from items: [MealItem], units: UnitSystem) -> ShoppingList {
        var map: [String: (qty: Double, unit: String, category: String, isOnSale: Bool)] = [:]
        for item in items {
            for ing in item.recipe.ingredients {
                let key = ing.name.lowercased()
                let current = map[key] ?? (0, ing.unit, ing.category, ing.isOnSale)
                // If any instance of this ingredient is on sale, mark the whole item as on sale
                let isOnSale = current.isOnSale || ing.isOnSale
                map[key] = (current.qty + ing.quantity, ing.unit, ing.category, isOnSale)
            }
        }
        let listItems: [ShoppingItem] = map.map { (name, v) in
            ShoppingItem(name: name.capitalized, totalQuantity: v.qty, unit: v.unit, category: v.category, isOnSale: v.isOnSale)
        }.sorted { $0.category < $1.category }
        return ShoppingList(mealPlanId: UUID(), units: units, items: listItems)
    }
    
    func generateList(from items: [MealItem], units: UnitSystem) {
        currentList = buildList(from: items, units: units)
    }
    
    func toggleItemChecked(id: UUID) {
        guard let idx = currentList?.items.firstIndex(where: { $0.id == id }) else { return }
        currentList?.items[idx].isChecked.toggle()
    }
    
    func updateSortOrder(_ order: SortOrder) {
        currentList?.sortOrder = order
    }
    
    func updateCustomOrder(_ ids: [UUID]) {
        currentList?.customOrder = ids
    }
    
    func createListFromRecipe(recipe: Recipe, units: UnitSystem) {
        let listItems: [ShoppingItem] = recipe.ingredients.map { ing in
            ShoppingItem(
                name: ing.name.capitalized,
                totalQuantity: ing.quantity,
                unit: ing.unit,
                category: ing.category,
                isOnSale: ing.isOnSale
            )
        }.sorted { item1, item2 in
            let section1 = StoreSection.section(for: item1.category)
            let section2 = StoreSection.section(for: item2.category)
            if section1.sortPriority != section2.sortPriority {
                return section1.sortPriority < section2.sortPriority
            }
            return item1.name < item2.name
        }
        
        currentList = ShoppingList(mealPlanId: UUID(), units: units, items: listItems)
    }
    
    func addRecipeToList(recipe: Recipe) {
        guard currentList != nil else { return }
        
        // Add each ingredient to the existing list
        for ing in recipe.ingredients {
            let key = ing.name.lowercased()
            
            // Check if ingredient already exists in the list
            if let existingIndex = currentList?.items.firstIndex(where: { $0.name.lowercased() == key }) {
                // Update quantity of existing ingredient
                currentList?.items[existingIndex].totalQuantity += ing.quantity
                // If any instance is on sale, mark the whole item as on sale
                if ing.isOnSale {
                    currentList?.items[existingIndex].isOnSale = true
                }
            } else {
                // Add new ingredient
                let newItem = ShoppingItem(
                    name: ing.name.capitalized,
                    totalQuantity: ing.quantity,
                    unit: ing.unit,
                    category: ing.category,
                    isOnSale: ing.isOnSale
                )
                currentList?.items.append(newItem)
            }
        }
        
        // Re-sort the list based on current sort order
        if let sortOrder = currentList?.sortOrder {
            currentList?.items = sortItems(currentList?.items ?? [], by: sortOrder)
        }
    }
    
    private func sortItems(_ items: [ShoppingItem], by order: SortOrder) -> [ShoppingItem] {
        switch order {
        case .alphabetical:
            return items.sorted { $0.name < $1.name }
        case .storeLayout:
            return items.sorted { item1, item2 in
                let section1 = StoreSection.section(for: item1.category)
                let section2 = StoreSection.section(for: item2.category)
                if section1.sortPriority != section2.sortPriority {
                    return section1.sortPriority < section2.sortPriority
                }
                return item1.name < item2.name
            }
        case .custom:
            guard let customOrder = currentList?.customOrder else {
                return items
            }
            return items.sorted { item1, item2 in
                let index1 = customOrder.firstIndex(of: item1.id) ?? Int.max
                let index2 = customOrder.firstIndex(of: item2.id) ?? Int.max
                return index1 < index2
            }
        }
    }
}
