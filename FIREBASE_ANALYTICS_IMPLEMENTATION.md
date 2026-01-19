# Firebase Analytics, Crashlytics & Performance - Implémentation Planea

## ✅ Installation Complétée

### Services créés
- ✅ `AnalyticsService.swift` - Gestion centralisée des événements Analytics
- ✅ `CrashlyticsService.swift` - Gestion du crash reporting
- ✅ `PerformanceService.swift` - Monitoring de performance

### Configuration
- ✅ Firebase initialisé dans `PlaneaApp.swift`
- ✅ User properties configurées au lancement
- ✅ Tracking ajouté dans `PlanViewModel` (génération de recettes plan)
- ✅ Tracking ajouté dans `FavoritesViewModel` (favoris add/remove)

## 🔄 Intégrations Restantes Recommandées

### 1. MealPrepViewModel
Ajouter dans les méthodes de génération:
```swift
// Dans generateMealPrep après succès:
AnalyticsService.shared.logMealPrepCreated(
    recipeCount: selectedRecipes.count,
    totalServings: totalServings
)
```

### 2. ShoppingViewModel  
Ajouter le tracking des exports:
```swift
// Dans la fonction d'export:
AnalyticsService.shared.logShoppingListExported(
    itemCount: shoppingList.items.count,
    format: "text" // ou "share"
)
```

### 3. ChatViewModel
Ajouter:
```swift
// Lors de l'envoi de message:
AnalyticsService.shared.logChatMessageSent(
    agentMode: currentMode.rawValue,
    messageLength: message.count
)

// Si utilisation de la voix:
AnalyticsService.shared.logVoiceInputUsed(agentMode: currentMode.rawValue)
```

### 4. StoreManager (Subscriptions)
Ajouter:
```swift
// Lors d'un achat:
AnalyticsService.shared.logSubscriptionPurchased(
    productID: product.id,
    price: product.price,
    currency: "CAD"
)

// Lors d'une restauration:
AnalyticsService.shared.logSubscriptionRestored(productID: productID)
```

### 5. FamilyViewModel
Ajouter:
```swift
// Lors de l'ajout d'un membre:
AnalyticsService.shared.logFamilyMemberAdded(totalMembers: members.count)

// Lors de la suppression:
AnalyticsService.shared.logFamilyMemberRemoved(totalMembers: members.count)
```

### 6. Onboarding
Ajouter dans `OnboardingContainerView`:
```swift
// À la fin de l'onboarding:
AnalyticsService.shared.logOnboardingComplete()

// À chaque étape:
AnalyticsService.shared.logOnboardingStep(step: "family_setup")
```

### 7. RecipeDetailView
Ajouter lors de l'affichage:
```swift
.onAppear {
    AnalyticsService.shared.logRecipeViewed(
        recipeID: recipe.id.uuidString,
        recipeTitle: recipe.title,
        source: "plan" // ou "adhoc", "favorite", "history"
    )
}
```

### 8. Paywall Views
Ajouter:
```swift
.onAppear {
    AnalyticsService.shared.logPaywallViewed(source: "trial_banner")
}
```

### 9. Settings
Lors des changements:
```swift
// Changement de langue:
AnalyticsService.shared.logLanguageChanged(from: oldLang, to: newLang)

// Changement d'unités:
AnalyticsService.shared.logUnitSystemChanged(from: oldSystem, to: newSystem)
```

### 10. IAService (Backend errors)
Dans les appels API qui échouent:
```swift
AnalyticsService.shared.logAPIError(
    endpoint: "/generate",
    statusCode: statusCode,
    errorMessage: error.localizedDescription
)

CrashlyticsService.shared.logError(error, additionalInfo: [
    "endpoint": "/generate",
    "status_code": statusCode
])
```

## 🔧 Build Script pour Crashlytics

### IMPORTANT: Ajouter un Run Script dans Xcode

1. Ouvrez Xcode
2. Sélectionnez le target "Planea"
3. Allez dans l'onglet "Build Phases"
4. Cliquez sur "+" et sélectionnez "New Run Script Phase"
5. Nommez-le "Upload dSYM to Crashlytics"
6. Ajoutez ce script:

```bash
# Upload dSYM files to Crashlytics for better crash reporting
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

7. Assurez-vous que ce script se trouve APRÈS "Compile Sources"
8. Dans "Input Files", ajoutez:
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}
```

## 📊 Événements Analytics Implémentés

### Navigation & Engagement
- ✅ `app_open` - Au lancement
- ✅ `onboarding_complete` - Fin onboarding
- ✅ `whats_new_viewed` - Vue What's New

### Génération de Contenu
- ✅ `recipe_generated` - Recettes générées (plan/adhoc)
- ⏳ `meal_prep_created` - Meal prep créé
- ⏳ `chat_message_sent` - Message chat envoyé

### Favoris
- ✅ `recipe_favorited` - Recette ajoutée aux favoris
- ✅ `recipe_unfavorited` - Recette retirée des favoris
- ✅ `favorite_added_to_week` - Favori ajouté au plan

### Shopping
- ⏳ `shopping_list_exported` - Liste exportée

### Monétisation
- ⏳ `paywall_viewed` - Paywall affiché
- ⏳ `subscription_purchased` - Abonnement acheté
- ⏳ `usage_limit_reached` - Limite atteinte

### Settings
- ⏳ `language_changed` - Langue changée
- ⏳ `unit_system_changed` - Unités changées
- ⏳ `family_member_added/removed` - Membres ajoutés/retirés

## 🧪 Testing Firebase

### 1. Test Analytics en Debug
Dans Xcode, exécutez avec ces arguments:
```
-FIRDebugEnabled
-FIRAnalyticsDebugEnabled
```

Vous verrez les événements dans la console:
```
[Firebase/Analytics][I-ACS023000] Logging event: event_name: app_open
```

### 2. Test Crashlytics
Pour tester un crash (DEBUG uniquement):
```swift
// Ajoutez un bouton temporaire dans Settings
Button("Test Crash") {
    CrashlyticsService.shared.forceCrash()
}
```

### 3. Vérifier dans Firebase Console
- **Analytics:** Firebase Console > Analytics > Events (données après 24h)
- **Crashlytics:** Firebase Console > Crashlytics (immédiat après crash)
- **Performance:** Firebase Console > Performance (données après quelques minutes)

### 4. Debug View (Analytics en temps réel)
1. Exécutez l'app sur un appareil
2. Dans Terminal, exécutez:
```bash
adb shell setprop debug.firebase.analytics.app com.dreille.Planea
```
3. Allez dans Firebase Console > Analytics > DebugView
4. Vous verrez les événements en temps réel

## 📝 User Properties Configurées

- `app_language` - Langue de l'app
- `unit_system` - Système d'unités (metric/imperial)
- `subscription_status` - Status abonnement (subscribed/free)
- `family_member_count` - Nombre de membres famille

## ⚠️ Notes Importantes

1. **Privacy**: Les événements Analytics sont anonymes par défaut
2. **Crashlytics**: Ne log pas automatiquement les infos personnelles
3. **Performance**: Les traces HTTP sont automatiques pour URLSession
4. **Data Retention**: Analytics conserve les données 14 mois par défaut
5. **Quotas**: Tout est gratuit dans les limites normales d'utilisation

## 🚀 Prochaines Étapes Recommandées

1. Tester l'app et vérifier que Firebase fonctionne
2. Ajouter les tracking manquants (voir section "Intégrations Restantes")
3. Configurer le build script Crashlytics
4. Tester un crash volontaire pour valider Crashlytics
5. Surveiller les événements dans Firebase Console après 24h
6. Créer des audiences et funnels dans Analytics
7. Configurer des alertes Crashlytics pour les nouveaux crashes

## 📚 Ressources

- [Firebase Analytics](https://firebase.google.com/docs/analytics)
- [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)
- [Firebase Performance](https://firebase.google.com/docs/perf-mon)
- [Best Practices](https://firebase.google.com/docs/analytics/best-practices)
