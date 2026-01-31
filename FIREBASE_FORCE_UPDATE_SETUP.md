# Firebase Force Update - Configuration Guide

Ce document explique comment configurer et utiliser le système de mise à jour forcée avec Firebase Remote Config pour Planea iOS.

## 📋 Vue d'ensemble

Le système de mise à jour forcée permet de bloquer l'accès à l'application si la version installée est inférieure à une version minimale définie dans Firebase Remote Config. Cela vous permet de :

- Forcer les utilisateurs à mettre à jour en cas de bug critique
- Garantir que tous les utilisateurs utilisent une version compatible avec votre backend
- Contrôler les mises à jour à distance sans publier une nouvelle version

## 🏗️ Architecture

### Composants créés

1. **ForceUpdateService.swift** - Service singleton qui gère la logique de vérification
2. **ForceUpdateView.swift** - Vue full-screen affichée quand une mise à jour est requise
3. **Intégration dans PlaneaApp.swift** - Vérification au lancement
4. **Traductions** - Clés ajoutées dans en.lproj et fr.lproj

## 🔧 Configuration Firebase

### Étape 1 : Ajouter Firebase Remote Config (si pas déjà fait)

1. Ouvrez le projet Xcode : `Planea-iOS/Planea/Planea.xcodeproj`

2. Dans Xcode, allez dans **File > Add Package Dependencies**

3. Ajoutez le package Firebase si pas déjà présent :
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```

4. Sélectionnez **FirebaseRemoteConfig** dans la liste des produits

5. Vérifiez que FirebaseRemoteConfig est bien importé dans `ForceUpdateService.swift`

### Étape 2 : Configuration dans la Console Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)

2. Sélectionnez votre projet Planea

3. Dans le menu latéral, cliquez sur **Remote Config** (sous "Engage")

4. Cliquez sur **Add parameter** (ou "Ajouter un paramètre")

5. Configurez le paramètre :
   - **Parameter key** : `minimum_ios_app_version`
   - **Data type** : String
   - **Default value** : `1.0.0` (ou votre version minimale souhaitée)
   - **Description** : "Version iOS minimale requise pour utiliser l'app"

6. Cliquez sur **Publish changes**

### Étape 3 : Configuration des conditions (optionnel)

Vous pouvez créer des conditions pour différents environnements :

#### Condition "Production"
- **Name** : `production`
- **Condition** : App > App instance ID matches regex : `.*`
- **Value pour minimum_ios_app_version** : `1.2.1` (version stricte)

#### Condition "Beta / TestFlight"
- **Name** : `beta`
- **Condition** : Platform / OS > iOS
- **Value pour minimum_ios_app_version** : `1.0.0` (plus permissif)

## 🚀 Utilisation

### Définir une version minimale

1. Dans Firebase Console, allez dans **Remote Config**

2. Modifiez la valeur de `minimum_ios_app_version`
   - Exemple : `1.2.1` pour forcer la mise à jour vers la version 1.2.1

3. Cliquez sur **Publish changes**

4. Les utilisateurs avec une version inférieure verront l'écran de mise à jour au prochain lancement

### Format de version

Le système utilise le versioning sémantique (semver) :
- Format : `MAJOR.MINOR.PATCH`
- Exemple : `1.2.3`
  - MAJOR = 1
  - MINOR = 2
  - PATCH = 3

### Comparaison de versions

Le service compare les versions de gauche à droite :
1. Compare MAJOR
2. Si égal, compare MINOR  
3. Si égal, compare PATCH

Exemples :
- `1.2.0` < `1.2.1` ✅ Mise à jour requise
- `1.1.9` < `1.2.0` ✅ Mise à jour requise
- `2.0.0` > `1.9.9` ❌ Pas de mise à jour requise
- `1.2.1` = `1.2.1` ❌ Pas de mise à jour requise

## ⚠️ Précautions importantes

### 1. **Ne JAMAIS** définir une version future

❌ **MAUVAIS** : Si votre dernière version sur l'App Store est `1.2.1`, ne pas mettre `1.2.2` ou supérieur
- Cela bloquerait TOUS les utilisateurs, y compris ceux avec la dernière version

✅ **BON** : Mettre `1.2.1` ou inférieur

### 2. Laisser un délai de grâce

Quand vous publiez une nouvelle version :
1. Publiez la version `1.3.0` sur l'App Store
2. Attendez 48-72 heures pour que la plupart des utilisateurs mettent à jour
3. Ensuite seulement, mettez `minimum_ios_app_version` à `1.3.0` dans Firebase

### 3. Tester avant d'activer

Avant de forcer une mise à jour en production :

1. **Testez en local** :
   ```swift
   // Dans ForceUpdateService.swift, modifiez temporairement :
   settings.minimumFetchInterval = 0 // Fetch immédiat
   ```
   
2. **Utilisez TestFlight** :
   - Créez une condition Firebase pour TestFlight
   - Testez avec une version minimale élevée
   - Vérifiez que l'écran de mise à jour s'affiche correctement

3. **Rollout progressif** :
   - Commencez avec 10% des utilisateurs (condition Firebase)
   - Surveillez les metrics
   - Augmentez progressivement à 100%

### 4. Communication avec les utilisateurs

Avant de forcer une mise à jour :
- Envoyez une notification push informant de la mise à jour à venir
- Expliquez pourquoi la mise à jour est importante
- Donnez un délai (ex: "Mise à jour requise dans 48h")

## 📊 Monitoring

### Analytics Events

Le service enregistre automatiquement des événements :

1. **`force_update_triggered`**
   - Déclenché quand une mise à jour est requise
   - Paramètres :
     - `current_version` : Version de l'utilisateur
     - `minimum_version` : Version minimale requise

2. **`force_update_app_store_opened`**
   - Déclenché quand l'utilisateur clique sur "Mettre à jour"

### Vérifier dans Firebase Analytics

1. Allez dans **Analytics > Events** dans Firebase Console
2. Cherchez `force_update_triggered` pour voir combien d'utilisateurs sont affectés
3. Surveillez le taux de conversion vers l'App Store

## 🔍 Debugging

### Logs Console

Le service affiche des logs utiles :

```
📱 Current app version: 1.2.0
📋 Minimum required version: 1.2.1
⚠️ UPDATE REQUIRED: App version 1.2.0 is below minimum 1.2.1
```

ou

```
📱 Current app version: 1.2.1
📋 Minimum required version: 1.2.0
✅ App version is up to date
```

### Tester en local

Pour tester l'écran de mise à jour :

1. Ouvrez `ForceUpdateService.swift`
2. Modifiez temporairement la version dans `getCurrentAppVersion()` :
   ```swift
   private func getCurrentAppVersion() -> String {
       return "1.0.0" // Version artificielle pour test
   }
   ```
3. Lancez l'app - l'écran de mise à jour devrait apparaître

### Désactiver temporairement

Si vous devez désactiver la fonctionnalité :

1. Dans Firebase Console, mettez `minimum_ios_app_version` à `0.0.0`
2. Publiez les changements
3. Les utilisateurs pourront utiliser n'importe quelle version

## 🎯 Scénarios d'utilisation

### Scénario 1 : Bug critique découvert

Vous avez publié la version `1.2.5` mais découvrez un bug de sécurité critique.

1. Corrigez le bug et publiez la version `1.2.6` sur l'App Store
2. Une fois la version approuvée par Apple, mettez `minimum_ios_app_version` à `1.2.6` dans Firebase
3. Les utilisateurs en `1.2.5` ou inférieur seront forcés de mettre à jour

### Scénario 2 : Changement d'API backend

Votre backend passe à une nouvelle API incompatible avec les anciennes versions de l'app.

1. Publiez la version `2.0.0` compatible avec la nouvelle API
2. Attendez 1 semaine pour adoption naturelle
3. Mettez `minimum_ios_app_version` à `2.0.0`
4. Désactivez l'ancienne API backend

### Scénario 3 : Fin de support d'une version

Vous voulez arrêter de supporter iOS 14.

1. Publiez une version qui requiert iOS 15+
2. Mettez `minimum_ios_app_version` à cette version
3. Les utilisateurs sur iOS 14 ne pourront plus utiliser l'app (mais ne peuvent de toute façon pas mettre à jour)

## 📝 Checklist avant activation

Avant de forcer une mise à jour en production :

- [ ] La nouvelle version est publiée et disponible sur l'App Store
- [ ] Testé sur TestFlight que l'écran de mise à jour fonctionne
- [ ] Vérifié que la version minimale est correcte (pas trop élevée)
- [ ] Laissé un délai de 48-72h après publication
- [ ] Communiqué avec les utilisateurs (notification push ou email)
- [ ] Analytics configuré pour monitorer l'impact
- [ ] Plan de rollback prêt (mettre version à 0.0.0)

## 🆘 Support et dépannage

Si les utilisateurs rapportent des problèmes :

1. **Vérifiez la version dans Firebase Console** - Assurez-vous qu'elle n'est pas trop élevée
2. **Vérifiez que la nouvelle version est disponible** - Parfois l'App Store met du temps
3. **Rollback temporaire** - Mettez `0.0.0` pour débloquer tout le monde
4. **Consultez Analytics** - Voyez combien d'utilisateurs sont affectés

## 📞 Contact

Pour toute question sur cette implémentation :
- GitHub : [Votre repo]
- Email : dreyerfred+planea@gmail.com
