# 🎯 Meal Prep - Gestion de Portions - Implémentation

## 📅 Date
14 février 2026

## 🎯 Objectif
Transformer le MealPrepKit existant en une entité avec gestion de portions, permettant d'assigner des portions à des jours spécifiques du plan de la semaine.

---

## ✅ Architecture Implémentée

### 1️⃣ Modèles de Données (COMPLÉTÉ)

#### **MealPrepKit** (évolué)
```swift
struct MealPrepKit {
    // Existant
    let id: UUID
    let name: String
    let totalPortions: Int
    let recipes: [MealPrepRecipeRef]
    let todayPreparation: TodayPreparation?
    let weeklyReheating: WeeklyReheating?
    
    // ✨ NOUVEAU - Gestion des portions
    var remainingPortions: Int              // Décrémenté automatiquement
    var assignments: [MealPrepAssignment]   // Historique
    let preparedDate: Date                  // Date de préparation
    var recipePortions: [RecipePortionTracker]?  // Tracker par recette (hybride)
    
    // Computed properties
    var hasAvailablePortions: Bool
}
```

#### **MealPrepAssignment** (nouveau)
```swift
struct MealPrepAssignment {
    let id: UUID
    let mealPrepKitId: UUID
    let date: Date
    let mealType: MealType
    let portionsUsed: Int
    let specificRecipeId: String?        // Optionnel
    let specificRecipeTitle: String?     // Optionnel
    let assignedAt: Date
}
```

#### **RecipePortionTracker** (nouveau - gestion hybride)
```swift
struct RecipePortionTracker {
    let id: UUID
    let recipeId: String
    let recipeTitle: String
    let totalPortions: Int
    var remainingPortions: Int
}
```

### 2️⃣ Intégration PlannedWeek (COMPLÉTÉ)

#### **MealSource** enum (nouveau)
```swift
enum MealSource: Codable {
    case recipe(Recipe)
    case mealPrep(MealPrepAssignment, MealPrepKit)
    
    // Helpers
    var recipe: Recipe?
    var mealPrepInfo: (assignment: MealPrepAssignment, kit: MealPrepKit)?
    var title: String
    var isMealPrep: Bool
}
```

#### **PlannedMeal** (modifié)
```swift
struct PlannedMeal {
    var id: UUID
    var mealType: MealType
    var source: MealSource  // ← Unified source
    
    // Legacy support
    @available(*, deprecated)
    var recipe: Recipe?
}
```

### 3️⃣ Logique Métier (COMPLÉTÉ)

#### **Extensions MealPrepKit**

**Gestion des portions :**
```swift
func canAssign(portions: Int) -> Bool
mutating func assignPortions(date:mealType:portions:specificRecipeId:) throws -> MealPrepAssignment
mutating func unassign(_ assignmentId: UUID) throws
```

**Gestion de l'expiration (Bonus) :**
```swift
var expirationDate: Date?
var isExpired: Bool
var daysUntilExpiration: Int?
var expirationWarning: String?
```

#### **MealPrepError** enum
```swift
enum MealPrepError: LocalizedError {
    case insufficientPortions(requested: Int, available: Int)
    case insufficientRecipePortions(recipeTitle: String, requested: Int, available: Int)
    case assignmentNotFound
}
```

---

## 🚧 À Implémenter (Phase 2)

### 4️⃣ Views

#### **AssignMealPrepSheet.swift** (à créer)
- Sélection de date
- Sélection de type de repas
- Stepper de portions
- Sélection optionnelle de recette spécifique
- Aperçu de l'assignation

#### **MealPrepPickerSheet.swift** (à créer)
- Liste des MealPrepKits avec portions disponibles
- Filtrage par portions > 0
- Display des infos clés (date préparation, portions restantes)

#### **Modifications MealPrepDetailView**
- Bouton "Ajouter au plan" dans toolbar
- Affichage des portions restantes
- Badge d'expiration si proche
- Liste des assignments actuels

### 5️⃣ ViewModels

#### **Extension MealPrepViewModel**
```swift
@MainActor func assignToWeek(kit:date:mealType:portions:recipeId:)
@MainActor func unassignFromWeek(assignment:)
```

#### **Extension PlanViewModel**
```swift
@MainActor func addMealPrepMeal(assignment:kit:date:mealType:)
@MainActor func removeMealPrepMeal(assignmentId:)
```

### 6️⃣ Modifications PlanWeekView

#### Affichage des MealPrep
- Badge "Meal Prep" distinct
- Nombre de portions affiché
- Nom du kit
- Recette spécifique si applicable

#### Menu contextuel
- Option "Ajouter Meal Prep"
- Sheet de sélection de MealPrepKit

### 7️⃣ Localisations

#### Français (fr.lproj/Localizable.strings)
```
// Portions
"mealprep.portions_available" = "%d portions disponibles";
"mealprep.portions_used" = "%d portions utilisées";

// Erreurs
"mealprep.error.insufficient_portions" = "Portions insuffisantes : %d demandées, %d disponibles";
"mealprep.error.insufficient_recipe_portions" = "%@ : %d portions demandées, %d disponibles";
"mealprep.error.assignment_not_found" = "Assignment introuvable";

// Expiration
"mealprep.expired" = "Expiré";
"mealprep.expires_today" = "Expire aujourd'hui";
"mealprep.expires_tomorrow" = "Expire demain";
"mealprep.expires_in_days" = "Expire dans %d jours";

// UI
"mealprep.assign_to_plan" = "Ajouter au plan";
"mealprep.choose_mealprep" = "Choisir un Meal Prep";
"mealprep.badge" = "Meal Prep";
```

#### Anglais (en.lproj/Localizable.strings)
```
// Portions
"mealprep.portions_available" = "%d portions available";
"mealprep.portions_used" = "%d portions used";

// Errors
"mealprep.error.insufficient_portions" = "Insufficient portions: %d requested, %d available";
"mealprep.error.insufficient_recipe_portions" = "%@: %d portions requested, %d available";
"mealprep.error.assignment_not_found" = "Assignment not found";

// Expiration
"mealprep.expired" = "Expired";
"mealprep.expires_today" = "Expires today";
"mealprep.expires_tomorrow" = "Expires tomorrow";
"mealprep.expires_in_days" = "Expires in %d days";

// UI
"mealprep.assign_to_plan" = "Add to Plan";
"mealprep.choose_mealprep" = "Choose Meal Prep";
"mealprep.badge" = "Meal Prep";
```

### 8️⃣ Persistence

#### **PersistenceController** (à modifier)
- Sauvegarde des MealPrepKits avec portions
- Sauvegarde des assignments
- Migration des kits existants

### 9️⃣ Analytics

#### **Events à tracker**
```swift
AnalyticsService.shared.logMealPrepAssigned(
    kitID: String,
    kitName: String,
    portions: Int,
    date: String
)

AnalyticsService.shared.logMealPrepUnassigned(
    assignmentID: String,
    reason: String
)
```

---

## 🎨 Décisions Architecture

### ✅ Choix Validés

1. **MealPrepKit évolue** (pas de nouvelle entité)
   - Backward compatible
   - Minimise les changements

2. **Gestion hybride des portions**
   - Global (simple)
   - Par recette (optionnel, précis)
   - Best of both worlds

3. **MealSource enum**
   - Unified, clean
   - Type-safe avec pattern matching
   - Extensible pour futurs types

4. **Assignment flexible**
   - Depuis MealPrepDetailView
   - Depuis PlanWeekView
   - UX cohérente

### 🎯 Avantages

- ✅ Architecture propre et découplée
- ✅ Réactivité SwiftUI native
- ✅ Backward compatible
- ✅ Scalable pour futures features
- ✅ Type-safe
- ✅ Testable

---

## 📝 Notes Techniques

### Backward Compatibility

**PlannedMeal** supporte les deux formats :
```swift
// Nouveau format
let meal = PlannedMeal(
    mealType: .dinner,
    source: .mealPrep(assignment, kit)
)

// Legacy format (still works)
let meal = PlannedMeal(
    mealType: .dinner,
    recipe: recipe
)
```

### Migration Path

Les MealPrepKits existants seront automatiquement migrés :
- `remainingPortions` = `totalPortions` si absent
- `assignments` = `[]` si absent
- `preparedDate` = `createdAt` si absent

---

## 🚀 Prochaines Étapes

1. [ ] Créer `AssignMealPrepSheet.swift`
2. [ ] Créer `MealPrepPickerSheet.swift`
3. [ ] Modifier `MealPrepDetailView.swift`
4. [ ] Étendre `MealPrepViewModel`
5. [ ] Étendre `PlanViewModel`
6. [ ] Modifier `PlanWeekView.swift`
7. [ ] Ajouter localisations
8. [ ] Mettre à jour `PersistenceController`
9. [ ] Ajouter analytics events
10. [ ] Tests end-to-end

---

## 🎁 Features Bonus Préparées

### Gestion automatique de l'expiration
```swift
let kit: MealPrepKit
if let warning = kit.expirationWarning {
    // Afficher le warning dans l'UI
    Text(warning)
        .foregroundColor(.orange)
}
```

### Suggestions automatiques (à venir)
```swift
func suggestAssignments(for kit: MealPrepKit) -> [MealPrepAssignment]
// Logique pour suggérer des jours optimaux
```

---

## 📚 Fichiers Modifiés

### Phase 1 (COMPLÉTÉ)
- ✅ `Planea-iOS/Planea/Planea/Models/MealPrepModels.swift`
- ✅ `Planea-iOS/Planea/Planea/Models/PlannedWeek.swift`

### Phase 2 (À FAIRE)
- [ ] `Planea-iOS/Planea/Planea/Views/AssignMealPrepSheet.swift` (nouveau)
- [ ] `Planea-iOS/Planea/Planea/Views/MealPrepPickerSheet.swift` (nouveau)
- [ ] `Planea-iOS/Planea/Planea/Views/MealPrepDetailView.swift` (modifier)
- [ ] `Planea-iOS/Planea/Planea/Views/PlanWeekView.swift` (modifier)
- [ ] `Planea-iOS/Planea/Planea/ViewModels/MealPrepViewModel.swift` (étendre)
- [ ] `Planea-iOS/Planea/Planea/ViewModels/PlanViewModel.swift` (étendre)
- [ ] `Planea-iOS/Planea/Planea/Persistence/PersistenceController.swift` (modifier)
- [ ] `Planea-iOS/Planea/Planea/Services/AnalyticsService.swift` (étendre)
- [ ] `Planea-iOS/Planea/Planea/fr.lproj/Localizable.strings` (ajouter)
- [ ] `Planea-iOS/Planea/Planea/en.lproj/Localizable.strings` (ajouter)

---

## ✨ Conclusion Phase 1

**Architecture solide mise en place** ✅

Les fondations sont prêtes pour la Phase 2 (UI et intégration complète). Le code est :
- Clean
- Type-safe
- Scalable
- Backward compatible
- Prêt pour évolution future

**Status:** Ready for implementation Phase 2 🚀
