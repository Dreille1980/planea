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
    if meal_type == "LUNCH":
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
            servings=4,
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
        
        prompt = f"""Génère une recette complète en français avec ce titre exact: "{req.title}"

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
