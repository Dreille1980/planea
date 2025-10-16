# Guide de soumission App Store - Planea

## ✅ Corrections automatiques complétées

Les éléments suivants ont été corrigés automatiquement :

1. **Sécurité réseau** : Configuration App Transport Security mise à jour
   - Remplacé `NSAllowsArbitraryLoads` par une exception spécifique pour `planea-production.up.railway.app`
   - Utilise TLS 1.2+ avec Forward Secrecy

2. **Traductions** : Permissions localisées ajoutées
   - NSRemindersUsageDescription en anglais et français

3. **Documents légaux** : Adresses email mises à jour
   - Support : `dreyerfred+planea@gmail.com`
   - Privacy : `dreyerfred+privacyplanea@gmail.com`

## 🚨 PROBLÈME CRITIQUE - Action requise IMMÉDIATEMENT

### Icône d'application manquante

**Statut** : ❌ BLOQUANT - Vous ne pouvez PAS soumettre sans icône

**Actions requises** :
1. Créer ou obtenir une icône 1024x1024px au format PNG
2. Dans Xcode, ouvrir `Planea-iOS/Planea/Planea/Assets.xcassets`
3. Cliquer sur `AppIcon`
4. Glisser-déposer votre icône 1024x1024px dans l'espace "App Store iOS 1024pt"
5. Xcode générera automatiquement toutes les autres tailles

**Spécifications de l'icône** :
- Format : PNG (sans transparence)
- Taille : 1024x1024 pixels
- Espace colorimétrique : sRGB ou P3
- Pas d'alpha channel (pas de transparence)
- Coins arrondis : NON (iOS les ajoutera automatiquement)

## 📝 Checklist de pré-soumission

### 1. Apple Developer Program
- [ ] Créer un compte Apple Developer (99 USD/an)
- [ ] Accepter tous les accords dans App Store Connect
- [ ] Configurer les informations fiscales et bancaires

### 2. App Store Connect - Configuration initiale

#### A. Créer l'app
- [ ] Aller sur https://appstoreconnect.apple.com
- [ ] Cliquer sur "My Apps" > "+" > "New App"
- [ ] Remplir les informations :
  - **Platform** : iOS
  - **Name** : Planea
  - **Primary Language** : French (ou English)
  - **Bundle ID** : Créer un nouveau Bundle ID (ex: `com.yourname.planea`)
  - **SKU** : Un identifiant unique (ex: `PLANEA001`)

#### B. Informations de base
- [ ] **Category** : Food & Drink (Primary)
- [ ] **Secondary Category** : Health & Fitness (optionnel)
- [ ] **Age Rating** : 4+ (Recommended)
  - Cocher "None" pour toutes les catégories sensibles

#### C. Pricing and Availability
- [ ] **Price** : Free
- [ ] **Availability** : All countries (ou sélectionner spécifiquement)

### 3. Abonnements (In-App Purchases)

#### Configuration dans App Store Connect
- [ ] Aller dans "Features" > "In-App Purchases"
- [ ] Créer un "Subscription Group" : "Planea Premium"
- [ ] Créer les 2 produits d'abonnement :

**Abonnement mensuel** :
- Product ID : `com.planea.subscription.monthly`
- Reference Name : Monthly Subscription
- Subscription Duration : 1 Month
- Price : $5.99 CAD (ou votre prix préféré)
- Free Trial : 1 Month (optionnel)
- Localizations :
  - EN : "Monthly Premium Access"
  - FR : "Accès Premium Mensuel"

**Abonnement annuel** :
- Product ID : `com.planea.subscription.yearly`
- Reference Name : Annual Subscription
- Subscription Duration : 1 Year
- Price : $54.99 CAD (ou votre prix préféré)
- Free Trial : 1 Month (optionnel)
- Localizations :
  - EN : "Annual Premium Access"
  - FR : "Accès Premium Annuel"

### 4. Documents légaux - URLs requises

**IMPORTANT** : Apple exige des URLs publiques pour vos documents légaux.

**Options** :
1. **GitHub Pages (GRATUIT - Recommandé)**
   - Créer un repo public GitHub
   - Activer GitHub Pages
   - URLs exemple :
     - https://yourname.github.io/planea/terms.html
     - https://yourname.github.io/planea/privacy.html

2. **Site web simple**
   - Créer un site basique (ex: avec Wix, WordPress, etc.)
   - Héberger les documents

**À faire** :
- [ ] Créer une page web pour Terms and Conditions (EN)
- [ ] Créer une page web pour Privacy Policy (EN)
- [ ] Optionnel : versions françaises séparées
- [ ] Noter les URLs pour les entrer dans App Store Connect

### 5. Métadonnées App Store

#### Descriptions (EN)
```
Name: Planea
Subtitle (max 30 char): AI-Powered Meal Planning

Description (max 4000 char):
Planea makes meal planning effortless with AI-powered recipe generation.

KEY FEATURES:
• Weekly meal planning with AI assistance
• Personalized recipes based on family preferences
• Smart shopping lists with export to Reminders
• Dietary restrictions and allergy management
• Multiple family member profiles
• Save your favorite recipes
• Bilingual: English & French

Perfect for busy families who want to:
- Save time on meal planning
- Reduce food waste
- Discover new recipes
- Accommodate everyone's preferences

SUBSCRIPTION:
Try all features free for 30 days! Choose monthly or annual plans after your trial.

PRIVACY:
Your data stays on your device. We respect your privacy.

Keywords (max 100 char, comma separated):
meal plan,recipe,cooking,grocery,family,ai,food,dinner,shopping list,meal prep
```

#### Descriptions (FR)
```
Name: Planea
Subtitle (max 30 char): Planification repas par IA

Description (max 4000 char):
Planea simplifie la planification des repas grâce à l'IA.

FONCTIONNALITÉS:
• Planification hebdomadaire avec IA
• Recettes personnalisées selon préférences
• Listes d'épicerie intelligentes
• Gestion allergies et restrictions
• Profils famille multiples
• Sauvegarde recettes favorites
• Bilingue : Français & Anglais

Parfait pour les familles occupées qui veulent :
- Gagner du temps
- Réduire le gaspillage alimentaire
- Découvrir de nouvelles recettes
- Accommoder tous les goûts

ABONNEMENT:
Essai gratuit de 30 jours ! Plans mensuel ou annuel après l'essai.

Keywords (max 100 char, comma separated):
planification repas,recette,cuisine,épicerie,famille,ia,nourriture,souper,liste
```

### 6. Screenshots requis

**IMPORTANT** : Vous devez fournir des screenshots pour AU MOINS 2 tailles d'écran.

**Tailles requises** :
- **6.7"** : 1290 x 2796 pixels (iPhone 15 Pro Max) - REQUIS
- **6.5"** : 1242 x 2688 pixels (iPhone 11 Pro Max) - REQUIS
- **5.5"** : 1242 x 2208 pixels (iPhone 8 Plus) - Optionnel

**Nombre de screenshots** : 3-10 par taille d'écran

**Contenu suggéré** :
1. Écran d'accueil / Planning hebdomadaire
2. Détail d'une recette
3. Liste d'épicerie
4. Gestion de la famille
5. Génération de recette avec IA (optionnel)

**Comment les créer** :
1. Utiliser le simulateur Xcode
2. Cmd+S pour capturer l'écran
3. Les screenshots sont sauvés sur le Bureau
4. Ou utiliser App Store Connect pour les créer avec des outils de design

**Alternative** : Utiliser un outil comme Screenshots.pro ou Mockuuups

### 7. Informations de contact

Dans App Store Connect, sous "App Information" :
- [ ] **Support URL** : URL vers votre site ou page GitHub
- [ ] **Marketing URL** : Même URL (optionnel)
- [ ] **Privacy Policy URL** : URL de votre Privacy Policy hébergée

### 8. App Privacy - Déclaration de collecte de données

Dans App Store Connect > "App Privacy" :
- [ ] Déclarer les types de données collectées

**Données à déclarer** :
- **Contact Info** : None
- **Health & Fitness** : None
- **Financial Info** : None
- **Location** : None
- **Sensitive Info** : None
- **Contacts** : None
- **User Content** :
  - Meal plans ✓
  - Recipes saved ✓
  - Family profiles ✓
  - Purpose : App Functionality
  - Linked to User : No
  - Used for Tracking : No
- **Identifiers** : None
- **Usage Data** : None
- **Diagnostics** :
  - Crash Data ✓
  - Purpose : App Functionality
  - Linked to User : No

### 9. Build et soumission dans Xcode

#### A. Configuration du projet
1. Ouvrir `Planea.xcodeproj` dans Xcode
2. Sélectionner le target "Planea"
3. Aller dans "Signing & Capabilities"
4. Cocher "Automatically manage signing"
5. Sélectionner votre Team (Apple Developer account)
6. Vérifier que le Bundle Identifier correspond à celui créé dans App Store Connect

#### B. Créer l'archive
1. Dans Xcode, sélectionner "Any iOS Device" comme destination
2. Menu : Product > Archive
3. Attendre la compilation (peut prendre plusieurs minutes)
4. Une fois terminé, l'Organizer s'ouvre automatiquement

#### C. Upload vers App Store Connect
1. Dans l'Organizer, sélectionner votre archive
2. Cliquer "Distribute App"
3. Sélectionner "App Store Connect"
4. Cliquer "Upload"
5. Cocher toutes les options (Bitcode, symbols, etc.)
6. Cliquer "Upload"
7. Attendre la fin de l'upload (5-10 minutes)

#### D. Traitement par Apple
- Après l'upload, Apple prend 15-60 minutes pour traiter le build
- Vous recevrez un email quand c'est prêt
- Le build apparaîtra dans App Store Connect sous "TestFlight"

### 10. Soumettre pour review

Une fois le build traité :
- [ ] Aller dans App Store Connect > votre app
- [ ] Cliquer sur "+ Version" pour créer la version 1.0
- [ ] Sélectionner le build uploadé
- [ ] Vérifier que toutes les métadonnées sont complètes
- [ ] Ajouter les screenshots
- [ ] Ajouter les URLs des documents légaux
- [ ] Cliquer "Submit for Review"

**Informations pour App Review** :
- [ ] Notes de review : Mentionner le compte test si besoin
- [ ] Contact info : Votre email
- [ ] Demo account : Si l'app nécessite un login (pas votre cas)

### 11. Attendre l'approbation

**Timeline typique** :
- Soumission → In Review : 1-3 jours
- In Review → Decision : 24-48 heures
- Total : 2-5 jours en moyenne

**Statuts possibles** :
- **Waiting for Review** : En attente
- **In Review** : Apple teste l'app
- **Pending Developer Release** : Approuvée ! Vous décidez quand la publier
- **Ready for Sale** : Publiée dans l'App Store
- **Rejected** : Voir les raisons et corriger

## 🔍 Points d'attention pour l'App Review

Apple vérifiera :
1. ✅ L'app fonctionne sans crasher
2. ✅ Les abonnements fonctionnent correctement
3. ✅ Les documents légaux sont accessibles
4. ✅ La description correspond aux fonctionnalités
5. ✅ Pas de contenu inapproprié
6. ✅ L'icône est de qualité professionnelle
7. ✅ Les permissions sont justifiées (Reminders)
8. ✅ L'app respecte les guidelines Apple

## 🚫 Raisons communes de rejet

1. **Métadonnées incomplètes** : Vérifier tous les champs
2. **Screenshots manquants** : Minimum 2 tailles requises
3. **Privacy Policy manquante ou inaccessible**
4. **App crashing pendant le test**
5. **Fonctionnalités cachées** : Tout doit être accessible
6. **Icône de mauvaise qualité**

## 📧 Contacts importants

- **Support** : dreyerfred+planea@gmail.com
- **Privacy** : dreyerfred+privacyplanea@gmail.com

## 🎯 Après l'approbation

1. **Publier l'app** : Cliquer sur "Release this version"
2. **Promouvoir** : Partager le lien App Store
3. **Monitoring** : Vérifier les reviews et les crashs
4. **Mises à jour** : Répéter le processus pour les nouvelles versions

## 📱 Lien App Store

Une fois publiée, votre app sera disponible à :
`https://apps.apple.com/app/idXXXXXXXXX`

(L'ID sera généré par Apple)

## ⚠️ RAPPEL IMPORTANT

**AVANT toute soumission** :
- ✅ Icône d'application créée et ajoutée
- ✅ Documents légaux hébergés en ligne (URLs prêtes)
- ✅ Screenshots créés pour 2+ tailles d'écran
- ✅ Compte Apple Developer actif
- ✅ Abonnements créés dans App Store Connect
- ✅ Tout testé sur appareil réel

## 💡 Conseils finaux

1. **TestFlight** : Utilisez-le pour tester avant la soumission publique
2. **Beta testers** : Invitez quelques personnes à tester
3. **Phased Release** : Considérez une sortie progressive (0-100% des utilisateurs)
4. **Monitoring** : Configurez des outils comme Crashlytics
5. **Support** : Préparez-vous à répondre aux utilisateurs rapidement

Bonne chance avec votre soumission ! 🚀
