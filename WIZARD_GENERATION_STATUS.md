# 🧙‍♂️ Week Generation Wizard - Status Report

**Dernière mise à jour:** 15/02/2026 13:53  
**Commit:** 71bfb49 - Phase 3A UI Wizard

---

## ✅ PHASE 3A - COMPLÉTÉE (100%)

### 🎨 UI Wizard - 6 fichiers créés

**Models:**
- ✅ `WeekGenerationConfig.swift` - Configuration complète (DayConfig, MealPrepMealTypeSelection, validation)

**ViewModels:**
- ✅ `WeekGenerationConfigViewModel.swift` - Gestion état, navigation, validation

**Views:**
- ✅ `WeekGenerationWizardView.swift` - Structure principale avec TabView
- ✅ `DaySelectionStepView.swift` - Étape 1 : Sélection jours + type
- ✅ `MealPrepConfigStepView.swift` - Étape 2 : Portions + meal types
- ✅ `PreferencesStepView.swift` - Étape 3 : Préférences (collapsible)

**Documentation:**
- ✅ `WIZARD_GENERATION_LOCALIZATIONS.md` - 35 clés FR/EN documentées

### 🎯 Fonctionnalités implémentées

- ✅ Wizard 3 étapes avec barre de progression
- ✅ Sélection jours individuelle (toggle on/off)
- ✅ Choix type par jour (Normal vs Meal Prep)
- ✅ Calcul automatique portions (jours × famille × meal types)
- ✅ Édition manuelle portions via sheet
- ✅ Segmented control pour type meal prep (lunch/dinner/both)
- ✅ Navigation intelligente (skip étape 2 si pas de meal prep)
- ✅ Validation à chaque étape
- ✅ Summary cards avec statistiques temps réel
- ✅ Préférences optionnelles collapsibles
- ✅ Analytics events préparés

---

## 🚧 PHASE 3B - EN COURS (0%)

### Backend Integration

**À faire:**
1. **PlanViewModel.generateWeekWithConfig()** - Nouvelle fonction
   ```swift
   @MainActor
   func generateWeekWithConfig(_ config: WeekGenerationConfig) async throws {
       // Call backend endpoint
       // Parse PlannedWeek with MealSource
       // Save MealPrepKit separately
       // Update UI
   }
   ```

2. **Backend Endpoint** - `/ai/generate-week-with-meal-prep`
   - Input: meal_prep_days, normal_days, portions, preferences
   - Output: PlannedWeek mixte + MealPrepKit
   - Logic: Générer meal prep + recettes normales séparément, puis merger

### UI Integration

**À faire:**
3. **MealPrepCard.swift** - Nouveau composant
   - Badge "🍱 Meal Prep" overlay
   - Affichage portions utilisées
   - Style visuel distinct
   - Navigation vers MealPrepDetailView

4. **PlanWeekView modification**
   - Remplacer bouton "Générer" par wizard
   - Détecter `MealSource.mealPrep` dans cards
   - Afficher badge meal prep
   - Context menu meal prep

---

## 📋 PHASE 3C - BACKEND (0%)

### Nouvel endpoint Python

**mock-server/main.py:**
```python
@app.post("/ai/generate-week-with-meal-prep")
async def generate_week_with_meal_prep(request: Request, req: dict):
    """
    Generate mixed week with normal recipes + meal prep.
    """
    meal_prep_days = req["meal_prep_days"]  # ["monday", "wednesday"]
    normal_days = req["normal_days"]  # ["tuesday", "thursday"]
    meal_prep_portions = req["meal_prep_portions"]  # 12
    meal_prep_meal_types = req["meal_prep_meal_types"]  # ["lunch", "dinner"]
    family_size = req["family_size"]  # 4
    preferences = req["preferences"]
    
    # 1. Generate meal prep kit
    meal_prep_kit = await generate_meal_prep_kits({...})
    
    # 2. Generate normal recipes
    normal_recipes = await generate_normal_recipes({...})
    
    # 3. Build PlannedWeek with MealSource
    planned_week = build_mixed_week(...)
    
    return {
        "planned_week": planned_week,
        "meal_prep_kit": meal_prep_kit
    }
```

---

## 🌍 PHASE 3D - LOCALISATIONS (0%)

### À ajouter

**FR (35 clés):**
- Voir `WIZARD_GENERATION_LOCALIZATIONS.md` section FR

**EN (35 clés):**
- Voir `WIZARD_GENERATION_LOCALIZATIONS.md` section EN

---

## 🔧 ARCHITECTURE TECHNIQUE

### Flow complet

```
User tap "Générer"
    ↓
WeekGenerationWizardView
    ↓
WeekGenerationConfigViewModel
    ↓
PlanViewModel.generateWeekWithConfig(config)
    ↓
Backend: /ai/generate-week-with-meal-prep
    ↓
Response: PlannedWeek + MealPrepKit
    ↓
Save: MealPlan (legacy) + MealPrepKit
    ↓
PlanWeekView refresh
    ↓
Display: RecipeCard + MealPrepCard avec badges
```

### MealSource Enum

```swift
enum MealSource {
    case recipe(Recipe)
    case mealPrep(assignment: MealPrepAssignment, kit: MealPrepKit)
}
```

**Déjà implémenté dans Phase 1-2 ✅**

---

## 📊 STATISTIQUES

### Code créé (Phase 3A uniquement)

- **Fichiers:** 7 nouveaux (6 Swift + 1 MD)
- **Lignes de code:** ~1,300 lignes Swift
- **Localisations:** 35 clés documentées
- **Commits:** 1 (71bfb49)

### Reste à faire (Phase 3B-3D)

- **Fichiers Swift:** 2 (PlanViewModel ext + MealPrepCard)
- **Modifications:** 2 (PlanWeekView + mock-server/main.py)
- **Localisations:** 70 lignes (35×2 langues)
- **Estimation:** ~800 lignes additionnelles

---

## ⚠️ POINTS D'ATTENTION

### 1. Backend Mock vs Production
- Le mock-server a déjà `/ai/meal-prep-kits` ✅
- Besoin d'un nouvel endpoint qui merge meal prep + normal
- Doit retourner structure compatible avec PlannedWeek

### 2. Backward Compatibility
- MealPlanAdapter déjà adapté ✅
- MealSource enum déjà implémenté ✅
- Conversion legacy MealPlan ↔ PlannedWeek OK ✅

### 3. Persistence
- MealPrepKit sauvé séparément via MealPrepStorageService ✅
- Plan sauvé via PersistenceController (legacy format) ✅
- Synchronisation automatique

### 4. Analytics
- Events déjà préparés dans WeekGenerationConfigViewModel ✅
- Besoin d'ajouter tracking backend response time

---

## 🎯 PROCHAINES ÉTAPES RECOMMANDÉES

### Option A: Implémentation complète immédiate
1. Créer MealPrepCard.swift
2. Étendre PlanViewModel avec generateWeekWithConfig()
3. Modifier PlanWeekView (intégrer wizard + badge)
4. Créer backend endpoint
5. Ajouter localisations
6. Tests end-to-end

**Temps estimé:** 2-3 heures

### Option B: Test incrémental
1. D'abord : Ajouter localisations pour tester UI wizard
2. Créer MealPrepCard stub
3. Modifier PlanWeekView pour ouvrir wizard
4. Test UI flow complet sans backend
5. Puis continuer avec backend

**Temps estimé:** 1h pour UI test, puis 1-2h backend

### Option C: Backend d'abord
1. Créer endpoint backend
2. Tester avec Postman/curl
3. Puis continuer UI integration

**Temps estimé:** 1h backend, puis 1-2h UI

---

## 🚀 RECOMMENDATION

**Je recommande Option B (Test incrémental)**

**Pourquoi:**
- Permet de valider l'UX du wizard immédiatement
- Détecte les problèmes UI/navigation avant backend
- Backend peut être développé/testé séparément
- Moins risqué (changements isolés)

**Action immédiate:**
1. Ajouter les 35 clés de localisation (10 min)
2. Créer MealPrepCard stub (15 min)
3. Modifier PlanWeekView pour ouvrir wizard (15 min)
4. **→ TEST complet du flow UI wizard** 🎉

Ensuite :
5. Backend endpoint (45 min)
6. Intégration complète (30 min)
7. Tests finaux (30 min)

**Total: ~2h30 pour completion Phase 3**

---

## 📝 NOTES

- Context window usage: 82% (163K/200K tokens)
- Code compile sans erreur ✅
- Architecture propre et scalable ✅
- Prêt pour évolution future ✅
