# 🍳 Meal Prep - Timeline de Cuisson Ultra-Précise

## 📋 Résumé des Modifications

**Date**: 10 janvier 2026  
**Objectif**: Éliminer toute ambiguïté dans la timeline de cuisson du Meal Prep

## 🎯 Problème Résolu

**Avant**: Étapes vagues comme "Cook vegetables" ou "Cuire les légumes"  
**Après**: Étapes précises comme "Rôtir brocoli, carottes et poivrons sur plaque au four"

## ✅ Règle ABSOLUE Implémentée

Chaque étape de cuisson DOIT suivre ce pattern EXACT:

```
[Verbe d'action] + [ingrédients spécifiques] + [méthode/localisation]
```

### Exemples Acceptables ✅

- "Rôtir brocoli, carottes et poivrons sur plaque au four"
- "Saisir filets de saumon à la poêle"
- "Finir portions de porc au four à 200°C"
- "Réchauffer glaçage érable dans petite casserole"
- "Préchauffer four à 220°C"

### Exemples INTERDITS ❌

- "Cuire les légumes" (trop vague!)
- "Préparer la protéine" (pas spécifique!)
- "Finir le plat" (incomplet!)
- "Cook vegetables"
- "Prepare protein"
- "Finish dish"

## 🔧 Modifications Techniques

### Fichier Modifié
**`mock-server/main.py`** - Fonction `generate_cooking_phases()`

### Changements au Prompt OpenAI

#### 1. **Ajout de la Règle Absolue**
```python
🚨🚨🚨 RÈGLE ABSOLUE - FORMAT DES ÉTAPES 🚨🚨🚨

CHAQUE étape DOIT suivre ce pattern EXACT:
[Verbe d'action] + [ingrédients spécifiques] + [méthode/localisation]
```

#### 2. **Règles Critiques Ajoutées**
- TOUJOURS nommer les ingrédients précis (brocoli, carottes, saumon, etc.)
- TOUJOURS indiquer la méthode (rôtir, saisir, mijoter, réduire)
- TOUJOURS indiquer l'équipement/location (four, poêle, casserole, plaque)

#### 3. **Exemples Concrets dans le JSON**
Le prompt inclut maintenant des exemples complets montrant le format exact:

```json
{
  "description": "Rôtir brocoli, carottes et poivrons sur plaque au four (15 min)",
  "recipe_title": "Salmon Bowl",
  "estimated_minutes": 15
}
```

#### 4. **Avertissement Final**
```
SI TU NE RESPECTES PAS LE FORMAT [Verbe + Ingrédients spécifiques + Méthode/Location], 
LA TIMELINE SERA RATÉE.
```

#### 5. **Ajout des Ingrédients au Contexte**
```python
recipe_summaries.append({
    # ... autres champs ...
    "ingredients": recipe.get("ingredients", []),  # NOUVEAU
})
```

Ceci permet à l'IA de voir les ingrédients précis de chaque recette pour les nommer correctement.

## 📊 Structure des 4 Phases

### Phase 1: 🔥 Cuisson (Cook)
- Préchauffage
- Cuisson des ingrédients avec noms précis
- Indication du parallélisme

### Phase 2: 🧩 Assemblage (Assemble)
- Assemblage final avec ingrédients nommés
- Glaçages, combinaisons

### Phase 3: ❄️ Refroidissement (Cool Down)
- Repos des protéines et plats
- Temps de refroidissement

### Phase 4: 📦 Conservation (Store)
- Portionnement dans contenants
- Réfrigération et étiquetage

## 🎨 Exemple de Timeline Générée

### Avant (Vague) ❌
```
☐ Cook vegetables
☐ Prepare protein
☐ Finish dish
```

### Après (Précis) ✅
```
☐ Préchauffer four à 220°C (5 min)
☐ Rôtir brocoli, carottes et poivrons sur plaque au four (15 min)
☐ Saisir filets de saumon à la poêle (6 min)
   💡 Pendant que les légumes rôtissent
☐ Glacer filets de saumon avec sauce teriyaki (2 min)
☐ Laisser reposer filets de saumon (5 min)
☐ Portionner saumon avec légumes dans 4 contenants (3 min)
☐ Réfrigérer et étiqueter tous les contenants (2 min)
```

## 🧪 Test et Validation

Pour tester les modifications:

1. **Générer un nouveau Meal Prep** via l'app iOS
2. **Vérifier la section "Preparation"** (onglet 2)
3. **Vérifier les phases de cuisson**:
   - Phase "🔥 Cuisson"
   - Phase "🧩 Assemblage"
   - Phase "❄️ Refroidissement"
   - Phase "📦 Conservation"
4. **Confirmer que chaque étape**:
   - Nomme les ingrédients précis
   - Indique la méthode de cuisson
   - Spécifie l'équipement/location

## ✨ Résultat Attendu

Une timeline de cuisson qui:
- ✅ Est précise au niveau ingrédient
- ✅ Guide le cuisinier pas à pas
- ✅ Rend le parallélisme évident
- ✅ Inspire confiance
- ✅ **Fonctionne comme un vrai plan de match**
- ✅ **Ne nécessite JAMAIS d'ouvrir les recettes pour comprendre**

## 🔄 Prochaines Étapes

1. **Redémarrer le serveur backend** pour appliquer les modifications
2. **Générer un test Meal Prep** dans l'app
3. **Valider le format** des étapes générées
4. **Ajuster si nécessaire** (mais le prompt est maintenant très explicite)

## 📝 Notes Importantes

- Le prompt a été modifié dans **les deux langues** (français ET anglais)
- Les exemples sont **culturellement adaptés** (terminologie québécoise pour le français)
- La règle est **répétée plusieurs fois** dans le prompt pour maximiser le respect
- L'IA a maintenant **accès aux ingrédients précis** de chaque recette

---

**✅ Status**: Modifications complétées et prêtes pour test
