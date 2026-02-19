# Wizard de Génération - Simplification UX

## 📋 Résumé des changements

Date: 18 février 2026

### Objectif
Simplifier l'expérience utilisateur du wizard de génération de semaine en réduisant le nombre d'étapes et en affichant automatiquement les repas générés.

## 🎯 Améliorations implémentées

### 1. **Suppression de l'étape Préférences (Step 3)**
- ✅ L'étape PreferencesStepView a été complètement supprimée du wizard
- ✅ Les préférences (temps de cuisson, niveau d'épices, kid-friendly, etc.) sont maintenant chargées automatiquement depuis les paramètres sauvegardés
- ✅ Les restrictions alimentaires des membres de famille (allergies, dislikes, diets) sont automatiquement appliquées

### 2. **Simplification du flow de navigation**
**Avant:**
- Étape 1: Sélection des jours/repas
- Étape 2: Configuration Meal Prep (si applicable)
- Étape 3: Préférences de génération
- Étape 4: WizardSuccessView après génération

**Après:**
- Étape 1: Sélection des jours/repas (avec indicateurs visuels clairs)
- Étape 2 (optionnelle): Configuration Meal Prep (seulement si meal prep sélectionné)
- Génération → Fermeture automatique du wizard
- Affichage direct dans PlanWeekView

### 3. **Auto-dismiss après génération**
- ✅ Le wizard se ferme automatiquement après une génération réussie
- ✅ L'utilisateur voit immédiatement les repas organisés par jour dans PlanWeekView
- ✅ WizardSuccessView n'est plus affichée (simplification)

### 4. **Indicateurs visuels améliorés**
- ✅ La barre de progression affiche correctement 1/1 ou 1/2 ou 2/2 selon le flow
- ✅ La carte de résumé (NewSummaryCard) montre clairement le nombre total de repas sélectionnés
- ✅ Distinction visuelle entre repas simples et meal prep

## 📂 Fichiers modifiés

### 1. **WeekGenerationConfigViewModel.swift**
- `totalSteps`: Modifié pour retourner 1 ou 2 (au lieu de 2 ou 3)
- `nextStep()` et `previousStep()`: Logique simplifiée sans skip de step
- Commentaires ajoutés pour clarifier la nouvelle structure

### 2. **WeekGenerationWizardView.swift**
- Suppression de PreferencesStepView du TabView
- Suppression de l'affichage conditionnel de WizardSuccessView
- Ajout de `.onChange(of: viewModel.generationSuccess)` pour auto-dismiss
- Simplification de la structure du body

### 3. **WeekGenerationConfig.swift**
- `canProceedFromStep()`: Suppression du case 2 (préférences)
- Pas de changement aux computed properties (compatibilité maintenue)

### 4. **Fichiers inchangés mais importants**
- **DaySelectionStepView.swift**: Déjà bien optimisé avec quick actions et résumé visuel
- **MealPrepConfigStepView.swift**: Reste tel quel pour les repas meal prep
- **PreferencesStepView.swift**: Garde le fichier pour référence future si besoin
- **PlanWeekView.swift**: Affiche déjà parfaitement les repas par jour

## 🔄 Flow utilisateur simplifié

```
┌─────────────────────────────────────┐
│  1. Utilisateur ouvre wizard       │
│     (bouton wand.and.stars)         │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  2. Étape 1: Sélection repas        │
│     - Quick actions                 │
│     - Sélection granulaire          │
│     - Carte résumé (X repas)        │
│     - Simple vs Meal Prep           │
└──────────────┬──────────────────────┘
               │
               ▼
        ┌──────────────┐
        │ Meal Prep?   │
        └──┬────────┬──┘
          Oui      Non
           │        │
           ▼        │
┌─────────────────┐ │
│ 2. Config MP    │ │
│    - Portions   │ │
└────────┬────────┘ │
         │          │
         └────┬─────┘
              ▼
┌─────────────────────────────────────┐
│  3. Bouton "Générer"                │
│     - Loading overlay               │
│     - Génération backend            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  4. Auto-dismiss wizard             │
│     + Affichage PlanWeekView        │
│     - Vue jour par jour             │
│     - Tous les détails visibles     │
└─────────────────────────────────────┘
```

## 📱 Préférences automatiquement appliquées

Les préférences suivantes sont chargées depuis les paramètres sauvegardés:

### Depuis PreferencesService:
- ✅ Temps de cuisson maximum (weekday/weekend)
- ✅ Niveau d'épices (mild, medium, spicy)
- ✅ Kid-friendly
- ✅ Jour de début de semaine
- ✅ Toute autre préférence générale

### Depuis les membres de famille:
- ✅ Allergènes (par membre)
- ✅ Dislikes (par membre)
- ✅ Régimes alimentaires (par membre)

Ces informations sont automatiquement agrégées et envoyées au backend lors de la génération.

## 🎨 Avantages UX

1. **Moins de clics**: 2 étapes maximum au lieu de 3
2. **Plus rapide**: Pas besoin de configurer les préférences à chaque fois
3. **Plus clair**: Indicateurs visuels améliorés sur le nombre de repas
4. **Plus fluide**: Transition automatique vers la vue des repas
5. **Plus cohérent**: Les préférences sont centralisées dans les paramètres

## 🧪 Points à tester

- [ ] Génération avec uniquement des repas simples (1 étape)
- [ ] Génération avec des meal prep (2 étapes)
- [ ] Vérification que les préférences sont bien appliquées
- [ ] Vérification que le wizard se ferme après génération
- [ ] Vérification que PlanWeekView affiche correctement les repas
- [ ] Gestion des erreurs (réseau, timeout, etc.)
- [ ] Navigation back/next entre les étapes
- [ ] Quick actions (select all, deselect all, etc.)

## 📝 Notes techniques

- Le code legacy est maintenu pour compatibilité (propriétés `days`, `mealPrepDays`, etc.)
- Les nouvelles propriétés granulaires (`mealSlots`, `selectedSlots`, etc.) sont utilisées en priorité
- PreferencesStepView.swift n'est pas supprimé du projet (garde pour référence)
- WizardSuccessView.swift n'est pas supprimé du projet (garde pour référence)

## 🚀 Prochaines améliorations possibles

1. Ajouter un feedback haptique lors de la sélection
2. Animation de transition vers PlanWeekView
3. Toast notification "Semaine générée avec succès"
4. Possibilité de régénérer depuis le wizard directement
5. Sauvegarde des dernières sélections du wizard

---

**Statut**: ✅ Implémenté et prêt pour tests
**Impact**: Amélioration significative de l'UX du wizard
