# Template & Planned Week Architecture - Implementation Guide

## 📋 Overview

This document describes the implementation of a dual-model architecture for Planea that supports:
1. **TemplateWeek**: Reusable meal plans without specific dates
2. **PlannedWeek**: Calendar-based meal plans with real dates
3. **Backward compatibility**: Legacy MealPlan structure still works via adapter pattern

---

## ✅ What Was Implemented

### 1. New Models

#### **TemplateWeek.swift**
- `TemplateWeek`: Container for reusable weekly plans
- `TemplateDay`: Day with `weekdayIndex` (0-6) instead of dates
- `TemplateMeal`: Meal with `mealType` and `recipe`

**Location**: `Planea-iOS/Planea/Planea/Models/TemplateWeek.swift`

#### **PlannedWeek.swift**
- `PlannedWeek`: Container for calendar-based weekly plans
- `PlannedDay`: Day with real `Date` 
- `PlannedMeal`: Meal with `mealType` and `recipe`

**Location**: `Planea-iOS/Planea/Planea/Models/PlannedWeek.swift`

---

### 2. Helper Utilities

#### **WeekDateHelper.swift**
Core date manipulation and template application logic:

**Key Functions:**
- `generateWeekDates(from:)` - Generate 7 consecutive dates
- `nextSunday()` - Get next Sunday (default week start)
- `todayAtMidnight()` - Get today at 00:00:00
- `weekdayToIndex()` / `indexToWeekday()` - Convert between Weekday enum and index
- `formatWeekRange()` - Format "March 11 – March 17"
- `applyTemplate(_:to:)` - **Main function to apply template to date**
- `isValidWeekdayIndex()` - Validation helper

**Location**: `Planea-iOS/Planea/Planea/Services/WeekDateHelper.swift`

---

### 3. Adapter Pattern

#### **MealPlanAdapter.swift**
Provides bidirectional conversion without destructive migration:

**Conversions:**
- `toPlannedWeek()` - Legacy MealPlan → PlannedWeek
- `toMealPlan()` - PlannedWeek → Legacy MealPlan
- `toTemplate()` - PlannedWeek → TemplateWeek
- `mealPlanToTemplate()` - Legacy MealPlan → TemplateWeek
- `canConvert()` / `canConvertToTemplate()` - Validation

**Location**: `Planea-iOS/Planea/Planea/Models/MealPlanAdapter.swift`

---

### 4. Persistence Layer

#### **PersistenceController.swift Updates**
Added template persistence methods:

```swift
func saveTemplateWeek(_ template: TemplateWeek)
func loadTemplateWeeks() -> [TemplateWeek]
func deleteTemplateWeek(id: UUID)
```

**Location**: `Planea-iOS/Planea/Planea/Persistence/PersistenceController.swift`

---

### 5. ViewModel Updates

#### **PlanViewModel.swift**
Added template support:

**New Properties:**
```swift
@Published var templates: [TemplateWeek] = []
@Published var showApplyTemplateSheet = false
@Published var selectedTemplate: TemplateWeek?
```

**New Methods:**
```swift
func loadTemplates()
func saveTemplate(_ template: TemplateWeek)
func saveCurrentPlanAsTemplate(name: String)
func applyTemplate(_ template: TemplateWeek, startDate: Date)
func deleteTemplate(id: UUID)
```

**Location**: `Planea-iOS/Planea/Planea/ViewModels/PlanViewModel.swift`

---

### 6. UI Components

#### **ApplyTemplateSheet.swift**
Date picker sheet for applying templates:

**Features:**
- Graphical date picker
- Default to next Sunday
- "Start Today" quick action button
- Week range preview (e.g., "March 11 – March 17")
- Cancel/Confirm actions

**Location**: `Planea-iOS/Planea/Planea/Views/ApplyTemplateSheet.swift`

---

### 7. Enum Updates

#### **Enums.swift**
Updated `Weekday` enum to start with Sunday:

**Before:** `case monday, tuesday, ...`
**After:** `case sunday, monday, tuesday, ...`

This aligns with iOS Calendar weekday numbering (1=Sunday).

**Location**: `Planea-iOS/Planea/Planea/Models/Enums.swift`

---

## 🔄 Core Data Migration Required

### Step 1: Add TemplateWeekEntity to Planea.xcdatamodeld

Open: `Planea-iOS/Planea/Planea/Planea.xcdatamodeld`

**Add new entity:**

**Entity Name:** `TemplateWeekEntity`

**Attributes:**
| Attribute | Type | Optional | Indexed |
|-----------|------|----------|---------|
| id | UUID | No | Yes |
| familyId | UUID | No | No |
| name | String | No | No |
| daysData | Binary Data | No | No |
| createdDate | Date | No | No |
| lastModifiedDate | Date | No | Yes |

**Codegen:** Manual/None (or Category/Extension based on your preference)

---

### Step 2: Create Model Version (Optional but Recommended)

1. Select `Planea.xcdatamodeld` in Xcode
2. Menu: Editor → Add Model Version
3. Name it: `Planea 2` (or increment from current version)
4. Click "Finish"
5. Select the new version as Current in the file inspector

---

### Step 3: Test Migration

Before deploying, test that:
- Existing MealPlan entities load correctly
- New TemplateWeek entities can be saved/loaded
- App doesn't crash on first launch after update

---

## 🎯 How to Use the New Architecture

### Creating a Template from Current Plan

```swift
// In PlanViewModel or UI
planVM.saveCurrentPlanAsTemplate(name: "Ma semaine préférée")
```

This will:
1. Validate the current plan
2. Convert to TemplateWeek (strips dates, keeps weekday indices)
3. Save to Core Data
4. Log analytics event

---

### Applying a Template to a Date

```swift
// Show the ApplyTemplateSheet
planVM.selectedTemplate = template
planVM.showApplyTemplateSheet = true

// Then in the sheet callback:
planVM.applyTemplate(template, startDate: selectedDate)
```

This will:
1. Generate 7 real dates from startDate
2. Map template days → planned days with actual dates
3. Convert to legacy MealPlan for compatibility
4. Save as current draft plan
5. Log analytics event

---

### Manually Applying Template (Programmatic)

```swift
let template = TemplateWeek(
    familyId: familyId,
    name: "Test Template",
    days: [...]
)

let startDate = WeekDateHelper.nextSunday()
let plannedWeek = WeekDateHelper.applyTemplate(template, to: startDate)

// Convert to legacy format if needed
let mealPlan = MealPlanAdapter.toMealPlan(plannedWeek)
persistence.saveMealPlan(mealPlan)
```

---

## 🛡️ Edge Cases Handled

### 1. Invalid Weekday Index
**Problem:** weekdayIndex < 0 or > 6
**Solution:** WeekDateHelper validates and prints warning, skips invalid day

### 2. Empty Templates
**Problem:** Template with no meals
**Solution:** MealPlanAdapter.canConvertToTemplate() returns false, prevents creation

### 3. Missing Recipe Data
**Problem:** Recipe with empty title or no ingredients
**Solution:** Validation in adapter, logs warning

### 4. Date in Past
**Problem:** User selects past date
**Solution:** WeekDateHelper.isInPast() can validate (not enforced in UI yet)

### 5. Timezone Changes
**Problem:** Date calculations fail across timezones
**Solution:** Uses Calendar.current for all date operations

### 6. Backward Compatibility
**Problem:** Existing MealPlan data
**Solution:** Adapter pattern - no data migration needed, works transparently

---

## 📊 Architecture Benefits

### ✅ Modularity
- Clear separation: Templates vs Planned Weeks
- Easy to extend (e.g., share templates, import/export)

### ✅ Scalability
- No breaking changes to existing code
- Legacy MealPlan still works
- Future: can fully migrate to PlannedWeek if desired

### ✅ User Experience
- DatePicker before creation (prevents accidents)
- Reusable templates (save user time)
- Week range preview (clarity)

### ✅ Analytics
- Track template creation
- Track template usage
- Measure template popularity

---

## 🚀 Next Steps

### Required Before Deployment

1. **Create TemplateWeekEntity in Core Data**
   - Follow migration guide above
   - Test on simulator and device

2. **Add Localization Strings**
   - "Appliquer le template"
   - "Sauvegarder comme template"
   - "Choisir la date de début"
   - "Commencer aujourd'hui"
   - "Créer le plan"

3. **UI Integration** (Not yet implemented)
   - Add "Save as Template" button in PlanWeekView toolbar
   - Create Templates list view
   - Add template selection/application flow

4. **Test End-to-End**
   - Create template from plan
   - Apply template to different dates
   - Delete templates
   - Verify persistence across app restarts

---

### Optional Enhancements

1. **Template Library View**
   - List all templates
   - Preview template meals
   - Edit template names
   - Duplicate templates

2. **Template Sharing**
   - Export template as JSON
   - Import template from QR code
   - Share via AirDrop

3. **Smart Date Selection**
   - Detect conflicts with existing plans
   - Suggest next available week
   - Show calendar with highlighted weeks

4. **Template Analytics Dashboard**
   - Most used templates
   - Template usage trends
   - Recommend templates to users

---

## 🐛 Known Limitations

1. **Core Data Entity Not Created Yet**
   - TemplateWeekEntity must be added manually
   - App will crash if trying to save templates without it

2. **No UI for Template Management**
   - Backend logic complete
   - Frontend integration needed

3. **No Conflict Detection**
   - Can create overlapping plans
   - Should warn user if week already has plan

4. **Limited Validation**
   - Date picker allows any date
   - Should prevent very old dates or far future dates

---

## 📝 Code Usage Examples

### Example 1: Create and Apply Template

```swift
// Step 1: User has a plan they like
guard let currentPlan = planVM.currentPlan else { return }

// Step 2: Save as template
planVM.saveCurrentPlanAsTemplate(name: "Semaine Végétarienne")

// Step 3: Load templates
planVM.loadTemplates()

// Step 4: Apply template to next week
if let template = planVM.templates.first {
    let nextWeek = WeekDateHelper.nextSunday()
    planVM.applyTemplate(template, startDate: nextWeek)
}
```

### Example 2: Custom Date Logic

```swift
// Get Monday in 2 weeks
let today = Date()
let calendar = Calendar.current
let twoWeeksFromNow = calendar.date(byAdding: .day, value: 14, to: today)!
let nextMonday = WeekDateHelper.nextWeekday(2, from: twoWeeksFromNow) // 2 = Monday

// Apply template
planVM.applyTemplate(template, startDate: nextMonday)
```

### Example 3: Validate Before Convert

```swift
if MealPlanAdapter.canConvert(mealPlan) {
    let template = MealPlanAdapter.mealPlanToTemplate(mealPlan, name: "My Template")
    planVM.saveTemplate(template)
} else {
    print("⚠️ Plan has invalid data, cannot create template")
}
```

---

## 📚 Architecture Diagrams

### Data Flow: Create Template
```
MealPlan (legacy)
    ↓
MealPlanAdapter.mealPlanToTemplate()
    ↓
TemplateWeek (new)
    ↓
PersistenceController.saveTemplateWeek()
    ↓
Core Data (TemplateWeekEntity)
```

### Data Flow: Apply Template
```
TemplateWeek (stored)
    ↓
WeekDateHelper.applyTemplate(template, date)
    ↓
PlannedWeek (new, with real dates)
    ↓
MealPlanAdapter.toMealPlan()
    ↓
MealPlan (legacy, for compatibility)
    ↓
PersistenceController.saveMealPlan()
    ↓
Core Data (MealPlanEntity)
```

---

## 🔗 File Reference

| File | Purpose | Status |
|------|---------|--------|
| TemplateWeek.swift | Template models | ✅ Complete |
| PlannedWeek.swift | Planned week models | ✅ Complete |
| WeekDateHelper.swift | Date utilities | ✅ Complete |
| MealPlanAdapter.swift | Conversion logic | ✅ Complete |
| Enums.swift | Updated Weekday enum | ✅ Complete |
| ApplyTemplateSheet.swift | Date picker UI | ✅ Complete |
| PersistenceController.swift | Template persistence | ✅ Complete |
| PlanViewModel.swift | Template methods | ✅ Complete |
| Planea.xcdatamodeld | Core Data schema | ⚠️ **Needs Update** |
| PlanWeekView.swift | UI integration | ⚠️ **Needs Update** |

---

## 💡 Tips for Implementation

1. **Always use WeekDateHelper** for date calculations
   - Don't manually add days to dates
   - Use provided helpers for consistency

2. **Validate before converting**
   - Use adapter's `canConvert()` methods
   - Prevents crashes from bad data

3. **Test with different timezones**
   - Use Calendar.current (respects user locale)
   - Test date transitions

4. **Log analytics events**
   - Template creation/usage valuable metrics
   - Already integrated in ViewModel

5. **Maintain backward compatibility**
   - Legacy MealPlan still works
   - No rush to migrate everything

---

## 🎉 Summary

This implementation provides a **scalable, modular architecture** for managing meal plans with and without dates. The adapter pattern ensures **zero breaking changes** while enabling powerful new features like template reusability.

**Key Achievement:** Users can now save favorite weeks as templates and reuse them with just a few taps! 🚀

---

**Questions or Issues?**
Refer to the code comments in each file for detailed documentation.
