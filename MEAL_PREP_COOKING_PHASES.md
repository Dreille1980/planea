# Meal Prep - Section Individual Recipe (Post-Prep)

## ✅ Implémentation Complète

### 🎯 Objectif
Créer une section qui guide le cuisinier une fois toute la préparation terminée, avec un format checklist structuré en phases pour optimiser le temps, le parallélisme et la clarté.

---

## 📋 Structure des Phases

### **Phase 1: 🔥 Cook (Cuisson)**
- Toutes les étapes de cuisson (poêle, four, grill)
- Exclusion des étapes de préparation (couper, hacher, etc.) - déjà faites en mise en place
- Identification intelligente des étapes parallèles
- Format: étapes courtes avec temps estimés

**Exemple:**
```
🔥 Cook (35 min)

☐ Start couscous (5 min)
  → In parallel with next steps

☐ Sauté lamb chops (10 min)
☐ Grill tuna steaks (8 min)
  → In parallel with next step
☐ Stir-fry tofu (7 min)
```

### **Phase 2: 🧩 Assemble (Assemblage)**
- Combinaison des éléments cuits
- Ajout des sauces et garnitures finales
- Pas de cuisson - uniquement assemblage

**Exemple:**
```
🧩 Assemble (10 min)

☐ Combine lamb + vegetables
☐ Add sauce to tofu
☐ Finish tuna with salsa
☐ Toss couscous with herbs
```

### **Phase 3: ❄️ Cool Down (Refroidissement)**
- Laisser refroidir les plats avant le stockage
- Sécurité alimentaire et qualité des textures

**Exemple:**
```
❄️ Cool Down (15 min)

☐ Let cooked proteins rest
☐ Allow sauces to cool
```

### **Phase 4: 📦 Store (Conservation)**
- Portionnement dans des contenants
- Instructions de stockage (frigo vs congélateur)
- Labels et durée de conservation

**Exemple:**
```
📦 Store (10 min)

☐ Portion lamb couscous (4 containers)
☐ Store tuna separately (airtight)
☐ Refrigerate tofu stir-fry
☐ Label containers (date + recipe)
```

---

## 🔧 Implémentation Backend

### **Fichier: `mock-server/main.py`**

#### **Fonction `generate_cooking_phases()` (NOUVEAU)**
- **Entrée**: Liste des recettes du kit + langue
- **Sortie**: Dict avec 4 phases structurées
- **Méthode**: Utilise GPT-4o pour orchestrer intelligemment les étapes

**Structure de sortie:**
```python
{
  "cook": {
    "title": "🔥 Cuisson",
    "total_minutes": 35,
    "steps": [
      {
        "id": "uuid",
        "description": "Démarrer le couscous (5 min)",
        "recipe_title": "Lamb Couscous",
        "recipe_index": 1,
        "estimated_minutes": 5,
        "is_parallel": true,
        "parallel_note": "En parallèle avec la prochaine étape"
      }
    ]
  },
  "assemble": {...},
  "cool_down": {...},
  "store": {...}
}
```

#### **Modifications dans `generate_meal_prep_kits()`**
- Remplacement de `optimize_recipe_steps()` par `generate_cooking_phases()`
- Le champ `optimized_recipe_steps` devient `cooking_phases`
- Structure plus riche avec les 4 phases explicites

---

## 🧠 Règles d'Orchestration de l'IA

### **Parallélisme Intelligent**
L'IA identifie automatiquement:
- ✅ Cuisson au four (passive) → peut être parallélisée
- ✅ Mijoter (passive) → peut être parallélisée
- ❌ Sauté à la poêle (active) → séquentielle

### **Exclusion des Préparations**
- ❌ Couper, hacher, émincer, râper → exclus (déjà en mise en place)
- ✅ Cuire, griller, rôtir, sauté → inclus

### **Optimisation du Temps**
- Minimisation des temps morts
- Regroupement logique par type d'équipement
- Timeline globale cohérente

---

## 📱 Prochaines Étapes (Frontend iOS)

### **1. Modèles Swift à Mettre à Jour**

Fichier: `Planea-iOS/Planea/Planea/Models/MealPrepModels.swift`

Ajouter:
```swift
// MARK: - Cooking Phases

struct CookingPhase: Identifiable, Codable {
    let id: UUID
    let title: String
    let totalMinutes: Int
    let steps: [PhaseStep]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case totalMinutes = "total_minutes"
        case steps
    }
}

struct PhaseStep: Identifiable, Codable {
    let id: UUID
    let description: String
    let recipeTitle: String
    let recipeIndex: Int?
    let estimatedMinutes: Int?
    let isParallel: Bool
    let parallelNote: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case description
        case recipeTitle = "recipe_title"
        case recipeIndex = "recipe_index"
        case estimatedMinutes = "estimated_minutes"
        case isParallel = "is_parallel"
        case parallelNote = "parallel_note"
    }
}

struct CookingPhasesSet: Codable {
    let cook: CookingPhase
    let assemble: CookingPhase
    let coolDown: CookingPhase
    let store: CookingPhase
    
    enum CodingKeys: String, CodingKey {
        case cook
        case assemble
        case coolDown = "cool_down"
        case store
    }
}

// Update MealPrepKit
extension MealPrepKit {
    let cookingPhases: CookingPhasesSet?
    
    // Remove optimizedRecipeSteps (deprecated)
}
```

### **2. Vue d'Affichage**

Fichier: `Planea-iOS/Planea/Planea/Views/MealPrepDetailView.swift`

Section à ajouter:
```swift
// Phase Selector
Picker("Phase", selection: $selectedPhase) {
    Text("🔥 Cook").tag(0)
    Text("🧩 Assemble").tag(1)
    Text("❄️ Cool Down").tag(2)
    Text("📦 Store").tag(3)
}

// Phase Content
switch selectedPhase {
case 0: CookingPhaseView(phase: kit.cookingPhases.cook)
case 1: CookingPhaseView(phase: kit.cookingPhases.assemble)
case 2: CookingPhaseView(phase: kit.cookingPhases.coolDown)
case 3: CookingPhaseView(phase: kit.cookingPhases.store)
}

// Phase Step View with Checkbox
struct PhaseStepRow: View {
    let step: PhaseStep
    @State private var isCompleted: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Button {
                isCompleted.toggle()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
            }
            
            VStack(alignment: .leading) {
                Text(step.description)
                
                if step.isParallel, let note = step.parallelNote {
                    Label(note, systemImage: "arrow.triangle.branch")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if let time = step.estimatedMinutes {
                    Text("\(time) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
```

---

## ✨ Avantages de Cette Approche

### **1. Génération Intelligente par l'IA**
- ✅ Orchestration optimale automatique
- ✅ Identification du parallélisme
- ✅ Adaptation au contexte (nombre de recettes, temps total)

### **2. Format Checklist Pratique**
- ✅ Étapes cochables
- ✅ Indication claire du parallélisme
- ✅ Temps estimés pour chaque étape

### **3. Organisation Logique**
- ✅ Phases séparées et claires
- ✅ Pas de redondance avec la mise en place
- ✅ Ordre chronologique cohérent

### **4. Expérience Utilisateur**
- ✅ Téléphone sur le comptoir = checklist de chef
- ✅ Progression visible
- ✅ Clarté maximale

---

## 🧪 Test de l'Implémentation

### **Test Backend:**
```bash
# Démarrer le serveur
cd mock-server
python main.py

# Générer un kit
curl -X POST http://localhost:8000/ai/meal-prep-kits \
  -H "Content-Type: application/json" \
  -d '{
    "days": ["Mon", "Tue", "Wed"],
    "meals": ["LUNCH", "DINNER"],
    "servings_per_meal": 4,
    "language": "fr"
  }'
```

### **Vérifier:**
- ✅ Le JSON contient `cooking_phases` au lieu de `optimized_recipe_steps`
- ✅ 4 phases présentes: cook, assemble, cool_down, store
- ✅ Chaque phase a un titre, total_minutes, et steps
- ✅ Chaque step a is_parallel et parallel_note

---

## 📝 Notes de Développement

### **Compatibilité Backward**
- L'ancien champ `optimized_recipe_steps` a été supprimé
- Les kits existants devront être régénérés
- Pas de migration nécessaire (données temporaires)

### **Performance**
- Un appel API GPT-4o supplémentaire par génération de kit
- Temps ajouté: ~3-5 secondes
- Acceptable car génération unique par kit

### **Langues Supportées**
- ✅ Français
- ✅ Anglais
- Structure identique, seuls les labels changent

---

## 🎯 Résultat Final

L'utilisateur obtient une section **Individual Recipe (Post-Prep)** qui:
1. **Exclut** la préparation (déjà faite en mise en place)
2. **Structure** les étapes en 4 phases logiques
3. **Identifie** intelligemment les étapes parallèles
4. **Présente** un format checklist pratique et clair
5. **Optimise** le temps de cuisson global

**Format checklist de chef ✨**
