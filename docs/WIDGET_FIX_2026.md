# Correction du Widget iOS - Janvier 2026

## Problème identifié

Le widget iOS affichait toujours "Aucun repas planifié" même quand des repas étaient disponibles dans l'application principale.

### Causes racines

1. **Décodage JSON manuel fragile** : Le widget utilisait `JSONSerialization.jsonObject` au lieu de `Codable`, ce qui échouait silencieusement
2. **Blocage du thread** : Utilisation de `DispatchGroup.wait()` qui pouvait causer des timeouts
3. **Manque de logs** : Impossible de diagnostiquer le problème
4. **Structures dupliquées** : Les modèles du widget n'étaient pas partagés avec l'app principale
5. **Logique limitée** : Affichait uniquement les repas d'aujourd'hui, pas les prochains à venir

## Solution implémentée

### 1. Nouveau fichier `WidgetSharedModels.swift`

Ce fichier contient :
- `WidgetMealItem` : Structure `Codable` pour les repas du widget
- `WidgetWeekday` et `WidgetMealType` : Enums avec noms localisés en français
- Extensions `Date` : Helpers pour calculer les jours relatifs ("Aujourd'hui", "Demain", etc.)

### 2. Réécriture complète de `PleneaWidget.swift`

#### Améliorations principales

**a) Décodage fiable avec Codable**
```swift
struct TempMealItem: Codable {
    let id: UUID
    let weekday: String
    let mealType: String
    let recipe: TempRecipe
    
    enum CodingKeys: String, CodingKey {
        case id, weekday, recipe
        case mealType = "meal_type"
    }
}
```

**b) Nouvelle logique de recherche de repas**
1. Cherche d'abord les repas d'aujourd'hui
2. Si aucun repas aujourd'hui, parcourt les 7 prochains jours
3. Retourne le premier jour avec des repas planifiés
4. Affiche clairement le jour concerné

**c) Logs détaillés pour le débogage**
```swift
print("Widget: Loading current entry...")
print("Widget: Store URL: \(storeURL.path)")
print("Widget: Core Data loaded successfully")
print("Widget: Decoded \(decodedItems.count) items")
```

**d) Interface améliorée**
- Couleur bleue pour "Aujourd'hui"
- Couleur orange pour les jours futurs
- Affichage clair du jour ("Aujourd'hui", "Demain", "Mercredi")
- Support des 3 tailles de widget (small, medium, large)

#### Structure de l'Entry mise à jour
```swift
struct WeeklyPlanEntry: TimelineEntry {
    let date: Date
    let meals: [WidgetMealItem]
    let planName: String?
    let displayDay: String      // "Aujourd'hui", "Demain", "Mercredi"
    let isToday: Bool           // Pour adapter les couleurs
}
```

### 3. Flux de données

```
App principale (Core Data)
    ↓
App Group Container (Planea.sqlite)
    ↓
Widget lit les données via Core Data (read-only)
    ↓
Décode avec Codable
    ↓
Cherche aujourd'hui → puis jours futurs
    ↓
Affiche dans le widget
```

## Fonctionnalités

✅ Affiche les repas d'aujourd'hui s'ils existent
✅ Affiche les prochains repas si rien aujourd'hui (jusqu'à 7 jours)
✅ Indication claire du jour affiché
✅ Couleurs différentes pour "Aujourd'hui" vs "Prochainement"
✅ Support 3 tailles de widget
✅ Logs pour diagnostiquer les problèmes
✅ Performance optimisée
✅ Gestion d'erreur robuste

## Tests à effectuer

1. **Widget avec repas aujourd'hui** : Vérifier l'affichage correct
2. **Widget sans repas aujourd'hui** : Vérifier qu'il affiche le prochain jour
3. **Widget sans aucun repas** : Vérifier le message "Aucun repas planifié"
4. **Les 3 tailles** : Small, Medium, Large
5. **Rafraîchissement** : Vérifier que le widget se met à jour (toutes les 4h et à minuit)

## Notes techniques

- Le widget utilise l'App Group `group.com.dreille.planea` pour accéder aux données
- Core Data est ouvert en mode read-only dans le widget
- Utilisation de `DispatchSemaphore` avec timeout de 2 secondes pour éviter les blocages
- Rafraîchissement automatique toutes les 4 heures et à minuit

## Prochaines étapes recommandées

1. Tester le widget sur un appareil réel
2. Vérifier les logs dans Xcode console lors du chargement du widget
3. S'assurer que les capabilities App Group sont bien configurées pour l'app ET le widget
4. Tester avec différents scénarios de planification
