# 🚀 Meal Prep UI - Phase 2 : Fonctionnalités Avancées

## Statut : Reporté (Focus actuel : Phase 1 - UI Refactoring)

---

## 📋 Vue d'ensemble

Ce document liste les fonctionnalités avancées identifiées lors de la conception de l'interface Meal Prep, mais reportées en Phase 2 pour prioriser l'amélioration de l'UX de base.

---

## 🔄 1. Regroupement Intelligent d'Étapes

### Objectif
Fusionner automatiquement les étapes similaires entre plusieurs recettes pour optimiser le workflow de cuisine.

### Exemple concret
**Avant :**
- Étape 2 : Chauffer l'huile (Poulet Zen)
- Étape 5 : Chauffer l'huile (Bœuf Thaï)

**Après :**
- Étape 2 : Chauffer l'huile **pour Poulet Zen ET Bœuf Thaï**

### Complexité
- **Backend :** Analyse sémantique des instructions pour détecter les similarités
- **Frontend :** Affichage des étapes fusionnées avec badges multiples
- **Logique :** Matching intelligent (même action + même timing)

### Estimation
**3-4 jours de développement**

### Dépendances
- Modification de l'API backend `/meal-prep/generate`
- Nouvelle structure de données pour étapes groupées
- Tests avec différentes combinaisons de recettes

---

## 🎙️ 2. Mode Mains Libres Avancé (Commande Vocale)

### Objectif
Permettre la navigation entre les étapes à la voix, sans toucher l'écran (mains sales/mouillées).

### Fonctionnalités
- **Commandes vocales :**
  - "Suivant" / "Next" → Avance à l'étape suivante
  - "Précédent" / "Previous" → Retour à l'étape précédente
  - "Répète" / "Repeat" → Re-lit l'instruction actuelle
  - "Minuteur X minutes" → Lance un timer

### Technologie
- `SpeechRecognitionService` (déjà présent dans l'app)
- Reconnaissance en continu (mode "always listening" en cuisine)
- Feedback sonore pour confirmation

### Complexité
- Configuration du microphone en mode continu
- Filtrage du bruit ambiant (eau, casseroles, etc.)
- Consommation batterie optimisée
- Multi-langue (FR/EN)

### Estimation
**2-3 jours de développement**

### Dépendances
- Permission Microphone (déjà gérée)
- Tests en conditions réelles de cuisine

---

## 📸 3. Visuels d'Ingrédients Avancés

### Objectif
Remplacer les emojis par de vraies miniatures photographiques des ingrédients.

### Options envisagées

#### Option A : API externe
- **Spoonacular API** (https://spoonacular.com/food-api)
  - Base de données de 5000+ ingrédients
  - Images haute qualité
  - Coût : ~0.002$ par requête
  
- **Unsplash API**
  - Images gratuites
  - Qualité variable
  - Nécessite recherche + filtrage

#### Option B : Bibliothèque locale
- Assets personnalisés (~100 ingrédients courants)
- Pas de dépendance réseau
- Contrôle total du style visuel

#### Option C : Hybride
- Assets locaux pour ingrédients courants
- API de fallback pour ingrédients rares
- Meilleur compromis performance/couverture

### Estimation
**1-2 jours de développement** (Option B)  
**3-4 jours de développement** (Option C avec cache)

---

## 🧠 4. Suggestions Intelligentes Contextuelles

### Objectif
Proposer des micro-tâches optimisées pendant les temps d'attente.

### Exemples
- "Vous avez 5 minutes pendant que l'eau bout → Préparez les légumes ?"
- "Le riz cuit pendant 20 min → Préparez la sauce maintenant ?"
- "Temps libre détecté → Nettoyez votre plan de travail ?"

### Logique
1. **Analyse des temps d'attente :**
   - Détection des étapes "passives" (cuisson, marinade, repos)
   
2. **Matching avec micro-tâches :**
   - Cherche des étapes courtes non bloquantes
   - Priorise selon dépendances
   
3. **Notification contextuelle :**
   - Toast/Banner discret
   - Option "Ignorer" ou "Accepter"

### Complexité
- Graphe de dépendances entre étapes
- Algorithme de scheduling optimisé
- UX non-intrusive

### Estimation
**3-4 jours de développement**

---

## 📊 5. Analytics & Gamification

### Objectif
Tracker les performances de meal prep pour encourager l'amélioration.

### Métriques proposées
- Temps réel vs estimé
- Taux de complétion
- Séries de jours consécutifs
- Badges de réussite

### Fonctionnalités
- Graphique d'évolution du temps de prep
- Comparaison avec communauté (optionnel)
- Achievements débloquables

### Estimation
**2-3 jours de développement**

---

## 🔧 6. Personnalisation Avancée

### Objectif
Adapter l'interface aux préférences de l'utilisateur.

### Options
- **Thème cuisine :**
  - Mode "Chef Pro" (dense, compact)
  - Mode "Débutant" (spacieux, explicatif)
  
- **Affichage des temps :**
  - Format 12h/24h
  - Countdown vs temps écoulé
  
- **Langue des unités :**
  - Métrique (g, ml, L)
  - Impérial (oz, cups, tbsp)

### Estimation
**1-2 jours de développement**

---

## 🎯 Priorisation Recommandée (Phase 2)

### Priorité Haute (Impact utilisateur fort)
1. **Regroupement intelligent** → Gain de temps réel
2. **Mode mains libres** → Hygiène + praticité

### Priorité Moyenne
3. **Suggestions intelligentes** → Optimisation workflow
4. **Visuels avancés** → Amélioration esthétique

### Priorité Basse (Nice to have)
5. **Analytics/Gamification** → Engagement long-terme
6. **Personnalisation** → Confort utilisateur

---

## 📅 Calendrier Provisoire

**Si Phase 1 terminée le :** 16 janvier 2026

**Phase 2 pourrait commencer :** Février 2026

**Durée estimée totale :** 2-3 semaines (selon priorisation)

---

## 💡 Idées Supplémentaires (Backlog)

- **Mode offline** : Cache des instructions pour cuisine sans connexion
- **Partage de progression** : "Je suis à l'étape 5/12" → partageable
- **Intégration Apple Watch** : Timer + notifications au poignet
- **Mode nuit/cuisine sombre** : Économie batterie + moins éblouissant
- **Export PDF** : Imprimer la checklist pour cuisine sans écran

---

## 🚀 Notes de mise en œuvre

- **Tests utilisateurs recommandés** avant chaque feature
- **AB Testing** pour regroupement intelligent (opt-in Phase 2.1)
- **Feedback loop** : Collecter retours sur suggestions IA
- **Performance monitoring** : Temps de réponse API < 2s

---

**Dernière mise à jour :** 16 janvier 2026  
**Statut :** En attente de validation Phase 1
