# Fix: Meal Prep - Préférences de Protéines Non Respectées

## Le Problème

Le wizard Meal Prep n'utilisait PAS les préférences de protéines (ex: tofu désactivé) lors de la génération des recettes. Des recettes avec du tofu étaient suggérées même si l'utilisateur l'avait désactivé dans Settings > Recipe Preferences.

## La Cause Racine

Le problème était **DOUBLE**:

### 1. Distribution des protéines
La fonction `distribute_proteins_for_meal_prep()` cherchait `preferredProteins` dans `preferences` mais le wizard l'envoyait dans `constraints`.

### 2. Prompt OpenAI (CRITIQUE!)
Même si la distribution lisait correctement les préférences, le prompt OpenAI **ne les utilisait PAS**! Les `preferredProteins` n'étaient JAMAIS transmis à OpenAI.

## La Solution

### Changement 1: Lecture des constraints dans `distribute_proteins_for_meal_prep()`
```python
# CRITICAL: Check constraints first (sent by meal prep wizard), then preferences
preferred_proteins = preferences.get("preferredProteins", [])
if not preferred_proteins and isinstance(preferences, dict):
    # If not in preferences, check if it's nested in constraints
    constraints = preferences.get("constraints", {})
    preferred_proteins = constraints.get("preferredProteins", [])
```

### Changement 2: Ajout au prompt OpenAI (LA VRAIE SOLUTION!)
```python
# CRITICAL ADDITION: Also check constraints for preferredProteins if not found in preferences
# This handles Meal Prep which sends preferredProteins in constraints, not preferences
if not preferences_text or "Preferred proteins" not in preferences_text:
    if constraints.get("preferredProteins"):
        proteins_list = constraints["preferredProteins"]
        if proteins_list:
            proteins = ", ".join(proteins_list)
            preferences_text += f"CRITICAL - USER'S PREFERRED PROTEINS: {proteins}. YOU MUST ONLY USE THESE PROTEINS. "
            print(f"  ✅ Added preferredProteins from constraints to prompt: {proteins}")
```

## Déploiement Sur Production

**IMPORTANT:** Tu utilises le serveur de PRODUCTION sur Render.com (`https://planea-backend.onrender.com`), pas le serveur local.

### Étapes pour déployer:

1. **Commit les changements:**
```bash
cd /Users/T979672/developer/planea
git add mock-server/main.py
git commit -m "Fix: Respect recipe protein preferences in meal prep"
```

2. **Push vers GitHub:**
```bash
git push origin main
```

3. **Déployer sur Render.com:**
   - Va sur ton dashboard Render: https://dashboard.render.com
   - Trouve ton service backend
   - Clique sur "Manual Deploy" > "Deploy latest commit"
   - Attends que le déploiement soit terminé (environ 2-3 minutes)

4. **Vérifier:**
   - Génère un nouveau meal prep depuis l'app
   - Vérifie les logs dans Render.com (onglet "Logs")
   - Tu devrais voir: `✅ Added preferredProteins from constraints to prompt:`

## Logs Attendus Après le Fix

Après le déploiement, quand tu génères un meal prep, tu devrais voir dans les logs:

```
🔍 MEAL PREP - Protein Preferences Detection:
  preferences dict keys: ['constraints', ...]
  preferred_proteins found: ['chicken', 'beef', 'pork', 'fish', 'seafood', 'legumes', 'eggs']

🎯 MEAL PREP Protein Distribution:
  Total recipes: 5
  Min unique proteins: 4
  Protein pool: ['chicken', 'beef', 'pork', 'fish', 'seafood', 'legumes', 'eggs']
  ✅ Distribution: ['chicken', 'beef', 'pork', 'fish', 'seafood']

✅ Added preferredProteins from constraints to prompt: chicken, beef, pork, fish, seafood, legumes, eggs
```

## Test

Après le déploiement:
1. Va dans Settings > Recipe Preferences
2. Désactive le tofu (et autres protéines non désirées)
3. Génère un nouveau meal prep
4. **RÉSULTAT ATTENDU:** Aucune recette de tofu ne devrait être suggérée!

## Fichiers Modifiés

- `mock-server/main.py` - Fonction `generate_recipe_with_openai()` ligne ~500
- `mock-server/main.py` - Fonction `distribute_proteins_for_meal_prep()` ligne ~380

## Note Importante

Ces modifications sont dans le serveur LOCAL (`mock-server/main.py`). Tu DOIS les déployer sur Render.com pour qu'elles prennent effet dans l'app!
