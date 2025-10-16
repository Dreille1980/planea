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
        case .meat: return 2
        case .fish: return 3
        case .dairy: return 4
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
        for section in StoreSection.allCases {
            if lowercased.contains(section.rawValue) {
                return section
            }
        }
        return .other
    }
}
