# Meal Prep - Statut d'implémentation

## Résumé de la tâche
Implémenter les améliorations meal prep:
1. **Une seule option de meal prep générée** (pas 3 choix)
2. **Conservation adaptative**: Les recettes doivent avoir une durée de conservation adaptée au jour de consommation
3. **Intégration au plan**: Après approbation, ramener les recettes dans le plan de la semaine

## ✅ Phase 1-3: Backend (Complété)

### Fichiers modifiés:
- `mock-server/main.py`
- `Planea-iOS/Planea/Planea/Models/MealPrepModels.swift`

### Changements backend:

1. **Endpoint `/ai/meal-prep-concepts` créé:**
   - Génère 3 concepts thématiques + option texte libre
   - Supporte FR/EN avec fallback

2. **Infrastructure conservation adaptative:**
   ```python
   # Ligne ~2850 dans main.py
   day_mapping = {"Mon": 0, "Tue": 1, ...}
   target_day_index = day_mapping.get(target_day, 0)
   min_shelf_life_required = target_day_index + 1
   ```

3. **Paramètre concept optionnel ajouté:**
   ```python
   selected_concept = req.get("selected_concept", None)
   ```

4. **✅ Intégration complète conservation adaptative & concepts:**
   - Paramètres `min_shelf_life_required` et `selected_concept` ajoutés à `generate_recipe_with_openai()`
   - Instructions de conservation adaptative dans les prompts FR/EN
   - Instructions de concepts thématiques intégrées
   - Paramètres passés correctement dans `/ai/meal-prep-kits` avec `weekday=target_day`

### ~~Ce qui RESTE à faire dans backend~~ BACKEND COMPLÉTÉ ✅

#### ~~TODO Backend #1: Finaliser conservation adaptative~~ FAIT ✅
~~Dans `generate_recipe_with_openai()`, ajouter paramètre et logique:~~

```python
async def generate_recipe_with_openai(
    meal_type: str,
    # ... autres paramètres existants ...
    min_shelf_life_required: int = 3,  # AJOUTER CE PARAMÈTRE
    selected_concept: dict = None  # AJOUTER CE PARAMÈTRE
):
```

Puis dans les prompts (lignes ~850-900), ajouter:

```python
# Après les instructions de complexité, ajouter:
storage_instructions = ""
if min_shelf_life_required > 3:
    if language == "fr":
        storage_instructions = f"""
🥡 CONSERVATION ADAPTATIVE (CRITIQUE):
Cette recette sera consommée le jour {min_shelf_life_required} après préparation.
Elle DOIT ABSOLUMENT:
- Se conserver {min_shelf_life_required} jours au frigo, OU
- Être congélable

TYPES DE RECETTES PRIVILÉGIÉS pour longue conservation:
- Soupes, ragoûts, chilis
- Plats mijotés (curry, tajines)
- Casseroles, lasagnes, gratins
- Pâtes au four

ÉVITER: salades, poisson frais, fruits de mer non congelés
"""
    else:
        storage_instructions = f"""
🥡 ADAPTIVE STORAGE (CRITICAL):
This recipe will be consumed on day {min_shelf_life_required} after preparation.
It MUST:
- Keep {min_shelf_life_required} days in fridge, OR
- Be freezable

PRIORITIZE for long storage:
- Soups, stews, chilis
- Braised dishes (curries, tagines)
- Casseroles, lasagnas, gratins
- Baked pasta

AVOID: salads, fresh fish, non-frozen seafood
"""

# Ajouter concept si fourni
concept_instructions = ""
if selected_concept:
    if language == "fr":
        concept_instructions = f"""
🎨 THÈME CULINAIRE:
{selected_concept['name']}: {selected_concept['description']}
Inspire-toi de ce thème pour créer la recette.
"""
    else:
        concept_instructions = f"""
🎨 CULINARY THEME:
{selected_concept['name']}: {selected_concept['description']}
Draw inspiration from this theme.
"""

# Puis intégrer storage_instructions et concept_instructions dans le prompt
```

#### TODO Backend #2: Passer paramètres au générateur
Dans `/ai/meal-prep-kits` (ligne ~2890), modifier l'appel:

```python
recipe = await generate_recipe_with_openai(
    meal_type=meal_type,
    constraints=constraints,
    units=units,
    servings=servings_per_meal,
    previous_recipes=None,
    diversity_seed=kit_idx * 100 + recipe_idx,
    language=language,
    preferences={...},
    min_shelf_life_required=min_shelf_life_required,  # AJOUTER
    selected_concept=selected_concept  # AJOUTER
)
```

## 🔄 Phase 3-6: iOS (À FAIRE)

### Fichiers à modifier:

#### 1. `Planea-iOS/Planea/Planea/Services/MealPrepService.swift`

Ajouter méthode pour concepts:

```swift
func generateConcepts(constraints: [String: Any], language: String) async throws -> [MealPrepConcept] {
    let url = URL(string: "\(baseURL)/ai/meal-prep-concepts")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = [
        "language": language,
        "constraints": constraints
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode([String: [MealPrepConcept]].self, from: data)
    return response["concepts"] ?? []
}
```

Modifier méthode existante pour accepter concept:

```swift
func generateMealPrepKits(
    days: [String],
    meals: [String],
    servingsPerMeal: Int,
    totalPrepTime: String,
    skillLevel: String,
    avoidRare: Bool,
    preferLongShelf: Bool,
    selectedConcept: MealPrepConcept?,  // AJOUTER CE PARAMÈTRE
    customConceptText: String?  // AJOUTER CE PARAMÈTRE
) async throws -> [MealPrepKit] {
    // Dans le body, ajouter:
    if let concept = selectedConcept {
        body["selected_concept"] = [
            "id": concept.id,
            "name": concept.name,
            "description": concept.description
        ]
    } else if let customText = customConceptText, !customText.isEmpty {
        body["selected_concept"] = [
            "id": UUID().uuidString,
            "name": "Custom",
            "description": customText
        ]
    }
    
    // ... reste du code existant
}
```

#### 2. `Planea-iOS/Planea/Planea/ViewModels/MealPrepViewModel.swift`

Ajouter propriétés pour concepts:

```swift
// Après les propriétés existantes, ajouter:
@Published var concepts: [MealPrepConcept] = []
@Published var selectedConcept: MealPrepConcept?
@Published var customConceptText: String = ""
@Published var isLoadingConcepts: Bool = false
@Published var conceptsError: String?

// Ajouter méthode
@MainActor
func loadConcepts() async {
    isLoadingConcepts = true
    conceptsError = nil
    
    do {
        let constraints = buildConstraints()
        concepts = try await mealPrepService.generateConcepts(
            constraints: constraints,
            language: LocalizationHelper.currentLanguage()
        )
    } catch {
        conceptsError = error.localizedDescription
    }
    
    isLoadingConcepts = false
}

// Modifier generateKits() pour passer le concept
@MainActor
func generateKits() async {
    // ... code existant jusqu'à l'appel service ...
    
    kits = try await mealPrepService.generateMealPrepKits(
        days: selectedDays,
        meals: selectedMeals,
        servingsPerMeal: servingsPerMeal,
        totalPrepTime: totalPrepTime.rawValue,
        skillLevel: skillLevel.rawValue,
        avoidRare: avoidRareIngredients,
        preferLongShelf: preferLongShelfLife,
        selectedConcept: selectedConcept,  // AJOUTER
        customConceptText: customConceptText  // AJOUTER
    )
    
    // ... reste du code ...
}
```

#### 3. `Planea-iOS/Planea/Planea/Views/MealPrepWizardView.swift`

Ajouter nouveau step après la configuration (Step 2.5):

```swift
// Dans l'enum WizardStep, ajouter après .configuration:
case conceptSelection

// Dans le body, ajouter case dans le switch:
case .conceptSelection:
    ConceptSelectionView(viewModel: viewModel)

// Créer la nouvelle view à la fin du fichier:
struct ConceptSelectionView: View {
    @ObservedObject var viewModel: MealPrepViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("meal_prep.concept_selection.title")
                .font(.title)
                .bold()
            
            Text("meal_prep.concept_selection.subtitle")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if viewModel.isLoadingConcepts {
                ProgressView()
                    .padding()
            } else if let error = viewModel.conceptsError {
                Text(error)
                    .foregroundColor(.red)
            } else {
                // Options de concepts
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.concepts) { concept in
                            ConceptCard(
                                concept: concept,
                                isSelected: viewModel.selectedConcept?.id == concept.id,
                                onSelect: {
                                    viewModel.selectedConcept = concept
                                    viewModel.customConceptText = ""
                                }
                            )
                        }
                        
                        // Option texte libre
                        VStack(alignment: .leading, spacing: 12) {
                            Text("meal_prep.concept_selection.custom")
                                .font(.headline)
                            
                            TextField("meal_prep.concept_selection.custom_placeholder", text: $viewModel.customConceptText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: viewModel.customConceptText) { newValue in
                                    if !newValue.isEmpty {
                                        viewModel.selectedConcept = nil
                                    }
                                }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            Button(action: {
                viewModel.currentStep = .kitSelection
            }) {
                Text("common.continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedConcept == nil && viewModel.customConceptText.isEmpty)
            .padding(.horizontal)
        }
        .task {
            await viewModel.loadConcepts()
        }
    }
}

struct ConceptCard: View {
    let concept: MealPrepConcept
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(concept.name)
                        .font(.headline)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Text(concept.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let cuisine = concept.cuisine {
                    Text(cuisine)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
```

Modifier la navigation pour inclure le nouveau step:

```swift
// Dans nextStep():
case .configuration:
    currentStep = .conceptSelection  // Changer de .kitSelection à .conceptSelection

case .conceptSelection:
    currentStep = .kitSelection
```

#### 4. Ajouter Step 4: Confirmation avec mapping

Dans `WizardStep` enum, ajouter après `.kitSelection`:
```swift
case confirmation
```

Créer `ConfirmationView` avec mapping jour/recette + validation conservation.

#### 5. `Planea-iOS/Planea/Planea/Services/MealPrepStorageService.swift`

Améliorer l'algorithme `mapKitToWeekPlan()`:

```swift
private func mapKitToWeekPlan(
    kit: MealPrepKit,
    selectedDays: [String],
    selectedMeals: [String]
) -> [String: [MealPlanRecipe]] {
    var plan: [String: [MealPlanRecipe]] = [:]
    
    // Trier les recettes: courte conservation d'abord
    let sortedRecipes = kit.recipes.sorted { r1, r2 in
        let shelf1 = r1.recipe.shelfLifeDays ?? 3
        let shelf2 = r2.recipe.shelfLifeDays ?? 3
        return shelf1 < shelf2  // Plus courte conservation = priorité
    }
    
    var recipeIndex = 0
    
    // Mapper aux jours (chronologique)
    for (dayIndex, day) in selectedDays.enumerated() {
        var dayMeals: [MealPlanRecipe] = []
        
        for meal in selectedMeals {
            guard recipeIndex < sortedRecipes.count else { break }
            
            let recipeRef = sortedRecipes[recipeIndex]
            
            // Vérifier si la conservation est adéquate
            let daysUntilConsumption = dayIndex + 1
            let shelfLife = recipeRef.recipe.shelfLifeDays ?? 3
            
            if shelfLife >= daysUntilConsumption || (recipeRef.recipe.isFreezable ?? false) {
                // OK, on peut utiliser cette recette
                dayMeals.append(convertToMealPlanRecipe(recipeRef, mealType: meal))
                recipeIndex += 1
            } else {
                // Chercher une recette avec meilleure conservation
                // ... logique de fallback
            }
        }
        
        plan[day] = dayMeals
    }
    
    return plan
}
```

#### 6. Navigation finale

Dans `MealPrepViewModel`, après `confirmKit()`:

```swift
@Published var shouldNavigateToPlan: Bool = false

func confirmKit(_ kit: MealPrepKit) async {
    // ... code existant de sauvegarde ...
    
    // À la fin:
    await MainActor.run {
        shouldNavigateToPlan = true
    }
}
```

Dans `MealPrepWizardView`:

```swift
.onChange(of: viewModel.shouldNavigateToPlan) { shouldNavigate in
    if shouldNavigate {
        dismiss()
        // Le parent view détectera la fermeture et naviguera
    }
}
```

## 📝 Localisation à ajouter

Dans `fr.lproj/Localizable.strings`:
```
"meal_prep.concept_selection.title" = "Choisissez un thème";
"meal_prep.concept_selection.subtitle" = "Sélectionnez un concept ou décrivez votre propre thème";
"meal_prep.concept_selection.custom" = "Ou décrivez votre propre thème";
"meal_prep.concept_selection.custom_placeholder" = "Ex: Cuisine asiatique avec beaucoup de légumes";
"meal_prep.confirmation.title" = "Confirmez votre plan";
"meal_prep.confirmation.subtitle" = "Voici comment vos recettes seront distribuées";
```

## 🧪 Tests à effectuer

1. Générer meal prep pour 3+ jours
2. Vérifier que recettes vendredi ont conservation ≥5 jours
3. Vérifier qu'après confirmation, les recettes apparaissent dans PlanWeekView
4. Tester avec concept sélectionné vs texte libre

## Priorités

1. ✅ Backend concepts endpoint
2. ✅ Backend conservation infrastructure
3. 🔴 TODO Backend: Finaliser prompts conservation/concept
4. 🔴 TODO iOS: MealPrepService.generateConcepts()
5. 🔴 TODO iOS: Wizard Step 2.5 (concepts)
6. 🔴 TODO iOS: Améliorer mapping
7. 🔴 TODO iOS: Step 4 confirmation
8. 🔴 TODO iOS: Navigation finale
