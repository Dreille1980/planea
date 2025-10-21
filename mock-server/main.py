from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Literal, Optional
from datetime import date
import os
from dotenv import load_dotenv
from openai import AsyncOpenAI
import json
import asyncio
import random
from flyer_scraper import FlyerScraperService

# Load environment variables
load_dotenv()

app = FastAPI(title="Planea AI Server", version="1.0.0")
# Configuration CORS pour permettre les requêtes depuis l'app iOS
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, vous pourriez restreindre ceci
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Initialize OpenAI client (async for parallel processing)
client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Initialize flyer scraper service
flyer_scraper = FlyerScraperService()

MealType = Literal["BREAKFAST", "LUNCH", "DINNER"]
Weekday = Literal["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

class Slot(BaseModel):
    weekday: Weekday
    meal_type: MealType

class PlanRequest(BaseModel):
    week_start: date
    units: Literal["METRIC", "IMPERIAL"]
    slots: List[Slot]
    constraints: dict = Field(default_factory=dict)
    language: str = "fr"
    preferences: dict = Field(default_factory=dict)

class Ingredient(BaseModel):
    name: str
    quantity: float
    unit: str
    category: str
    is_on_sale: bool = False

class Recipe(BaseModel):
    title: str
    servings: int
    total_minutes: int
    ingredients: List[Ingredient]
    steps: List[str]
    equipment: List[str] = []
    tags: List[str] = []

class PlanItem(BaseModel):
    weekday: Weekday
    meal_type: MealType
    recipe: Recipe

class PlanResponse(BaseModel):
    items: List[PlanItem]

class RecipeRequest(BaseModel):
    idea: str
    constraints: dict = Field(default_factory=dict)
    servings: int = 4
    units: Literal["METRIC", "IMPERIAL"] = "METRIC"
    language: str = "fr"
    preferences: dict = Field(default_factory=dict)


async def mark_ingredients_on_sale(recipe: Recipe, preferences: dict) -> Recipe:
    """Mark ingredients that are on sale based on weekly flyers."""
    
    # Check if flyer deals feature is enabled
    if not preferences or not preferences.get("useFlyerDeals"):
        return recipe
    
    # Get postal code and store
    postal_code = preferences.get("postalCode")
    store_name = preferences.get("preferredStore")
    
    if not postal_code or not store_name:
        print("Flyer deals requested but postal code or store not provided")
        return recipe
    
    try:
        # Fetch weekly deals
        print(f"Fetching deals for {store_name} at {postal_code}...")
        deals = await asyncio.to_thread(
            flyer_scraper.get_weekly_deals,
            store_name=store_name,
            postal_code=postal_code
        )
        
        if not deals:
            print(f"No deals found for {store_name}")
            return recipe
        
        print(f"Found {len(deals)} deals")
        
        # Normalize deals for comparison (lowercase, remove accents, etc.)
        normalized_deals = set()
        for deal in deals:
            # Simple normalization: lowercase and strip
            normalized = deal.lower().strip()
            normalized_deals.add(normalized)
            # Also add individual words for partial matching
            for word in normalized.split():
                if len(word) > 3:  # Only words longer than 3 chars
                    normalized_deals.add(word)
        
        # Mark ingredients that are on sale
        for ingredient in recipe.ingredients:
            ing_name = ingredient.name.lower().strip()
            
            # Check for exact or partial match
            is_on_sale = False
            
            # Check exact match
            if ing_name in normalized_deals:
                is_on_sale = True
            else:
                # Check if any deal word is in ingredient name or vice versa
                ing_words = set(ing_name.split())
                for ing_word in ing_words:
                    if len(ing_word) > 3 and ing_word in normalized_deals:
                        is_on_sale = True
                        break
            
            if is_on_sale:
                ingredient.is_on_sale = True
                print(f"  ✓ Marked '{ingredient.name}' as ON SALE")
        
        return recipe
        
    except Exception as e:
        print(f"Error fetching flyer deals: {e}")
        # Return recipe unchanged if there's an error
        return recipe


def distribute_proteins_for_plan(slots: List[Slot], preferences: dict) -> List[str]:
    """
    Distribute proteins across the meal plan to ensure diversity.
    Returns a list of suggested proteins, one for each slot.
    """
    # Default protein list with good variety
    default_proteins = ["chicken", "beef", "pork", "fish", "salmon", "shrimp", "tofu", "turkey", "lamb"]
    
    # Get user's preferred proteins if available
    preferred_proteins = preferences.get("preferredProteins", [])
    
    # Use preferred proteins if available, otherwise use defaults
    protein_pool = preferred_proteins if preferred_proteins else default_proteins
    
    # Ensure we have enough variety
    if len(protein_pool) < 3:
        # If user only selected 1-2 proteins, add some defaults for variety
        protein_pool = list(set(protein_pool + default_proteins[:5]))
    
    num_slots = len(slots)
    suggested_proteins = []
    
    # Shuffle the protein pool for randomness
    shuffled_proteins = protein_pool.copy()
    random.shuffle(shuffled_proteins)
    
    # Distribute proteins ensuring no immediate repeats
    for i in range(num_slots):
        # Special handling for breakfast - prefer lighter proteins
        if slots[i].meal_type == "BREAKFAST":
            breakfast_options = ["eggs", "turkey", "salmon", "tofu", "yogurt"]
            # Filter to breakfast options that haven't been used recently
            available = [p for p in breakfast_options if p not in suggested_proteins[-2:]]
            if not available:
                available = breakfast_options
            suggested_proteins.append(random.choice(available))
        else:
            # For lunch and dinner, cycle through the protein pool
            # Avoid repeating the last protein
            cycle_index = i % len(shuffled_proteins)
            protein = shuffled_proteins[cycle_index]
            
            # If this protein was just used, try the next one
            if suggested_proteins and protein == suggested_proteins[-1]:
                cycle_index = (cycle_index + 1) % len(shuffled_proteins)
                protein = shuffled_proteins[cycle_index]
            
            suggested_proteins.append(protein)
    
    print(f"🎯 Protein distribution for {num_slots} slots: {suggested_proteins}")
    return suggested_proteins


async def generate_recipe_with_openai(
    meal_type: str, 
    constraints: dict, 
    units: str, 
    servings: int = 4, 
    previous_recipes: List[str] = None, 
    diversity_seed: int = 0, 
    language: str = "fr", 
    preferences: dict = None,
    suggested_protein: str = None,
    other_plan_proteins: List[str] = None
) -> Recipe:
    """Generate a single recipe using OpenAI with diversity awareness (async)."""
    
    # Build constraints text
    constraints_text = ""
    if constraints.get("diet"):
        diets = ", ".join(constraints["diet"])
        constraints_text += f"Régimes alimentaires: {diets}. "
    if constraints.get("evict"):
        allergies = ", ".join(constraints["evict"])
        constraints_text += f"Allergies/Éviter: {allergies}. "
    
    # Build preferences text from preferences dict
    preferences_text = ""
    if preferences:
        # Time constraints based on meal day
        if preferences.get("weekdayMaxMinutes") is not None or preferences.get("weekendMaxMinutes") is not None:
            weekday_max = preferences.get("weekdayMaxMinutes", 30)
            weekend_max = preferences.get("weekendMaxMinutes", 60)
            preferences_text += f"TIMING CONSTRAINT: Weekday recipes must take NO MORE than {weekday_max} minutes. Weekend recipes can take up to {weekend_max} minutes. "
        
        # Complexity based on time
        max_time = preferences.get("maxMinutes", 30)  # For ad-hoc recipes
        if max_time <= 30:
            preferences_text += "COMPLEXITY: Keep the recipe simple with basic cooking techniques. "
        elif max_time <= 60:
            preferences_text += "COMPLEXITY: Use intermediate cooking techniques and interesting flavor combinations. "
        else:
            preferences_text += "COMPLEXITY: Use advanced culinary techniques, complex flavor profiles, and sophisticated presentations. "
        
        # Spice level
        if preferences.get("spiceLevel") and preferences["spiceLevel"] != "none":
            preferences_text += f"Spice level: {preferences['spiceLevel']}. "
        
        # Preferred proteins
        if preferences.get("preferredProteins"):
            proteins = ", ".join(preferences["preferredProteins"])
            preferences_text += f"Preferred proteins: {proteins}. "
        
        # Available appliances
        if preferences.get("availableAppliances"):
            appliances = ", ".join(preferences["availableAppliances"])
            preferences_text += f"Available cooking equipment: {appliances}. "
        
        # Kid-friendly
        if preferences.get("kidFriendly"):
            preferences_text += "Kid-friendly meals preferred. "
    
    # Build protein portions guide
    protein_portions_text = "\n\nCRITICAL - PROTEIN PORTIONS PER PERSON:\n"
    protein_portions_text += "You MUST include adequate protein in each recipe following these guidelines:\n"
    protein_portions_text += "- Chicken (breast, thigh): 150-200g per person (250-300g if bone-in)\n"
    protein_portions_text += "- Beef (steak, roast): 180-220g per person\n"
    protein_portions_text += "- Pork (chops, tenderloin): 160-200g per person\n"
    protein_portions_text += "- Lamb: 180-200g per person\n"
    protein_portions_text += "- Fish (fillet): 150-180g per person (300-350g if whole fish)\n"
    protein_portions_text += "- Shrimp/Prawns: 120-150g per person\n"
    protein_portions_text += "- Tofu: 120-150g per person\n"
    protein_portions_text += "- Tempeh/Seitan: 100-130g per person\n"
    protein_portions_text += "- Eggs: 2-3 large eggs per person\n"
    protein_portions_text += "- Ground meat (beef, pork, chicken): 150-180g per person\n"
    protein_portions_text += "These portions ensure adequate protein intake for a satisfying meal.\n"
    
    # Build diversity instructions with protein guidance
    diversity_text = "\n\nIMPÉRATIF - DIVERSITÉ MAXIMALE:\n"
    if suggested_protein and other_plan_proteins:
        diversity_text += f"- PROTÉINE SUGGÉRÉE pour cette recette: {suggested_protein}\n"
        diversity_text += f"- INTERDICTION d'utiliser ces protéines (déjà dans le plan): {', '.join(other_plan_proteins)}\n"
        diversity_text += f"- Tu DOIS utiliser {suggested_protein} ou une alternative DIFFÉRENTE des protéines interdites\n"
    diversity_text += "- Crée une recette TOTALEMENT UNIQUE et DIFFÉRENTE\n"
    diversity_text += "- Varie librement: cuisines du monde, légumes, épices, techniques\n"
    diversity_text += "- Explore des combinaisons créatives et inattendues\n"
    diversity_text += "- Chaque recette doit être distincte des autres\n"
    diversity_text += "- Utilise la créativité maximale sans limitations\n"
    
    unit_system = "métrique (grammes, ml)" if units == "METRIC" else "impérial (oz, cups)"
    
    meal_type_fr = {
        "BREAKFAST": "petit-déjeuner",
        "LUNCH": "lunch",
        "DINNER": "souper"
    }.get(meal_type, "repas")
    
    # Language-specific prompts
    if language == "en":
        meal_type_name = {
            "BREAKFAST": "breakfast",
            "LUNCH": "lunch",
            "DINNER": "dinner"
        }.get(meal_type, "meal")
        
        constraints_text_en = ""
        if constraints.get("diet"):
            diets = ", ".join(constraints["diet"])
            constraints_text_en += f"Dietary requirements: {diets}. "
        if constraints.get("evict"):
            allergies = ", ".join(constraints["evict"])
            constraints_text_en += f"Allergies/Avoid: {allergies}. "
        
        protein_portions_text_en = "\n\nCRITICAL - PROTEIN PORTIONS PER PERSON:\n"
        protein_portions_text_en += "You MUST include adequate protein in each recipe following these guidelines:\n"
        protein_portions_text_en += "- Chicken (breast, thigh): 150-200g per person (250-300g if bone-in)\n"
        protein_portions_text_en += "- Beef (steak, roast): 180-220g per person\n"
        protein_portions_text_en += "- Pork (chops, tenderloin): 160-200g per person\n"
        protein_portions_text_en += "- Lamb: 180-200g per person\n"
        protein_portions_text_en += "- Fish (fillet): 150-180g per person (300-350g if whole fish)\n"
        protein_portions_text_en += "- Shrimp/Prawns: 120-150g per person\n"
        protein_portions_text_en += "- Tofu: 120-150g per person\n"
        protein_portions_text_en += "- Tempeh/Seitan: 100-130g per person\n"
        protein_portions_text_en += "- Eggs: 2-3 large eggs per person\n"
        protein_portions_text_en += "- Ground meat (beef, pork, chicken): 150-180g per person\n"
        protein_portions_text_en += "These portions ensure adequate protein intake for a satisfying meal.\n"
        
        diversity_text_en = "\n\nCRITICAL - MAXIMUM DIVERSITY:\n"
        if suggested_protein and other_plan_proteins:
            diversity_text_en += f"- SUGGESTED PROTEIN for this recipe: {suggested_protein}\n"
            diversity_text_en += f"- FORBIDDEN to use these proteins (already in plan): {', '.join(other_plan_proteins)}\n"
            diversity_text_en += f"- You MUST use {suggested_protein} or a DIFFERENT alternative from the forbidden proteins\n"
        diversity_text_en += "- Create a COMPLETELY UNIQUE and DIFFERENT recipe\n"
        diversity_text_en += "- Freely vary: world cuisines, vegetables, spices, techniques\n"
        diversity_text_en += "- Explore creative and unexpected combinations\n"
        diversity_text_en += "- Each recipe must be distinct from others\n"
        diversity_text_en += "- Use maximum creativity without limitations\n"
        
        unit_system_text = "metric (grams, ml)" if units == "METRIC" else "imperial (oz, cups)"
        
        prompt = f"""Generate a {meal_type_name} recipe in English for {servings} people.

{constraints_text_en}{preferences_text}{protein_portions_text_en}{diversity_text_en}

CRITICAL - PREPARATION STEPS: The recipe MUST start with detailed preparation steps:
- First steps should describe ALL ingredient preparations (cutting, dicing, chopping, grating, etc.)
- Be specific about cuts: "dice carrots into 1cm cubes", "grate 100g cheese", "finely chop 2 onions"
- Include prep for ALL ingredients before cooking steps
- Then include cooking/assembly steps with exact times, temperatures, and techniques

Return ONLY a valid JSON object with this exact structure (no text before or after):
{{
    "title": "Creative and appetizing recipe name",
    "servings": {servings},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingredient", "quantity": 200, "unit": "g", "category": "vegetables"}}
    ],
    "steps": [
        "Preparation: Dice the carrots into 1cm cubes. Finely chop the onion. Grate the cheese.",
        "Preparation: Cut the chicken into bite-sized pieces and season with salt and pepper.",
        "Heat oil in a large pan over medium-high heat...",
        "Add the diced carrots and cook for 5 minutes...",
        "Finish with grated cheese and serve..."
    ],
    "equipment": ["pan", "pot"],
    "tags": ["easy", "quick"]
}}

Use the {unit_system_text} system.
Possible ingredient categories: vegetables, fruits, meats, fish, dairy, dry goods, condiments, canned goods.

IMPORTANT: Generate at least 6-8 detailed steps with EXPLICIT preparation steps at the beginning."""

    else:
        prompt = f"""Génère une recette de {meal_type_fr} en français pour {servings} personnes.

{constraints_text}{preferences_text}{protein_portions_text}{diversity_text}

CRITIQUE - ÉTAPES DE PRÉPARATION: La recette DOIT commencer par des étapes de préparation détaillées:
- Les premières étapes doivent décrire TOUTES les préparations d'ingrédients (couper, émincer, hacher, râper, etc.)
- Sois précis sur les coupes: "couper les carottes en dés de 1cm", "râper 100g de fromage", "émincer finement 2 oignons"
- Inclure la préparation de TOUS les ingrédients avant les étapes de cuisson
- Ensuite inclure les étapes de cuisson/assemblage avec temps exacts, températures et techniques

Retourne UNIQUEMENT un objet JSON valide avec cette structure exacte (sans texte avant ou après):
{{
    "title": "Nom créatif et appétissant de la recette",
    "servings": {servings},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingrédient", "quantity": 200, "unit": "g", "category": "légumes"}}
    ],
    "steps": [
        "Préparation: Couper les carottes en dés de 1cm. Émincer finement l'oignon. Râper le fromage.",
        "Préparation: Couper le poulet en morceaux et assaisonner de sel et poivre.",
        "Faire chauffer l'huile dans une grande poêle à feu moyen-vif...",
        "Ajouter les carottes en dés et cuire 5 minutes...",
        "Terminer avec le fromage râpé et servir..."
    ],
    "equipment": ["poêle", "casserole"],
    "tags": ["facile", "rapide"]
}}

Utilise le système {unit_system}.
Catégories d'ingrédients possibles: légumes, fruits, viandes, poissons, produits laitiers, sec, condiments, conserves.

IMPORTANT: Génère au moins 6-8 étapes détaillées avec des étapes de préparation EXPLICITES au début."""

    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "Tu es un chef cuisinier créatif et expert qui génère des recettes uniques et détaillées en JSON. Tu varies toujours les ingrédients, cuisines et techniques."},
                {"role": "user", "content": prompt}
            ],
            temperature=1.0,  # Maximum creativity and diversity
            max_tokens=1200  # Increased for detailed steps
        )
        
        content = response.choices[0].message.content.strip()
        
        # Remove markdown code blocks if present
        if content.startswith("```"):
            content = content.split("```")[1]
            if content.startswith("json"):
                content = content[4:]
            content = content.strip()
        
        recipe_data = json.loads(content)
        
        # Ensure all ingredients have required fields
        for ingredient in recipe_data.get("ingredients", []):
            if "unit" not in ingredient or not ingredient.get("unit"):
                ingredient["unit"] = "unité"
            if "category" not in ingredient or not ingredient.get("category"):
                ingredient["category"] = "autre"
        
        return Recipe(**recipe_data)
        
    except Exception as e:
        print(f"Error generating recipe with OpenAI: {e}")
        # Fallback to a simple recipe
        return Recipe(
            title=f"Recette simple de {meal_type_fr}",
            servings=servings,
            total_minutes=30,
            ingredients=[
                Ingredient(name="ingrédient principal", quantity=500, unit="g" if units == "METRIC" else "oz", category="sec")
            ],
            steps=["Préparer les ingrédients", "Cuire selon les instructions"],
            equipment=["poêle"],
            tags=["simple"]
        )


@app.post("/ai/plan", response_model=PlanResponse)
async def ai_plan(req: PlanRequest):
    """Generate a meal plan using OpenAI with parallel generation and diversity seeds."""
    
    # Distribute proteins across the plan for variety
    suggested_proteins = distribute_proteins_for_plan(req.slots, req.preferences)
    
    # Generate all recipes in parallel with diversity seeds and protein guidance
    tasks = [
        generate_recipe_with_openai(
            meal_type=slot.meal_type,
            constraints=req.constraints,
            units=req.units,
            servings=4,
            previous_recipes=None,
            diversity_seed=idx,  # Each recipe gets a different seed for variety
            language=req.language,
            preferences=req.preferences,
            suggested_protein=suggested_proteins[idx],
            other_plan_proteins=[p for i, p in enumerate(suggested_proteins) if i != idx]
        )
        for idx, slot in enumerate(req.slots)
    ]
    
    # Execute all API calls in parallel
    recipes = await asyncio.gather(*tasks)
    
    # Mark ingredients on sale if feature is enabled
    for recipe in recipes:
        await mark_ingredients_on_sale(recipe, req.preferences)
    
    # Build response
    items = [
        PlanItem(
            weekday=slot.weekday,
            meal_type=slot.meal_type,
            recipe=recipe
        )
        for slot, recipe in zip(req.slots, recipes)
    ]
    
    # Log ingredient categories for debugging
    print("\n=== SHOPPING LIST DEBUG - Ingredient Categories ===")
    for item in items:
        print(f"\nRecipe: {item.recipe.title}")
        for ing in item.recipe.ingredients:
            print(f"  - {ing.name}: category='{ing.category}'")
    print("=== END SHOPPING LIST DEBUG ===\n")
    
    return PlanResponse(items=items)


class RegenerateMealRequest(BaseModel):
    weekday: Weekday
    meal_type: MealType
    constraints: dict = Field(default_factory=dict)
    servings: int = 4
    units: Literal["METRIC", "IMPERIAL"] = "METRIC"
    language: str = "fr"
    diversity_seed: int = 0
    preferences: dict = Field(default_factory=dict)


@app.post("/ai/regenerate-meal", response_model=Recipe)
async def regenerate_meal(req: RegenerateMealRequest):
    """Regenerate a single meal with diversity."""
    recipe = await generate_recipe_with_openai(
        meal_type=req.meal_type,
        constraints=req.constraints,
        units=req.units,
        servings=req.servings,
        previous_recipes=None,
        diversity_seed=req.diversity_seed,
        language=req.language,
        preferences=req.preferences
    )
    
    # Mark ingredients on sale if feature is enabled
    await mark_ingredients_on_sale(recipe, req.preferences)
    
    return recipe


@app.post("/ai/recipe", response_model=Recipe)
async def ai_recipe(req: RecipeRequest):
    """Generate a single recipe from a prompt using OpenAI (async)."""
    
    # Select a random protein for variety in ad-hoc generation
    # Use user preferences if available, otherwise use default variety
    default_proteins = ["beef", "pork", "fish", "salmon", "shrimp", "tofu", "turkey", "lamb", "duck"]
    
    preferred_proteins = []
    if req.preferences and req.preferences.get("preferredProteins"):
        preferred_proteins = req.preferences.get("preferredProteins", [])
    
    # Use preferred or default proteins
    protein_pool = preferred_proteins if preferred_proteins else default_proteins
    suggested_protein = random.choice(protein_pool)
    print(f"🎲 Random protein selected for ad-hoc recipe: {suggested_protein}")
    
    # Build preferences text from preferences dict
    preferences_text = ""
    if req.preferences:
        # Complexity based on time
        max_time = req.preferences.get("maxMinutes", 30)
        if max_time <= 30:
            preferences_text += "COMPLEXITY: Keep the recipe simple with basic cooking techniques. "
        elif max_time <= 60:
            preferences_text += "COMPLEXITY: Use intermediate cooking techniques and interesting flavor combinations. "
        else:
            preferences_text += "COMPLEXITY: Use advanced culinary techniques, complex flavor profiles, and sophisticated presentations. "
        
        # Spice level
        if req.preferences.get("spiceLevel") and req.preferences["spiceLevel"] != "none":
            preferences_text += f"Spice level: {req.preferences['spiceLevel']}. "
        
        # Available appliances
        if req.preferences.get("availableAppliances"):
            appliances = ", ".join(req.preferences["availableAppliances"])
            preferences_text += f"Available cooking equipment: {appliances}. "
        
        # Kid-friendly
        if req.preferences.get("kidFriendly"):
            preferences_text += "Kid-friendly meals preferred. "
    
    # Build protein portions guide
    protein_portions_text = "\n\nCRITICAL - PROTEIN PORTIONS PER PERSON:\n"
    protein_portions_text += "You MUST include adequate protein in each recipe following these guidelines:\n"
    protein_portions_text += "- Chicken (breast, thigh): 150-200g per person (250-300g if bone-in)\n"
    protein_portions_text += "- Beef (steak, roast): 180-220g per person\n"
    protein_portions_text += "- Pork (chops, tenderloin): 160-200g per person\n"
    protein_portions_text += "- Lamb: 180-200g per person\n"
    protein_portions_text += "- Fish (fillet): 150-180g per person (300-350g if whole fish)\n"
    protein_portions_text += "- Shrimp/Prawns: 120-150g per person\n"
    protein_portions_text += "- Tofu: 120-150g per person\n"
    protein_portions_text += "- Tempeh/Seitan: 100-130g per person\n"
    protein_portions_text += "- Eggs: 2-3 large eggs per person\n"
    protein_portions_text += "- Ground meat (beef, pork, chicken): 150-180g per person\n"
    protein_portions_text += "These portions ensure adequate protein intake for a satisfying meal.\n"
    
    # Language-specific handling
    if req.language == "en":
        constraints_text = ""
        if req.constraints.get("diet"):
            diets = ", ".join(req.constraints["diet"])
            constraints_text += f"Dietary requirements: {diets}. "
        if req.constraints.get("evict"):
            allergies = ", ".join(req.constraints["evict"])
            constraints_text += f"Allergies/Avoid: {allergies}. "
        
        unit_system = "metric (grams, ml)" if req.units == "METRIC" else "imperial (oz, cups)"
        
        # Add protein suggestion for variety
        protein_suggestion = ""
        if suggested_protein:
            protein_suggestion = f"\nSUGGESTED PROTEIN: Use {suggested_protein} as the main protein for variety.\n"
        
        prompt = f"""Generate a recipe in English based on this idea: "{req.idea}"
        
For {req.servings} people.
{constraints_text}{protein_suggestion}

CRITICAL - PREPARATION STEPS: The recipe MUST start with detailed preparation steps:
- First steps should describe ALL ingredient preparations (cutting, dicing, chopping, grating, etc.)
- Be specific about cuts: "dice carrots into 1cm cubes", "grate 100g cheese", "finely chop 2 onions"
- Include prep for ALL ingredients before cooking steps
- Then include cooking/assembly steps with exact times, temperatures, and techniques

Return ONLY a valid JSON object with this exact structure:
{{
    "title": "Recipe name",
    "servings": {req.servings},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingredient", "quantity": 200, "unit": "g", "category": "vegetables"}}
    ],
    "steps": [
        "Preparation: Dice the carrots into 1cm cubes. Finely chop the onion...",
        "Heat oil in a large pan...",
        "Add ingredients and cook..."
    ],
    "equipment": ["pan", "pot"],
    "tags": ["easy"]
}}

Use the {unit_system} system.
Categories: vegetables, fruits, meats, fish, dairy, dry goods, condiments, canned goods.

IMPORTANT: Generate at least 5-7 detailed steps with EXPLICIT preparation steps at the beginning."""
        
        system_prompt = "You are a creative and expert chef who generates unique and detailed recipes in JSON."
        
    else:
        # French version
        constraints_text = ""
        if req.constraints.get("diet"):
            diets = ", ".join(req.constraints["diet"])
            constraints_text += f"Régimes alimentaires: {diets}. "
        if req.constraints.get("evict"):
            allergies = ", ".join(req.constraints["evict"])
            constraints_text += f"Allergies/Éviter: {allergies}. "
        
        unit_system = "métrique (grammes, ml)" if req.units == "METRIC" else "impérial (oz, cups)"
        
        # Add protein suggestion for variety
        protein_suggestion = ""
        if suggested_protein:
            protein_suggestion = f"\nPROTÉINE SUGGÉRÉE: Utilise {suggested_protein} comme protéine principale pour la variété.\n"
        
        prompt = f"""Génère une recette en français basée sur cette idée: "{req.idea}"

Pour {req.servings} personnes.
{constraints_text}{preferences_text}{protein_suggestion}{protein_portions_text}

CRITIQUE - ÉTAPES DE PRÉPARATION: La recette DOIT commencer par des étapes de préparation détaillées:
- Les premières étapes doivent décrire TOUTES les préparations d'ingrédients (couper, émincer, hacher, râper, etc.)
- Sois précis sur les coupes: "couper les carottes en dés de 1cm", "râper 100g de fromage", "émincer finement 2 oignons"
- Inclure la préparation de TOUS les ingrédients avant les étapes de cuisson
- Ensuite inclure les étapes de cuisson/assemblage avec temps exacts, températures et techniques

Retourne UNIQUEMENT un objet JSON valide avec cette structure exacte:
{{
    "title": "Nom de la recette",
    "servings": {req.servings},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingrédient", "quantity": 200, "unit": "g", "category": "légumes"}}
    ],
    "steps": [
        "Préparation: Couper les carottes en dés de 1cm. Émincer finement l'oignon...",
        "Faire chauffer l'huile dans une grande poêle...",
        "Ajouter les ingrédients et cuire..."
    ],
    "equipment": ["poêle", "casserole"],
    "tags": ["facile"]
}}

Utilise le système {unit_system}.
Catégories: légumes, fruits, viandes, poissons, produits laitiers, sec, condiments, conserves.

IMPORTANT: Génère au moins 5-7 étapes détaillées avec des étapes de préparation EXPLICITES au début."""

    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "Tu es un chef cuisinier créatif et expert qui génère des recettes uniques et détaillées en JSON."},
                {"role": "user", "content": prompt}
            ],
            temperature=1.0,  # Maximum creativity and diversity
            max_tokens=1200  # Increased for detailed steps
        )
        
        content = response.choices[0].message.content.strip()
        
        # Remove markdown code blocks if present
        if content.startswith("```"):
            content = content.split("```")[1]
            if content.startswith("json"):
                content = content[4:]
            content = content.strip()
        
        recipe_data = json.loads(content)
        return Recipe(**recipe_data)
        
    except Exception as e:
        print(f"Error generating recipe: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate recipe: {str(e)}")


class RecipeFromTitleRequest(BaseModel):
    title: str
    servings: int = 4
    constraints: dict = Field(default_factory=dict)
    units: Literal["METRIC", "IMPERIAL"] = "METRIC"
    language: str = "fr"
    preferences: dict = Field(default_factory=dict)


@app.post("/ai/recipe-from-title", response_model=Recipe)
async def ai_recipe_from_title(req: RecipeFromTitleRequest):
    """Generate a complete recipe from just a title using OpenAI."""
    
    # Build preferences text from preferences dict
    preferences_text = ""
    if req.preferences:
        # Complexity based on time
        max_time = req.preferences.get("maxMinutes", 30)
        if max_time <= 30:
            preferences_text += "COMPLEXITY: Keep the recipe simple with basic cooking techniques. "
        elif max_time <= 60:
            preferences_text += "COMPLEXITY: Use intermediate cooking techniques and interesting flavor combinations. "
        else:
            preferences_text += "COMPLEXITY: Use advanced culinary techniques, complex flavor profiles, and sophisticated presentations. "
        
        # Spice level
        if req.preferences.get("spiceLevel") and req.preferences["spiceLevel"] != "none":
            preferences_text += f"Spice level: {req.preferences['spiceLevel']}. "
        
        # Preferred proteins
        if req.preferences.get("preferredProteins"):
            proteins = ", ".join(req.preferences["preferredProteins"])
            preferences_text += f"Preferred proteins: {proteins}. "
        
        # Available appliances
        if req.preferences.get("availableAppliances"):
            appliances = ", ".join(req.preferences["availableAppliances"])
            preferences_text += f"Available cooking equipment: {appliances}. "
        
        # Kid-friendly
        if req.preferences.get("kidFriendly"):
            preferences_text += "Kid-friendly meals preferred. "
    
    # Build protein portions guide
    protein_portions_text = "\n\nCRITICAL - PROTEIN PORTIONS PER PERSON:\n"
    protein_portions_text += "You MUST include adequate protein in each recipe following these guidelines:\n"
    protein_portions_text += "- Chicken (breast, thigh): 150-200g per person (250-300g if bone-in)\n"
    protein_portions_text += "- Beef (steak, roast): 180-220g per person\n"
    protein_portions_text += "- Pork (chops, tenderloin): 160-200g per person\n"
    protein_portions_text += "- Lamb: 180-200g per person\n"
    protein_portions_text += "- Fish (fillet): 150-180g per person (300-350g if whole fish)\n"
    protein_portions_text += "- Shrimp/Prawns: 120-150g per person\n"
    protein_portions_text += "- Tofu: 120-150g per person\n"
    protein_portions_text += "- Tempeh/Seitan: 100-130g per person\n"
    protein_portions_text += "- Eggs: 2-3 large eggs per person\n"
    protein_portions_text += "- Ground meat (beef, pork, chicken): 150-180g per person\n"
    protein_portions_text += "These portions ensure adequate protein intake for a satisfying meal.\n"
    
    # Language-specific handling
    if req.language == "en":
        constraints_text = ""
        if req.constraints.get("diet"):
            diets = ", ".join(req.constraints["diet"])
            constraints_text += f"Dietary requirements: {diets}. "
        if req.constraints.get("evict"):
            allergies = ", ".join(req.constraints["evict"])
            constraints_text += f"Allergies/Avoid: {allergies}. "
        
        unit_system = "metric (grams, ml)" if req.units == "METRIC" else "imperial (oz, cups)"
        
        prompt = f"""Generate a complete recipe in English with this exact title: "{req.title}"

For {req.servings} people.
{constraints_text}{preferences_text}{protein_portions_text}

CRITICAL - PREPARATION STEPS: The recipe MUST start with detailed preparation steps:
- First steps should describe ALL ingredient preparations (cutting, dicing, chopping, grating, etc.)
- Be specific about cuts: "dice carrots into 1cm cubes", "grate 100g cheese", "finely chop 2 onions"
- Include prep for ALL ingredients before cooking steps
- Then include cooking/assembly steps with exact times, temperatures, and techniques

Return ONLY a valid JSON object with this exact structure:
{{
    "title": "{req.title}",
    "servings": {req.servings},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingredient", "quantity": 200, "unit": "g", "category": "vegetables"}}
    ],
    "steps": [
        "Preparation: Dice the carrots into 1cm cubes. Finely chop the onion...",
        "Heat oil in a large pan...",
        "Add ingredients and cook..."
    ],
    "equipment": ["pan", "pot"],
    "tags": ["easy"]
}}

Use the {unit_system} system.
Categories: vegetables, fruits, meats, fish, dairy, dry goods, condiments, canned goods.

IMPORTANT: 
- Use EXACTLY the title provided: "{req.title}"
- Generate at least 5-7 detailed steps with EXPLICIT preparation steps at the beginning
- Create realistic and appropriate ingredients for this dish"""
        
        system_prompt = "You are a creative and expert chef who generates unique and detailed recipes in JSON based on dish names."
        
    else:
        # French version
        constraints_text = ""
        if req.constraints.get("diet"):
            diets = ", ".join(req.constraints["diet"])
            constraints_text += f"Régimes alimentaires: {diets}. "
        if req.constraints.get("evict"):
            allergies = ", ".join(req.constraints["evict"])
            constraints_text += f"Allergies/Éviter: {allergies}. "
        
        unit_system = "métrique (grammes, ml)" if req.units == "METRIC" else "impérial (oz, cups)"
        
        prompt = f"""Génère une recette complète en français avec ce titre exact: "{req.title}"

Pour {req.servings} personnes.
{constraints_text}{preferences_text}{protein_portions_text}

CRITIQUE - ÉTAPES DE PRÉPARATION: La recette DOIT commencer par des étapes de préparation détaillées:
- Les premières étapes doivent décrire TOUTES les préparations d'ingrédients (couper, émincer, hacher, râper, etc.)
- Sois précis sur les coupes: "couper les carottes en dés de 1cm", "râper 100g de fromage", "émincer finement 2 oignons"
- Inclure la préparation de TOUS les ingrédients avant les étapes de cuisson
- Ensuite inclure les étapes de cuisson/assemblage avec temps exacts, températures et techniques

Retourne UNIQUEMENT un objet JSON valide avec cette structure exacte:
{{
    "title": "{req.title}",
    "servings": {req.servings},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingrédient", "quantity": 200, "unit": "g", "category": "légumes"}}
    ],
    "steps": [
        "Préparation: Couper les carottes en dés de 1cm. Émincer finement l'oignon...",
        "Faire chauffer l'huile dans une grande poêle...",
        "Ajouter les ingrédients et cuire..."
    ],
    "equipment": ["poêle", "casserole"],
    "tags": ["facile"]
}}

Utilise le système {unit_system}.
Catégories: légumes, fruits, viandes, poissons, produits laitiers, sec, condiments, conserves.

IMPORTANT: 
- Utilise EXACTEMENT le titre fourni: "{req.title}"
- Génère au moins 5-7 étapes détaillées avec des étapes de préparation EXPLICITES au début
- Crée des ingrédients réalistes et appropriés pour ce plat"""
        
        system_prompt = "Tu es un chef cuisinier créatif et expert qui génère des recettes uniques et détaillées en JSON à partir de noms de plats."

    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=1200
        )
        
        content = response.choices[0].message.content.strip()
        
        # Remove markdown code blocks if present
        if content.startswith("```"):
            content = content.split("```")[1]
            if content.startswith("json"):
                content = content[4:]
            content = content.strip()
        
        recipe_data = json.loads(content)
        
        # Ensure the title matches exactly what was requested
        recipe_data["title"] = req.title
        
        # Ensure all ingredients have required fields
        for ingredient in recipe_data.get("ingredients", []):
            if "unit" not in ingredient or not ingredient.get("unit"):
                ingredient["unit"] = "unité" if req.language == "fr" else "unit"
            if "category" not in ingredient or not ingredient.get("category"):
                ingredient["category"] = "autre" if req.language == "fr" else "other"
        
        return Recipe(**recipe_data)
        
    except Exception as e:
        print(f"Error generating recipe from title: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate recipe: {str(e)}")


class RecipeFromImageRequest(BaseModel):
    image_base64: str
    servings: int = 4
    constraints: dict = Field(default_factory=dict)
    units: Literal["METRIC", "IMPERIAL"] = "METRIC"
    language: str = "fr"
    preferences: dict = Field(default_factory=dict)


@app.post("/ai/recipe-from-image", response_model=Recipe)
async def ai_recipe_from_image(req: RecipeFromImageRequest):
    """Generate a recipe from a fridge photo using OpenAI Vision."""
    
    import base64
    
    # Build preferences text from preferences dict
    preferences_text = ""
    if req.preferences:
        # Complexity based on time
        max_time = req.preferences.get("maxMinutes", 30)
        if max_time <= 30:
            preferences_text += "COMPLEXITY: Keep the recipe simple with basic cooking techniques. "
        elif max_time <= 60:
            preferences_text += "COMPLEXITY: Use intermediate cooking techniques and interesting flavor combinations. "
        else:
            preferences_text += "COMPLEXITY: Use advanced culinary techniques, complex flavor profiles, and sophisticated presentations. "
        
        # Spice level
        if req.preferences.get("spiceLevel") and req.preferences["spiceLevel"] != "none":
            preferences_text += f"Spice level: {req.preferences['spiceLevel']}. "
        
        # Available appliances
        if req.preferences.get("availableAppliances"):
            appliances = ", ".join(req.preferences["availableAppliances"])
            preferences_text += f"Available cooking equipment: {appliances}. "
        
        # Kid-friendly
        if req.preferences.get("kidFriendly"):
            preferences_text += "Kid-friendly meals preferred. "
        
        # Extra user instructions
        if req.preferences.get("extra"):
            preferences_text += f"Additional instructions: {req.preferences['extra']}. "
    
    # Build protein portions guide
    protein_portions_text = "\n\nCRITICAL - PROTEIN PORTIONS PER PERSON:\n"
    protein_portions_text += "You MUST include adequate protein in each recipe following these guidelines:\n"
    protein_portions_text += "- Chicken (breast, thigh): 150-200g per person (250-300g if bone-in)\n"
    protein_portions_text += "- Beef (steak, roast): 180-220g per person\n"
    protein_portions_text += "- Pork (chops, tenderloin): 160-200g per person\n"
    protein_portions_text += "- Lamb: 180-200g per person\n"
    protein_portions_text += "- Fish (fillet): 150-180g per person (300-350g if whole fish)\n"
    protein_portions_text += "- Shrimp/Prawns: 120-150g per person\n"
    protein_portions_text += "- Tofu: 120-150g per person\n"
    protein_portions_text += "- Tempeh/Seitan: 100-130g per person\n"
    protein_portions_text += "- Eggs: 2-3 large eggs per person\n"
    protein_portions_text += "- Ground meat (beef, pork, chicken): 150-180g per person\n"
    protein_portions_text += "These portions ensure adequate protein intake for a satisfying meal.\n"
    
    # Language-specific handling
    if req.language == "en":
        constraints_text = ""
        if req.constraints.get("diet"):
            diets = ", ".join(req.constraints["diet"])
            constraints_text += f"Dietary requirements: {diets}. "
        if req.constraints.get("evict"):
            allergies = ", ".join(req.constraints["evict"])
            constraints_text += f"Allergies/Avoid: {allergies}. "
        
        unit_system = "metric (grams, ml)" if req.units == "METRIC" else "imperial (oz, cups)"
        
        text_prompt = f"""Analyze this fridge/pantry photo and generate a creative recipe using the visible ingredients.

For {req.servings} people.
{constraints_text}{preferences_text}{protein_portions_text}

CRITICAL - PREPARATION STEPS: The recipe MUST start with detailed preparation steps:
- First steps should describe ALL ingredient preparations (cutting, dicing, chopping, grating, etc.)
- Be specific about cuts: "dice carrots into 1cm cubes", "grate 100g cheese", "finely chop 2 onions"
- Include prep for ALL ingredients before cooking steps
- Then include cooking/assembly steps with exact times, temperatures, and techniques

Return ONLY a valid JSON object with this exact structure:
{{
    "title": "Creative recipe name based on ingredients",
    "servings": {req.servings},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingredient from photo", "quantity": 200, "unit": "g", "category": "vegetables"}}
    ],
    "steps": [
        "Preparation: Dice the carrots into 1cm cubes. Finely chop the onion...",
        "Heat oil in a large pan...",
        "Add ingredients and cook..."
    ],
    "equipment": ["pan", "pot"],
    "tags": ["fridge cleanup", "creative"]
}}

Use the {unit_system} system.
Categories: vegetables, fruits, meats, fish, dairy, dry goods, condiments, canned goods.

IMPORTANT:
- Generate at least 5-7 detailed steps with EXPLICIT preparation steps at the beginning
- Use ingredients visible in the photo
- Be creative with the recipe name
- Ensure realistic quantities for {req.servings} people"""
        
        system_prompt = "You are a creative chef who creates recipes from available ingredients. Analyze the image and suggest a delicious recipe."
        
    else:
        # French version
        constraints_text = ""
        if req.constraints.get("diet"):
            diets = ", ".join(req.constraints["diet"])
            constraints_text += f"Régimes alimentaires: {diets}. "
        if req.constraints.get("evict"):
            allergies = ", ".join(req.constraints["evict"])
            constraints_text += f"Allergies/Éviter: {allergies}. "
        
        unit_system = "métrique (grammes, ml)" if req.units == "METRIC" else "impérial (oz, cups)"
        
        text_prompt = f"""Analyse cette photo de frigo/garde-manger et génère une recette créative utilisant les ingrédients visibles.

Pour {req.servings} personnes.
{constraints_text}{preferences_text}{protein_portions_text}

CRITIQUE - ÉTAPES DE PRÉPARATION: La recette DOIT commencer par des étapes de préparation détaillées:
- Les premières étapes doivent décrire TOUTES les préparations d'ingrédients (couper, émincer, hacher, râper, etc.)
- Sois précis sur les coupes: "couper les carottes en dés de 1cm", "râper 100g de fromage", "émincer finement 2 oignons"
- Inclure la préparation de TOUS les ingrédients avant les étapes de cuisson
- Ensuite inclure les étapes de cuisson/assemblage avec temps exacts, températures et techniques

Retourne UNIQUEMENT un objet JSON valide avec cette structure exacte:
{{
    "title": "Nom créatif de recette basé sur les ingrédients",
    "servings": {req.servings},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingrédient de la photo", "quantity": 200, "unit": "g", "category": "légumes"}}
    ],
    "steps": [
        "Préparation: Couper les carottes en dés de 1cm. Émincer finement l'oignon...",
        "Faire chauffer l'huile dans une grande poêle...",
        "Ajouter les ingrédients et cuire..."
    ],
    "equipment": ["poêle", "casserole"],
    "tags": ["vide-frigo", "créatif"]
}}

Utilise le système {unit_system}.
Catégories: légumes, fruits, viandes, poissons, produits laitiers, sec, condiments, conserves.

IMPORTANT:
- Génère au moins 5-7 étapes détaillées avec des étapes de préparation EXPLICITES au début
- Utilise les ingrédients visibles sur la photo
- Sois créatif avec le nom de la recette
- Assure des quantités réalistes pour {req.servings} personnes"""
        
        system_prompt = "Tu es un chef créatif qui crée des recettes à partir d'ingrédients disponibles. Analyse l'image et suggère une délicieuse recette."

    try:
        # Use OpenAI Vision API to analyze the image
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": system_prompt
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": text_prompt
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{req.image_base64}",
                                "detail": "low"  # Use low detail for faster/cheaper processing
                            }
                        }
                    ]
                }
            ],
            temperature=0.9,
            max_tokens=1500
        )
        
        content = response.choices[0].message.content.strip()
        
        # Remove markdown code blocks if present
        if content.startswith("```"):
            content = content.split("```")[1]
            if content.startswith("json"):
                content = content[4:]
            content = content.strip()
        
        recipe_data = json.loads(content)
        
        # Ensure all ingredients have required fields
        for ingredient in recipe_data.get("ingredients", []):
            if "unit" not in ingredient or not ingredient.get("unit"):
                ingredient["unit"] = "unité" if req.language == "fr" else "unit"
            if "category" not in ingredient or not ingredient.get("category"):
                ingredient["category"] = "autre" if req.language == "fr" else "other"
        
        return Recipe(**recipe_data)
        
    except Exception as e:
        print(f"Error generating recipe from image: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Failed to generate recipe from image: {str(e)}")


@app.get("/")
def root():
    return {"message": "Planea AI Server with OpenAI - Ready!"}
