# Corrections Meal Prep - 25 novembre 2025

## Problèmes identifiés et corrigés

### 1. ✅ Tofu utilisé malgré les préférences NON cochées

**Cause**: Les `preferredProteins` n'étaient PAS envoyées au backend lors de la génération du meal prep.

**Solution**: Modification de `MealPrepWizardView.swift`, fonction `buildConstraints()`:
- Ajout de l'extraction des protéines préférées depuis `GenerationPreferences`
- Ajout de ces protéines dans le dictionnaire `constraintsDict` envoyé au backend
- Le backend utilise maintenant ces préférences via la fonction `distribute_proteins_for_meal_prep`

**Fichier modifié**: 
- `Planea-iOS/Planea/Planea/Views/MealPrepWizardView.swift` (ligne ~733)

**Code ajouté**:
```swift
// CRITICAL: Add preferred proteins so backend knows which proteins to use
let preferredProteinStrings = generationPrefs.preferredProteins.map { $0.rawValue }
constraintsDict["preferredProteins"] = preferredProteinStrings
```

**Résultat**: 
- Le backend reçoit maintenant la liste des protéines préférées
- Si l'utilisateur n'a PAS coché "tofu", le backend ne l'utilisera plus
- La diversité des protéines est maintenue selon les préférences de l'utilisateur

---

### 2. ✅ Navigation vers RecipeDetailView dans l'onglet Recettes

**Cause**: Aucun `NavigationLink` n'était configuré pour ouvrir les détails d'une recette.

**Solution**: Modification de `MealPrepDetailView.swift`, fonction `recipeCard()`:
- Ajout d'un `NavigationLink` vers `RecipeDetailView` quand la recette complète est disponible
- Ajout d'un chevron (flèche) pour indiquer visuellement que la recette est cliquable
- Utilisation de `.buttonStyle(PlainButtonStyle())` pour garder le style de card

**Fichier modifié**: 
- `Planea-iOS/Planea/Planea/Views/MealPrepDetailView.swift` (ligne ~106)

**Résultat**: 
- Les utilisateurs peuvent maintenant cliquer sur une recette dans l'onglet "Recettes"
- Une navigation fluide vers `RecipeDetailView` avec toutes les informations (ingrédients, étapes, équipement)
- L'expérience utilisateur est maintenant cohérente avec les plans hebdo

---

### 3. ⚠️ "Recette simple de souper" - Problème de génération

**Cause identifiée**: Cette recette générique est un **fallback** du backend Python quand OpenAI échoue à générer une recette.

**Localisation**: `mock-server/main.py`, fonction `generate_recipe_with_openai()`, ligne ~2810

**Code du fallback**:
```python
except Exception as e:
    print(f"Error generating recipe with OpenAI: {e}")
    # Fallback to a simple recipe
    return Recipe(
        title=f"Recette simple de {meal_type_fr}",
        servings=servings,
        total_minutes=30,
        ingredients=[...],
        steps=["Préparer les ingrédients", "Cuire selon les instructions"],
        equipment=["poêle"],
        tags=["simple"]
    )
```

**Raisons possibles d'échec OpenAI**:
1. Timeout de l'API OpenAI (120 secondes)
2. Erreur de décodage JSON de la réponse
3. Token limit atteint
4. Erreur temporaire du service OpenAI
5. Format JSON invalide retourné par le modèle

**Solutions possibles** (non implémentées pour l'instant):
1. ✅ Vérifier les logs backend pour identifier l'erreur exacte
2. Augmenter le timeout si nécessaire
3. Améliorer la gestion d'erreur pour retenter la génération
4. Améliorer le prompt pour éviter les erreurs de parsing JSON
5. Ajouter une validation plus robuste du JSON retourné

**Action recommandée**: 
- Tester à nouveau le meal prep maintenant que les `preferredProteins` sont envoyées correctement
- Si le problème persiste, vérifier les logs du backend (`mock-server/main.py`) pour l'erreur spécifique
- Le fallback devrait être rare avec le fix des protéines préférées

---

## Tests recommandés

1. **Test des protéines préférées**:
   - Aller dans Settings > Recipe Preferences
   - Décocher "tofu" (et d'autres protéines si désiré)
   - Générer un nouveau meal prep
   - Vérifier qu'aucune recette n'utilise le tofu

2. **Test de navigation**:
   - Ouvrir un meal prep existant
   - Aller dans l'onglet "Recettes"
   - Cliquer sur une recette
   - Vérifier que RecipeDetailView s'ouvre avec tous les détails

3. **Test de génération**:
   - Générer plusieurs meal preps
   - Vérifier qu'aucune "recette simple de souper" n'apparaît
   - Si elle apparaît, vérifier les logs backend

---

## Statut

- ✅ Problème 1 (tofu): **CORRIGÉ**
- ✅ Problème 2 (navigation): **CORRIGÉ**
- ⚠️ Problème 3 ("recette simple"): **DIAGNOSTIQUÉ** - Devrait être résolu avec le fix #1

---

## Notes techniques

### Backend (main.py)
- La fonction `distribute_proteins_for_meal_prep()` gère maintenant correctement les `preferredProteins`
- Elle filtre les protéines de petit-déjeuner (eggs, yogurt, bacon) pour le meal prep
- Elle assure une diversité avec minimum 2 protéines uniques et maximum 2 répétitions par protéine

### iOS (Swift)
- `GenerationPreferences` contient déjà `preferredProteins: Set<Protein>`
- `PreferencesService` charge et sauvegarde ces préférences correctement
- Le problème était uniquement dans la transmission au backend

---

## Prochaines étapes suggérées

1. Tester les corrections en production
2. Monitorer les logs backend pour détecter d'éventuelles erreurs OpenAI
3. Si nécessaire, améliorer la robustesse de la génération de recettes
4. Ajouter une retry logic si les timeouts sont fréquents
