# Architecture Planea - Notes Importantes

## 📱 Structure iOS

### Vues de génération de recettes Ad Hoc

⚠️ **IMPORTANT - Leçon apprise:**

Il existe deux fichiers pour la génération Ad Hoc, mais **UN SEUL est utilisé**:

#### ✅ RecipesView.swift (FICHIER ACTIF)
- **Localisation:** `Planea-iOS/Planea/Planea/Views/RecipesView.swift`
- **Contient:** `AdHocRecipeContentView` - la vue réellement affichée dans l'onglet "Ad hoc"
- **Usage:** C'est ce fichier qu'il faut modifier pour toute fonctionnalité Ad Hoc
- **Raison:** L'onglet "Ad hoc" dans RecipesView affiche `AdHocRecipeContentView()`, pas `AdHocRecipeView()`

#### ⚠️ AdHocRecipeView.swift (FICHIER OBSOLÈTE/STANDALONE)
- **Localisation:** `Planea-iOS/Planea/Planea/Views/AdHocRecipeView.swift`
- **Contient:** `AdHocRecipeView` - vue standalone qui n'est plus utilisée
- **Usage:** NE PAS MODIFIER - conservé pour compatibilité mais non utilisé dans l'app principale
- **Raison:** Version originale standalone qui a été intégrée dans RecipesView

### Pour ajouter une fonctionnalité Ad Hoc:

1. ✅ Modifier `RecipesView.swift` → `AdHocRecipeContentView`
2. ✅ Modifier `IAService.swift` si nécessaire (pour les appels API)
3. ✅ Modifier les localisations (EN + FR)
4. ✅ Modifier le backend (`main.py` ET `mock-server/main.py`)
5. ❌ NE PAS modifier `AdHocRecipeView.swift`

## 🔧 Backend

### Déploiement

⚠️ **TOUJOURS modifier les deux fichiers:**
- `main.py` (racine du projet)
- `mock-server/main.py` (copie pour Render)

Les deux doivent être identiques pour le déploiement sur Render.

### Configuration Render

- **Root Directory:** `mock-server/`
- **Build Command:** `pip install -r requirements.txt`
- **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`

## 🌐 Localisations

Toujours maintenir les deux langues:
- `Planea-iOS/Planea/Planea/en.lproj/Localizable.strings`
- `Planea-iOS/Planea/Planea/fr.lproj/Localizable.strings`

## 📊 Génération de recettes

### Portions de protéines

Le système recommande **150-200g de viande/protéines par personne** dans les recettes.

### Complexité des recettes

Trois niveaux disponibles:
- **Simple:** 30 minutes
- **Intermédiaire:** 60 minutes  
- **Avancé:** 90 minutes

Cette information est passée via le paramètre `maxMinutes` au backend.

## 🗂️ Structure de fichiers

### Vues principales
- `RecipesView.swift` - Onglets "Plan" et "Ad hoc"
- `PlanWeekView.swift` - Planification hebdomadaire
- `RecipeDetailView.swift` - Détails d'une recette

### Services
- `IAService.swift` - Communication avec l'API backend
- `PreferencesService.swift` - Gestion des préférences utilisateur
- `StoreManager.swift` - In-App Purchases

### ViewModels
- `RecipeViewModel.swift` - Gestion des recettes
- `FamilyViewModel.swift` - Gestion des membres famille
- `PlanViewModel.swift` - Gestion des plans hebdomadaires

## 📝 Notes de développement

**Date:** 2025-10-19

- Migration des vues Ad Hoc: La fonctionnalité Ad Hoc a été migrée de `AdHocRecipeView.swift` (standalone) vers `RecipesView.swift` (intégré dans l'interface à onglets)
- Le fichier `AdHocRecipeView.swift` existe toujours mais n'est plus utilisé dans le flux principal de l'app
- Toute modification future à la génération Ad Hoc doit se faire dans `RecipesView.swift`
