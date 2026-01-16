# Backend Changes - À Implémenter

## 📍 Fichier: `mock-server/main.py`

### ✅ Changements Frontend (Déjà complétés)
- Checkbox à droite dans Cooking ✓
- Suppression du tag "While/Parallel" dans l'UI ✓

### 🔧 Changements Backend (À faire)

---

## 1. Désactiver isParallel / parallelNote

**Fonction:** `generate_cooking_phases()` (ligne ~2700)

**Changement dans le prompt OpenAI:**

### AVANT:
```python
"is_parallel": true,
"parallel_note": "Pendant que les légumes rôtissent"
```

### APRÈS:
```python
"is_parallel": false,
"parallel_note": null
```

**Action:** Dans le prompt, remplacer toutes les mentions de:
- `is_parallel: true` par `is_parallel: false`
- Retirer les instructions sur `parallel_note`

**Localisation exacte:**
- Chercher: `"is_parallel": true` dans le prompt
- Remplacer par: `"is_parallel": false`
- Supprimer: Toutes les instructions sur "PARALLELISM"

---

## 2. Les nouvelles règles de tri/filtrage sont DÉJÀ dans le document

Voir **MEAL_PREP_BACKEND_REFINEMENTS.md** sections:

### Section 1: MISE EN PLACE - Section Chop
- Tri par catégorie: Légumes → Protéines → Fromage
- Fusionner Grate → Chop

### Section 3: MISE EN PLACE - Section Mix
- **RÈGLE STRICTE:** Liquides seulement

### Section 4: COOKING
- Exclure étapes déjà dans Mise en Place
- Simplifier références aux items préparés

---

## 🎯 Ordre d'implémentation recommandé

### Phase 1 - Quick Win (5 min)
1. **Désactiver isParallel/parallelNote**
   - Fichier: `mock-server/main.py`
   - Fonction: `generate_cooking_phases()`
   - Action: Modifier le prompt pour forcer `is_parallel: false` partout

### Phase 2 - Prompt Engineering (30 min)
2. **Mettre à jour le prompt OpenAI dans `generate_cooking_phases()`**
   - Ajouter les nouvelles règles de MEAL_PREP_BACKEND_REFINEMENTS.md
   - Intégrer les règles Mix (liquides seulement)
   - Intégrer les règles Chop (tri par catégorie)

### Phase 3 - Test (15 min)
3. **Tester avec un meal prep réel**
   - Générer un kit de 3 recettes
   - Vérifier que isParallel = false partout
   - Vérifier que parallelNote = null partout
   - Vérifier l'ordre des sections de Mise en Place

---

## ⚡ Code à modifier - generate_cooking_phases()

**Ligne ~2850 (approximatif):**

```python
# CHERCHER CES LIGNES:
"is_parallel": true,
"parallel_note": "Pendant que les légumes rôtissent"

# ET AUSSI:
"PARALLELISM EXAMPLE:"
"While broccoli roasts in oven (30 min)" → is_parallel=true

# REMPLACER PAR:
"is_parallel": false,
"parallel_note": null

# ET SUPPRIMER COMPLÈTEMENT:
Toute la section "PARALLELISM EXAMPLE"
```

---

## 📝 Template du nouveau prompt (extrait)

```python
prompt = f"""...

📋 STRUCTURE OBLIGATOIRE:

{{
  "cook": {{
    "title": "🔥 Cuisson",
    "total_minutes": XX,
    "steps": [
      {{
        "id": "uuid",
        "description": "Préchauffer four à 220°C",
        "recipe_title": "Multiple",
        "recipe_index": null,
        "estimated_minutes": 5,
        "is_parallel": false,
        "parallel_note": null
      }},
      {{
        "id": "uuid",
        "description": "Rôtir brocoli, carottes et poivrons sur plaque au four (15 min)",
        "recipe_title": "Salmon Bowl",
        "recipe_index": 1,
        "estimated_minutes": 15,
        "is_parallel": false,  // ← TOUJOURS false maintenant
        "parallel_note": null   // ← TOUJOURS null maintenant
      }}
    ]
  }},
  ...
}}

❌ RÈGLE ABSOLUE: is_parallel DOIT TOUJOURS être false
❌ RÈGLE ABSOLUE: parallel_note DOIT TOUJOURS être null

Retourne UNIQUEMENT le JSON."""
```

---

## 🧪 Test après modification

1. Redémarrer le serveur backend
2. Générer un nouveau meal prep kit
3. Vérifier dans la réponse JSON:
   ```json
   "cooking_phases": {
     "cook": {
       "steps": [
         {
           "is_parallel": false,  // ← Doit être false
           "parallel_note": null  // ← Doit être null
         }
       ]
     }
   }
   ```

---

## 📊 Status

- [ ] Backend: Désactiver isParallel/parallelNote dans generate_cooking_phases()
- [ ] Backend: Intégrer nouvelles règles Mix/Chop/Peel du document REFINEMENTS
- [ ] Backend: Tester génération d'un kit
- [x] Frontend: Checkbox à droite dans Cooking
- [x] Frontend: Suppression affichage tag "While/Parallel"
- [x] Documentation: MEAL_PREP_BACKEND_REFINEMENTS.md créé

---

## 💡 Note Importante

Les règles détaillées pour Mise en Place et Cooking sont TOUTES dans:
**MEAL_PREP_BACKEND_REFINEMENTS.md**

Ce fichier contient:
- Logique Python complète pour tri par catégorie
- Validation stricte pour Mix (liquides seulement)  
- Filtrage des étapes redondantes
- Nouveau prompt OpenAI complet

Il suffit de:
1. Lire MEAL_PREP_BACKEND_REFINEMENTS.md
2. Appliquer les changements au prompt dans `generate_cooking_phases()`
3. Tester

**Tout est déjà documenté et prêt à être appliqué !**
