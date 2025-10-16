# Planea Legal Documents - GitHub Pages Setup

Ce dossier contient les documents légaux de Planea prêts à être hébergés sur GitHub Pages.

## 📋 Fichiers Inclus

- `index.html` - Page d'accueil avec liens vers tous les documents
- `privacy-fr.html` - Politique de confidentialité en français
- `privacy-en.html` - Privacy Policy in English
- `terms-fr.html` - Conditions d'utilisation en français
- `terms-en.html` - Terms of Service in English

## 🚀 Déploiement sur GitHub Pages

### Étape 1: Créer le Repository

1. Allez sur https://github.com
2. Cliquez sur le bouton **"+"** en haut à droite → **"New repository"**
3. Nommez-le `planea-legal` (ou un autre nom de votre choix)
4. Sélectionnez **"Public"** (obligatoire pour GitHub Pages gratuit)
5. Cochez **"Add a README file"**
6. Cliquez sur **"Create repository"**

### Étape 2: Upload les Fichiers

**Option A - Via l'interface web GitHub:**
1. Dans votre nouveau repository, cliquez sur **"Add file"** → **"Upload files"**
2. Glissez-déposez tous les fichiers HTML de ce dossier
3. Ajoutez un message de commit (ex: "Add legal documents")
4. Cliquez sur **"Commit changes"**

**Option B - Via Git en ligne de commande:**
```bash
cd github-pages-legal
git init
git add .
git commit -m "Initial commit with legal documents"
git branch -M main
git remote add origin https://github.com/VOTRE-USERNAME/planea-legal.git
git push -u origin main
```

### Étape 3: Activer GitHub Pages

1. Dans votre repository, allez dans **Settings** (⚙️)
2. Dans le menu de gauche, cliquez sur **Pages**
3. Sous "Source", sélectionnez:
   - Branch: **main** (ou **master**)
   - Folder: **/ (root)**
4. Cliquez sur **"Save"**
5. Attendez 1-2 minutes

### Étape 4: Vérifier le Déploiement

Après quelques minutes, votre site sera accessible à:
```
https://VOTRE-USERNAME.github.io/planea-legal/
```

Vous pouvez trouver l'URL exacte en haut de la page Settings → Pages.

## 📝 Personnalisation Nécessaire

Avant de déployer, **remplacez** les placeholders suivants dans tous les fichiers:

- `[DATE]` - Ajoutez la date de dernière mise à jour (ex: "15 janvier 2025")
- `[VOTRE EMAIL]` - Ajoutez votre email de contact (ex: "support@planea.app")
- `[YOUR EMAIL]` - Dans les fichiers anglais
- `[X]` - Nombre de jours d'essai gratuit (ex: "7 jours")
- `[VOTRE JURIDICTION]` - Votre juridiction légale (ex: "Canada" ou "France")
- `[YOUR JURISDICTION]` - Dans les fichiers anglais

## 🔗 URLs des Documents

Une fois déployé, vos documents seront accessibles à:

- **Français:**
  - Politique de confidentialité: `https://VOTRE-USERNAME.github.io/planea-legal/privacy-fr.html`
  - Conditions d'utilisation: `https://VOTRE-USERNAME.github.io/planea-legal/terms-fr.html`

- **English:**
  - Privacy Policy: `https://VOTRE-USERNAME.github.io/planea-legal/privacy-en.html`
  - Terms of Service: `https://VOTRE-USERNAME.github.io/planea-legal/terms-en.html`

## 📱 Intégration dans l'App iOS

Ces URLs seront utilisées dans `LegalDocumentView.swift` pour charger les documents dynamiquement depuis GitHub Pages.

## 🔄 Mises à Jour

Pour mettre à jour un document:
1. Modifiez le fichier HTML localement
2. Commitez et pushez vers GitHub
3. Les changements seront visibles sur GitHub Pages en quelques minutes

## ✅ Avantages de GitHub Pages

- ✅ Gratuit et fiable
- ✅ HTTPS automatique
- ✅ CDN mondial
- ✅ Mises à jour instantanées
- ✅ Historique des versions via Git
- ✅ Pas de maintenance serveur

## 📞 Support

Pour toute question, référez-vous à la documentation GitHub Pages:
https://docs.github.com/pages
