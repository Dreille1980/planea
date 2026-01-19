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
    preferences: dict = Field(default_factory=dict)

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
    preferences: dict = Field(default_factory=dict)


async def generate_diversity_plan(num_meals: int, constraints: dict, language: str = "fr", preferences: dict = None) -> List[dict]:
    """Generate a diversity blueprint for the meal plan to ensure variety."""
    
    # Build constraints for the diversity plan
    constraints_text = ""
    if constraints.get("diet"):
        diets = ", ".join(constraints["diet"])
        if language == "en":
            constraints_text += f"Dietary requirements: {diets}. "
        else:
            constraints_text += f"Régimes alimentaires: {diets}. "
    
    # Build preferences context
    prefs_text = ""
    if preferences:
        if preferences.get("preferredProteins"):
            proteins = ", ".join(preferences["preferredProteins"])
            if language == "en":
                prefs_text += f"Preferred proteins (use these when possible): {proteins}. "
            else:
                prefs_text += f"Protéines préférées (à utiliser quand possible): {proteins}. "
    
    if language == "en":
        prompt = f"""Create a diversity plan for {num_meals} meals with MAXIMUM VARIETY.

{constraints_text}{prefs_text}

CRITICAL DIVERSITY RULES:
1. Each protein should appear at MOST 2 times (prefer different proteins)
2. Each main vegetable should appear at MOST 2 times
3. Include 1-2 meal-soups OR meal-salads naturally in the mix
4. Vary cooking methods: stir-fry, grilled, braised, baked, soup, salad, pasta, rice bowl, curry, tacos, etc.
5. Vary world cuisines: Asian (Chinese, Thai, Japanese, Korean), Mediterranean (Italian, Greek), Mexican, Middle-Eastern, Indian, French, American, Fusion

Return ONLY valid JSON with this structure:
{{
    "meals": [
        {{
            "cuisine": "Thai",
            "protein": "chicken",
            "dish_type": "stir-fry",
            "vegetable_focus": "bell peppers and basil",
            "description": "Thai basil chicken stir-fry"
        }},
        {{
            "cuisine": "Mediterranean",
            "protein": "fish",
            "dish_type": "grilled",
            "vegetable_focus": "tomatoes and olives",
            "description": "Grilled fish with Mediterranean vegetables"
        }}
    ]
}}

IMPORTANT: Create {num_meals} diverse meal blueprints ensuring no repetition."""
    
    else:
        prompt = f"""Crée un plan de diversité pour {num_meals} repas avec une VARIÉTÉ MAXIMALE.

{constraints_text}{prefs_text}

RÈGLES DE DIVERSITÉ CRITIQUES:
1. Chaque protéine doit apparaître AU MAXIMUM 2 fois (préférer des protéines différentes)
2. Chaque légume principal doit apparaître AU MAXIMUM 2 fois
3. Inclure 1-2 soupes-repas OU salades-repas naturellement dans le mélange
4. Varier les méthodes de cuisson: sauté, grillé, mijoté, au four, soupe, salade, pâtes, bol de riz, cari, tacos, etc.
5. Varier les cuisines du monde: Asiatique (chinoise, thaï, japonaise, coréenne), Méditerranéenne (italienne, grecque), Mexicaine, Moyen-orientale, Indienne, Française, Américaine, Fusion

Retourne UNIQUEMENT du JSON valide avec cette structure:
{{
    "meals": [
        {{
            "cuisine": "Thaïlandaise",
            "protein": "poulet",
            "dish_type": "sauté",
            "vegetable_focus": "poivrons et basilic",
            "description": "Sauté de poulet au basilic thaï"
        }},
        {{
            "cuisine": "Méditerranéenne",
            "protein": "poisson",
            "dish_type": "grillé",
            "vegetable_focus": "tomates et olives",
            "description": "Poisson grillé aux légumes méditerranéens"
        }}
    ]
}}

IMPORTANT: Crée {num_meals} plans de repas diversifiés sans répétition."""

    try:
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "Tu es un expert en planification de menus qui crée des plans de repas extrêmement variés et équilibrés."},
                {"role": "user", "content": prompt}
            ],
            temperature=1.0,
            max_tokens=800
        )
        
        content = response.choices[0].message.content.strip()
        
        # Remove markdown code blocks if present
        if content.startswith("```"):
            content = content.split("```")[1]
            if content.startswith("json"):
                content = content[4:]
            content = content.strip()
        
        plan_data = json.loads(content)
        print(f"✅ Generated diversity plan: {plan_data}")
        return plan_data.get("meals", [])
        
    except Exception as e:
        print(f"Error generating diversity plan: {e}")
        # Fallback to basic diverse plan
        basic_proteins = ["chicken", "beef", "fish", "pork", "tofu"]
        return [
            {
                "cuisine": "varied",
                "protein": basic_proteins[i % len(basic_proteins)],
                "dish_type": "varied",
                "vegetable_focus": "seasonal vegetables",
                "description": f"Diverse meal {i+1}"
            }
            for i in range(num_meals)
        ]


async def generate_recipe_with_openai(meal_type: str, constraints: dict, units: str, servings: int = 4, previous_recipes: List[str] = None, diversity_seed: int = 0, language: str = "fr", preferences: dict = None, diversity_blueprint: dict = None) -> Recipe:
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
    
    # Build diversity instructions based on blueprint
    diversity_text = ""
    if diversity_blueprint:
        if language == "en":
            diversity_text = f"\n\nDIVERSITY BLUEPRINT - MUST FOLLOW:\n"
            diversity_text += f"- Cuisine style: {diversity_blueprint.get('cuisine', 'varied')}\n"
            diversity_text += f"- Main protein: {diversity_blueprint.get('protein', 'varied')}\n"
            diversity_text += f"- Dish type: {diversity_blueprint.get('dish_type', 'varied')}\n"
            diversity_text += f"- Vegetable focus: {diversity_blueprint.get('vegetable_focus', 'seasonal')}\n"
            diversity_text += f"- Concept: {diversity_blueprint.get('description', 'creative dish')}\n"
            diversity_text += "You MUST respect these diversity constraints while creating a delicious recipe.\n"
        else:
            diversity_text = f"\n\nPLAN DE DIVERSITÉ - DOIT SUIVRE:\n"
            diversity_text += f"- Style de cuisine: {diversity_blueprint.get('cuisine', 'varié')}\n"
            diversity_text += f"- Protéine principale: {diversity_blueprint.get('protein', 'varié')}\n"
            diversity_text += f"- Type de plat: {diversity_blueprint.get('dish_type', 'varié')}\n"
            diversity_text += f"- Focus légumes: {diversity_blueprint.get('vegetable_focus', 'de saison')}\n"
            diversity_text += f"- Concept: {diversity_blueprint.get('description', 'plat créatif')}\n"
            diversity_text += "Tu DOIS respecter ces contraintes de diversité tout en créant une recette délicieuse.\n"
    else:
        # Fallback to general diversity instructions
        diversity_text = "\n\nIMPÉRATIF - DIVERSITÉ MAXIMALE:\n"
        diversity_text += "- Crée une recette TOTALEMENT UNIQUE et DIFFÉRENTE\n"
        diversity_text += "- Varie librement: cuisines du monde, protéines, légumes, épices, techniques\n"
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
        diversity_text_en += "- Create a COMPLETELY UNIQUE and DIFFERENT recipe\n"
        diversity_text_en += "- Freely vary: world cuisines, proteins, vegetables, spices, techniques\n"
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
    """Generate a meal plan using OpenAI with 2-phase diversity system."""
    
    # PHASE 1: Generate diversity blueprint for the entire plan
    print(f"🎯 Phase 1: Generating diversity blueprint for {len(req.slots)} meals...")
    diversity_blueprints = await generate_diversity_plan(
        num_meals=len(req.slots),
        constraints=req.constraints,
        language=req.language,
        preferences=req.preferences
    )
    
    # Ensure we have enough blueprints (fallback if needed)
    while len(diversity_blueprints) < len(req.slots):
        diversity_blueprints.append({
            "cuisine": "varied",
            "protein": "varied",
            "dish_type": "varied",
            "vegetable_focus": "seasonal",
            "description": "diverse meal"
        })
    
    print(f"✅ Phase 1 complete. Blueprints: {[bp.get('description', 'N/A') for bp in diversity_blueprints]}")
    
    # PHASE 2: Generate all recipes in parallel with their specific blueprints
    print(f"🎯 Phase 2: Generating {len(req.slots)} recipes in parallel with diversity constraints...")
    tasks = [
        generate_recipe_with_openai(
            meal_type=slot.meal_type,
            constraints=req.constraints,
            units=req.units,
            servings=4,
            previous_recipes=None,
            diversity_seed=idx,
            language=req.language,
            preferences=req.preferences,
            diversity_blueprint=diversity_blueprints[idx]  # Pass specific blueprint for this meal
        )
        for idx, slot in enumerate(req.slots)
    ]
    
    # Execute all API calls in parallel
    recipes = await asyncio.gather(*tasks)
    print(f"✅ Phase 2 complete. Generated {len(recipes)} recipes.")
    
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
    return await generate_recipe_with_openai(
        meal_type=req.meal_type,
        constraints=req.constraints,
        units=req.units,
        servings=req.servings,
        previous_recipes=None,
        diversity_seed=req.diversity_seed,
        language=req.language,
        preferences=req.preferences
    )


@app.post("/ai/recipe", response_model=Recipe)
async def ai_recipe(req: RecipeRequest):
    """Generate a single recipe from a prompt using OpenAI (async)."""
    
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
        
        prompt = f"""Generate a recipe in English based on this idea: "{req.idea}"
        
For {req.servings} people.
{constraints_text}

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
        
        prompt = f"""Génère une recette en français basée sur cette idée: "{req.idea}"

Pour {req.servings} personnes.
{constraints_text}{preferences_text}{protein_portions_text}

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


@app.get("/")
def root():
    return {"message": "Planea AI Server with OpenAI - Ready!"}
