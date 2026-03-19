# Guide de préparation pour la production - Planea

## ✅ Ce qui a été ajouté

### 1. Documents légaux
- **Terms and Conditions** (Conditions d'utilisation) en anglais et français
- **Privacy Policy** (Politique de confidentialité) en anglais et français
- Les documents couvrent tous les aspects importants pour une app iOS avec IA et abonnements

### 2. Interface utilisateur

#### SettingsView (Réglages)
- Section "Support & Feedback" avec un bouton pour envoyer un email
- Section "Legal" avec liens vers:
  - Terms and Conditions
  - Privacy Policy

#### OnboardingView
- Liens vers Terms and Conditions et Privacy Policy en bas de l'écran d'onboarding
- Les utilisateurs peuvent consulter les documents avant de commencer à utiliser l'app

#### LegalDocumentView
- Nouvelle vue pour afficher les documents légaux
- Navigation avec bouton "Done" pour fermer
- Support complet du bilinguisme (EN/FR)

### 3. Fonctionnalité de feedback
- Bouton "Send Feedback" dans Settings
- Ouvre le client email avec:
  - Adresse: dreyerfred+planea@gmail.com
  - Sujet pré-rempli
  - Corps du message avec version de l'app, iOS et modèle d'appareil

## 📝 Ce qu'il reste à faire avant la production

### 1. Email de support
- [x] **Email configuré**: dreyerfred+planea@gmail.com (existante)
- [ ] Optionnel: Créer une adresse dédiée pour privacy (ex: dreyerfred+planea-privacy@gmail.com) pour les demandes RGPD

### 2. Révision légale
- [ ] **IMPORTANT**: Faire réviser les Terms and Conditions par un avocat
- [ ] **IMPORTANT**: Faire réviser la Privacy Policy par un avocat
- [ ] S'assurer que les documents sont conformes aux lois:
  - Canada (loi applicable mentionnée dans les conditions)
  - États-Unis (où les serveurs IA sont hébergés)
  - Union Européenne (RGPD - déjà mentionné dans la Privacy Policy)

### 3. App Store Connect
- [ ] Ajouter les URLs des documents légaux dans App Store Connect:
  - Terms of Use URL
  - Privacy Policy URL
- [ ] **Option recommandée**: Héberger les documents sur un site web
  - Créer une page web pour chaque document
  - Permet de mettre à jour facilement sans nouvelle version de l'app
  - URLs suggestions: 
    - https://planea-app.com/terms
    - https://planea-app.com/privacy

### 4. Conformité Apple
- [ ] **Age Rating**: L'app mentionne "pas pour les enfants de moins de 13 ans"
  - Configurer l'âge minimum dans App Store Connect: 4+
- [ ] **Data Collection**: Déclarer dans App Store Connect les données collectées:
  - Profils famille (noms, préférences alimentaires, allergies)
  - Usage de l'app (analytics)
  - Données envoyées aux services IA (OpenAI/Anthropic)

### 5. Tests
- [ ] Tester le bouton de feedback sur un appareil réel
- [ ] Vérifier que tous les liens vers les documents légaux fonctionnent
- [ ] Tester dans les deux langues (EN/FR)
- [ ] Vérifier que les documents s'affichent correctement sur différentes tailles d'écran

### 6. Contenu des documents légaux à vérifier

#### Dans Terms and Conditions:
- L'adresse de contact (actuellement: support@planea-app.com - à mettre à jour avec dreyerfred+planea@gmail.com si souhaité)
- La juridiction (actuellement: Canada)
- Le nom de l'entreprise/développeur

#### Dans Privacy Policy:
- L'adresse email (actuellement: privacy@planea-app.com - à mettre à jour si souhaité)
- Les services IA utilisés (OpenAI/Anthropic - confirmer lesquels)
- L'adresse physique si nécessaire pour RGPD

### 7. Autres considérations

#### Site web (recommandé)
- Créer un site web simple pour:
  - Présenter l'app
  - Héberger les documents légaux (version web)
  - Fournir un formulaire de contact alternatif
  - Support: dreyerfred+planea@gmail.com

#### Analytics et suivi
- Décider si vous utilisez des analytics
- Si oui, mettre à jour la Privacy Policy en conséquence
- Implémenter un opt-out si nécessaire

#### Backend
- Si vous ajoutez un backend plus tard:
  - Mettre à jour la Privacy Policy
  - Ajouter des informations sur le stockage cloud
  - Documenter les transferts de données internationaux

## 📄 Fichiers modifiés

1. `Planea-iOS/Planea/Planea/Views/LegalDocumentView.swift` - Nouvelle vue
2. `Planea-iOS/Planea/Planea/Views/SettingsView.swift` - Ajout sections Legal et Support
3. `Planea-iOS/Planea/Planea/Views/OnboardingView.swift` - Ajout liens légaux
4. `Planea-iOS/Planea/Planea/en.lproj/Localizable.strings` - Traductions EN
5. `Planea-iOS/Planea/Planea/fr.lproj/Localizable.strings` - Traductions FR

## 🔒 Points importants de sécurité

- Les données sont stockées localement (Core Data)
- Pas de cookies ou tracking web
- Les données IA sont envoyées via API sécurisées
- Abonnements gérés par Apple (sécurisé)

## 📱 Conformité RGPD (pour utilisateurs EU)

Les documents incluent déjà:
- Droit d'accès aux données
- Droit de rectification
- Droit à l'effacement
- Droit à la portabilité
- Droit d'opposition
- Droit de déposer une plainte

## ⚠️ DISCLAIMER

**Les documents légaux fournis sont des templates génériques. Il est FORTEMENT RECOMMANDÉ de les faire réviser par un avocat spécialisé en droit de la technologie et en protection des données avant de publier l'application en production.**

Chaque juridiction a ses propres exigences légales, et les conséquences d'un non-respect peuvent être sérieuses (amendes RGPD, poursuites, etc.).

## 🎯 Checklist finale avant soumission App Store

- [ ] Tous les documents légaux révisés par un avocat
- [ ] Emails support configurés et testés
- [ ] URLs des documents légaux ajoutées dans App Store Connect
- [ ] Data collection déclarée correctement
- [ ] App testée sur plusieurs appareils et tailles d'écran
- [ ] Les deux langues (EN/FR) testées
- [ ] Tous les liens fonctionnent
- [ ] Age rating configuré correctement (4+)
- [ ] Screenshots et description mis à jour si nécessaire
