# Configuration de la localisation Planea

## Structure créée

La localisation a été correctement configurée avec la structure iOS standard:

```
Planea-iOS/Planea/Planea/
├── fr.lproj/
│   ├── Localizable.strings (traductions françaises)
│   └── InfoPlist.strings (messages système en français)
├── en.lproj/
│   ├── Localizable.strings (traductions anglaises)
│   └── InfoPlist.strings (messages système en anglais)
└── Info.plist (avec CFBundleLocalizations configuré)
```

## Changements effectués

### 1. Structure de localisation
- ✅ Créé dossiers `fr.lproj` et `en.lproj`
- ✅ Fichiers `Localizable.strings` pour chaque langue (60+ clés)
- ✅ Fichiers `InfoPlist.strings` pour messages système
- ✅ Supprimé ancien dossier `Resources`

### 2. Configuration Info.plist
```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>fr</string>
</array>
<key>CFBundleDevelopmentRegion</key>
<string>fr</string>
```

### 3. Code mis à jour
- ✅ Toutes les vues utilisent `String(localized: "key")`
- ✅ PlaneaApp.swift avec `.id(appLanguage)` pour rafraîchissement immédiat
- ✅ Tous les textes hardcodés remplacés par des clés localisées

### 4. Langues supportées
1. **Système** - Suit la langue du téléphone
2. **Français** - Langue française
3. **English** - Langue anglaise

## Comment tester

### Dans Xcode:

1. **Nettoyez le build** (Important!)
   ```
   Product > Clean Build Folder (Shift+Cmd+K)
   ```

2. **Reconstruire le projet**
   ```
   Product > Build (Cmd+B)
   ```

3. **Tester le changement de langue**
   - Lancez l'app
   - Allez dans Réglages
   - Changez la langue
   - L'app devrait se rafraîchir immédiatement avec la nouvelle langue

### Vérification des traductions:

L'app changera de langue immédiatement grâce à:
```swift
.environment(\.locale, Locale(identifier: AppLanguage.currentLocale(appLanguage)))
.id(appLanguage) // Force le rebuild quand la langue change
```

## Traductions complètes

### Écrans localisés:
- ✅ Onboarding
- ✅ Plan de la semaine
- ✅ Liste d'épicerie
- ✅ Recette ad hoc
- ✅ Réglages
- ✅ Gestion de la famille
- ✅ Détails du membre
- ✅ Écran de génération

### Catégories de traduction:
- Interface utilisateur (onglets, titres, boutons)
- Messages d'erreur
- Messages de génération
- Actions (sauvegarder, annuler, ajouter, etc.)
- Jours de la semaine
- Types de repas
- Unités et préférences

## Dépannage

Si la langue ne change pas:
1. Nettoyez le build folder (Shift+Cmd+K)
2. Supprimez l'app du simulateur/appareil
3. Reconstruisez et relancez

Si vous voyez encore du texte hardcodé:
- Vérifiez que tous les fichiers utilisent `String(localized: "key")`
- Assurez-vous que les fichiers .lproj contiennent toutes les clés

## Notes techniques

- Le système iOS cherche les traductions dans les dossiers `.lproj`
- `CFBundleLocalizations` déclare les langues supportées
- `CFBundleDevelopmentRegion` définit la langue par défaut
- Le modificateur `.id()` force SwiftUI à reconstruire la vue complète
