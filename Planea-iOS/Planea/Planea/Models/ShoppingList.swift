import Foundation

enum SortOrder: String, Codable, CaseIterable {
    case alphabetical = "alphabetical"
    case storeLayout = "storeLayout"
    case custom = "custom"
    
    var localizedName: String {
        switch self {
        case .alphabetical:
            return "shopping.sort.alphabetical"
        case .storeLayout:
            return "shopping.sort.storeLayout"
        case .custom:
            return "shopping.sort.custom"
        }
    }
}

struct ShoppingList: Identifiable, Codable {
    var id: UUID = .init()
    var mealPlanId: UUID
    var units: UnitSystem
    var generatedAt: Date = .init()
    var items: [ShoppingItem] = []
    var sortOrder: SortOrder = .storeLayout
    var customOrder: [UUID] = [] // Store custom order of item IDs
}

struct ShoppingItem: Identifiable, Codable, Equatable {
    var id: UUID = .init()
    var name: String
    var totalQuantity: Double
    var unit: String
    var category: String
    var isChecked: Bool = false
    var isOnSale: Bool = false
    var customSortIndex: Int = 0
    
    static func == (lhs: ShoppingItem, rhs: ShoppingItem) -> Bool {
        lhs.id == rhs.id
    }
}

// Store layout category order (typical grocery store layout)
enum StoreSection: String, CaseIterable {
    case fruits = "fruits"
    case vegetables = "vegetables"
    case dairy = "dairy"
    case meat = "meat"
    case fish = "fish"
    case bakery = "bakery"
    case grains = "grains"
    case pasta = "pasta"
    case canned = "canned"
    case condiments = "condiments"
    case spices = "spices"
    case frozen = "frozen"
    case beverages = "beverages"
    case snacks = "snacks"
    case other = "other"
    
    var sortPriority: Int {
        switch self {
        case .fruits: return 0
        case .vegetables: return 1
        case .dairy: return 2
        case .meat: return 3
        case .fish: return 4
        case .bakery: return 5
        case .grains: return 6
        case .pasta: return 7
        case .canned: return 8
        case .condiments: return 9
        case .spices: return 10
        case .frozen: return 11
        case .beverages: return 12
        case .snacks: return 13
        case .other: return 14
        }
    }
    
    static func section(for category: String) -> StoreSection {
        let lowercased = category.lowercased()
        
        // Map French and English category names to sections
        if lowercased.contains("fruit") {
            return .fruits
        }
        if lowercased.contains("légume") || lowercased.contains("legume") || lowercased.contains("vegetable") {
            return .vegetables
        }
        if lowercased.contains("lait") || lowercased.contains("dairy") || lowercased.contains("produit laitier") || lowercased.contains("fromage") || lowercased.contains("yaourt") || lowercased.contains("yogurt") {
            return .dairy
        }
        if lowercased.contains("viande") || lowercased.contains("meat") || lowercased.contains("boeuf") || lowercased.contains("beef") || lowercased.contains("poulet") || lowercased.contains("chicken") || lowercased.contains("porc") || lowercased.contains("pork") {
            return .meat
        }
        if lowercased.contains("poisson") || lowercased.contains("fish") || lowercased.contains("seafood") || lowercased.contains("fruit de mer") {
            return .fish
        }
        if lowercased.contains("pain") || lowercased.contains("bakery") || lowercased.contains("boulangerie") {
            return .bakery
        }
        if lowercased.contains("grain") || lowercased.contains("céréale") || lowercased.contains("cereal") || lowercased.contains("riz") || lowercased.contains("rice") {
            return .grains
        }
        if lowercased.contains("pasta") || lowercased.contains("pâte") || lowercased.contains("pate") {
            return .pasta
        }
        if lowercased.contains("conserve") || lowercased.contains("canned") {
            return .canned
        }
        if lowercased.contains("condiment") || lowercased.contains("sauce") {
            return .condiments
        }
        if lowercased.contains("épice") || lowercased.contains("spice") || lowercased.contains("herbe") || lowercased.contains("herb") {
            return .spices
        }
        if lowercased.contains("surgelé") || lowercased.contains("surgele") || lowercased.contains("frozen") || lowercased.contains("congelé") || lowercased.contains("congele") {
            return .frozen
        }
        if lowercased.contains("boisson") || lowercased.contains("beverage") || lowercased.contains("drink") {
            return .beverages
        }
        if lowercased.contains("snack") || lowercased.contains("collation") || lowercased.contains("grignotage") {
            return .snacks
        }
        if lowercased.contains("sec") || lowercased.contains("dry") {
            return .grains
        }
        
        return .other
    }
}
