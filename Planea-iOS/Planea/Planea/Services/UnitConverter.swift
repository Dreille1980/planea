import Foundation

struct UnitConverter {
    // Weight conversions
    static func gramsToOunces(_ g: Double) -> Double { g / 28.3495 }
    static func ouncesToGrams(_ oz: Double) -> Double { oz * 28.3495 }
    
    // Volume conversions
    static func mlToCups(_ ml: Double) -> Double { ml / 240.0 }
    static func cupsToMl(_ c: Double) -> Double { c * 240.0 }
    static func mlToTablespoons(_ ml: Double) -> Double { ml / 15.0 }
    static func tablespoonsToMl(_ tbsp: Double) -> Double { tbsp * 15.0 }
    static func mlToTeaspoons(_ ml: Double) -> Double { ml / 5.0 }
    static func teaspoonsToMl(_ tsp: Double) -> Double { tsp * 5.0 }
    
    // Convert ingredient quantity and unit based on target unit system
    static func convertIngredient(quantity: Double, unit: String, from sourceSystem: UnitSystem, to targetSystem: UnitSystem) -> (quantity: Double, unit: String) {
        // If systems are the same, no conversion needed
        if sourceSystem == targetSystem {
            return (quantity, unit)
        }
        
        let lowercasedUnit = unit.lowercased()
        
        // Convert from metric to imperial
        if sourceSystem == .metric && targetSystem == .imperial {
            if lowercasedUnit.contains("g") && !lowercasedUnit.contains("kg") {
                return (gramsToOunces(quantity), "oz")
            } else if lowercasedUnit.contains("kg") {
                return (gramsToOunces(quantity * 1000) / 16, "lb")
            } else if lowercasedUnit.contains("ml") {
                if quantity >= 240 {
                    return (mlToCups(quantity), "cups")
                } else if quantity >= 15 {
                    return (mlToTablespoons(quantity), "tbsp")
                } else {
                    return (mlToTeaspoons(quantity), "tsp")
                }
            } else if lowercasedUnit.contains("l") && !lowercasedUnit.contains("ml") {
                return (mlToCups(quantity * 1000), "cups")
            }
        }
        
        // Convert from imperial to metric
        if sourceSystem == .imperial && targetSystem == .metric {
            if lowercasedUnit.contains("oz") {
                return (ouncesToGrams(quantity), "g")
            } else if lowercasedUnit.contains("lb") {
                return (ouncesToGrams(quantity * 16) / 1000, "kg")
            } else if lowercasedUnit.contains("cup") {
                return (cupsToMl(quantity), "ml")
            } else if lowercasedUnit.contains("tbsp") || lowercasedUnit.contains("tablespoon") {
                return (tablespoonsToMl(quantity), "ml")
            } else if lowercasedUnit.contains("tsp") || lowercasedUnit.contains("teaspoon") {
                return (teaspoonsToMl(quantity), "ml")
            }
        }
        
        // No conversion needed for units like "unités", "pincée", etc.
        return (quantity, unit)
    }
}
