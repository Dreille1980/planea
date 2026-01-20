# Fix: Erreur Build Script Crashlytics

## 🚨 Problème

Vous voyez cette erreur lors du build:
```
Command PhaseScriptExecution failed with a nonzero exit code
Run script build phase 'Upload dSYM to Crashlytics' will be run during every build...
```

## ✅ Solution Rapide (Recommandée)

**Retirez temporairement le script Crashlytics** - Analytics et Performance fonctionneront parfaitement sans lui!

### Étapes:

1. Dans Xcode, sélectionnez le projet **Planea** (icône bleue en haut du navigateur)
2. Sélectionnez le target **Planea** 
3. Cliquez sur l'onglet **Build Phases**
4. Trouvez la phase **"Upload dSYM to Crashlytics"** ou **"Run Script"** 
5. **Supprimez-la** (clic droit > Delete ou sélectionnez et appuyez sur Delete)
6. **Build à nouveau** (Cmd+B)

✅ L'app devrait compiler sans erreur!

## 📊 Ce qui continuera de fonctionner

Même sans le script Crashlytics:
- ✅ Firebase Analytics fonctionne parfaitement
- ✅ Firebase Performance fonctionne parfaitement  
- ✅ Crashlytics fonctionne toujours! (mais sans les symboles de debug pour l'instant)

## 🔧 Solution Alternative (Avancée)

Si vous voulez absolument garder Crashlytics avec les symboles:

### Option A: Utiliser le nouveau script Firebase

Remplacez le contenu du script par:

```bash
# Check if the file exists before running
CRASHLYTICS_SCRIPT="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"

if [ -f "$CRASHLYTICS_SCRIPT" ]; then
    "$CRASHLYTICS_SCRIPT"
else
    echo "Crashlytics upload script not found at $CRASHLYTICS_SCRIPT"
    echo "Skipping dSYM upload"
fi
```

### Option B: Script conditionnel

```bash
# Only run in Release builds
if [ "${CONFIGURATION}" = "Release" ]; then
    CRASHLYTICS_UPLOAD="${PODS_ROOT}/FirebaseCrashlytics/upload-symbols"
    if [ -f "$CRASHLYTICS_UPLOAD" ]; then
        "$CRASHLYTICS_UPLOAD" -gsp "${PROJECT_DIR}/Planea/GoogleService-Info.plist" -p ios "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
    fi
fi
```

## 🎯 Recommandation

**Pour l'instant, supprimez le script** comme expliqué dans la Solution Rapide.

Vous pourrez toujours l'ajouter plus tard quand vous ferez une build Release pour l'App Store. Les crashes seront quand même reportés dans Firebase, vous aurez juste moins de détails sur la localisation exacte dans le code.

## 📝 Note

Le script Crashlytics est principalement utile pour les builds Release soumises à l'App Store. Pour le développement, Analytics et Performance sont plus que suffisants!
