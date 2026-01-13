# Logique du Prompt "Vide Frigo"

## 📍 Emplacement
**Fichier:** `mock-server/main.py`  
**Fonction:** `ai_recipe_from_image()` (ligne ~2750-2950)  
**Endpoint:** `POST /ai/recipe-from-image`

---

## 🎯 Objectif Principal

Créer une recette basée sur:
1. **Une photo du frigo/garde-manger** (analyse visuelle par GPT-4o Vision)
2. **Instructions optionnelles de l'utilisateur** (texte libre)

---

## 🧠 Logique Actuelle du Prompt (Version Française)

### Structure en 3 Étapes:

#### **ÉTAPE 1 - ANALYSE OBLIGATOIRE DE LA PHOTO**
```
Examine ATTENTIVEMENT la photo du frigo/garde-manger et liste les ingrédients visibles:
- Protéines (viandes, poissons, œufs, tofu, etc.)
- Légumes (tous types)
- Fruits
- Produits laitiers
- Condiments et assaisonnements
- Autres items
```

#### **ÉTAPE 2 - INGRÉDIENTS DE BASE DISPONIBLES**
```
Tu peux utiliser sans restriction:
- Huile, beurre
- Sel, poivre, épices courantes
- Ail, oignon, échalote
- Farine, sucre, bouillon
```

#### **ÉTAPE 3 - CRÉATION DE LA RECETTE**
Contient la **LOGIQUE DE PRIORITÉ** qui détermine comment créer la recette.

---

## ⚖️ Logique de Priorité (Approche Balancée)

### **CAS 1: Instructions utilisateur présentes**
```python
if user_instructions_text:  # Ex: "j'ai des crevettes"
    1. UTILISER l'ingrédient mentionné comme INGRÉDIENT PRINCIPAL/PROTÉINE
    2. COMPLÉTER OBLIGATOIREMENT avec légumes/accompagnements VISIBLES dans la photo
    3. Ajouter ingrédients de base pour équilibrer
```

**Exemple:**
- Photo montre: brocoli, carottes, poivrons, oignons
- User dit: "j'ai des crevettes"
- ✅ **CORRECT:** Crevettes sautées avec brocoli, carottes et poivrons (de la photo)
- ❌ **INCORRECT:** Crevettes à l'ail et citron (invente citron, ignore la photo)

### **CAS 2: AUCUNE instruction utilisateur**
```python
else:  # Pas d'instructions
    1. CRÉER une recette avec les ingrédients les PLUS VISIBLES/ABONDANTS dans la photo
    2. PRIORISER les protéines visibles
    3. Compléter avec ingrédients de base
```

---

## 🚨 PROBLÈME IDENTIFIÉ

### Scénario Problématique:
```
Photo: brocoli, carottes, poivrons, oignons (AUCUNE protéine visible)
User dit: "recette asiatique" (pas de protéine mentionnée)

Résultat actuel: L'IA INVENTE du poulet/crevettes
Résultat attendu: Recette végétarienne asiatique avec les légumes de la photo
```

### Cause Racine:
Le prompt ne distingue PAS clairement entre:
- **Instructions mentionnant une protéine:** "j'ai des crevettes"
- **Instructions sans protéine:** "recette asiatique", "quelque chose de rapide"

L'IA interprète "recette asiatique" comme une permission d'inventer des ingrédients typiques de cette cuisine.

---

## ✅ SOLUTION PROPOSÉE

### Ajouter une règle EXPLICITE sur les protéines

**Emplacement:** APRÈS l'ÉTAPE 1, AVANT l'ÉTAPE 2

```python
🚨🚨🚨 RÈGLE ABSOLUE - PROTÉINES 🚨🚨🚨

Tu DOIS détecter si l'utilisateur mentionne une protéine spécifique dans ses instructions.
Protéines courantes: poulet, boeuf, porc, poisson, saumon, thon, crevettes, tofu, oeufs, dinde, agneau, veau, canard

CAS 1 - User mentionne UNE PROTÉINE spécifique:
  Exemple: "j'ai des crevettes", "avec du poulet", "utilise le saumon"
  ✅ UTILISER cette protéine + légumes/ingrédients de la photo
  ✅ La protéine mentionnée devient l'ingrédient principal

CAS 2 - User NE mentionne PAS de protéine spécifique:
  Exemple: "recette asiatique", "quelque chose de rapide", "plat végétarien", ""
  ✅ Utiliser UNIQUEMENT les protéines visibles dans la photo
  ❌ N'INVENTE JAMAIS une protéine qui n'est ni visible ni mentionnée
  ✅ Si aucune protéine visible → Créer recette végétarienne/végétalienne

CETTE RÈGLE EST ABSOLUE ET NON NÉGOCIABLE.
```

---

## 🎭 Exemples Avant/Après

### Exemple 1: Protéine mentionnée
```
Photo: brocoli, carottes, oignons
User: "j'ai des crevettes"

AVANT: Crevettes à l'ail (invente ail invisible)
APRÈS: Crevettes sautées avec brocoli et carottes ✓
```

### Exemple 2: Style sans protéine
```
Photo: brocoli, carottes, tofu visible
User: "recette asiatique"

AVANT: Poulet teriyaki (invente poulet)
APRÈS: Tofu sauté asiatique avec légumes ✓
```

### Exemple 3: Pas d'instructions, pas de protéine visible
```
Photo: brocoli, carottes, champignons, oignons
User: "" (vide)

AVANT: Poulet aux légumes (invente poulet)
APRÈS: Sauté de légumes asiatique (végétarien) ✓
```

### Exemple 4: Pas d'instructions, protéine visible
```
Photo: poulet visible, brocoli, carottes
User: "" (vide)

AVANT: Poulet aux légumes ✓
APRÈS: Poulet aux légumes ✓ (pas de changement)
```

---

## 📝 Règles Strictes (existantes)

```python
RÈGLES STRICTES:
✅ ANALYSER la photo dans TOUS les cas
✅ SI user mentionne "crevettes" → Utiliser crevettes + légumes de la photo
✅ SI user mentionne "style asiatique" → Appliquer le style + ingrédients de la photo
✅ TOUJOURS inclure des ingrédients visibles dans la photo

❌ N'INVENTE JAMAIS d'ingrédients spécifiques non mentionnés/visibles
❌ Ne crée PAS de recette sans utiliser la photo
❌ N'ignore PAS les ingrédients visibles dans la photo
```

---

## 🔧 Implémentation

### Fichier à modifier:
`mock-server/main.py`

### Section:
Fonction `ai_recipe_from_image()`, dans le bloc `text_prompt` pour le français (ligne ~2850-2950)

### Action:
Insérer le bloc "RÈGLE ABSOLUE - PROTÉINES" entre ÉTAPE 1 et ÉTAPE 2

---

## 🧪 Tests Suggérés

1. **Test végétarien:** Photo avec légumes seulement + "recette rapide"
   - Attendu: Recette végétarienne

2. **Test protéine mentionnée:** Photo avec légumes + "j'ai du saumon"
   - Attendu: Recette avec saumon + légumes de la photo

3. **Test style sans protéine:** Photo avec légumes + "cuisine méditerranéenne"
   - Attendu: Recette méditerranéenne végétarienne

4. **Test protéine visible:** Photo avec poulet + légumes + pas d'instructions
   - Attendu: Recette avec le poulet visible

---

## 📚 Contexte Technique

- **Modèle:** GPT-4o avec Vision (multimodal)
- **Température:** 0.9 (créativité élevée)
- **Max tokens:** 1500
- **Format de sortie:** JSON structuré avec recette complète

