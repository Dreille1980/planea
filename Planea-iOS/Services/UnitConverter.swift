import Foundation

struct UnitConverter {
    static func gramsToOunces(_ g: Double) -> Double { g / 28.3495 }
    static func ouncesToGrams(_ oz: Double) -> Double { oz * 28.3495 }
    static func mlToCups(_ ml: Double) -> Double { ml / 240.0 }
    static func cupsToMl(_ c: Double) -> Double { c * 240.0 }
}
