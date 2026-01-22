# Solution pour les warnings dSYM Firebase lors de l'export vers TestFlight

## Problème
Lors de l'export vers TestFlight, vous recevez des warnings indiquant que les fichiers dSYM sont manquants pour:
- FirebaseAnalytics.framework
- GoogleAdsOnDeviceConversion.framework  
- GoogleAppMeasurement.framework

## Cause
Ces warnings apparaissent car Firebase est intégré via Swift Package Manager (SPM), et les packages SPM ne copient pas automatiquement les fichiers dSYM dans l'archive finale.

## Solution
Un script a été créé pour copier automatiquement les dSYMs des frameworks Firebase/Google dans l'archive. Vous devez maintenant l'ajouter comme Build Phase dans Xcode.

## Instructions d'installation dans Xcode

### Étape 1: Ouvrir le projet
1. Ouvrez `Planea.xcodeproj` dans Xcode
2. Sélectionnez le projet "Planea" dans la barre latérale gauche (l'icône bleue tout en haut)

### Étape 2: Accéder aux Build Phases
1. Sélectionnez la **target** "Planea" (pas "PleneaWidgetExtension")
2. Cliquez sur l'onglet **"Build Phases"** en haut

### Étape 3: Ajouter une nouvelle Run Script Phase
1. Cliquez sur le bouton **"+"** en haut à gauche de la section Build Phases
2. Sélectionnez **"New Run Script Phase"**
3. Une nouvelle phase "Run Script" sera créée à la fin de la liste

### Étape 4: Déplacer le script (IMPORTANT)
1. **Glissez-déposez** cette nouvelle phase "Run Script" pour la positionner:
   - **APRÈS** "Embed Foundation Extensions" 
   - **AVANT** toute autre phase existante si applicable
   - Elle doit être une des dernières phases

### Étape 5: Configurer le script
1. **Développez** la phase "Run Script" en cliquant sur le triangle
2. Changez le nom en **"Copy SPM dSYMs"** (optionnel mais recommandé)
3. Dans le champ de texte du script, collez cette ligne:

```bash
"${SRCROOT}/copy-spm-dsyms.sh"
```

4. **Cochez** la case "Run script: Based on dependency analysis" pour optimiser les builds
5. Dans la section "Input Files", ajoutez (cliquez sur le + si nécessaire):
   - (Laissez vide - pas nécessaire pour ce script)

6. Dans la section "Output Files", ajoutez:
   - (Laissez vide - pas nécessaire pour ce script)

### Étape 6: Désactiver User Script Sandboxing (SI NÉCESSAIRE)
Si le script échoue lors du build avec une erreur de permissions:

1. Restez dans les Build Settings de la target "Planea"
2. Cliquez sur l'onglet **"Build Settings"**
3. Cherchez **"User Script Sandboxing"** (utilisez la barre de recherche)
4. Changez la valeur à **"No"**

**OU** plus simplement, modifiez le script pour ne pas avoir besoin de cette modification:

Dans la phase Run Script, utilisez plutôt ce script étendu:

```bash
# Désactiver temporairement l'exit on error si nécessaire
set +e
"${SRCROOT}/copy-spm-dsyms.sh"
exit 0
```

### Étape 7: Tester
1. **Clean Build Folder**: Product → Clean Build Folder (ou Cmd+Shift+K puis Cmd+Shift+Option+K)
2. **Archive**: Product → Archive
3. Lors de l'archive, vous devriez voir dans les logs de build:
   ```
   🔍 Searching for SPM dSYM files...
   📦 Found: FirebaseAnalytics.dSYM
   📦 Found: GoogleAppMeasurement.dSYM
   etc...
   ✅ dSYM copy completed
   ```
4. **Exporter** vers TestFlight et vérifier que les warnings ont disparu

## Vérification rapide

Après avoir archivé, vous pouvez vérifier manuellement que les dSYMs sont présents:
1. Window → Organizer
2. Sélectionnez votre archive
3. Clic droit → "Show in Finder"
4. Clic droit sur l'archive → "Show Package Contents"
5. Naviguez vers `dSYMs/`
6. Vous devriez voir les fichiers `.dSYM` pour Firebase et Google

## Alternative: Laisser Firebase les télécharger automatiquement

Si vous ne voulez pas ajouter ce script, sachez que:
- Les warnings n'empêchent PAS l'app de fonctionner
- Firebase Crashlytics peut télécharger automatiquement les dSYMs depuis App Store Connect
- Ce téléchargement automatique prend quelques heures après la publication
- Les crash reports fonctionneront correctement après ce délai

**Recommandation**: Ajoutez le script maintenant pour avoir les crash reports symbolisés immédiatement et éviter les warnings.

## Emplacement du script
Le script se trouve à: `Planea-iOS/Planea/copy-spm-dsyms.sh`

## Note sur les futurs uploads
Une fois le script configuré, il s'exécutera automatiquement à chaque archive. Vous n'aurez plus à vous en préoccuper.
