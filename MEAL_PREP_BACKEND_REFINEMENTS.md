# Meal Prep Backend Refinements

## 📋 Nouvelles exigences UX - 16 janvier 2026

### 1. MISE EN PLACE - Section Chop (Couper)

**Ordre de tri des ingrédients à couper:**
1. 🥕 Légumes/Fruits en premier
2. 🍗 Protéines (viandes/poissons) ensuite
3. 🧀 Fromage et autres (à râper) en dernier

**Consolidation Grate → Chop:**
- ❌ NE PLUS créer de section "Grate" séparée
- ✅ Fusionner tous les ingrédients à râper dans la section "Chop"
- Exemple: "Fromage cheddar — 200g, râpé" dans section Chop

**Logique backend:**
```python
def build_chop_section():
    items = []
    
    # 1. Légumes & fruits
    items.extend(filter_by_category(ingredients, ["vegetables", "fruits"]))
    
    # 2. Protéines
    items.extend(filter_by_category(ingredients, ["meats", "fish", "proteins"]))
    
    # 3. Fromage & reste (à râper aussi)
    items.extend(filter_by_category(ingredients, ["dairy", "other"]))
    
    return ActionSection(
        action_type="chop",
        items=items
    )
```

### 2. MISE EN PLACE - Section Peel (Éplucher)

**Cas d'usage spécifiques:**
- Crevettes (enlever carapace)
- Saumon (enlever peau)
- Légumes à éplucher (carottes, pommes de terre, etc.)

**Ne PAS inclure:**
- Ail (considéré comme "prep" général, pas "peel")
- Oignons (considéré comme "chop")

### 3. MISE EN PLACE - Section Mix

**⚠️ RÈGLE STRICTE: Liquides uniquement pour sauces/marinades**

**✅ À INCLURE:**
- Sauces liquides (vinaigrette, marinade, sauce soja + miel, etc.)
- Mélanges liquides/semi-liquides
- Exemple: "Mix soy sauce, honey, water for glaze"

**❌ NE PAS INCLURE:**
- Légumes pour salades (→ va dans "Assemble")
- Légumes pour sautés (→ va dans "Cooking")
- Exemple: "Mix lettuce, tomatoes, cucumber" → MAUVAIS

**Logique backend:**
```python
def should_be_in_mix_section(step_description: str, ingredients: List[Ingredient]) -> bool:
    """
    Determine if a mix step should be in Mise en Place or elsewhere.
    """
    # Check if it's mixing liquids/sauces
    liquid_keywords = ["sauce", "marinade", "dressing", "glaze", "vinaigrette", "oil", "vinegar"]
    
    # Check if ingredients are primarily liquid
    liquid_ingredients = ["soy sauce", "oil", "vinegar", "water", "juice", "honey", "syrup"]
    
    has_liquid_keyword = any(keyword in step_description.lower() for keyword in liquid_keywords)
    has_liquid_ingredients = any(ing.lower() in step_description.lower() for ing in liquid_ingredients)
    
    # If it's vegetables/salads, exclude
    veggie_keywords = ["lettuce", "salad", "tomato", "cucumber", "pepper", "onion"]
    has_veggies = any(veg in step_description.lower() for veg in veggie_keywords)
    
    return (has_liquid_keyword or has_liquid_ingredients) and not has_veggies
```

### 4. COOKING - Toutes les étapes de cuisson

**Principe:**
- ✅ Inclure TOUTES les étapes de la recette
- ❌ EXCLURE les étapes déjà dans "Mise en Place"

**Étapes à exclure de Cooking (car déjà faites):**
- Chopping (déjà dans Mise en Place → Chop)
- Peeling (déjà dans Mise en Place → Peel)
- Mixing sauces (déjà dans Mise en Place → Mix)
- Measuring (si présent dans Mise en Place)

**Simplification des références:**
Si une sauce a été préparée dans Mix, l'étape de cooking doit juste dire:
- ✅ "Ajouter la sauce" ou "Add the sauce"
- ❌ PAS "Mix soy sauce, honey, water and add to chicken" (redondant)

**Exemple de transformation:**

**Recette originale:**
1. Chop onions
2. Peel shrimp
3. Mix soy sauce, honey, water
4. Heat oil in pan
5. Sauté onions
6. Add shrimp
7. Pour sauce over shrimp

**Après optimisation:**

**Mise en Place → Chop:**
- Onions — 2 medium, chopped

**Mise en Place → Peel:**
- Shrimp — 500g, peeled and deveined

**Mise en Place → Mix (Sauce):**
- Soy sauce — 30ml
- Honey — 15ml
- Water — 60ml
- (Action: Mix together for glaze)

**Cooking:**
1. Chauffer l'huile dans la poêle
2. Faire revenir les oignons (5 min)
3. Ajouter les crevettes (3 min)
4. Ajouter la sauce (2 min)
5. Laisser mijoter

### 5. COOKING - Interface UI

**Changements à appliquer côté frontend:**

**Checkbox position:**
- ✅ À DROITE (comme dans Mise en Place)
- ❌ PAS à gauche

**Tag "While" (Parallel):**
- ❌ SUPPRIMER complètement
- Le backend ne doit plus générer `isParallel: true`
- OU le frontend doit l'ignorer

**Code à modifier dans MealPrepDetailView.swift:**
```swift
// Dans cookingStepCard():
// AVANT:
if step.isParallel, let note = step.parallelNote {
    // ... affichage du tag orange
}

// APRÈS:
// Supprimer complètement ce bloc
```

### 6. Backend - Prompt Changes

**Nouveau prompt pour la génération:**

```
MISE EN PLACE RULES:

1. CHOP Section:
   - Include ALL ingredients that need cutting (chopping, slicing, dicing, mincing)
   - Include grated items (cheese, vegetables)
   - Order: Vegetables/Fruits first, then Proteins (meats/fish), then Cheese/Dairy
   - Consolidate identical ingredients across recipes

2. PEEL Section:
   - Only for items that need skin/shell removal
   - Examples: shrimp (shell), salmon (skin), potatoes, carrots
   - Do NOT include garlic or onions here (they go in CHOP)

3. MIX Section - LIQUIDS ONLY:
   - Only for liquid sauces, marinades, dressings, glazes
   - Must contain primarily liquid ingredients (oil, soy sauce, vinegar, honey, water, juice)
   - DO NOT include vegetable salads or stir-fry mixes
   - Examples: vinaigrette, marinade, sauce glaze
   - Counter-examples: "mix lettuce and tomatoes" → goes to ASSEMBLE, NOT here

4. Other prep sections:
   - MEASURE: dry ingredients, spices (if not already in other sections)
   - MARINATE: non-liquid marinades or when proteins soak in prepared sauce
   - PREP_SAUCES: complex sauces requiring cooking (not just mixing)

COOKING PHASE RULES:

1. Exclude steps already done in Mise en Place:
   - No chopping
   - No peeling  
   - No mixing of sauces/dressings

2. Reference prepared items:
   - If sauce was mixed in Mise en Place, say "Add the sauce" not "Mix X, Y, Z and add"
   - If vegetables were chopped, say "Add the onions" not "Chop and add onions"

3. Do NOT generate parallel/while tags:
   - Set isParallel: false for all steps
   - Remove parallelNote completely

4. Focus on actual cooking actions:
   - Heat, sauté, boil, simmer, bake, roast, grill
   - Add prepared ingredients
   - Season and adjust
   - Cook until done
```

## 📝 Action Items

### Backend (Python/FastAPI)
1. [ ] Modifier la logique de détection d'action dans `meal_prep_optimizer.py`
2. [ ] Fusionner Grate → Chop avec tri par catégorie
3. [ ] Ajouter validation stricte pour Mix (liquides seulement)
4. [ ] Filtrer les étapes redondantes dans Cooking
5. [ ] Simplifier les références aux items préparés
6. [ ] Désactiver `isParallel` et `parallelNote`

### Frontend (Swift/iOS)
1. [x] Checkbox à droite dans Mise en Place ✅
2. [ ] Checkbox à droite dans Cooking
3. [ ] Supprimer affichage du tag "While/Parallel"
4. [ ] Tester avec données backend mises à jour

### Test Cases
1. [ ] Recette avec sauce liquide → doit aller dans Mix
2. [ ] Recette avec salade → "mix vegetables" ne doit PAS aller dans Mix
3. [ ] Fromage râpé → doit aller dans Chop (pas Grate)
4. [ ] Crevettes → section Peel dédiée
5. [ ] Cooking steps → pas de duplication avec Mise en Place
6. [ ] Cooking → checkbox à droite, pas de tag "while"
