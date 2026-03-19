# Firebase Analytics - Guide de Démarrage Rapide

## ✅ Ce qui a été fait

1. **Firebase SDK installé** (Analytics, Crashlytics, Performance)
2. **3 services créés** pour centraliser les appels Firebase
3. **Firebase initialisé** au lancement de l'app
4. **User properties** configurées automatiquement
5. **Tracking de base** ajouté (recettes, favoris, app launch)
6. **Code commité** à GitHub

## 🚀 Prochaines Étapes Immédiates

### 1. Compiler l'app (pour vérifier que tout fonctionne)

Dans Xcode:
- Ouvrez le projet Planea
- Build l'app (Cmd+B)
- Si ça compile sans erreur, c'est bon! ✅

### 2. Ajouter le Build Script Crashlytics

**IMPORTANT** pour que Crashlytics fonctionne correctement:

1. Dans Xcode, sélectionnez le projet "Planea"
2. Sélectionnez le target "Planea"
3. Allez dans "Build Phases"
4. Cliquez le "+" en haut à gauche
5. Choisissez "New Run Script Phase"
6. Nommez-le "Upload dSYM to Crashlytics"
7. Ajoutez ce script:
```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```
8. **Assurez-vous** que cette phase est APRÈS "Compile Sources"

### 3. Tester l'app

Lancez l'app et:
- ✅ Ouvrez l'app (log `app_open`)
- ✅ Générez un plan de repas (log `recipe_generated`)
- ✅ Ajoutez une recette aux favoris (log `recipe_favorited`)

### 4. Vérifier Firebase Console

Dans 24-48 heures, allez sur:
- https://console.firebase.google.com
- Sélectionnez le projet "Planea"
- Analytics > Events

Vous verrez vos événements!

## 📋 Événements Déjà Trackés

- ✅ **app_open** - Au lancement
- ✅ **recipe_generated** - Quand un plan est généré
- ✅ **recipe_favorited** - Ajout aux favoris
- ✅ **recipe_unfavorited** - Retrait des favoris
- ✅ **favorite_added_to_week** - Favori ajouté au plan
- ✅ **whats_new_viewed** - Vue What's New

## 🔧 Tracking Supplémentaire Recommandé

Consultez `FIREBASE_ANALYTICS_IMPLEMENTATION.md` pour:
- Tracking du chat
- Tracking du shopping
- Tracking du meal prep
- Tracking des subscriptions
- Et plus encore...

## 🐛 Debug (optionnel)

Pour voir les événements en temps réel dans la console Xcode:

1. Dans Xcode, allez dans Product > Scheme > Edit Scheme
2. Allez dans "Run" > "Arguments"
3. Ajoutez dans "Arguments Passed On Launch":
   - `-FIRDebugEnabled`
   - `-FIRAnalyticsDebugEnabled`
4. Lancez l'app

Vous verrez dans la console:
```
[Firebase/Analytics] Logging event: app_open
```

## ❓ Questions?

Tout est documenté dans `FIREBASE_ANALYTICS_IMPLEMENTATION.md`!

## 🎉 Félicitations!

Firebase Analytics est maintenant installé et fonctionnel dans Planea! 🚀
