# Planea - Family Meal Planning App

A native iOS app for family meal planning with AI-powered recipe generation.

## 🎯 Features

- **Family Management**: Create family profiles with member preferences, dietary restrictions, and allergens
- **Smart Meal Planning**: Select specific meal slots (21 combinations: 7 days × 3 meal types) and generate AI-powered meal plans
- **Recipe Details**: View complete recipes with ingredients, steps, cooking time, and equipment
- **Shopping Lists**: Auto-generated shopping lists from meal plans with ingredient aggregation
- **Ad-hoc Recipes**: Generate custom recipes from free-text prompts
- **Bilingual**: Full support for French and English
- **Unit Systems**: Metric and Imperial unit support
- **100% Local**: All data stored locally on device (no login required)

## 🏗️ Architecture

- **Language**: Swift 5.10+
- **Framework**: SwiftUI
- **Pattern**: MVVM
- **Persistence**: In-memory (SwiftData coming soon)
- **Network**: URLSession + Codable
- **Compatibility**: iOS 16+

## 📁 Project Structure

```
Planea-iOS/
├── PlaneaApp.swift           # App entry point
├── Models/                   # Data models
│   ├── Enums.swift
│   ├── Family.swift
│   ├── Member.swift
│   ├── MealPlan.swift
│   ├── Recipe.swift
│   └── ShoppingList.swift
├── ViewModels/               # Business logic
│   ├── FamilyViewModel.swift
│   ├── PlanViewModel.swift
│   ├── RecipeViewModel.swift
│   └── ShoppingViewModel.swift
├── Views/                    # UI components
│   ├── OnboardingView.swift
│   ├── PlanWeekView.swift
│   ├── RecipeDetailView.swift
│   ├── ShoppingListView.swift
│   ├── AdHocRecipeView.swift
│   └── SettingsView.swift
├── Services/                 # External services
│   ├── IAService.swift
│   └── UnitConverter.swift
├── Persistence/              # Data persistence
│   └── PersistenceController.swift
└── Resources/                # Localization
    ├── Localizable.strings (FR)
    └── Localizable-en.strings (EN)
```

## 🚀 Getting Started

### Prerequisites

- macOS with Xcode 15.0+
- Python 3.8+ (for mock server)
- iOS 16+ device or simulator

### Setup

1. **Start the Mock AI Server**:
   ```bash
   cd mock-server
   pip install -r requirements.txt
   uvicorn main:app --reload --port 8000
   ```

2. **Open in Xcode**:
   ```bash
   cd Planea-iOS
   open Planea.xcodeproj
   ```
   
   Or create the Xcode project:
   ```bash
   # If you have xcodegen installed
   xcodegen generate
   
   # Otherwise, open Xcode and create a new iOS App project
   # Then add all the Swift files from the Planea-iOS directory
   ```

3. **Build and Run**:
   - Select your target device/simulator
   - Press Cmd+R to build and run

### Quick Start Guide

1. **Setup Family**: Go to the "Famille" tab and enter your family name, add members
2. **Plan Meals**: Go to "Plan" tab, select meal slots (e.g., Monday breakfast, Tuesday dinner), tap "Generate Plan"
3. **View Recipes**: Tap any meal to see the full recipe details
4. **Shopping List**: Go to "Épicerie" tab to see the auto-generated shopping list
5. **Custom Recipe**: Use "Recette ad hoc" tab to generate a recipe from a free-text prompt

## 🔧 Configuration

### Change Language
Settings → Language → Select French/English/System

### Change Units
Settings → Units → Select Metric/Imperial

### Mock Server URL
The app connects to `http://localhost:8000` by default. To change this, update the URL in:
- `PlanWeekView.swift` (line ~95)
- `AdHocRecipeView.swift` (line ~55)

## 📝 API Endpoints

### POST /ai/plan
Generate a meal plan for selected slots.

**Request**:
```json
{
  "week_start": "2025-01-13",
  "units": "METRIC",
  "slots": [
    {"weekday": "Mon", "meal_type": "BREAKFAST"},
    {"weekday": "Mon", "meal_type": "DINNER"}
  ],
  "constraints": {
    "diet": ["vegetarian"],
    "evict": ["nuts", "dairy"]
  }
}
```

**Response**: Returns a `PlanResponse` with meal items.

### POST /ai/recipe
Generate a single recipe from a prompt.

**Request**:
```json
{
  "idea": "chicken and broccoli, 30 min, 4 servings",
  "servings": 4,
  "units": "METRIC",
  "constraints": {}
}
```

**Response**: Returns a `Recipe` object.

## 🎨 Features in Detail

### Fine-Grained Meal Selection
- Select exactly which meals to generate (21 possible combinations)
- Mix and match: breakfast only, dinners only, or any combination
- Efficient: only generate what you need

### Family Preferences
- Per-member dietary preferences (vegetarian, vegan, etc.)
- Allergen tracking (nuts, dairy, gluten, etc.)
- Dislikes management
- Automatic constraint aggregation for the whole family

### Shopping List Intelligence
- Automatic ingredient aggregation (combines duplicate ingredients)
- Organized by category (produce, meats, dairy, etc.)
- Checkboxes to track shopping progress
- Export to text for sharing

## 🔮 Roadmap

- [ ] SwiftData persistence (replace in-memory storage)
- [ ] Recipe regeneration for individual meals
- [ ] Meal plan history
- [ ] Favorite recipes
- [ ] Custom ingredient substitutions
- [ ] Nutritional information
- [ ] Meal prep mode
- [ ] Widget support

## 📄 License

This project is a starter template for educational purposes.

## 🤝 Contributing

This is a starter project. Feel free to fork and customize for your needs!
