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
    
    // MARK: - Produce Weight Database
    // Average weights in grams for common fruits and vegetables
    private static let produceWeights: [String: Double] = [
        // Vegetables
        "potato": 150, "potatoes": 150, "pomme de terre": 150, "pommes de terre": 150,
        "tomato": 120, "tomatoes": 120, "tomate": 120, "tomates": 120,
        "onion": 150, "onions": 150, "oignon": 150, "oignons": 150,
        "carrot": 60, "carrots": 60, "carotte": 60, "carottes": 60,
        "zucchini": 200, "courgette": 200, "courgettes": 200,
        "bell pepper": 150, "peppers": 150, "poivron": 150, "poivrons": 150,
        "cucumber": 300, "concombre": 300, "concombres": 300,
        "eggplant": 450, "aubergine": 450, "aubergines": 450,
        "lettuce": 500, "laitue": 500,
        "cabbage": 900, "chou": 900, "choux": 900,
        "broccoli": 300, "brocoli": 300,
        "cauliflower": 600, "chou-fleur": 600,
        "celery": 100, "céleri": 100,
        "leek": 200, "poireau": 200, "poireaux": 200,
        "turnip": 200, "navet": 200, "navets": 200,
        "beet": 150, "beets": 150, "betterave": 150, "betteraves": 150,
        "radish": 20, "radishes": 20, "radis": 20,
        "squash": 800, "courge": 800, "courges": 800,
        "pumpkin": 3000, "citrouille": 3000,
        
        // Fruits
        "apple": 180, "apples": 180, "pomme": 180, "pommes": 180,
        "banana": 120, "bananas": 120, "banane": 120, "bananes": 120,
        "orange": 140, "oranges": 140,
        "lemon": 100, "lemons": 100, "citron": 100, "citrons": 100,
        "lime": 70, "limes": 70,
        "pear": 180, "pears": 180, "poire": 180, "poires": 180,
        "peach": 150, "peaches": 150, "pêche": 150, "pêches": 150,
        "plum": 70, "plums": 70, "prune": 70, "prunes": 70,
        "avocado": 200, "avocados": 200, "avocat": 200, "avocats": 200,
        "mango": 300, "mangoes": 300, "mangue": 300, "mangues": 300,
        "pineapple": 900, "ananas": 900,
        "strawberry": 15, "strawberries": 15, "fraise": 15, "fraises": 15,
        "blueberry": 1, "blueberries": 1, "bleuet": 1, "bleuets": 1,
        "raspberry": 1, "raspberries": 1, "framboise": 1, "framboises": 1,
        "grape": 5, "grapes": 5, "raisin": 5, "raisins": 5,
        "watermelon": 4000, "melon d'eau": 4000, "pastèque": 4000,
        "cantaloupe": 1000, "cantaloup": 1000,
        "kiwi": 70, "kiwis": 70,
        "cherry": 8, "cherries": 8, "cerise": 8, "cerises": 8,
        "apricot": 35, "apricots": 35, "abricot": 35, "abricots": 35
    ]
    
    // MARK: - Produce Detection
    static func isProduce(_ ingredientName: String) -> Bool {
        let lowercased = ingredientName.lowercased()
        return produceWeights.keys.contains { lowercased.contains($0) }
    }
    
    // MARK: - Weight to Unit Count Conversion
    static func weightToUnitCount(ingredientName: String, weightInGrams: Double) -> Double? {
        guard isProduce(ingredientName) else { return nil }
        
        let lowercased = ingredientName.lowercased()
        
        // Find matching produce weight
        for (key, avgWeight) in produceWeights {
            if lowercased.contains(key) {
                return weightInGrams / avgWeight
            }
        }
        
        return nil
    }
    
    // MARK: - Unit Translation
    static func localizeUnit(_ unit: String) -> String {
        let lowercased = unit.lowercased()
        
        // Check if it's "unité" and needs translation
        if lowercased == "unité" || lowercased == "unités" {
            // Get current language from Bundle
            let currentLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            
            if currentLanguage == "fr" {
                return unit // Keep as is in French
            } else {
                // Translate to English
                return unit.lowercased().hasPrefix("unité") ? "unit" : unit
            }
        }
        
        return unit
    }
    
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
