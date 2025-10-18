from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Literal
from datetime import date
import os
from dotenv import load_dotenv
from openai import AsyncOpenAI
import json
import asyncio

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
    servings: int = 4
    language: str = "fr"

class Ingredient(BaseModel):
    name: str
    quantity: float
    unit: str
    category: str

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


async def generate_recipe_with_openai(meal_type: str, constraints: dict, units: str, servings: int = 4, previous_recipes: List[str] = None, diversity_seed: int = 0, language: str = "fr", use_fast_model: bool = False, weekday: str = None) -> Recipe:
    """Generate a single recipe using OpenAI with diversity awareness (async).
    
    Args:
        use_fast_model: If True, uses gpt-4o (faster, more expensive). If False, uses gpt-4o-mini (balanced).
        weekday: The day of the week (Mon, Tue, Wed, etc.) to determine time constraints
    """
    
    # Extract time constraints from extra field if present
    # Need to check if it's a weekend or weekday to apply correct time limit
    max_minutes = None
    if constraints.get("extra"):
        extra_text = constraints["extra"]
        import re
        
        # Determine if this is a weekend meal based on weekday parameter
        is_weekend = weekday and (weekday == "Sat" or weekday == "Sun")
        
        # Extract weekday and weekend time constraints separately
        weekday_match = re.search(r'Monday through Friday.*?(\d+)\s+minutes', extra_text, re.IGNORECASE | re.DOTALL)
        weekend_match = re.search(r'Saturday and Sunday.*?(\d+)\s+minutes', extra_text, re.IGNORECASE | re.DOTALL)
        
        if is_weekend and weekend_match:
            max_minutes = int(weekend_match.group(1))
            print(f"Weekend recipe ({weekday}): using {max_minutes} minutes limit")
        elif not is_weekend and weekday_match:
            max_minutes = int(weekday_match.group(1))
            print(f"Weekday recipe ({weekday}): using {max_minutes} minutes limit")
        else:
            # Fallback to generic time constraint
            time_match = re.search(r'(?:max|maximum|NO MORE than)\s+(\d+)\s+minutes', extra_text, re.IGNORECASE)
            if time_match:
                max_minutes = int(time_match.group(1))
    
    # Build constraints text
    constraints_text = ""
    if constraints.get("diet"):
        diets = ", ".join(constraints["diet"])
        constraints_text += f"Régimes alimentaires: {diets}. "
    if constraints.get("evict"):
        allergies = ", ".join(constraints["evict"])
        constraints_text += f"Allergies/Éviter: {allergies}. "
    # IMPORTANT: Include user preferences from "extra" field
    if constraints.get("extra"):
        constraints_text += f"\n\nPRÉFÉRENCES UTILISATEUR (À RESPECTER STRICTEMENT):\n{constraints['extra']}\n"
    
    # Build diversity instructions with enhanced variety prompts
    diversity_text = "\n\nIMPORTANT - DIVERSITÉ ET ORIGINALITÉ:\n"
    
    # Enhanced diversity guidance based on seed
    cuisine_styles = [
        "méditerranéenne", "asiatique", "mexicaine", "française", 
        "italienne", "indienne", "marocaine", "grecque"
    ]
    protein_types = [
        "poulet", "bœuf", "porc", "poisson", "fruits de mer",
        "légumineuses", "tofu", "œufs"
    ]
    cooking_methods = [
        "sauté", "rôti au four", "grillé", "mijote", "à la vapeur",
        "poêlé", "en papillote", "braisé"
    ]
    
    cuisine_hint = cuisine_styles[diversity_seed % len(cuisine_styles)]
    protein_hint = protein_types[diversity_seed % len(protein_types)]
    method_hint = cooking_methods[diversity_seed % len(cooking_methods)]
    
    diversity_text += f"- Inspire-toi de la cuisine {cuisine_hint}\n"
    diversity_text += f"- Utilise de préférence {protein_hint} comme protéine\n"
    diversity_text += f"- Méthode de cuisson suggérée: {method_hint}\n"
    diversity_text += "- Crée une recette UNIQUE et ORIGINALE\n"
    diversity_text += "- Varie les saveurs, textures et présentations\n"
    
    unit_system = "métrique (grammes, ml)" if units == "METRIC" else "impérial (oz, cups)"
    
    meal_type_fr = {
        "BREAKFAST": "déjeuner",
        "LUNCH": "dîner",
        "DINNER": "souper"
    }.get(meal_type, "repas")
    
    # Add meal-specific guidance for appropriate meal types
    meal_guidance = ""
    if meal_type == "BREAKFAST":
        # Define specific breakfast types for variety based on diversity_seed
        breakfast_types_fr = [
            "omelette aux légumes",
            "crêpes",
            "gaufres",
            "pain doré",
            "bol de gruau",
            "parfait au yogourt et granola",
            "bol smoothie",
            "bagel garni",
            "muffins maison",
            "œufs bénédictine",
            "frittata",
            "sandwich déjeuner",
            "burrito déjeuner"
        ]
        breakfast_types_en = [
            "vegetable omelette",
            "pancakes",
            "waffles",
            "french toast",
            "oatmeal bowl",
            "yogurt parfait with granola",
            "smoothie bowl",
            "loaded bagel",
            "homemade muffins",
            "eggs benedict",
            "frittata",
            "breakfast sandwich",
            "breakfast burrito"
        ]
        
        if language == "en":
            breakfast_type = breakfast_types_en[diversity_seed % len(breakfast_types_en)]
            meal_guidance = f"\n\nIMPORTANT - BREAKFAST MEAL REQUIREMENTS:\n- This MUST be a {breakfast_type} recipe (morning meal)\n- Create a UNIQUE variation of {breakfast_type}\n- Should be energizing for starting the day\n- Avoid heavy dinner-style dishes, roasted meats, or elaborate multi-course meals\n- Focus on classic, morning-appropriate breakfast foods\n- DO NOT create a burrito if you've been asked for something else"
        else:
            breakfast_type = breakfast_types_fr[diversity_seed % len(breakfast_types_fr)]
            meal_guidance = f"\n\nIMPORTANT - EXIGENCES POUR LE DÉJEUNER:\n- Ceci DOIT être une recette de {breakfast_type} (repas du matin)\n- Crée une variation UNIQUE de {breakfast_type}\n- Doit être énergisant pour commencer la journée\n- Éviter les plats de type souper, viandes rôties ou repas élaborés\n- Concentre-toi sur des aliments classiques appropriés pour le matin\n- NE crée PAS un burrito si on te demande autre chose"
    elif meal_type == "LUNCH":
        if language == "en":
            meal_guidance = "\n\nIMPORTANT - LUNCH MEAL REQUIREMENTS:\n- This MUST be an appropriate lunch meal (midday meal)\n- Suitable options include: salads, sandwiches, wraps, pasta dishes, grain bowls, soups, quiches, light protein dishes\n- Should be lighter than dinner, easy to prepare and serve\n- Avoid heavy roasted meats or elaborate dinner-style dishes\n- Focus on fresh, balanced, midday-appropriate meals"
        else:
            meal_guidance = "\n\nIMPORTANT - EXIGENCES POUR LE DÎNER:\n- Ceci DOIT être un repas approprié pour le dîner (repas du midi)\n- Options appropriées: salades, sandwichs, wraps, plats de pâtes, bols de grains, soupes, quiches, plats légers avec protéines\n- Doit être plus léger que le souper, facile à préparer et servir\n- Éviter les viandes rôties lourdes ou les plats élaborés de type souper\n- Concentre-toi sur des repas frais, équilibrés et appropriés pour le midi"
    
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
        
        cuisine_styles_en = [
            "Mediterranean", "Asian", "Mexican", "French", 
            "Italian", "Indian", "Moroccan", "Greek"
        ]
        protein_types_en = [
            "chicken", "beef", "pork", "fish", "seafood",
            "legumes", "tofu", "eggs"
        ]
        cooking_methods_en = [
            "sautéed", "roasted", "grilled", "stewed", "steamed",
            "pan-fried", "baked in parchment", "braised"
        ]
        
        cuisine_hint_en = cuisine_styles_en[diversity_seed % len(cuisine_styles_en)]
        protein_hint_en = protein_types_en[diversity_seed % len(protein_types_en)]
        method_hint_en = cooking_methods_en[diversity_seed % len(cooking_methods_en)]
        
        diversity_text_en = "\n\nIMPORTANT - DIVERSITY AND ORIGINALITY:\n"
        diversity_text_en += f"- Draw inspiration from {cuisine_hint_en} cuisine\n"
        diversity_text_en += f"- Preferably use {protein_hint_en} as protein\n"
        diversity_text_en += f"- Suggested cooking method: {method_hint_en}\n"
        diversity_text_en += "- Create a UNIQUE and ORIGINAL recipe\n"
        diversity_text_en += "- Vary flavors, textures and presentations\n"
        
        unit_system_text = "metric (grams, ml)" if units == "METRIC" else "imperial (oz, cups)"
        
        prompt = f"""Generate a {meal_type_name} recipe in English for {servings} people.

{constraints_text_en}{diversity_text_en}{meal_guidance}

CRITICAL - PREPARATION STEPS: The recipe MUST start with detailed preparation steps:
- First steps should describe ALL ingredient preparations (cutting, dicing, chopping, grating, etc.)
- Be specific about cuts: "dice carrots into 1cm cubes", "grate 100g cheese", "finely chop 2 onions"
- Include prep for ALL ingredients before cooking steps
- Then include cooking/assembly steps with exact times, temperatures, and techniques

TEMPERATURE FORMAT: When mentioning temperatures, ALWAYS include both Celsius and Fahrenheit in parentheses.
- Format: "180°C (350°F)" or "température de 180°C (350°F)"
- This applies to ALL temperature mentions (oven, cooking, serving temperatures, etc.)

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
        # Use the actual time constraint in the example
        example_time = max_minutes if max_minutes else 30
        time_constraint_text = f"\n\nCRITICAL TIME CONSTRAINT: The total_minutes field MUST be {example_time} or LESS. This is MANDATORY." if max_minutes else ""
        
        prompt = f"""Génère une recette de {meal_type_fr} en français pour {servings} personnes.

{constraints_text}{diversity_text}{meal_guidance}{time_constraint_text}

CRITIQUE - ÉTAPES DE PRÉPARATION: La recette DOIT commencer par des étapes de préparation détaillées:
- Les premières étapes doivent décrire TOUTES les préparations d'ingrédients (couper, émincer, hacher, râper, etc.)
- Sois précis sur les coupes: "couper les carottes en dés de 1cm", "râper 100g de fromage", "émincer finement 2 oignons"
- Inclure la préparation de TOUS les ingrédients avant les étapes de cuisson
- Ensuite inclure les étapes de cuisson/assemblage avec temps exacts, températures et techniques

FORMAT DES TEMPÉRATURES: Lors de la mention de températures, TOUJOURS inclure Celsius ET Fahrenheit entre parenthèses.
- Format: "180°C (350°F)" ou "à une température de 180°C (350°F)"
- Ceci s'applique à TOUTES les mentions de température (four, cuisson, service, etc.)

Retourne UNIQUEMENT un objet JSON valide avec cette structure exacte (sans texte avant ou après):
{{
    "title": "Nom créatif et appétissant de la recette",
    "servings": {servings},
    "total_minutes": {example_time},
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

IMPORTANT: Génère au moins 6-8 étapes détaillées avec des étapes de préparation EXPLICITES au début.
RAPPEL CRITIQUE: total_minutes doit être {example_time} maximum."""

    # Select model based on use_fast_model flag
    model = "gpt-4o" if use_fast_model else "gpt-4o-mini"
    
    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = await client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "Tu es un chef cuisinier créatif et expert qui génère des recettes uniques et détaillées en JSON. Tu varies toujours les ingrédients, cuisines et techniques. Tu RESPECTES TOUJOURS les contraintes de temps données."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.9,  # Increased for more creativity and diversity
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
            
            # CRITICAL: ALWAYS enforce time constraint if specified
            if max_minutes is not None:
                recipe_time = recipe_data.get("total_minutes", 999)
                if recipe_time > max_minutes:
                    print(f"Recipe time {recipe_time} exceeds max {max_minutes}, forcing to {max_minutes}")
                    recipe_data["total_minutes"] = max_minutes
                    
                    # If this isn't the last attempt, retry to get a naturally shorter recipe
                    if attempt < max_retries - 1:
                        print(f"Retrying for naturally shorter recipe (attempt {attempt + 1}/{max_retries})")
                        continue
            
            # Ensure all ingredients have required fields
            for ingredient in recipe_data.get("ingredients", []):
                if "unit" not in ingredient or not ingredient.get("unit"):
                    ingredient["unit"] = "unité"
                if "category" not in ingredient or not ingredient.get("category"):
                    ingredient["category"] = "autre"
            
            return Recipe(**recipe_data)
            
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"Error on attempt {attempt + 1}/{max_retries}: {e}, retrying...")
                continue
            else:
                print(f"Error generating recipe with OpenAI after {max_retries} attempts: {e}")
                # Fallback to a simple recipe
                return Recipe(
                    title=f"Recette simple de {meal_type_fr}",
                    servings=servings,
                    total_minutes=max_minutes if max_minutes else 30,
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
    
    # Generate all recipes in parallel with diversity seeds for variety
    tasks = [
        generate_recipe_with_openai(
            meal_type=slot.meal_type,
            constraints=req.constraints,
            units=req.units,
            servings=req.servings,
            previous_recipes=None,
            diversity_seed=idx,  # Each recipe gets a different seed for variety
            language=req.language,
            weekday=slot.weekday  # Pass weekday for time constraints
        )
        for idx, slot in enumerate(req.slots)
    ]
    
    # Execute all API calls in parallel
    recipes = await asyncio.gather(*tasks)
    
    # Build response
    items = [
        PlanItem(
            weekday=slot.weekday,
            meal_type=slot.meal_type,
            recipe=recipe
        )
        for slot, recipe in zip(req.slots, recipes)
    ]
    
    return PlanResponse(items=items)


class RegenerateMealRequest(BaseModel):
    weekday: Weekday
    meal_type: MealType
    constraints: dict = Field(default_factory=dict)
    servings: int = 4
    units: Literal["METRIC", "IMPERIAL"] = "METRIC"
    language: str = "fr"
    diversity_seed: int = 0


@app.post("/ai/regenerate-meal", response_model=Recipe)
async def regenerate_meal(req: RegenerateMealRequest):
    """Regenerate a single meal with diversity."""
    return await generate_recipe_with_openai(
        meal_type=req.meal_type,
        constraints=req.constraints,
        units=req.units,
        servings=req.servings,
        previous_recipes=None,
        diversity_seed=req.diversity_seed,
        language=req.language,
        weekday=req.weekday  # Pass weekday for time constraints
    )


@app.post("/ai/recipe", response_model=Recipe)
async def ai_recipe(req: RecipeRequest):
    """Generate a single recipe from a prompt."""
    
    # Language-specific handling
    if req.language == "en":
        constraints_text = ""
        if req.constraints.get("diet"):
            diets = ", ".join(req.constraints["diet"])
            constraints_text += f"Dietary requirements: {diets}. "
        if req.constraints.get("evict"):
            allergies = ", ".join(req.constraints["evict"])
            constraints_text += f"Allergies/Avoid: {allergies}. "
        # IMPORTANT: Include user preferences
        if req.constraints.get("extra"):
            constraints_text += f"\n\nUSER PREFERENCES (MUST BE STRICTLY RESPECTED):\n{req.constraints['extra']}\n"
        
        unit_system = "metric (grams, ml)" if req.units == "METRIC" else "imperial (oz, cups)"
        
        prompt = f"""Generate a recipe in English based on this idea: "{req.idea}"
        
For {req.servings} people.
{constraints_text}

CRITICAL - PREPARATION STEPS: The recipe MUST start with detailed preparation steps:
- First steps should describe ALL ingredient preparations (cutting, dicing, chopping, grating, etc.)
- Be specific about cuts: "dice carrots into 1cm cubes", "grate 100g cheese", "finely chop 2 onions"
- Include prep for ALL ingredients before cooking steps
- Then include cooking/assembly steps with exact times, temperatures, and techniques

TEMPERATURE FORMAT: When mentioning temperatures, ALWAYS include both Celsius and Fahrenheit in parentheses.
- Format: "180°C (350°F)" or "at 180°C (350°F)"
- This applies to ALL temperature mentions (oven, cooking, serving temperatures, etc.)

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
        # IMPORTANT: Include user preferences
        if req.constraints.get("extra"):
            constraints_text += f"\n\nPRÉFÉRENCES UTILISATEUR (À RESPECTER STRICTEMENT):\n{req.constraints['extra']}\n"
        
        unit_system = "métrique (grammes, ml)" if req.units == "METRIC" else "impérial (oz, cups)"
        
        prompt = f"""Génère une recette en français basée sur cette idée: "{req.idea}"

Pour {req.servings} personnes.
{constraints_text}

CRITIQUE - ÉTAPES DE PRÉPARATION: La recette DOIT commencer par des étapes de préparation détaillées:
- Les premières étapes doivent décrire TOUTES les préparations d'ingrédients (couper, émincer, hacher, râper, etc.)
- Sois précis sur les coupes: "couper les carottes en dés de 1cm", "râper 100g de fromage", "émincer finement 2 oignons"
- Inclure la préparation de TOUS les ingrédients avant les étapes de cuisson
- Ensuite inclure les étapes de cuisson/assemblage avec temps exacts, températures et techniques

FORMAT DES TEMPÉRATURES: Lors de la mention de températures, TOUJOURS inclure Celsius ET Fahrenheit entre parenthèses.
- Format: "180°C (350°F)" ou "à 180°C (350°F)"
- Ceci s'applique à TOUTES les mentions de température (four, cuisson, service, etc.)

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
            temperature=0.9,  # Increased for more creativity
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


class RecipeFromImageRequest(BaseModel):
    image_base64: str
    constraints: dict = Field(default_factory=dict)
    servings: int = 4
    units: Literal["METRIC", "IMPERIAL"] = "METRIC"
    language: str = "fr"


@app.post("/ai/recipe-from-title", response_model=Recipe)
async def ai_recipe_from_title(req: RecipeFromTitleRequest):
    """Generate a complete recipe from just a title."""
    
    # Language-specific handling
    if req.language == "en":
        constraints_text = ""
        if req.constraints.get("diet"):
            diets = ", ".join(req.constraints["diet"])
            constraints_text += f"Dietary requirements: {diets}. "
        if req.constraints.get("evict"):
            allergies = ", ".join(req.constraints["evict"])
            constraints_text += f"Allergies/Avoid: {allergies}. "
        # IMPORTANT: Include user preferences
        if req.constraints.get("extra"):
            constraints_text += f"\n\nUSER PREFERENCES (MUST BE STRICTLY RESPECTED):\n{req.constraints['extra']}\n"
        
        unit_system = "metric (grams, ml)" if req.units == "METRIC" else "imperial (oz, cups)"
        
        prompt = f"""Generate a complete recipe in English with this exact title: "{req.title}"

For {req.servings} people.
{constraints_text}

CRITICAL - PREPARATION STEPS: The recipe MUST start with detailed preparation steps:
- First steps should describe ALL ingredient preparations (cutting, dicing, chopping, grating, etc.)
- Be specific about cuts: "dice carrots into 1cm cubes", "grate 100g cheese", "finely chop 2 onions"
- Include prep for ALL ingredients before cooking steps
- Then include cooking/assembly steps with exact times, temperatures, and techniques

TEMPERATURE FORMAT: When mentioning temperatures, ALWAYS include both Celsius and Fahrenheit in parentheses.
- Format: "180°C (350°F)" or "at 180°C (350°F)"
- This applies to ALL temperature mentions (oven, cooking, serving temperatures, etc.)

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
        # IMPORTANT: Include user preferences
        if req.constraints.get("extra"):
            constraints_text += f"\n\nPRÉFÉRENCES UTILISATEUR (À RESPECTER STRICTEMENT):\n{req.constraints['extra']}\n"
        
        unit_system = "métrique (grammes, ml)" if req.units == "METRIC" else "impérial (oz, cups)"
        
        prompt = f"""🚨🚨🚨 MISSION CRITIQUE: UTILISER UNIQUEMENT LES INGRÉDIENTS VISIBLES 🚨🚨🚨

Tu analyses une photo de frigo/garde-manger. Ta MISSION ABSOLUE est de créer une recette en utilisant EXCLUSIVEMENT les ingrédients que tu peux VOIR dans la photo.

Pour {req.servings} personnes.
{constraints_text}

════════════════════════════════════════════════════════════════
⛔⛔⛔ LOI FONDAMENTALE - LIS 3 FOIS AVANT DE CONTINUER ⛔⛔⛔
════════════════════════════════════════════════════════════════

TU DOIS SUIVRE CE PROCESSUS OBLIGATOIRE EN 3 ÉTAPES:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ÉTAPE 1: IDENTIFICATION EXHAUSTIVE DES INGRÉDIENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Avant de créer TOUTE recette, tu DOIS:
1. Scanner TOUTE l'image systématiquement (gauche à droite, haut en bas)
2. Identifier CHAQUE aliment visible, incluant:
   - Items dans des emballages/contenants (lis les étiquettes si visibles)
   - Items partiellement visibles
   - Items en arrière-plan
   - Petits items, condiments, épices
   - Produits frais, viandes, produits laitiers, grains, conserves
3. Créer une LISTE COMPLÈTE de TOUS les ingrédients identifiés
4. Être MINUTIEUX et EXHAUSTIF - ne RIEN manquer

⚠️ Si tu sautes cette étape ou la fais négligemment, tu ÉCHOUERAS la mission.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 ÉTAPE 2: VÉRIFICATION DE LA CONTRAINTE ABSOLUE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚫 RÈGLES CRITIQUES - VIOLER CELLES-CI = ÉCHEC AUTOMATIQUE:

1. ❌ PAS DE POULET sauf si tu vois du poulet dans la photo
2. ❌ PAS DE BŒUF sauf si tu vois du bœuf dans la photo
3. ❌ PAS DE PORC sauf si tu vois du porc dans la photo
4. ❌ PAS DE POISSON sauf si tu vois du poisson dans la photo
5. ❌ PAS D'ŒUFS sauf si tu vois des œufs dans la photo
6. ❌ PAS D'HUILE sauf si tu vois de l'huile dans la photo
7. ❌ PAS DE BEURRE sauf si tu vois du beurre dans la photo
8. ❌ PAS DE SEL sauf si tu vois du sel dans la photo
9. ❌ PAS DE POIVRE sauf si tu vois du poivre dans la photo
10. ❌ PAS D'AIL sauf si tu vois de l'ail dans la photo
11. ❌ PAS D'OIGNONS sauf si tu vois des oignons dans la photo
12. ❌ PAS D'INGRÉDIENT sauf s'il est dans ta liste ÉTAPE 1

⚠️ EXEMPLES D'ACTIONS INTERDITES:
❌ "Assaisonner de sel et poivre" → INTERDIT si non visible
❌ "Ajouter du poulet en dés" → INTERDIT si pas de poulet visible
❌ "Arroser d'huile d'olive" → INTERDIT si pas d'huile visible
❌ "Faire revenir dans du beurre" → INTERDIT si pas de beurre visible
❌ "Ajouter de l'ail émincé" → INTERDIT si pas d'ail visible

🔒 LA RÈGLE D'OR:
SI TU NE L'AS PAS VU À L'ÉTAPE 1, ÇA N'EXISTE PAS.
SI ÇA N'EXISTE PAS, TU NE PEUX PAS L'UTILISER.
AUCUNE EXCEPTION. AUCUNE SUPPOSITION. AUCUN INGRÉDIENT STANDARD.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🍳 ÉTAPE 3: CRÉATION DE RECETTE AVEC CONFORMITÉ STRICTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MAINTENANT et SEULEMENT MAINTENANT, crée une recette utilisant:
- UNIQUEMENT les ingrédients de ta liste ÉTAPE 1
- Des techniques de cuisson CRÉATIVES qui fonctionnent avec les ingrédients disponibles
- Des méthodes de préparation RÉALISTES étant donné les contraintes

AVANT d'inclure UN ingrédient, demande-toi:
"Ai-je vu cet ingrédient SPÉCIFIQUE à l'ÉTAPE 1?"
→ Si OUI: Tu peux l'utiliser
→ Si NON: NE L'UTILISE PAS, trouve une alternative dans ta liste

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ ÉTAPE 4: VÉRIFICATION FINALE (OBLIGATOIRE)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Avant de soumettre ta recette:
1. Révise CHAQUE ingrédient dans ta recette
2. Confirme que CHACUN était dans ta liste d'identification ÉTAPE 1
3. Si UN ingrédient N'EST PAS de l'ÉTAPE 1 → ENLÈVE-LE IMMÉDIATEMENT
4. Aucun ingrédient n'a de passe-droit - même pas les "communs" comme sel ou huile

════════════════════════════════════════════════════════════════

Pour {req.servings} personnes.
{constraints_text}

CRITIQUE - ÉTAPES DE PRÉPARATION: La recette DOIT commencer par des étapes de préparation détaillées:
- Les premières étapes doivent décrire TOUTES les préparations d'ingrédients (couper, émincer, hacher, râper, etc.)
- Sois précis sur les coupes: "couper les carottes en dés de 1cm", "râper 100g de fromage", "émincer finement 2 oignons"
- Inclure la préparation de TOUS les ingrédients avant les étapes de cuisson
- Ensuite inclure les étapes de cuisson/assemblage avec temps exacts, températures et techniques

FORMAT DES TEMPÉRATURES: Lors de la mention de températures, TOUJOURS inclure Celsius ET Fahrenheit entre parenthèses.
- Format: "180°C (350°F)" ou "à 180°C (350°F)"
- Ceci s'applique à TOUTES les mentions de température (four, cuisson, service, etc.)

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


@app.post("/ai/recipe-from-image", response_model=Recipe)
async def ai_recipe_from_image(req: RecipeFromImageRequest):
    """Generate a recipe from a fridge photo using GPT-4o Vision."""
    
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
        
        prompt = f"""🚨🚨🚨 CRITICAL MISSION: ONLY USE VISIBLE INGREDIENTS 🚨🚨🚨

You are analyzing a fridge/pantry photo. Your ABSOLUTE MISSION is to create a recipe using EXCLUSIVELY the ingredients you can SEE in the photo.

For {req.servings} people.
{constraints_text}

════════════════════════════════════════════════════════════════
⛔⛔⛔ FUNDAMENTAL LAW - READ 3 TIMES BEFORE PROCEEDING ⛔⛔⛔
════════════════════════════════════════════════════════════════

YOU MUST FOLLOW THIS MANDATORY 3-STEP PROCESS:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 STEP 1: EXHAUSTIVE INGREDIENT IDENTIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Before creating ANY recipe, you MUST:
1. Scan the ENTIRE image systematically (left to right, top to bottom)
2. Identify EVERY food item visible, including:
   - Items in packages/containers (read labels if visible)
   - Partially visible items
   - Items in the background
   - Small items, condiments, spices
   - Fresh produce, meats, dairy, grains, canned goods
3. Create a COMPREHENSIVE LIST of ALL identified ingredients
4. Be THOROUGH and EXHAUSTIVE - miss NOTHING

⚠️ If you skip this step or do it carelessly, you WILL fail the mission.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 STEP 2: ABSOLUTE CONSTRAINT VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚫 CRITICAL RULES - VIOLATING THESE = AUTOMATIC FAILURE:

1. ❌ NO CHICKEN unless you see chicken in the photo
2. ❌ NO BEEF unless you see beef in the photo
3. ❌ NO PORK unless you see pork in the photo
4. ❌ NO FISH unless you see fish in the photo
5. ❌ NO EGGS unless you see eggs in the photo
6. ❌ NO OIL unless you see oil in the photo
7. ❌ NO BUTTER unless you see butter in the photo
8. ❌ NO SALT unless you see salt in the photo
9. ❌ NO PEPPER unless you see pepper in the photo
10. ❌ NO GARLIC unless you see garlic in the photo
11. ❌ NO ONIONS unless you see onions in the photo
12. ❌ NO ANY INGREDIENT unless it's in your STEP 1 list

⚠️ EXAMPLES OF FORBIDDEN ACTIONS:
❌ "Season with salt and pepper" → FORBIDDEN if not visible
❌ "Add diced chicken" → FORBIDDEN if no chicken visible
❌ "Drizzle with olive oil" → FORBIDDEN if no oil visible
❌ "Sauté with butter" → FORBIDDEN if no butter visible
❌ "Add minced garlic" → FORBIDDEN if no garlic visible

🔒 THE GOLDEN RULE:
IF YOU DID NOT SEE IT IN STEP 1, IT DOES NOT EXIST.
IF IT DOES NOT EXIST, YOU CANNOT USE IT.
NO EXCEPTIONS. NO ASSUMPTIONS. NO STANDARD INGREDIENTS.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🍳 STEP 3: RECIPE CREATION WITH STRICT COMPLIANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NOW and ONLY NOW, create a recipe using:
- ONLY ingredients from your STEP 1 list
- CREATIVE cooking techniques that work with available ingredients
- REALISTIC preparation methods given the constraints

BEFORE including ANY ingredient, ask yourself:
"Did I see this SPECIFIC ingredient in STEP 1?"
→ If YES: You may use it
→ If NO: DO NOT USE IT, find an alternative from your list

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ STEP 4: FINAL VERIFICATION (MANDATORY)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Before submitting your recipe:
1. Review EVERY ingredient in your recipe
2. Confirm EACH ONE was in your STEP 1 identification list
3. If ANY ingredient is NOT from STEP 1 → REMOVE IT IMMEDIATELY
4. No ingredient gets a pass - not even "common" ones like salt or oil

════════════════════════════════════════════════════════════════

CRITICAL - PREPARATION STEPS: The recipe MUST start with detailed preparation steps:
- First steps should describe ALL ingredient preparations (cutting, dicing, chopping, grating, etc.)
- Be specific about cuts: "dice carrots into 1cm cubes", "grate 100g cheese", "finely chop 2 onions"
- Include prep for ALL ingredients before cooking steps
- Then include cooking/assembly steps with exact times, temperatures, and techniques

TEMPERATURE FORMAT: When mentioning temperatures, ALWAYS include both Celsius and Fahrenheit in parentheses.
- Format: "180°C (350°F)" or "at 180°C (350°F)"
- This applies to ALL temperature mentions (oven, cooking, serving temperatures, etc.)

Return ONLY a valid JSON object with this exact structure:
{{
    "title": "Creative recipe name based on identified ingredients",
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
    "tags": ["easy", "from-fridge"],
    "detected_ingredients": "List of main ingredients detected in the photo (comma-separated)"
}}

Use the {unit_system} system.
Categories: vegetables, fruits, meats, fish, dairy, dry goods, condiments, canned goods.

IMPORTANT: 
- Generate at least 5-7 detailed steps with EXPLICIT preparation steps at the beginning
- The "detected_ingredients" field should list ALL the main ingredients you identified in the photo
- Use realistic quantities based on what you see in the image
- Prioritize using AS MANY of the visible ingredients as makes sense for a coherent recipe"""
        
        system_prompt = "You are a creative chef who analyzes fridge photos and creates delicious, practical recipes using available ingredients."
        
    else:
        # French version
        constraints_text = ""
        if req.constraints.get("diet"):
            diets = ", ".join(req.constraints["diet"])
            constraints_text += f"Régimes alimentaires: {diets}. "
        if req.constraints.get("evict"):
            allergies = ", ".join(req.constraints["evict"])
            constraints_text += f"Allergies/Éviter: {allergies}. "
        # IMPORTANT: Include user instructions from "extra" field
        if req.constraints.get("extra"):
            constraints_text += f"\n\n🎯 INSTRUCTIONS UTILISATEUR (PRIORITÉ ABSOLUE - À SUIVRE STRICTEMENT):\n{req.constraints['extra']}\n"
        
        unit_system = "métrique (grammes, ml)" if req.units == "METRIC" else "impérial (oz, cups)"
        
        prompt = f"""🎯 MISSION: Créer une recette pratique et savoureuse avec les ingrédients disponibles

Tu analyses une photo de frigo/garde-manger pour créer une recette délicieuse.

Pour {req.servings} personnes.
{constraints_text}

════════════════════════════════════════════════════════════════
📋 RÈGLES HIÉRARCHIQUES - APPLIQUE DANS CET ORDRE
════════════════════════════════════════════════════════════════

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ NIVEAU 1: INGRÉDIENTS DE BASE (TOUJOURS AUTORISÉS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ces ingrédients sont TOUJOURS disponibles, même s'ils ne sont PAS visibles dans la photo:

🧂 Assaisonnements de base:
   - Sel, poivre noir
   - Herbes séchées (basilic, thym, origan, persil, etc.)
   - Épices communes (paprika, cumin, curry, etc.)

🧈 Matières grasses:
   - Huile d'olive, huile végétale
   - Beurre

🥄 Condiments et basiques:
   - Ail, oignons (en quantité raisonnable)
   - Vinaigre, moutarde
   - Farine, sucre
   - Bouillon (poulet, légumes, bœuf)

💡 Tu peux LIBREMENT utiliser ces ingrédients pour assaisonner et cuisiner.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 NIVEAU 2: INSTRUCTIONS UTILISATEUR (PRIORITÉ ABSOLUE)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🚨🚨🚨 RÈGLE LA PLUS IMPORTANTE DE TOUTES 🚨🚨🚨

Si l'utilisateur donne des instructions spécifiques (demande un ingrédient, type de plat, style de cuisine):
✅ Ces instructions ONT LA PRIORITÉ ABSOLUE #1
✅ Tu DOIS ABSOLUMENT créer ce que l'utilisateur demande
✅ Tu IGNORES la contrainte "ingrédients visibles uniquement" pour l'ingrédient demandé
✅ Les ingrédients visibles deviennent des accompagnements/garnitures

EXEMPLES CRITIQUES À SUIVRE EXACTEMENT:

📝 Instructions: "je veux faire des crevettes" OU "crevettes" OU "avec des crevettes"
   → ✅ OBLIGATOIRE: Crée une recette DE CREVETTES
   → ✅ Les crevettes sont l'ingrédient PRINCIPAL (500g+)
   → ✅ Utilise les ingrédients visibles comme accompagnements
   → ❌ INTERDIT: Créer une recette sans crevettes

📝 Instructions: "avec du saumon" OU "saumon" OU "je veux du saumon"
   → ✅ OBLIGATOIRE: Crée une recette DE SAUMON
   → ✅ Le saumon est l'ingrédient PRINCIPAL (400g+)
   → ❌ INTERDIT: Créer une recette sans saumon

📝 Instructions: "poulet rôti" OU "poulet" OU "avec du poulet"
   → ✅ OBLIGATOIRE: Crée une recette DE POULET RÔTI
   → ✅ Le poulet est l'ingrédient PRINCIPAL (600g+)
   → ❌ INTERDIT: Créer une recette sans poulet

📝 Instructions: "tacos" OU "je veux des tacos"
   → ✅ OBLIGATOIRE: Crée une recette DE TACOS
   → ✅ Avec viande/protéine + ingrédients visibles
   → ❌ INTERDIT: Créer autre chose que des tacos

COMMENT DÉTECTER LES INSTRUCTIONS:
- Cherche dans le texte des instructions utilisateur
- Identifie les noms d'ingrédients: crevettes, saumon, poulet, bœuf, porc, agneau, etc.
- Identifie les types de plats: tacos, pizza, pâtes, curry, etc.
- SI TU TROUVES un ingrédient ou plat demandé → TU DOIS le faire

⚠️⚠️⚠️ AVERTISSEMENT CRITIQUE ⚠️⚠️⚠️
Si tu IGNORES les instructions utilisateur et crées une recette différente de ce qui est demandé, TU ÉCHOUES COMPLÈTEMENT ta mission. C'est la règle #1 ABSOLUE qui écrase TOUTES les autres règles.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🥗 NIVEAU 3: INGRÉDIENTS VISIBLES (MAXIMISER L'UTILISATION)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PROCESSUS D'IDENTIFICATION:
1. Scanner TOUTE l'image systématiquement
2. Identifier CHAQUE aliment visible:
   - Items dans emballages (lis les étiquettes)
   - Items partiellement visibles
   - Items en arrière-plan
   - Produits frais, viandes, produits laitiers, conserves, etc.
3. Créer une LISTE COMPLÈTE des ingrédients identifiés

RÈGLE D'UTILISATION:
✅ Utilise AU MAXIMUM les ingrédients visibles
✅ Ils forment la BASE de ta recette (sauf si instructions utilisateur prioritaires)
❌ N'invente PAS d'ingrédients principaux non visibles ET non demandés

EXEMPLES:
📸 Photo: tomates, poivrons, courgettes + Aucune instruction
   → ✅ Recette végétarienne avec ces légumes
   → ✅ Assaisonnements de base OK (sel, huile, ail)
   → ❌ PAS de poulet si non visible ET non demandé

📸 Photo: carottes, brocoli + Instructions: "crevettes"
   → ✅ Crevettes sautées aux carottes et brocoli
   → ✅ Huile, ail, sel pour la cuisson

════════════════════════════════════════════════════════════════

CRITIQUE - ÉTAPES DE PRÉPARATION: La recette DOIT commencer par des étapes de préparation détaillées:
- Les premières étapes doivent décrire TOUTES les préparations d'ingrédients (couper, émincer, hacher, râper, etc.)
- Sois précis sur les coupes: "couper les carottes en dés de 1cm", "râper 100g de fromage", "émincer finement 2 oignons"
- Inclure la préparation de TOUS les ingrédients avant les étapes de cuisson
- Ensuite inclure les étapes de cuisson/assemblage avec temps exacts, températures et techniques

FORMAT DES TEMPÉRATURES: Lors de la mention de températures, TOUJOURS inclure Celsius ET Fahrenheit entre parenthèses.
- Format: "180°C (350°F)" ou "à 180°C (350°F)"
- Ceci s'applique à TOUTES les mentions de température (four, cuisson, service, etc.)

Retourne UNIQUEMENT un objet JSON valide avec cette structure exacte:
{{
    "title": "Nom créatif de la recette basé sur les ingrédients identifiés",
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
    "tags": ["facile", "du-frigo"],
    "detected_ingredients": "Liste des principaux ingrédients détectés dans la photo (séparés par des virgules)"
}}

Utilise le système {unit_system}.
Catégories: légumes, fruits, viandes, poissons, produits laitiers, sec, condiments, conserves.

IMPORTANT: 
- Génère au moins 5-7 étapes détaillées avec des étapes de préparation EXPLICITES au début
- Le champ "detected_ingredients" doit lister TOUS les principaux ingrédients que tu as identifiés dans la photo
- Utilise des quantités réalistes basées sur ce que tu vois dans l'image
- Priorise l'utilisation du PLUS GRAND NOMBRE d'ingrédients visibles qui ont du sens pour une recette cohérente"""
        
        system_prompt = "Tu es un chef créatif expert qui génère des recettes délicieuses et pratiques à partir de photos de frigo. Tu comprends la hiérarchie des priorités: 1) Ingrédients de base toujours disponibles (sel, huile, épices), 2) Instructions spécifiques de l'utilisateur (priorité absolue), 3) Ingrédients visibles dans la photo (maximiser l'utilisation). Tu crées des recettes qui respectent parfaitement cette hiérarchie."

    try:
        response = await client.chat.completions.create(
            model="gpt-4o",  # Use GPT-4o for vision capabilities
            messages=[
                {"role": "system", "content": system_prompt},
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{req.image_base64}",
                                "detail": "high"  # High detail for better ingredient identification
                            }
                        }
                    ]
                }
            ],
            temperature=0.7,
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
        raise HTTPException(status_code=500, detail=f"Failed to generate recipe from image: {str(e)}")


@app.get("/")
def root():
    return {"message": "Planea AI Server with OpenAI - Ready!"}


@app.get("/health")
def health():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    # Use Railway's PORT environment variable, default to 8000 for local dev
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
