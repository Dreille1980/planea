# Recipes Hub Implementation

## Overview

This implementation completely refactors the Recipes section of the Planea app to provide a hub-based navigation with three main options for users.

## Changes Made

### 1. New RecipesHubView (`RecipesHubView.swift`)

A new hub view that serves as the entry point for the Recipes tab with three action cards:

- **Consulter le plan** (View Plan) - View the active weekly plan or create a new one if none exists
- **Générer un nouveau plan** (Generate New Plan) - Opens the week generation wizard
- **Recette ad hoc** (Ad Hoc Recipe) - Generate a single recipe instantly

The hub shows:
- An "Active" badge if there's an existing plan
- Prompts the user to create a plan if none exists
- Beautiful card-based UI with icons and descriptions

### 2. Refactored RecipesView (`RecipesView.swift`)

Changed from segmented control to state-based navigation using `RecipesAction` enum:
- `.viewPlan` - Shows PlanWeekView
- `.generatePlan` - Shows WeekGenerationWizardView
- `.adHoc` - Shows AdHocRecipeContentView

Navigation includes a back button to return to the hub from any sub-view.

### 3. Updated WeekGenerationConfig (`WeekGenerationConfig.swift`)

Added new granular slot selection model:
- `MealSlot` struct for individual lunch/dinner slots per day
- `SlotType` enum (simple vs mealPrep)
- Methods for toggling and configuring slots
- Support for both simple recipes and meal prep in the same plan

### 4. New DaySelectionStepView (`DaySelectionStepView.swift`)

Completely redesigned the day selection UI:
- Each day shows Lunch and Dinner as separate selectable chips
- Long-press toggles between Simple and Meal Prep
- Quick action buttons for bulk operations (Select All, Deselect All, All Meal Prep, All Simple)
- Summary showing counts of simple vs meal prep selections

### 5. Enhanced MealPlan and MealItem Models (`MealPlan.swift`)

Added meal prep support to the core models:
- `isMealPrep` flag on MealItem
- `mealPrepSessionId` for grouping meal prep items
- `dayOfSteps` for day-of-consumption instructions
- `isPrepared` status tracking
- `MealPrepSession` struct for consolidated view

### 6. Updated PlanWeekView (`PlanWeekView.swift`)

Added visual indicators for meal prep items:
- `MealPrepBadge` component showing "Meal Prep" or "Prepared" status
- `DayOfStepsView` for displaying day-of instructions
- Orange-tinted background for meal prep items
- Custom icons for meal prep items

### 7. Auto-generated Shopping List (`PlanViewModel.swift`)

When a plan is saved:
- Automatically generates the shopping list
- References `ShoppingViewModel` via weak reference
- Analytics tracking for auto-generated lists

### 8. Localizations

Added new localization keys in both French and English:
- `recipes.hub.*` - Hub UI strings
- `wizard.step1.subtitle.new` - New wizard subtitle
- `wizard.quick_action.*` - Quick action buttons
- `wizard.slot_type.*` - Slot type labels
- `plan.mealprep.*` - Meal prep badge and indicators
- `wizard.error.*` - Localized error messages

## User Flow

1. User opens "Recettes" tab
2. Hub shows 3 options
3. **Option 1 - View Plan:**
   - If active plan exists → Shows PlanWeekView with all meals
   - If no plan → Shows alert to create one
4. **Option 2 - Generate Plan:**
   - Opens wizard with day/meal selection
   - User selects lunch/dinner for each day
   - User can mark meals as simple or meal prep (long press)
   - After generation, plan is shown with shopping list auto-created
5. **Option 3 - Ad Hoc:**
   - Shows text/photo input for single recipe generation
   - Same functionality as before

## Family Parameters

All generations respect:
- Family dietary constraints (vegetarian, vegan, etc.)
- Allergens of all family members
- Disliked ingredients
- Preferred proteins (from generation preferences)
- Cooking time preferences

## Technical Notes

- Uses SwiftUI's `@State` for navigation flow
- `EnvironmentObject` for sharing ViewModels
- Localized strings with `.localized` extension
- Analytics events for all major actions
- Haptic feedback on interactions

## Files Modified

1. `RecipesView.swift` - Complete refactor
2. `RecipesHubView.swift` - New file
3. `WeekGenerationConfig.swift` - Added slot-based model
4. `DaySelectionStepView.swift` - New UI
5. `WeekGenerationConfigViewModel.swift` - New slot methods
6. `MealPlan.swift` - Meal prep fields
7. `PlanWeekView.swift` - Meal prep indicators
8. `PlanViewModel.swift` - Auto shopping list
9. `fr.lproj/Localizable.strings` - New strings
10. `en.lproj/Localizable.strings` - New strings

## Future Improvements

- [ ] Backend endpoint for meal prep-specific generation
- [ ] Meal prep session consolidated view
- [ ] Day-of steps auto-generated from backend
- [ ] Mark individual meal preps as prepared
