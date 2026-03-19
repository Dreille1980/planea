# Amélioration du regroupement des ingrédients - Mise en place

## Problème identifié

Dans la section "Mise en place" du Meal Prep, les ingrédients n'étaient pas correctement regroupés:
- **Exemple 1 - Ail:** Au lieu d'afficher "ail - 10 gousses, haché", on voyait "ail - 2 unit + 2 unit, sliced + 2 unit + 2 unit"
- **Exemple 2 - Poivron:** Pour des préparations différentes, on voulait "poivron - 4 unités (2 en cubes, 2 en lanières)"

## Solution implémentée

### Fichier modifié
`Planea-iOS/Planea/Planea/Models/MealPrepModels.swift` - Fonction `buildActionBasedPrep()`

### Logique de consolidation

La nouvelle logique suit ces étapes:

1. **Regroupement par ingrédient d'abord** (pas par ingrédient + action)
   - Tous les items d'ail sont regroupés ensemble
   - Tous les items de poivron sont regroupés ensemble

2. **Analyse des actions pour chaque ingrédient**
   
   **Cas A: Une seule action (ex: ail haché)**
   - Parse les quantités numériques (ex: "2 unit", "3 gousses")
   - Somme les quantités: 2 + 2 + 3 + 3 = 10
   - Affiche: "10 gousses, haché"
   
   **Cas B: Plusieurs actions (ex: poivron en cubes ET en lanières)**
   - Calcule le total global: 4 unités
   - Calcule le sous-total par action:
     - diced: 2 + 2 = 2
     - sliced: 1 + 1 = 2
   - Affiche: "4 units (2 diced, 2 sliced)"

3. **Gestion des cas limites**
   - Si les quantités ne peuvent pas être parsées (format non standard), retombe sur la concaténation avec "+"
   - Gère les unités différentes (gousses, units, g, kg, etc.)
   - Conserve l'information des recettes d'origine

## Code clé

```swift
// Regroupement par ingrédient uniquement
var itemsByIngredient: [String: [PrepItem]] = [:]
for item in items {
    let key = item.ingredientName.lowercased()
    itemsByIngredient[key, default: []].append(item)
}

// Pour chaque ingrédient, analyser les actions
for (_, ingredientItems) in itemsByIngredient {
    var itemsByAction: [String: [PrepItem]] = [:]
    for item in ingredientItems {
        let actionKey = item.action.lowercased()
        itemsByAction[actionKey, default: []].append(item)
    }
    
    if itemsByAction.count == 1 {
        // Une seule action → Sommer les quantités
        // "10 gousses, haché"
    } else {
        // Plusieurs actions → Format avec détails
        // "4 units (2 diced, 2 sliced)"
    }
}
```

## Résultats attendus

### Avant
```
ail - 2 unit + 2 unit, sliced + 2 unit + 2 unit
poivron - 2 unit + 2 unit
```

### Après
```
ail - 10 gousses, haché
poivron - 4 units (2 diced, 2 sliced)
```

## Tests

✅ Compilation réussie (`BUILD SUCCEEDED`)
⚠️ À tester manuellement:
1. Générer un Meal Prep avec plusieurs recettes utilisant les mêmes ingrédients
2. Vérifier la section "Mise en place" 
3. Confirmer que l'ail est bien consolidé (total + action)
4. Confirmer que le poivron avec préparations différentes montre le détail

## Impact

- **UX améliorée:** Affichage plus clair et plus intuitif des ingrédients
- **Moins de confusion:** Les quantités sont maintenant additionnées automatiquement
- **Flexibilité:** Gère à la fois les ingrédients avec une seule préparation et ceux avec plusieurs préparations différentes
- **Backend inchangé:** La modification est côté client uniquement

## Date
9 janvier 2026
