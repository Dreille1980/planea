# 🎨 UI/Branding Implementation - Version "moins pastel / plus pro"

**Date:** 22 janvier 2026  
**Commit:** fc23783

## 📋 Objectif

Transformer l'interface de l'écran "Plan de la semaine" avec une identité visuelle plus affirmée, plus contrastée et plus professionnelle, tout en restant iOS-native et lisible.

## 🎨 Palette de couleurs implémentée

### Couleurs de marque

| Couleur | Hex | Usage |
|---------|-----|-------|
| **Bleu ardoise** (Primaire) | `#4E6FAE` | Bouton "✨ Générer le plan", icône active bottom tab, underline segmented control |
| **Orange brûlé** (Secondaire) | `#E38A3F` | Mot clé "Planifiez" dans titre, chip sélectionné (fond 15% opacité), icône ✨ |
| **Vert sauge foncé** (Tertiaire) | `#7FA19B` | Barre verticale gauche des cartes jour (4px, 100% opacité) |

### Neutres

| Couleur | Hex | Usage |
|---------|-----|-------|
| Fond principal | `#F2F3F7` | Background de l'app |
| Cartes | `#FFFFFF` | Fond des cartes |
| Texte principal | `#1C1C1E` | Titres, contenu important |
| Texte secondaire | `#6B7280` | Descriptions, labels |
| Bordures | `#E5E7EB` | Bordures légères |
| Chips par défaut | `#F1F2F6` | Fond chips non sélectionnés |

## 📁 Fichiers créés

### 1. `PlaneaColors.swift`
- Extension `Color` avec toutes les couleurs de la palette
- Helper `init(hex:)` pour convertir les codes hex en couleurs SwiftUI
- Documentation complète de chaque couleur et son usage STRICT

### 2. `PlaneaSegmentedControlStyle.swift`
- Modifier ViewModifier réutilisable `PlaneaSegmentedPickerStyle`
- Extension `.planeaSegmentedStyle()` pour application facile
- Style avec underline bleu ardoise pour l'onglet actif

## 🔄 Fichiers modifiés

### 1. `PlanWeekView.swift`

#### Header
- ✅ Ajout du logo Planea ("logo new 2") monochrome 16-18px
- ✅ Titre "Planifiez votre semaine" avec AttributedString (mot "Planifiez" en orange)
- ✅ Sous-titre en texte secondaire

#### Cartes jour (DaySelectionRow)
- ✅ Barre verticale verte (4px, vert sauge foncé, 100% opacité) à gauche
- ✅ Fond blanc avec ombre légère
- ✅ Texte jour en texte primaire

#### Chips repas (MealPillButton)
- ✅ État par défaut : Fond gris clair (#F1F2F6), texte noir
- ✅ État sélectionné : Fond orange à 15% opacité, texte noir
- ✅ Icônes contextuelles : ☀️ Déjeuner, 🍽️ Dîner, 🌙 Souper

#### Bouton principal "✨ Générer le plan"
- ✅ Fond bleu ardoise (#4E6FAE)
- ✅ Texte et icône ✨ en blanc
- ✅ État disabled : bleu à 40%, texte blanc à 60%
- ✅ Corners très arrondis (12px)

#### Cartes jour affichées (DayCardView)
- ✅ Barre verticale verte (4px) à gauche
- ✅ Fond blanc, ombre légère
- ✅ Badge compteur en fond gris clair
- ✅ Divider avec couleur planeaBorder

### 2. `RecipesView.swift`

#### Segmented Control (Recettes / Prépa-repas / Ad hoc)
- ✅ Application du style `.planeaSegmentedStyle()`
- ✅ Underline bleu ardoise pour l'onglet actif
- ✅ Fond `planeaBackground`

### 3. `PlaneaApp.swift`

#### Bottom Tab Bar
- ✅ Ajout de `.tint(.planeaPrimary)` sur le TabView
- ✅ Icônes actives en bleu ardoise
- ✅ Icônes inactives en gris système (par défaut)

## ✅ Contraintes respectées

- ✅ Aucune modification de structure
- ✅ Aucun ajout de sections
- ✅ Pas de fond coloré plein écran
- ✅ Logo monochrome (pas coloré)
- ✅ Maximum 2 couleurs fortes visibles simultanément
- ✅ Usage STRICT des couleurs selon les specs

## 🎯 Résultat attendu

L'interface est maintenant :
- ✅ Plus pro, moins "soft"
- ✅ Hiérarchie visuelle claire
- ✅ Couleur utilisée comme signal d'action
- ✅ Identité Planea présente mais discrète
- ✅ Sensation : "je contrôle ma semaine"

## 🔧 Prochaines étapes

1. **Tester dans Xcode** : Compiler et vérifier que tout fonctionne
2. **Ajouter les fichiers au projet Xcode** : S'assurer que PlaneaColors.swift et PlaneaSegmentedControlStyle.swift sont dans le target
3. **Vérifier "logo new 2.png"** : S'assurer que l'image est accessible dans Assets.xcassets
4. **Tests visuels** : Lancer l'app et vérifier chaque écran
5. **Dark mode** (optionnel) : Ajuster les couleurs si nécessaire pour le mode sombre

## 📝 Notes techniques

- Les couleurs sont définies en extension de `Color` pour être réutilisables partout
- Le style de segmented control est un ViewModifier réutilisable
- AttributedString utilisé pour le titre bicolore (approche propre et moderne)
- Les icônes contextuelles des chips sont des emojis natifs (☀️🍽️🌙)
- La barre verticale verte est un simple `Rectangle()` avec `frame(width: 4)`

## 🚀 Commit Git

```bash
git add -A
git commit -m "🎨 UI/Branding: Nouvelle identité visuelle 'moins pastel / plus pro'"
git push origin main
```

✅ **Commit poussé vers GitHub avec succès !**
