import Foundation

final class ShoppingViewModel: ObservableObject {
    func buildList(from items: [MealItem], units: UnitSystem) -> ShoppingList {
        var map: [String: (qty: Double, unit: String, category: String)] = [:]
        for item in items {
            for ing in item.recipe.ingredients {
                let key = ing.name.lowercased()
                let current = map[key] ?? (0, ing.unit, ing.category)
                map[key] = (current.qty + ing.quantity, ing.unit, ing.category)
            }
        }
        let listItems: [ShoppingItem] = map.map { (name, v) in
            ShoppingItem(name: name.capitalized, totalQuantity: v.qty, unit: v.unit, category: v.category)
        }.sorted { $0.category < $1.category }
        return ShoppingList(mealPlanId: UUID(), units: units, items: listItems)
    }
}
