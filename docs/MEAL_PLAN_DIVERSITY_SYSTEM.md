# Système de Diversité des Plans de Repas

## Vue d'ensemble

Implémentation d'un système en 2 phases pour améliorer considérablement la diversité des plans de repas générés, réduisant les répétitions de protéines et légumes, et incluant naturellement des soupes-repas et salades-repas.

## Problème résolu

**Avant l'implémentation:**
- Plans de repas manquant de variété
- Répétitions fréquentes de la même protéine (ex: 3 sautés de poulet dans un plan de 5 repas)
- Légumes principaux répétés trop souvent
- Peu de soupes-repas ou salades-repas générées
- Manque de diversité dans les cuisines et techniques de cuisson

**Après l'implémentation:**
- Plans de repas beaucoup plus variés et intéressants
- Maximum 2 occurrences d'une même protéine principale
- Maximum 2 occurrences d'un même légume principal
- 1-2 soupes-repas ou salades-repas incluses naturellement dans chaque plan
- Grande diversité de cuisines du monde (asiatique, méditerranéenne, mexicaine, etc.)
- Variété des techniques de cuisson (sauté, grillé, mijoté, au four, etc.)

## Architecture - Système en 2 Phases

### Phase 1: Génération du Blueprint de Diversité
Une nouvelle fonction `generate_diversity_plan()` crée un plan de diversité pour tous les repas de la semaine avant de générer les recettes.

**Pour chaque repas, le blueprint définit:**
- **Cuisine**: Style culinaire (thaïlandaise, italienne, mexicaine, etc.)
- **Protéine**: Protéine principale (poulet, boeuf, poisson, tofu, etc.)
- **Type de plat**: Méthode de préparation (sauté, grillé, soupe, salade, etc.)
- **Focus légumes**: Légumes principaux à utiliser
- **Description**: Concept général du repas

**Exemple de blueprint pour 5 repas:**
```json
{
  "meals": [
    {
      "cuisine": "Thaïlandaise",
      "protein": "poulet",
      "dish_type": "sauté",
      "vegetable_focus": "poivrons et basilic",
      "description": "Sauté de poulet au basilic thaï"
    },
    {
      "cuisine": "Méditerranéenne",
      "protein": "poisson",
      "dish_type": "grillé",
      "vegetable_focus": "tomates et olives",
      "description": "Poisson grillé aux légumes méditerranéens"
    },
    {
      "cuisine": "Mexicaine",
      "protein": "boeuf",
      "dish_type": "mijoté",
      "vegetable_focus": "poivrons et haricots",
      "description": "Chili de boeuf mexicain"
    },
    {
      "cuisine": "Asiatique",
      "protein": "tofu",
      "dish_type": "soupe",
      "vegetable_focus": "bok choy et champignons",
      "description": "Soupe miso au tofu et légumes"
    },
    {
      "cuisine": "Française",
      "protein": "poulet",
      "dish_type": "au four",
      "vegetable_focus": "carottes et herbes",
      "description": "Poulet rôti aux herbes de Provence"
    }
  ]
}
```

### Phase 2: Génération Parallèle des Recettes
Chaque recette est générée en parallèle (pour maintenir la rapidité) mais avec son blueprint spécifique comme contrainte.

**Avantages:**
- ✅ Génération toujours rapide (parallèle)
- ✅ Diversité garantie par les contraintes du blueprint
- ✅ Chaque recette respecte son style assigné
- ✅ Pas de répétitions excessives

## Règles de Diversité

Le système applique ces règles strictes lors de la génération du blueprint:

1. **Protéines:** Chaque protéine apparaît au maximum 2 fois
2. **Légumes:** Chaque légume principal apparaît au maximum 2 fois
3. **Soupes/Salades:** 1-2 soupes-repas ou salades-repas incluses naturellement
4. **Techniques:** Variation des méthodes de cuisson (sauté, grillé, mijoté, au four, soupe, salade, etc.)
5. **Cuisines:** Diversité des cuisines du monde (asiatique, méditerranéenne, mexicaine, moyen-orientale, indienne, française, américaine, fusion)

## Changements Techniques

### Nouveau: `generate_diversity_plan()`
```python
async def generate_diversity_plan(
    num_meals: int, 
    constraints: dict, 
    language: str = "fr", 
    preferences: dict = None
) -> List[dict]
```

Génère un blueprint de diversité via OpenAI avec:
- Température élevée (1.0) pour créativité maximale
- Instructions strictes sur la diversité
- Respect des contraintes alimentaires de l'utilisateur
- Intégration des préférences protéines

### Modifié: `generate_recipe_with_openai()`
Nouveau paramètre `diversity_blueprint: dict = None`:
- Si fourni, le prompt inclut les contraintes du blueprint
- Format clair pour l'IA: cuisine, protéine, type de plat, légumes
- L'IA DOIT respecter ces contraintes tout en créant une recette délicieuse

### Modifié: `/ai/plan` endpoint
Utilise maintenant le système en 2 phases:
1. Appelle `generate_diversity_plan()` pour créer le blueprint
2. Génère toutes les recettes en parallèle avec leur blueprint respectif
3. Logs détaillés pour debug (Phase 1, Phase 2, blueprints générés)

## Exemple de Prompt Amélioré

**Phase 1 - Génération du blueprint:**
```
Crée un plan de diversité pour 5 repas avec une VARIÉTÉ MAXIMALE.

RÈGLES DE DIVERSITÉ CRITIQUES:
1. Chaque protéine doit apparaître AU MAXIMUM 2 fois
2. Chaque légume principal doit apparaître AU MAXIMUM 2 fois
3. Inclure 1-2 soupes-repas OU salades-repas naturellement
4. Varier les méthodes de cuisson: sauté, grillé, mijoté, au four, soupe, salade, pâtes...
5. Varier les cuisines du monde: Asiatique, Méditerranéenne, Mexicaine, etc.
```

**Phase 2 - Génération de recette avec blueprint:**
```
PLAN DE DIVERSITÉ - DOIT SUIVRE:
- Style de cuisine: Thaïlandaise
- Protéine principale: poulet
- Type de plat: sauté
- Focus légumes: poivrons et basilic
- Concept: Sauté de poulet au basilic thaï

Tu DOIS respecter ces contraintes de diversité tout en créant une recette délicieuse.
```

## Tests Recommandés

Pour valider l'amélioration, générer plusieurs plans de 5 repas et vérifier:

1. **Diversité des protéines:** 
   - Compter les occurrences de chaque protéine
   - Vérifier qu'aucune protéine n'apparaît plus de 2 fois

2. **Diversité des légumes:**
   - Identifier les légumes principaux
   - Vérifier la variété des légumes utilisés

3. **Présence de soupes/salades:**
   - Compter le nombre de soupes-repas et salades-repas
   - Vérifier qu'il y en a au moins 1 dans chaque plan

4. **Variété des cuisines:**
   - Lister les styles culinaires représentés
   - Vérifier la diversité internationale

5. **Techniques de cuisson:**
   - Identifier les méthodes utilisées
   - Vérifier la variété (pas que des sautés)

## Performance

- **Temps de génération:** Légèrement augmenté (1 appel API supplémentaire pour le blueprint)
- **Impact:** Minimal car le blueprint est court et rapide à générer
- **Génération des recettes:** Toujours en parallèle, donc rapide
- **Temps total estimé:** +2-3 secondes par rapport à l'ancien système

## Déploiement

Les changements ont été:
- ✅ Committés au repository Git
- ✅ Poussés vers GitHub (main branch)
- ✅ Déployés automatiquement sur le serveur de production

**Note:** Aucun changement n'est requis côté iOS. Le système fonctionne de manière transparente avec l'API existante.

## Prochaines Améliorations Possibles

1. **Apprentissage utilisateur:** Se souvenir des repas précédents pour éviter les répétitions entre semaines
2. **Saisons:** Adapter les légumes selon la saison
3. **Préférences de cuisine:** Permettre à l'utilisateur de favoriser certaines cuisines
4. **Équilibrage automatique:** S'assurer d'un bon équilibre nutritionnel sur la semaine

## Date d'Implémentation

18 janvier 2026
