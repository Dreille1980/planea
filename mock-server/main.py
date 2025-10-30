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

# Translation dictionary for ingredients (EN <-> FR)
INGREDIENT_TRANSLATIONS = {
    # Proteins (EN -> FR)
    "chicken": "poulet",
    "chicken breast": "blanc de poulet",
    "turkey": "dinde",
    "turkey breast": "poitrine de dinde",
    "beef": "boeuf",
    "ground beef": "boeuf haché",
    "pork": "porc",
    "pork chops": "côtelettes de porc",
    "lamb": "agneau",
    "fish": "poisson",
    "salmon": "saumon",
    "tuna": "thon",
    "cod": "morue",
    "shrimp": "crevettes",
    "prawns": "crevettes",
    "seafood": "fruits de mer",
    "tofu": "tofu",
    "eggs": "oeufs",
    
    # Vegetables (EN -> FR)
    "carrots": "carottes",
    "broccoli": "brocoli",
    "cauliflower": "chou-fleur",
    "spinach": "épinards",
    "lettuce": "laitue",
    "tomatoes": "tomates",
    "potatoes": "pommes de terre",
    "onions": "oignons",
    "garlic": "ail",
    "peppers": "poivrons",
    "bell peppers": "poivrons",
    "mushrooms": "champignons",
    "zucchini": "courgettes",
    "cucumber": "concombre",
    "celery": "céleri",
    "asparagus": "asperges",
    "green beans": "haricots verts",
    "peas": "petits pois",
    "corn": "maïs",
    "cabbage": "chou",
    
    # Reverse (FR -> EN)
    "poulet": "chicken",
    "dinde": "turkey",
    "boeuf": "beef",
    "porc": "pork",
    "agneau": "lamb",
    "poisson": "fish",
    "saumon": "salmon",
    "thon": "tuna",
    "morue": "cod",
    "crevettes": "shrimp",
    "fruits de mer": "seafood",
    "oeufs": "eggs",
    "carottes": "carrots",
    "brocoli": "broccoli",
    "chou-fleur": "cauliflower",
    "épinards": "spinach",
    "laitue": "lettuce",
    "tomates": "tomatoes",
    "pommes de terre": "potatoes",
    "oignons": "onions",
    "ail": "garlic",
    "poivrons": "peppers",
    "champignons": "mushrooms",
    "courgettes": "zucchini",
    "concombre": "cucumber",
    "céleri": "celery",
    "asperges": "asparagus",
    "haricots verts": "green beans",
    "petits pois": "peas",
    "maïs": "corn",
    "chou": "cabbage",
}

def translate_ingredient(ingredient: str, to_language: str = "fr") -> str:
    """Translate an ingredient name between English and French."""
    ing_lower = ingredient.lower().strip()
    
    if to_language == "fr":
        # EN -> FR
        return INGREDIENT_TRANSLATIONS.get(ing_lower, ingredient)
    else:
        # FR -> EN
        return INGREDIENT_TRANSLATIONS.get(ing_lower, ingredient)

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
    
    print(f"\n🔍 DEBUG - mark_ingredients_on_sale called")
    print(f"  Preferences received: {preferences}")
    
    # Check if flyer deals feature is enabled
    if not preferences or not preferences.get("useWeeklyFlyers"):
        print(f"  ❌ Weekly flyers NOT enabled (useWeeklyFlyers={preferences.get('useWeeklyFlyers') if preferences else 'None'})")
        return recipe
    
    print(f"  ✅ Weekly flyers enabled!")
    
    # Get postal code and store
    postal_code = preferences.get("postalCode")
    store_name = preferences.get("preferredGroceryStore")
    
    print(f"  📍 Postal code: {postal_code}")
    print(f"  🏪 Store: {store_name}")
    
    if not postal_code or not store_name:
        print("  ❌ Flyer deals requested but postal code or store not provided")
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
            print(f"⚠️ No deals found for {store_name} via scraping, using fallback data...")
            # Use fallback data - common items typically on sale
            deals = [
                {"name": "poulet", "price": 8.99, "is_on_sale": True},
                {"name": "chicken", "price": 8.99, "is_on_sale": True},
                {"name": "saumon", "price": 9.99, "is_on_sale": True},
                {"name": "salmon", "price": 9.99, "is_on_sale": True},
                {"name": "boeuf haché", "price": 5.99, "is_on_sale": True},
                {"name": "ground beef", "price": 5.99, "is_on_sale": True},
                {"name": "porc", "price": 6.99, "is_on_sale": True},
                {"name": "pork", "price": 6.99, "is_on_sale": True},
                {"name": "brocoli", "price": 2.99, "is_on_sale": True},
                {"name": "broccoli", "price": 2.99, "is_on_sale": True},
                {"name": "carottes", "price": 1.99, "is_on_sale": True},
                {"name": "carrots", "price": 1.99, "is_on_sale": True},
                {"name": "tomates", "price": 3.49, "is_on_sale": True},
                {"name": "tomatoes", "price": 3.49, "is_on_sale": True},
                {"name": "pommes de terre", "price": 4.99, "is_on_sale": True},
                {"name": "potatoes", "price": 4.99, "is_on_sale": True},
                {"name": "oignons", "price": 2.49, "is_on_sale": True},
                {"name": "onions", "price": 2.49, "is_on_sale": True},
                {"name": "poivrons", "price": 3.99, "is_on_sale": True},
                {"name": "peppers", "price": 3.99, "is_on_sale": True},
            ]
            print(f"✅ Using {len(deals)} fallback deals for testing")
        
        print(f"Found {len(deals)} deals")
        
        # Normalize deals for comparison with translation support
        normalized_deals = set()
        print(f"\n📦 Deals found (with translations):")
        for deal in deals:
            # Extract the name from the deal dictionary
            deal_name = deal.get('name', '') if isinstance(deal, dict) else str(deal)
            normalized = deal_name.lower().strip()
            normalized_deals.add(normalized)
            
            # Add translation (EN <-> FR)
            translation = translate_ingredient(normalized, "fr")
            if translation != normalized:
                normalized_deals.add(translation)
                print(f"  - {deal_name} → {translation}")
            else:
                translation = translate_ingredient(normalized, "en")
                if translation != normalized:
                    normalized_deals.add(translation)
                    print(f"  - {deal_name} → {translation}")
                else:
                    print(f"  - {deal_name}")
            
            # Also add individual words for partial matching
            for word in normalized.split():
                if len(word) > 3:  # Only words longer than 3 chars
                    normalized_deals.add(word)
                    word_translation = translate_ingredient(word, "fr")
                    if word_translation != word:
                        normalized_deals.add(word_translation)
                    else:
                        word_translation = translate_ingredient(word, "en")
                        if word_translation != word:
                            normalized_deals.add(word_translation)
        
        print(f"\n🔍 Recipe ingredients to check:")
        for ingredient in recipe.ingredients:
            print(f"  - {ingredient.name}")
        
        # Words to ignore when matching (qualifiers, descriptors)
        ignore_words = {
            # French
            'frais', 'fraîche', 'fraîches', 'surgelé', 'surgelés', 'surgelée', 'surgelées',
            'congelé', 'congelés', 'congelée', 'congelées', 'décortiqué', 'décortiqués', 
            'décortiquée', 'décortiquées', 'épluché', 'épluchés', 'épluchée', 'épluchées',
            'coupé', 'coupés', 'coupée', 'coupées', 'tranché', 'tranchés', 'tranchée', 'tranchées',
            'haché', 'hachés', 'hachée', 'hachées', 'émincé', 'émincés', 'émincée', 'émincées',
            'bio', 'biologique', 'biologiques', 'local', 'locaux', 'locale', 'locales',
            'extra', 'gros', 'grosse', 'grosses', 'petit', 'petits', 'petite', 'petites',
            'jeune', 'jeunes', 'entier', 'entiers', 'entière', 'entières', 'blanc', 'blancs', 'blanche', 'blanches',
            # English
            'fresh', 'frozen', 'peeled', 'deveined', 'shelled', 'cleaned', 'trimmed',
            'chopped', 'diced', 'sliced', 'minced', 'shredded', 'grated',
            'organic', 'local', 'extra', 'large', 'small', 'medium', 'whole', 'boneless', 'skinless'
        }
        
        # Mark ingredients that are on sale
        for ingredient in recipe.ingredients:
            ing_name = ingredient.name.lower().strip()
            
            # Check for exact or partial match
            is_on_sale = False
            
            # Check exact match first
            if ing_name in normalized_deals:
                is_on_sale = True
            else:
                # Extract keywords from ingredient name (remove qualifiers)
                ing_words = set(ing_name.split())
                # Remove common qualifiers
                ing_keywords = {w for w in ing_words if w not in ignore_words and len(w) > 3}
                
                # Check if any keyword matches a deal
                for keyword in ing_keywords:
                    if keyword in normalized_deals:
                        is_on_sale = True
                        print(f"    - Matched keyword '{keyword}' from '{ing_name}' with deals")
                        break
                
                # Also check if any deal is a substring of the ingredient
                if not is_on_sale:
                    for deal in normalized_deals:
                        if len(deal) > 4 and deal in ing_name:
                            is_on_sale = True
                            print(f"    - Matched substring '{deal}' in '{ing_name}'")
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
    other_plan_proteins: List[str] = None,
    flyer_deals: List[str] = None
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
        
        # Enhanced JSON extraction - handle various formats
        # Remove markdown code blocks if present
        if "```json" in content:
            # Extract content between ```json and ```
            parts = content.split("```json")
            if len(parts) > 1:
                json_part = parts[1].split("```")[0]
                content = json_part.strip()
        elif content.startswith("```"):
            # Handle generic code blocks
            content = content.split("```")[1]
            if content.startswith("json"):
                content = content[4:]
            content = content.strip()
        
        # Remove any leading/trailing non-JSON text
        # Find the first { and last }
        start_idx = content.find('{')
        end_idx = content.rfind('}')
        if start_idx != -1 and end_idx != -1:
            content = content[start_idx:end_idx+1]
        
        try:
            recipe_data = json.loads(content)
        except json.JSONDecodeError as e:
            print(f"JSON decode error: {e}")
            print(f"Problematic content: {content[:500]}...")
            raise HTTPException(status_code=500, detail=f"Failed to parse recipe JSON: {str(e)}")
        
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
    
    # Get flyer deals BEFORE generating recipes if feature is enabled
    flyer_deals = []
    if req.preferences and req.preferences.get("useWeeklyFlyers"):
        postal_code = req.preferences.get("postalCode")
        store_name = req.preferences.get("preferredGroceryStore")
        
        if postal_code and store_name:
            try:
                print(f"\n🛒 Pre-fetching deals for meal plan generation...")
                deals = await asyncio.to_thread(
                    flyer_scraper.get_weekly_deals,
                    store_name=store_name,
                    postal_code=postal_code
                )
                
                if not deals:
                    # Use fallback data
                    deals = [
                        {"name": "poulet", "price": 8.99},
                        {"name": "chicken", "price": 8.99},
                        {"name": "turkey", "price": 8.99},
                        {"name": "dinde", "price": 8.99},
                        {"name": "saumon", "price": 9.99},
                        {"name": "salmon", "price": 9.99},
                        {"name": "crevettes", "price": 11.99},
                        {"name": "shrimp", "price": 11.99},
                        {"name": "boeuf haché", "price": 5.99},
                        {"name": "ground beef", "price": 5.99},
                        {"name": "porc", "price": 6.99},
                        {"name": "pork", "price": 6.99},
                        {"name": "brocoli", "price": 2.99},
                        {"name": "broccoli", "price": 2.99},
                        {"name": "carottes", "price": 1.99},
                        {"name": "carrots", "price": 1.99},
                        {"name": "tomates", "price": 3.49},
                        {"name": "tomatoes", "price": 3.49},
                        {"name": "épinards", "price": 2.99},
                        {"name": "spinach", "price": 2.99},
                        {"name": "chou-fleur", "price": 3.99},
                        {"name": "cauliflower", "price": 3.99},
                    ]
                
                # Extract deal names
                for deal in deals:
                    deal_name = deal.get('name', '') if isinstance(deal, dict) else str(deal)
                    if deal_name:
                        flyer_deals.append(deal_name)
                
                print(f"✅ Found {len(flyer_deals)} deals to suggest to recipes: {flyer_deals[:10]}")
            except Exception as e:
                print(f"⚠️ Error pre-fetching deals: {e}")
    
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
        
        text_prompt = f"""🚨 CRITICAL MISSION: ANALYZE THE IMAGE AND USE ONLY VISIBLE INGREDIENTS 🚨

You MUST carefully examine the fridge/pantry photo and create a recipe using ONLY the ingredients you can SEE in the image.

STEP 1 - IMAGE ANALYSIS (MANDATORY):
First, LIST all visible ingredients in the photo:
- Proteins (meat, fish, eggs, tofu, etc.)
- Vegetables
- Fruits  
- Dairy products
- Condiments and seasonings
- Grains and starches
- Other items

STEP 2 - RECIPE CREATION:
Create a recipe for {req.servings} people using PRIMARILY the ingredients from the photo.
{constraints_text}{preferences_text}

CRITICAL RULES:
✅ DO: Use ingredients visible in the photo as main ingredients
✅ DO: Add common pantry staples (salt, pepper, oil) if needed
✅ DO: Be creative with combinations
❌ DON'T: Invent ingredients not shown in the photo
❌ DON'T: Default to chicken if no protein is visible
❌ DON'T: Ignore what's actually in the image

Return ONLY a valid JSON object:
{{
    "title": "Creative name based on ACTUAL ingredients in photo",
    "servings": {req.servings},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingredient FROM PHOTO", "quantity": 200, "unit": "g", "category": "vegetables"}}
    ],
    "steps": [
        "Preparation: Prep all ingredients (cutting, dicing, etc.)...",
        "Cooking: Heat and combine ingredients...",
        "Final steps and serving..."
    ],
    "equipment": ["pan", "pot"],
    "tags": ["fridge cleanup", "zero waste"]
}}

Use {unit_system} system.
Categories: vegetables, fruits, meats, fish, dairy, dry goods, condiments, canned goods."""
        
        system_prompt = "You are an expert chef specializing in 'fridge cleanup' recipes. You MUST analyze the image carefully and create recipes using ONLY the visible ingredients. Never invent ingredients."
        
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
        
        # Build user instructions text if provided
        user_instructions_text = ""
        has_user_instructions = req.preferences.get('extra', '').strip() if req.preferences else ""
        
        if has_user_instructions:
            user_instructions_text = f"""
🚨🚨🚨 INSTRUCTIONS UTILISATEUR - PRIORITÉ ABSOLUE 🚨🚨🚨

L'utilisateur a fourni ces instructions OBLIGATOIRES:
"{has_user_instructions}"

RÈGLES NON NÉGOCIABLES:
- Ces instructions sont LA PRIORITÉ #1
- Tu DOIS créer une recette qui respecte EXACTEMENT ces instructions
- Si l'utilisateur mentionne un ingrédient (ex: crevettes), tu DOIS l'utiliser
- Si l'utilisateur mentionne un style (ex: asiatique), tu DOIS le respecter
- La photo du frigo sert UNIQUEMENT à compléter avec des ingrédients secondaires

❌ INTERDIT: Ignorer ces instructions ou les remplacer par autre chose
"""
        
        text_prompt = f"""🎯 MISSION : CRÉER UNE RECETTE VIDE-FRIGO PERSONNALISÉE

{user_instructions_text}

ÉTAPE 1 - ANALYSE DE LA PHOTO:
Examine la photo du frigo/garde-manger et identifie les ingrédients visibles:
- Protéines, légumes, fruits
- Produits laitiers
- Condiments et assaisonnements
- Autres items

ÉTAPE 2 - INGRÉDIENTS DE BASE DISPONIBLES:
Tu peux utiliser sans restriction:
- Huile, beurre
- Sel, poivre, épices courantes
- Ail, oignon, échalote
- Farine, sucre, bouillon

ÉTAPE 3 - CRÉATION DE LA RECETTE pour {req.servings} personnes:
{constraints_text}

LOGIQUE DE PRIORITÉ:
1. SI instructions utilisateur → Respecte-les OBLIGATOIREMENT
2. PUIS utilise les ingrédients visibles dans la photo
3. PUIS complète avec les ingrédients de base

RÈGLES STRICTES:
✅ RESPECTE ABSOLUMENT les instructions utilisateur
✅ Utilise les ingrédients de la photo pour compléter
✅ Ajoute des ingrédients de base si nécessaire

❌ N'INVENTE PAS d'ingrédients spécifiques non mentionnés/visibles
❌ NE REMPLACE PAS les ingrédients demandés par l'utilisateur
❌ N'IGNORE PAS les instructions utilisateur

Retourne UNIQUEMENT un objet JSON valide:
{{
    "title": "Nom créatif basé sur les instructions ET/OU ingrédients",
    "servings": {req.servings},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingrédient", "quantity": 200, "unit": "g", "category": "légumes"}}
    ],
    "steps": [
        "Préparation: Préparer tous les ingrédients...",
        "Cuisson: Chauffer et combiner...",
        "Finition et service..."
    ],
    "equipment": ["poêle", "casserole"],
    "tags": ["vide-frigo", "personnalisé"]
}}

Utilise le système {unit_system}.
Catégories: légumes, fruits, viandes, poissons, produits laitiers, sec, condiments, conserves."""
        
        system_prompt = "Tu es un chef expert spécialisé dans les recettes 'vide-frigo' personnalisées. Tu respectes TOUJOURS les instructions de l'utilisateur en priorité, puis tu analyses la photo pour compléter avec les ingrédients disponibles."

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


class ChatRequest(BaseModel):
    message: str
    conversation_history: List[dict] = Field(default_factory=list)
    user_context: dict = Field(default_factory=dict)
    language: str = "fr"


class ChatResponse(BaseModel):
    reply: str
    detected_mode: str
    requires_confirmation: bool = False
    suggested_actions: List[str] = Field(default_factory=list)
    modified_recipe: Optional[Recipe] = None
    pending_recipe_modification: Optional[Recipe] = None  # Recipe awaiting user confirmation
    modification_type: Optional[str] = None  # "replace_ingredient", "adjust_portions", "add_meal"
    modification_metadata: Optional[dict] = None  # Additional info (e.g., weekday, meal_type for add_meal)
    member_data: Optional[dict] = None  # For adding family members


class AddMemberRequest(BaseModel):
    name: str
    allergens: List[str] = Field(default_factory=list)
    preferences: List[str] = Field(default_factory=list)
    dislikes: List[str] = Field(default_factory=list)


class AddMemberResponse(BaseModel):
    success: bool
    message: str
    member: Optional[dict] = None


def detect_agent_mode(message: str, conversation_history: List[dict]) -> str:
    """Detect which agent mode should be used based on the message context."""
    message_lower = message.lower()
    
    # Check for recipe Q&A keywords
    recipe_qa_keywords = [
        # French
        'recette', 'substituer', 'remplacer', 'conversion', 'convertir', 'portion', 'portions',
        'ingrédient', 'ingrédients', 'étape', 'étapes', 'cuisson', 'température',
        'comment faire', 'comment cuire', 'combien de', 'ajuster',
        # English
        'recipe', 'substitute', 'replace', 'conversion', 'convert', 'portion', 'portions',
        'ingredient', 'ingredients', 'step', 'steps', 'cooking', 'temperature',
        'how to', 'how do i', 'how much', 'adjust'
    ]
    
    # Check conversation history for context (look at last 5 messages for better context)
    has_recipe_context = any('recipe' in str(msg).lower() or 'recette' in str(msg).lower() 
                            for msg in conversation_history[-5:] if msg)
    
    # Decision logic - ONLY recipe_qa and nutrition_coach modes
    if any(keyword in message_lower for keyword in recipe_qa_keywords) or has_recipe_context:
        return "recipe_qa"
    else:
        return "nutrition_coach"


def detect_member_addition_intent(message: str, conversation_history: List[dict]) -> bool:
    """Detect if the user wants to add a family member."""
    message_lower = message.lower()
    
    # Keywords indicating member addition
    addition_keywords_fr = ['ajoute', 'ajouter', 'nouveau membre', 'nouvelle personne', 'un membre', 'une personne']
    addition_keywords_en = ['add', 'adding', 'new member', 'new person', 'another member', 'another person']
    
    # Keywords that indicate we're asking member questions
    member_question_keywords_fr = ['quel est son nom', 'quelles sont ses allergies', "qu'est-ce qu'il n'aime pas", 'quels aliments']
    member_question_keywords_en = ['what is their name', 'what are their allergies', 'what foods do they dislike', 'do they have any']
    
    # Check if this is about adding someone
    is_adding = (
        any(keyword in message_lower for keyword in addition_keywords_fr) or
        any(keyword in message_lower for keyword in addition_keywords_en)
    )
    
    # CRITICAL: Check recent conversation history for context
    # If agent was asking member-specific questions, we're still adding a member
    if not is_adding and conversation_history:
        # Look at last 5 messages for better context
        for msg in conversation_history[-5:]:
            if msg and not msg.get("isFromUser"):
                msg_content = str(msg.get("content", "")).lower()
                # Check if agent was asking about adding a member OR asking member questions
                if (any(keyword in msg_content for keyword in addition_keywords_fr + addition_keywords_en) or
                    any(keyword in msg_content for keyword in member_question_keywords_fr + member_question_keywords_en)):
                    is_adding = True
                    print(f"🔒 Still in member addition context from agent question: {msg_content[:100]}")
                    break
    
    return is_adding


def extract_member_data_from_conversation(conversation_history: List[dict], current_message: str, language: str) -> Optional[dict]:
    """Extract member data from the conversation history."""
    member_data = {
        "name": None,
        "allergens": [],
        "dislikes": []
    }
    
    # Combine all messages into analysis
    all_messages = []
    for msg in conversation_history[-10:]:
        if msg.get("isFromUser"):
            all_messages.append(msg.get("content", ""))
    all_messages.append(current_message)
    
    # Simple extraction logic
    conversation_text = " ".join(all_messages).lower()
    
    # Look for name patterns
    name_patterns_fr = ['nom', "s'appelle", 'appelle', 'prenom', 'prénom']
    name_patterns_en = ['name', 'called', 'named']
    
    # Look for allergy patterns
    allergy_patterns_fr = ['allergie', 'allergies', 'allergique', 'intolerance', 'intolérance']
    allergy_patterns_en = ['allergy', 'allergies', 'allergic', 'intolerance', 'intolerant']
    
    # Look for dislike patterns
    dislike_patterns_fr = ["n'aime pas", "aime pas", 'déteste', 'éviter', 'préfère pas', 'preference']
    dislike_patterns_en = ["doesn't like", "don't like", 'dislike', 'dislikes', 'avoid', 'avoids', 'hate', 'hates', 'preference']
    
    # Common allergens
    common_allergens = ['gluten', 'lactose', 'noix', 'nuts', 'arachides', 'peanuts', 'fruits de mer', 'seafood', 'poisson', 'fish', 'oeufs', 'eggs', 'soja', 'soy']
    
    # Try to extract data from messages
    for msg_text in all_messages:
        msg_lower = msg_text.lower()
        words = msg_text.split()
        
        # Try to find name
        if not member_data["name"]:
            # Pattern 1: "1, Fred, 2..." format
            if len(words) >= 2 and words[0].strip('.,!?;:').isdigit():
                # User is answering multiple questions at once with numbers
                for i, word in enumerate(words):
                    cleaned = word.strip('.,!?;:')
                    if cleaned.isalpha() and len(cleaned) > 1 and cleaned[0].isupper():
                        member_data["name"] = cleaned
                        break
            # Pattern 2: Single capitalized word
            elif len(words) == 1 and words[0][0].isupper():
                member_data["name"] = words[0].strip('.,!?;:')
            # Pattern 3: Name pattern followed by name
            elif any(pattern in msg_lower for pattern in name_patterns_fr + name_patterns_en):
                for pattern in name_patterns_fr + name_patterns_en:
                    if pattern in msg_lower:
                        idx = msg_lower.find(pattern)
                        remaining = msg_text[idx + len(pattern):].strip()
                        if remaining:
                            potential_name = remaining.split()[0].strip('.,!?;:')
                            if len(potential_name) > 1 and potential_name.isalpha():
                                member_data["name"] = potential_name.capitalize()
                                break
        
        # Try to find allergies
        # Pattern 1: Check for "no allergy" / "pas d'allergie"
        no_allergy_keywords = ['pas d', 'no ', 'aucune', 'none', 'non', 'nothing']
        if any(keyword in msg_lower for keyword in no_allergy_keywords) and any(pattern in msg_lower for pattern in allergy_patterns_fr + allergy_patterns_en):
            # User said no allergies - leave empty
            pass
        elif any(pattern in msg_lower for pattern in allergy_patterns_fr + allergy_patterns_en):
            # Check for common allergens
            for allergen in common_allergens:
                if allergen in msg_lower and allergen not in [a.lower() for a in member_data["allergens"]]:
                    member_data["allergens"].append(allergen)
        
        # Try to find dislikes
        # Pattern 1: "pas de X" or "no X"
        # Pattern 2: Simple food mention after dislike question
        common_foods = ['carotte', 'carottes', 'carrots', 'brocoli', 'broccoli', 'courgette', 'courgettes', 'zucchini', 
                       'tomate', 'tomates', 'tomatoes', 'oignon', 'oignons', 'onions', 'poivron', 'poivrons', 'peppers',
                       'épinard', 'épinards', 'spinach', 'chou', 'cabbage']
        
        # Check if this message mentions dislikes
        mentions_dislikes = any(pattern in msg_lower for pattern in dislike_patterns_fr + dislike_patterns_en)
        
        # Also check if previous message asked about dislikes
        asked_about_dislikes = False
        for prev_msg in conversation_history[-3:]:
            if prev_msg and not prev_msg.get("isFromUser"):
                prev_content = str(prev_msg.get("content", "")).lower()
                if any(pattern in prev_content for pattern in dislike_patterns_fr + dislike_patterns_en):
                    asked_about_dislikes = True
                    break
        
        if mentions_dislikes or asked_about_dislikes:
            # Check for "nothing" / "rien" / "aucun"
            no_dislike_keywords = ['rien', 'nothing', 'aucun', 'aucune', 'none', 'non']
            has_no_dislikes = any(keyword in msg_lower for keyword in no_dislike_keywords)
            
            if not has_no_dislikes:
                # Extract food items
                for food in common_foods:
                    if food in msg_lower and food not in [d.lower() for d in member_data["dislikes"]]:
                        member_data["dislikes"].append(food)
    
    # Check if we have enough data
    if member_data["name"]:
        return member_data
    
    return None


def detect_recipe_modification_request(message: str, user_context: dict) -> tuple:
    """Detect if user is requesting a recipe modification and extract details.
    Returns: (is_modification, is_question, recipe_to_modify, message, modification_type, weekday, meal_type)
    """
    message_lower = message.lower()
    
    # Check if this is a QUESTION about possibility (vs a request for action)
    # Questions about possibility: "Est-ce que JE PEUX...?", "Can I...?"
    # Requests for action: "Peux-TU...?", "Can YOU...?", "Remplace...", etc.
    
    question_about_possibility_fr = ['est-ce que', 'est ce que', 'puis-je', 'peux-je', 'peut-on', 'pourrais-je', 'devrais-je', 'dois-je']
    question_about_possibility_en = ['can i', 'could i', 'should i', 'is it possible', 'would it be', 'may i']
    
    # Request for action indicators (the agent should DO something)
    action_request_fr = ['peux-tu', 'peux tu', 'peut-tu', 'peut tu', 'pourrais-tu', 'pourrais tu', 'veux-tu', 'veux tu']
    action_request_en = ['can you', 'could you', 'would you', 'will you', 'please']
    
    # Check if it's a question about possibility
    is_question = any(indicator in message_lower for indicator in question_about_possibility_fr + question_about_possibility_en)
    
    # If it's a request for action, treat as command (not a question)
    is_action_request = any(indicator in message_lower for indicator in action_request_fr + action_request_en)
    if is_action_request:
        is_question = False  # Override - this is a command, not a question
    
    # Keywords indicating modification
    modification_keywords = {
        'fr': ['remplace', 'remplacer', 'substitue', 'substituer', 'change', 'changer', 'modifie', 'modifier', 'ajuste', 'ajuster', 'double', 'triple'],
        'en': ['replace', 'substitute', 'change', 'modify', 'adjust', 'swap', 'double', 'triple']
    }
    
    is_modification = any(
        keyword in message_lower 
        for keywords in modification_keywords.values() 
        for keyword in keywords
    )
    
    if not is_modification:
        return (False, False, None, None, None, None, None)
    
    # Determine modification type
    modification_type = "replace_ingredient"  # default
    
    # Check for portion adjustment
    portion_keywords = ['portion', 'portions', 'servings', 'double', 'triple', 'moitié', 'half', 'personnes', 'people']
    if any(keyword in message_lower for keyword in portion_keywords):
        modification_type = "adjust_portions"
    
    # Try to find which recipe from context
    recipe_to_modify = None
    found_weekday = None
    found_meal_type = None
    
    # Check current plan recipes
    if user_context.get("current_plan"):
        for day, meals in user_context["current_plan"].items():
            for meal in meals:
                recipe_title = meal.get("title", "").lower()
                # Check if recipe title is mentioned in message
                if recipe_title in message_lower or any(word in recipe_title for word in message_lower.split() if len(word) > 4):
                    recipe_to_modify = meal
                    found_weekday = day
                    found_meal_type = meal.get("meal_type")
                    break
            if recipe_to_modify:
                break
    
    # If not found in plan, check recent recipes
    if not recipe_to_modify and user_context.get("recent_recipes"):
        for recipe in user_context["recent_recipes"]:
            recipe_title = recipe.get("title", "").lower()
            if recipe_title in message_lower or any(word in recipe_title for word in message_lower.split() if len(word) > 4):
                recipe_to_modify = recipe
                break
    
    # If not found, check favorites
    if not recipe_to_modify and user_context.get("favorite_recipes"):
        for recipe in user_context["favorite_recipes"]:
            recipe_title = recipe.get("title", "").lower()
            if recipe_title in message_lower or any(word in recipe_title for word in message_lower.split() if len(word) > 4):
                recipe_to_modify = recipe
                break
    
    return (True, is_question, recipe_to_modify, message, modification_type, found_weekday, found_meal_type)


def detect_add_meal_request(message: str) -> tuple:
    """Detect if user wants to add a meal to the plan.
    Returns: (is_add_meal, meal_type, weekday)
    """
    message_lower = message.lower()
    
    # Keywords indicating meal addition
    add_keywords_fr = ['ajoute', 'ajouter', 'crée', 'créer', 'génère', 'générer', 'propose', 'proposer']
    add_keywords_en = ['add', 'create', 'generate', 'suggest', 'propose']
    
    is_add_meal = any(keyword in message_lower for keyword in add_keywords_fr + add_keywords_en)
    
    if not is_add_meal:
        return (False, None, None)
    
    # Extract meal type
    meal_type = None
    meal_keywords = {
        'BREAKFAST': ['breakfast', 'petit-déjeuner', 'petit déjeuner', 'déjeuner'],
        'LUNCH': ['lunch', 'dîner', 'midi'],
        'DINNER': ['dinner', 'souper', 'soir', 'diner']
    }
    
    for mtype, keywords in meal_keywords.items():
        if any(keyword in message_lower for keyword in keywords):
            meal_type = mtype
            break
    
    # Extract weekday
    weekday = None
    weekday_keywords = {
        'Mon': ['lundi', 'monday', 'mon'],
        'Tue': ['mardi', 'tuesday', 'tue'],
        'Wed': ['mercredi', 'wednesday', 'wed'],
        'Thu': ['jeudi', 'thursday', 'thu'],
        'Fri': ['vendredi', 'friday', 'fri'],
        'Sat': ['samedi', 'saturday', 'sat'],
        'Sun': ['dimanche', 'sunday', 'sun']
    }
    
    for day, keywords in weekday_keywords.items():
        if any(keyword in message_lower for keyword in keywords):
            weekday = day
            break
    
    return (is_add_meal, meal_type, weekday)


def detect_user_confirmation(message: str, language: str) -> bool:
    """Detect if user is confirming a pending action."""
    message_lower = message.lower().strip()
    
    confirmation_keywords_fr = ['oui', 'ok', 'confirme', 'confirm', 'accepte', 'accept', 'd\'accord', 'daccord', 'parfait', 'vas-y', 'vas y', 'go']
    confirmation_keywords_en = ['yes', 'ok', 'confirm', 'accept', 'go ahead', 'sure', 'perfect', 'agreed']
    
    all_keywords = confirmation_keywords_fr + confirmation_keywords_en
    
    # Check for exact matches or if message starts with confirmation
    is_confirmation = (
        message_lower in all_keywords or
        any(message_lower.startswith(keyword) for keyword in all_keywords)
    )
    
    return is_confirmation


@app.post("/ai/chat", response_model=ChatResponse)
async def ai_chat(req: ChatRequest):
    """Conversational agent with 3 modes: onboarding, recipe Q&A, and nutrition coach."""
    
    # Check if user has premium access
    has_premium = req.user_context.get("has_premium", False)
    if not has_premium:
        raise HTTPException(status_code=403, detail="Premium subscription required for conversational agent")
    
    # Check if user is confirming a previous action
    is_confirmation = detect_user_confirmation(req.message, req.language)
    
    # Check if this is a recipe modification request
    is_modification, is_question, recipe_to_modify, modification_request, modification_type, found_weekday, found_meal_type = detect_recipe_modification_request(req.message, req.user_context)
    
    # Check if this is an add meal request - CRITICAL for meal plan integration
    is_add_meal, meal_type, weekday = detect_add_meal_request(req.message)
    
    print(f"\n🔍 ADD MEAL DETECTION:")
    print(f"  is_add_meal: {is_add_meal}")
    print(f"  meal_type: {meal_type}")
    print(f"  weekday: {weekday}")
    print(f"  message: {req.message}")
    
    # Detect which mode to use
    detected_mode = detect_agent_mode(req.message, req.conversation_history)
    
    # Build system prompt based on mode
    if detected_mode == "recipe_qa":
        if req.language == "en":
            system_prompt = """You are a knowledgeable culinary assistant for Planea, helping users with recipe questions.


You can help with:
- Ingredient substitutions
- Unit conversions
- Portion adjustments
- Step-by-step cooking instructions
- Cooking techniques and tips

Access to user's context:
- Recent recipes from meal plans
- Favorite recipes
- Recipe history

Be specific and practical in your answers. If the user mentions a specific recipe, reference it by name."""
        else:
            system_prompt = """Tu es un assistant culinaire compétent pour Planea, aidant les utilisateurs avec leurs questions de recettes.

Tu peux aider avec:
- Substitutions d'ingrédients
- Conversions d'unités
- Ajustement des portions
- Instructions de cuisson pas-à-pas
- Techniques et conseils de cuisine

Accès au contexte de l'utilisateur:
- Recettes récentes des plans de repas
- Recettes favorites
- Historique des recettes

Sois spécifique et pratique dans tes réponses. Si l'utilisateur mentionne une recette spécifique, référence-la par son nom."""
    
    else:  # nutrition_coach
        if req.language == "en":
            system_prompt = """You are a nutrition coach for Planea, providing general nutrition information and calculations.

CRITICAL: You MUST include this disclaimer in EVERY response:
"ℹ️ This information is for general purposes only and does not replace professional medical advice."

You can provide:
- General nutrition information
- Healthy eating tips
- Food group information
- Balanced meal suggestions
- CALORIE CALCULATIONS for recipes based on ingredients and quantities
- Macronutrient estimates (proteins, carbs, fats)
- Nutritional breakdowns per serving
- MEAL PLAN ANALYSIS: You have access to the user's current meal plan in the context below. You CAN analyze it for nutritional balance, variety, and provide feedback.

CALORIE CALCULATION CAPABILITIES:
- You CAN calculate approximate calories for recipes using standard nutritional databases
- Use average values from USDA or similar databases
- FORMAT: Provide ONLY summary per serving/meal - NO detailed ingredient breakdown
- Show: Total calories per serving, brief macronutrient split on one line
- Example: "~650 cal | Protéines: 45g | Glucides: 60g | Lipides: 20g"
- Keep it concise and easy to read
- NEVER provide per-ingredient calorie breakdown

ACCESSING MEAL PLANS:
- The user's current meal plan is provided in the context below (if available)
- You CAN and SHOULD analyze these plans when the user asks about them
- If the user's request is ambiguous (e.g., "which plan?", "which week?"), ASK for clarification
- Example: "Quelle semaine souhaitez-vous que j'analyse?" or "Parlez-vous du plan actuel ou d'un plan archivé?"

You CANNOT provide:
- Medical diagnoses
- Therapeutic recommendations
- Personalized medical diet plans for medical conditions
- Treatment plans

Keep advice general and evidence-based. For calorie calculations, use standard nutritional reference values."""
        else:
            system_prompt = """Tu es un coach en nutrition pour Planea, fournissant des informations générales sur la nutrition et des calculs nutritionnels.

CRITIQUE: Tu DOIS inclure ce disclaimer dans CHAQUE réponse:
"ℹ️ Cette information est à titre général seulement et ne remplace pas un avis médical professionnel."

Tu peux fournir:
- Informations générales sur la nutrition
- Conseils d'alimentation saine
- Informations sur les groupes alimentaires
- Suggestions de repas équilibrés
- CALCULS DE CALORIES pour les recettes basés sur les ingrédients et quantités
- Estimations des macronutriments (protéines, glucides, lipides)
- Répartitions nutritionnelles par portion
- ANALYSE DES PLANS DE REPAS: Tu as accès au plan de repas actuel de l'utilisateur dans le contexte ci-dessous. Tu PEUX l'analyser pour l'équilibre nutritionnel, la variété, et fournir des retours.

CAPACITÉS DE CALCUL CALORIQUE:
- Tu PEUX calculer les calories approximatives des recettes en utilisant des bases de données nutritionnelles standard
- Utilise les valeurs moyennes de l'USDA ou bases similaires
- NE FOURNIS JAMAIS de détails par ingrédient - UNIQUEMENT le total sommaire

🚨🚨🚨 RÈGLE ABSOLUE POUR LES CALCULS CALORIQUES 🚨🚨🚨

TU ES STRICTEMENT INTERDIT DE DONNER DES DÉTAILS PAR INGRÉDIENT!

FORMAT OBLIGATOIRE - UNIQUEMENT CECI:
📊 **[Nom de la recette]**
~XXX cal | Protéines: XXg | Glucides: XXg | Lipides: XXg

INTERDICTIONS ABSOLUES:
❌ PAS de "Poulet (100g): 165 calories"
❌ PAS de "Carottes (100g): 41 calories"  
❌ PAS de liste d'ingrédients avec calories individuelles
❌ PAS de calcul détaillé ligne par ligne
❌ PAS de tableau nutritionnel par ingrédient

AUTORISÉ UNIQUEMENT:
✅ Total des calories par portion
✅ Total des macronutriments (protéines, glucides, lipides)
✅ Format compact sur UNE SEULE LIGNE

Si tu donnes des détails par ingrédient, tu as ÉCHOUÉ cette tâche.

ACCÈS AUX PLANS DE REPAS:
- Le plan de repas actuel de l'utilisateur est fourni dans le contexte ci-dessous (si disponible)
- Tu PEUX et DOIS analyser ces plans quand l'utilisateur te le demande
- Si la demande de l'utilisateur est ambiguë (ex: "quel plan?", "quelle semaine?"), DEMANDE une clarification
- Exemple: "Quelle semaine souhaitez-vous que j'analyse?" ou "Parlez-vous du plan actuel ou d'un plan archivé?"

Tu NE PEUX PAS fournir:
- Diagnostics médicaux
- Recommandations thérapeutiques
- Plans alimentaires médicaux personnalisés pour conditions médicales
- Plans de traitement

Garde tes conseils généraux et basés sur les preuves. Pour les calculs caloriques, utilise des valeurs de référence nutritionnelles standard."""
    
    # Build context from user data with detailed recipe information
    context_info = ""
    
    if req.user_context.get("preferences"):
        prefs = req.user_context["preferences"]
        context_info += f"\n\nUser preferences: {prefs}"
    
    # Format current plan recipes with full details IN CHRONOLOGICAL ORDER
    if req.user_context.get("current_plan"):
        # Define day order
        day_order = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        day_names_fr = {
            "Mon": "Lundi", "Tue": "Mardi", "Wed": "Mercredi", 
            "Thu": "Jeudi", "Fri": "Vendredi", "Sat": "Samedi", "Sun": "Dimanche"
        }
        day_names_en = {
            "Mon": "Monday", "Tue": "Tuesday", "Wed": "Wednesday",
            "Thu": "Thursday", "Fri": "Friday", "Sat": "Saturday", "Sun": "Sunday"
        }
        
        context_info += "\n\n📅 PLAN ACTUEL - Vous avez ACCÈS COMPLET à ces recettes:\n"
        
        # Sort days chronologically
        sorted_days = sorted(
            req.user_context["current_plan"].items(),
            key=lambda x: day_order.index(x[0]) if x[0] in day_order else 999
        )
        
        for day_abbr, meals in sorted_days:
            # Use full day name
            day_name = day_names_fr.get(day_abbr, day_abbr) if req.language == "fr" else day_names_en.get(day_abbr, day_abbr)
            context_info += f"\n{day_name}:"
            for meal in meals:
                meal_type_fr = {"BREAKFAST": "Déjeuner", "LUNCH": "Dîner", "DINNER": "Souper"}.get(meal.get('meal_type', 'Repas'), meal.get('meal_type', 'Repas'))
                meal_type_en = {"BREAKFAST": "Breakfast", "LUNCH": "Lunch", "DINNER": "Dinner"}.get(meal.get('meal_type', 'Meal'), meal.get('meal_type', 'Meal'))
                meal_type_display = meal_type_fr if req.language == "fr" else meal_type_en
                
                context_info += f"\n  • {meal_type_display}: {meal.get('title', 'Unknown')}"
                if meal.get('servings') and meal.get('total_minutes'):
                    context_info += f" ({meal.get('servings')} portions, {meal.get('total_minutes')} min)"
    
    if req.user_context.get("recent_recipes"):
        recipes = req.user_context["recent_recipes"]
        context_info += f"\n\n📝 Recent recipes (access available): {len(recipes)} recipes"
        for idx, recipe in enumerate(recipes[:5]):  # Show first 5
            context_info += f"\n  {idx+1}. {recipe.get('title', 'Unknown')} ({recipe.get('servings', 'N/A')} servings)"
    
    if req.user_context.get("favorite_recipes"):
        favorites = req.user_context["favorite_recipes"]
        context_info += f"\n\n⭐ Favorite recipes (access available): {len(favorites)} recipes"
        for idx, recipe in enumerate(favorites[:5]):  # Show first 5
            context_info += f"\n  {idx+1}. {recipe.get('title', 'Unknown')} ({recipe.get('servings', 'N/A')} servings)"
    
    if not context_info.strip():
        context_info = "\n\nNo recipe data currently available in context."
    
    # Build conversation context
    messages = [
        {"role": "system", "content": system_prompt + context_info}
    ]
    
    # Add conversation history (last 10 messages)
    for msg in req.conversation_history[-10:]:
        messages.append({
            "role": "user" if msg.get("isFromUser") else "assistant",
            "content": msg.get("content", "")
        })
    
    # Add current message
    messages.append({"role": "user", "content": req.message})
    
    try:
        # Call OpenAI
        response = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            temperature=0.7,
            max_tokens=800
        )
        
        reply = response.choices[0].message.content.strip()
        
        # Check if onboarding is asking for confirmation
        requires_confirmation = False
        if detected_mode == "onboarding":
            confirmation_keywords = ["correct", "semble correct", "look correct", "save", "sauvegarder"]
            requires_confirmation = any(keyword in reply.lower() for keyword in confirmation_keywords)
        
        # Generate context-aware suggested actions based on mode and message
        suggested_actions = []
        message_lower = req.message.lower()
        
        if detected_mode == "onboarding":
            # Suggest common answers for onboarding questions
            if "combien" in message_lower or "how many" in message_lower:
                suggested_actions = ["2 personnes", "3 personnes", "4 personnes", "5+ personnes"] if req.language == "fr" else ["2 people", "3 people", "4 people", "5+ people"]
            elif "allergi" in message_lower:
                suggested_actions = ["Aucune", "Lactose", "Gluten", "Noix", "Fruits de mer"] if req.language == "fr" else ["None", "Lactose", "Gluten", "Nuts", "Seafood"]
            elif "temps" in message_lower or "time" in message_lower:
                suggested_actions = ["30 min semaine, 60 min weekend", "45 min semaine, 90 min weekend"] if req.language == "fr" else ["30 min weekday, 60 min weekend", "45 min weekday, 90 min weekend"]
            elif "unités" in message_lower or "units" in message_lower:
                suggested_actions = ["Métrique", "Impérial"] if req.language == "fr" else ["Metric", "Imperial"]
            elif "budget" in message_lower:
                suggested_actions = ["50-75$ / semaine", "75-100$ / semaine", "100-150$ / semaine", "Pas de limite"] if req.language == "fr" else ["$50-75 / week", "$75-100 / week", "$100-150 / week", "No limit"]
        elif detected_mode == "recipe_qa":
            if req.language == "en":
                suggested_actions = ["Substitute an ingredient", "Convert measurements", "Adjust servings", "Explain a step"]
            else:
                suggested_actions = ["Substituer un ingrédient", "Convertir mesures", "Ajuster portions", "Expliquer une étape"]
        elif detected_mode == "nutrition_coach":
            if req.language == "fr":
                suggested_actions = ["Idées repas équilibrés", "Besoins en protéines", "Portions légumes", "Horaires repas"]
            else:
                suggested_actions = ["Balanced meal ideas", "Protein needs", "Vegetable portions", "Meal timing"]
        
        # Handle ADD MEAL request - Generate and add to plan immediately
        if is_add_meal and meal_type and weekday:
            print(f"\n🍽️  ADDING MEAL TO PLAN")
            print(f"  Weekday: {weekday}, Meal Type: {meal_type}")
            print(f"  User message: {req.message}")
            
            try:
                # Extract recipe description from user's message
                # Remove add keywords and day/meal keywords to get the actual dish request
                recipe_description = req.message.lower()
                
                # Remove common keywords
                remove_keywords = [
                    'ajoute', 'ajouter', 'crée', 'créer', 'génère', 'générer', 'propose', 'proposer',
                    'add', 'create', 'generate', 'suggest', 'propose',
                    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche',
                    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
                    'petit-déjeuner', 'petit déjeuner', 'déjeuner', 'dîner', 'souper',
                    'breakfast', 'lunch', 'dinner',
                    'pour', 'for', 'le', 'la', 'un', 'une', 'a', 'an', 'au', 'à', 'at', 'on',
                    'midi', 'soir', 'matin', 'morning', 'noon', 'evening'
                ]
                
                for keyword in remove_keywords:
                    recipe_description = recipe_description.replace(keyword, ' ')
                
                recipe_description = ' '.join(recipe_description.split()).strip()
                
                print(f"  Extracted recipe description: '{recipe_description}'")
                
                # If we have a description, use it like ai_recipe endpoint
                # Otherwise fall back to generic generation
                if recipe_description and len(recipe_description) > 2:
                    # Use the recipe generation similar to /ai/recipe endpoint
                    recipe_request = RecipeRequest(
                        idea=recipe_description,
                        constraints=req.user_context.get("preferences", {}).get("constraints", {}),
                        servings=4,
                        units=req.user_context.get("preferences", {}).get("units", "METRIC"),
                        language=req.language,
                        preferences=req.user_context.get("preferences", {})
                    )
                    recipe = await ai_recipe(recipe_request)
                else:
                    # Fallback to generic generation based on meal_type
                    recipe = await generate_recipe_with_openai(
                        meal_type=meal_type,
                        constraints=req.user_context.get("preferences", {}).get("constraints", {}),
                        units=req.user_context.get("preferences", {}).get("units", "METRIC"),
                        servings=4,
                        previous_recipes=None,
                        diversity_seed=0,
                        language=req.language,
                        preferences=req.user_context.get("preferences", {}),
                        suggested_protein=None,
                        other_plan_proteins=[]
                    )
                
                # Mark ingredients on sale if feature is enabled
                await mark_ingredients_on_sale(recipe, req.user_context.get("preferences", {}))
                
                # Return the recipe as PENDING - user needs to confirm
                print(f"  ✅ Recipe generated: {recipe.title}")
                print(f"  📋 Returning as PENDING for user confirmation")
                
                if req.language == "fr":
                    day_names = {
                        "Mon": "Lundi", "Tue": "Mardi", "Wed": "Mercredi",
                        "Thu": "Jeudi", "Fri": "Vendredi", "Sat": "Samedi", "Sun": "Dimanche"
                    }
                    # Terminologie canadienne-française: dîner = midi, souper = soir
                    meal_names = {
                        "BREAKFAST": "petit-déjeuner", "LUNCH": "dîner", "DINNER": "souper"
                    }
                    
                    # Format the response with recipe card
                    reply = f"""📋 **{recipe.title}**

🍽️ Pour: {day_names.get(weekday, weekday)} {meal_names.get(meal_type, meal_type)}
👥 Portions: {recipe.servings}
⏱️ Temps: {recipe.total_minutes} minutes

Voulez-vous l'ajouter à votre plan?"""
                else:
                    day_names = {
                        "Mon": "Monday", "Tue": "Tuesday", "Wed": "Wednesday",
                        "Thu": "Thursday", "Fri": "Friday", "Sat": "Saturday", "Sun": "Sunday"
                    }
                    meal_names = {
                        "BREAKFAST": "breakfast", "LUNCH": "lunch", "DINNER": "dinner"
                    }
                    
                    reply = f"""📋 **{recipe.title}**

🍽️ For: {day_names.get(weekday, weekday)} {meal_names.get(meal_type, meal_type)}
👥 Servings: {recipe.servings}
⏱️ Time: {recipe.totalMinutes} minutes

Would you like to add it to your plan?"""
                
                return ChatResponse(
                    reply=reply,
                    detected_mode=detected_mode,
                    requires_confirmation=False,
                    suggested_actions=[],
                    modified_recipe=recipe,  # Return the recipe for pending storage
                    pending_recipe_modification=None,
                    modification_type="pending_add_meal",  # Changed to pending!
                    modification_metadata={
                        "weekday": weekday,
                        "meal_type": meal_type
                    },
                    member_data=None
                )
                
            except Exception as e:
                print(f"  ❌ Error generating recipe for add_meal: {e}")
                if req.language == "fr":
                    reply = f"⚠️ Désolé, je n'ai pas pu créer la recette pour {weekday} {meal_type}. Veuillez réessayer."
                else:
                    reply = f"⚠️ Sorry, I couldn't create the recipe for {weekday} {meal_type}. Please try again."
        
        # Handle ADD MEAL request when missing information - Ask for clarification
        elif is_add_meal and (not meal_type or not weekday):
            print(f"\n📋 ADD MEAL - MISSING INFO")
            print(f"  Missing: {'meal_type' if not meal_type else ''} {'weekday' if not weekday else ''}")
            
            # Ask for missing information
            if not weekday and not meal_type:
                if req.language == "fr":
                    reply = "Pour quel jour et quel repas souhaitez-vous ajouter cette recette? (Par exemple: 'lundi dîner' ou 'jeudi souper')"
                else:
                    reply = "Which day and meal would you like to add this recipe to? (For example: 'Monday lunch' or 'Thursday dinner')"
            elif not weekday:
                if req.language == "fr":
                    reply = "Pour quel jour souhaitez-vous ajouter ce repas? (lundi, mardi, mercredi, jeudi, vendredi, samedi ou dimanche)"
                else:
                    reply = "Which day would you like to add this meal? (Monday, Tuesday, Wednesday, Thursday, Friday, Saturday or Sunday)"
            elif not meal_type:
                if req.language == "fr":
                    reply = "Pour quel type de repas? (déjeuner, dîner ou souper)"
                else:
                    reply = "Which meal type? (breakfast, lunch or dinner)"
            
            return ChatResponse(
                reply=reply,
                detected_mode=detected_mode,
                requires_confirmation=False,
                suggested_actions=[],
                modified_recipe=None,
                pending_recipe_modification=None,
                modification_type=None,
                modification_metadata=None,
                member_data=None
            )
        
        # Handle recipe modifications with confirmation flow
        modified_recipe = None
        pending_recipe_modification = None
        modification_metadata = None
        
        # Check if there's a pending modification in conversation history
        has_pending_modification = False
        for msg in req.conversation_history[-3:]:
            if msg and not msg.get("isFromUser"):
                msg_content = str(msg.get("content", "")).lower()
                # Check if agent asked for confirmation
                if ("voulez-vous" in msg_content or "would you like" in msg_content) and ("modif" in msg_content or "remplace" in msg_content or "ajust" in msg_content):
                    has_pending_modification = True
                    break
        
        if is_confirmation and has_pending_modification:
            # User is confirming a pending modification
            # Look for the modification details in history
            print(f"\n✅ User confirmed modification")
            # Re-detect the original modification request from history
            for msg in req.conversation_history[-5:]:
                if msg and msg.get("isFromUser"):
                    msg_content = msg.get("content", "")
                    is_mod, is_q, recipe, mod_req, mod_type, wd, mt = detect_recipe_modification_request(msg_content, req.user_context)
                    if is_mod and recipe:
                        # Apply the modification now
                        try:
                            print(f"  Applying modification: {mod_req}")
                            # Generate the modified recipe
                            modification_prompt = f"""The user wants to modify this recipe:
                
Title: {recipe.get('title')}
Current servings: {recipe.get('servings', 4)}
Current ingredients: {recipe.get('ingredients', [])}
Current steps: {recipe.get('steps', [])}

User's modification request: "{mod_req}"

Generate a MODIFIED version of this recipe that implements the user's request. 
Keep the same title unless the modification fundamentally changes the dish.
Keep the structure and format identical to the original.
"""
                            
                            if req.language == "en":
                                full_prompt = f"""{modification_prompt}

Return ONLY a valid JSON object with this exact structure:
{{
    "title": "Recipe title (keep original unless fundamentally changed)",
    "servings": {recipe.get('servings', 4)},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingredient", "quantity": 200, "unit": "g", "category": "vegetables"}}
    ],
    "steps": [
        "Step 1...",
        "Step 2..."
    ],
    "equipment": ["pan", "pot"],
    "tags": ["modified"]
}}

IMPORTANT: 
- Implement the exact modification requested by the user
- Keep the recipe coherent and complete
- Adjust quantities and steps as needed for the modification"""
                            else:
                                full_prompt = f"""{modification_prompt}

Retourne UNIQUEMENT un objet JSON valide avec cette structure exacte:
{{
    "title": "Titre de la recette (garder l'original sauf si changement fondamental)",
    "servings": {recipe.get('servings', 4)},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingrédient", "quantity": 200, "unit": "g", "category": "légumes"}}
    ],
    "steps": [
        "Étape 1...",
        "Étape 2..."
    ],
    "equipment": ["poêle", "casserole"],
    "tags": ["modifié"]
}}

IMPORTANT:
- Implémente EXACTEMENT la modification demandée par l'utilisateur
- Garde la recette cohérente et complète
- Ajuste les quantités et étapes selon la modification"""
                            
                            modification_response = await client.chat.completions.create(
                                model="gpt-4o-mini",
                                messages=[
                                    {"role": "system", "content": "Tu es un chef expert qui modifie des recettes selon les demandes des utilisateurs."},
                                    {"role": "user", "content": full_prompt}
                                ],
                                temperature=0.7,
                                max_tokens=1200
                            )
                            
                            content = modification_response.choices[0].message.content.strip()
                            
                            # Remove markdown code blocks
                            if content.startswith("```"):
                                content = content.split("```")[1]
                                if content.startswith("json"):
                                    content = content[4:]
                                content = content.strip()
                            
                            # Extract JSON
                            start_idx = content.find('{')
                            end_idx = content.rfind('}')
                            if start_idx != -1 and end_idx != -1:
                                content = content[start_idx:end_idx+1]
                            
                            recipe_data = json.loads(content)
                            
                            # Ensure all ingredients have required fields
                            for ingredient in recipe_data.get("ingredients", []):
                                if "unit" not in ingredient or not ingredient.get("unit"):
                                    ingredient["unit"] = "unité" if req.language == "fr" else "unit"
                                if "category" not in ingredient or not ingredient.get("category"):
                                    ingredient["category"] = "autre" if req.language == "fr" else "other"
                            
                            modified_recipe = Recipe(**recipe_data)
                            print(f"  ✅ Modification applied: {modified_recipe.title}")
                            
                            # Update reply to confirm
                            if req.language == "fr":
                                reply = "✅ Parfait! J'ai modifié la recette comme demandé. La liste d'épicerie a été mise à jour automatiquement."
                            else:
                                reply = "✅ Perfect! I've modified the recipe as requested. The shopping list has been updated automatically."
                            
                        except Exception as e:
                            print(f"  ❌ Error applying modification: {e}")
                            if req.language == "fr":
                                reply = "⚠️ Désolé, une erreur s'est produite lors de la modification de la recette."
                            else:
                                reply = "⚠️ Sorry, an error occurred while modifying the recipe."
                        break
        
        elif is_modification and not is_question and recipe_to_modify and not is_confirmation:
            # Direct modification command (not a question) - generate and ask for confirmation
            try:
                print(f"\n🔧 Recipe modification detected!")
                print(f"  Original recipe: {recipe_to_modify.get('title', 'Unknown')}")
                print(f"  Modification request: {req.message}")
                
                # Generate the proposed modification
                modification_prompt = f"""The user wants to modify this recipe:
                
Title: {recipe_to_modify.get('title')}
Current servings: {recipe_to_modify.get('servings', 4)}
Current ingredients: {recipe_to_modify.get('ingredients', [])}
Current steps: {recipe_to_modify.get('steps', [])}

User's modification request: "{req.message}"

Generate a MODIFIED version of this recipe that implements the user's request. 
Keep the same title unless the modification fundamentally changes the dish.
Keep the structure and format identical to the original.
"""
                
                # Build the full prompt
                if req.language == "en":
                    full_prompt = f"""{modification_prompt}

Return ONLY a valid JSON object with this exact structure:
{{
    "title": "Recipe title (keep original unless fundamentally changed)",
    "servings": {recipe_to_modify.get('servings', 4)},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingredient", "quantity": 200, "unit": "g", "category": "vegetables"}}
    ],
    "steps": [
        "Step 1...",
        "Step 2..."
    ],
    "equipment": ["pan", "pot"],
    "tags": ["modified"]
}}

IMPORTANT: Implement the exact modification requested"""
                else:
                    full_prompt = f"""{modification_prompt}

Retourne UNIQUEMENT un objet JSON valide avec cette structure exacte:
{{
    "title": "Titre de la recette",
    "servings": {recipe_to_modify.get('servings', 4)},
    "total_minutes": 30,
    "ingredients": [
        {{"name": "ingrédient", "quantity": 200, "unit": "g", "category": "légumes"}}
    ],
    "steps": [
        "Étape 1...",
        "Étape 2..."
    ],
    "equipment": ["poêle", "casserole"],
    "tags": ["modifié"]
}}

IMPORTANT: Implémente EXACTEMENT la modification demandée"""
                
                # Generate proposed modification
                modification_response = await client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=[
                        {"role": "system", "content": "Tu es un chef expert qui modifie des recettes selon les demandes des utilisateurs."},
                        {"role": "user", "content": full_prompt}
                    ],
                    temperature=0.7,
                    max_tokens=1200
                )
                
                content = modification_response.choices[0].message.content.strip()
                
                # Remove markdown code blocks
                if content.startswith("```"):
                    content = content.split("```")[1]
                    if content.startswith("json"):
                        content = content[4:]
                    content = content.strip()
                
                # Extract JSON
                start_idx = content.find('{')
                end_idx = content.rfind('}')
                if start_idx != -1 and end_idx != -1:
                    content = content[start_idx:end_idx+1]
                
                recipe_data = json.loads(content)
                
                # Ensure all ingredients have required fields
                for ingredient in recipe_data.get("ingredients", []):
                    if "unit" not in ingredient or not ingredient.get("unit"):
                        ingredient["unit"] = "unité" if req.language == "fr" else "unit"
                    if "category" not in ingredient or not ingredient.get("category"):
                        ingredient["category"] = "autre" if req.language == "fr" else "other"
                
                pending_recipe_modification = Recipe(**recipe_data)
                print(f"  ✅ Proposed modification generated: {pending_recipe_modification.title}")
                
                # Ask for confirmation in the reply
                if req.language == "fr":
                    reply = f"J'ai préparé une version modifiée de la recette **{recipe_to_modify.get('title')}**.\n\nVoulez-vous que j'applique cette modification?"
                else:
                    reply = f"I've prepared a modified version of the recipe **{recipe_to_modify.get('title')}**.\n\nWould you like me to apply this modification?"
                
                # Store metadata for reference including weekday and meal_type for plan updates
                modification_metadata = {
                    "original_title": recipe_to_modify.get('title'),
                    "modification_request": req.message,
                    "weekday": found_weekday,
                    "meal_type": found_meal_type
                }
                
            except Exception as e:
                print(f"  ❌ Error generating modification proposal: {e}")
                if req.language == "fr":
                    reply = "⚠️ Je n'ai pas pu préparer la modification automatiquement, mais je peux vous guider sur les changements à faire."
                else:
                    reply = "⚠️ I couldn't prepare the modification automatically, but I can guide you through the changes."
        
        return ChatResponse(
            reply=reply,
            detected_mode=detected_mode,
            requires_confirmation=requires_confirmation,
            suggested_actions=suggested_actions,
            modified_recipe=modified_recipe,
            pending_recipe_modification=pending_recipe_modification,
            modification_type=modification_type,
            modification_metadata=modification_metadata,
            member_data=None  # No longer support member addition via chat
        )
        
    except Exception as e:
        print(f"Error in chat endpoint: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to process chat message: {str(e)}")


@app.get("/")
def root():
    return {"message": "Planea AI Server with OpenAI - Ready!"}
