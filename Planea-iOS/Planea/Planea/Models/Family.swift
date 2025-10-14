import Foundation

struct Family: Identifiable, Codable {
    var id: UUID = .init()
    var name: String
    var unitSystem: UnitSystem = .metric
}
