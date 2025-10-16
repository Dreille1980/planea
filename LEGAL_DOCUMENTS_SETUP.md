# Guide de Configuration des Documents Légaux sur GitHub Pages

Ce guide explique comment héberger vos documents légaux (Politique de Confidentialité et Conditions d'Utilisation) sur GitHub Pages et les intégrer dans l'application Planea.

## 📋 Résumé de ce qui a été fait

J'ai créé pour vous :
1. ✅ Fichiers HTML pour tous les documents légaux (français et anglais)
2. ✅ Service Swift (`LegalDocumentService`) avec cache offline
3. ✅ Vue mise à jour (`LegalDocumentView`) utilisant WebKit
4. ✅ Préchargement automatique des documents au démarrage de l'app

## 🚀 Étapes de Déploiement

### Étape 1: Créer le Repository GitHub

1. Allez sur https://github.com
2. Cliquez sur **"+"** (en haut à droite) → **"New repository"**
3. Configuration:
   - **Repository name**: `planea-legal`
   - **Visibility**: Cochez **"Public"** (obligatoire pour GitHub Pages gratuit)
   - **Initialize**: Cochez **"Add a README file"**
4. Cliquez sur **"Create repository"**

### Étape 2: Upload les Fichiers

**Option A - Via l'interface web (plus simple):**

1. Dans votre nouveau repository, cliquez sur **"Add file"** → **"Upload files"**
2. Allez dans le dossier `github-pages-legal/` de ce projet
3. Glissez-déposez tous les fichiers `.html`:
   - `index.html`
   - `privacy-fr.html`
   - `privacy-en.html`
   - `terms-fr.html`
   - `terms-en.html`
4. Message de commit: "Add legal documents"
5. Cliquez sur **"Commit changes"**

**Option B - Via Git en ligne de commande:**

```bash
cd github-pages-legal
git init
git add *.html
git commit -m "Initial commit with legal documents"
git branch -M main
git remote add origin https://github.com/VOTRE-USERNAME/planea-legal.git
git push -u origin main
```

### Étape 3: Activer GitHub Pages

1. Dans votre repository, allez dans **Settings** (icône ⚙️)
2. Dans le menu de gauche, cliquez sur **"Pages"**
3. Configuration:
   - **Source**: Sélectionnez **"Deploy from a branch"**
   - **Branch**: Sélectionnez **"main"** + **"/ (root)"**
4. Cliquez sur **"Save"**
5. ⏳ Attendez 1-2 minutes pour le déploiement

### Étape 4: Vérifier le Déploiement

1. Retournez dans **Settings** → **Pages**
2. En haut, vous verrez:
   ```
   Your site is live at https://VOTRE-USERNAME.github.io/planea-legal/
   ```
3. Cliquez sur ce lien pour vérifier que vos documents sont accessibles

## 📝 Personnalisation des Documents

### Placeholders à Remplacer

Avant d'utiliser en production, vous DEVEZ remplacer ces placeholders dans tous les fichiers HTML:

| Placeholder | Remplacer par | Exemple |
|------------|---------------|---------|
| `[DATE]` | Date actuelle | `15 janvier 2025` |
| `[VOTRE EMAIL]` | Votre email support | `support@planea.app` |
| `[YOUR EMAIL]` | (fichiers anglais) | `support@planea.app` |
| `[X]` | Jours d'essai gratuit | `7 jours` ou `7 days` |
| `[VOTRE JURIDICTION]` | Juridiction légale | `Canada`, `France`, etc. |
| `[YOUR JURISDICTION]` | (fichiers anglais) | `Canada`, `France`, etc. |

### Comment Modifier les Fichiers

1. Allez dans votre repository GitHub
2. Cliquez sur le fichier à modifier (ex: `privacy-fr.html`)
3. Cliquez sur l'icône ✏️ (Edit)
4. Faites vos modifications
5. Commit les changements
6. Les changements seront visibles sur GitHub Pages en 1-2 minutes

## 🔗 Intégration dans l'App iOS

### Étape 5: Mettre à Jour l'URL dans le Code

Une fois votre site GitHub Pages déployé, vous devez mettre à jour l'URL dans le code:

1. Ouvrez le fichier: `Planea-iOS/Planea/Planea/Services/LegalDocumentService.swift`
2. Ligne 7, remplacez:
   ```swift
   private let baseURL = "https://VOTRE-USERNAME.github.io/planea-legal"
   ```
   Par votre URL réelle, par exemple:
   ```swift
   private let baseURL = "https://dreille1980.github.io/planea-legal"
   ```

### Étape 6: Compiler et Tester

1. Ouvrez le projet dans Xcode:
   ```bash
   open Planea-iOS/Planea/Planea.xcodeproj
   ```

2. Ajoutez le nouveau fichier au projet:
   - Dans Xcode, clic droit sur le dossier `Services`
   - **"Add Files to Planea"**
   - Sélectionnez `LegalDocumentService.swift`
   - Cochez **"Copy items if needed"**
   - Cliquez sur **"Add"**

3. Compilez et testez l'application sur un simulateur ou un appareil réel

4. Naviguez vers **Settings** → **Privacy Policy** ou **Terms of Service**

5. Vérifiez que:
   - ✅ Les documents se chargent correctement
   - ✅ Le style HTML s'affiche bien
   - ✅ Le mode offline fonctionne (activez le mode avion, puis rouvrez les documents)

## 🔄 Mise à Jour des Documents

Pour mettre à jour un document légal:

1. Modifiez le fichier HTML sur GitHub (via l'interface web ou Git)
2. Commit les changements
3. Les changements sont visibles sur GitHub Pages en 1-2 minutes
4. Les utilisateurs de l'app recevront automatiquement la mise à jour
5. L'ancienne version reste en cache pour le mode offline

## ✅ Avantages de cette Solution

- ✅ **Gratuit**: GitHub Pages est gratuit pour les repos publics
- ✅ **Fiable**: 99.9% uptime, CDN mondial
- ✅ **HTTPS**: Certificat SSL automatique
- ✅ **Mises à jour instantanées**: Pas besoin de recompiler l'app
- ✅ **Mode offline**: Documents mis en cache localement
- ✅ **Multilingue**: Support français et anglais automatique
- ✅ **Versioning**: Historique Git de toutes les modifications
- ✅ **Conforme App Store**: Apple accepte les documents hébergés externement

## 🆚 Pourquoi GitHub Pages et pas Railway?

| Critère | GitHub Pages ✅ | Railway ❌ |
|---------|----------------|------------|
| Coût | Gratuit | $5-10/mois |
| Complexité | Simple | Plus complexe |
| Maintenance | Aucune | Serveur à gérer |
| Uptime | 99.9% garanti | Dépend de votre config |
| SSL/HTTPS | Automatique | À configurer |
| CDN | Inclus | Pas inclus |
| Idéal pour | Contenu statique | Applications dynamiques |

## 📱 URLs des Documents Finaux

Une fois déployé, vos documents seront disponibles à:

- **Page d'accueil**: `https://VOTRE-USERNAME.github.io/planea-legal/`
- **Privacy (FR)**: `https://VOTRE-USERNAME.github.io/planea-legal/privacy-fr.html`
- **Privacy (EN)**: `https://VOTRE-USERNAME.github.io/planea-legal/privacy-en.html`
- **Terms (FR)**: `https://VOTRE-USERNAME.github.io/planea-legal/terms-fr.html`
- **Terms (EN)**: `https://VOTRE-USERNAME.github.io/planea-legal/terms-en.html`

## 🆘 Dépannage

### Les documents ne se chargent pas dans l'app

1. Vérifiez que l'URL dans `LegalDocumentService.swift` est correcte
2. Vérifiez que GitHub Pages est bien activé (Settings → Pages)
3. Testez l'URL dans Safari pour confirmer qu'elle fonctionne
4. Vérifiez les logs Xcode pour voir les erreurs réseau

### Les styles HTML ne s'affichent pas

- Le CSS est inclus directement dans chaque fichier HTML, donc ça devrait fonctionner
- Assurez-vous d'avoir importé `WebKit` dans `LegalDocumentView.swift`

### Mode offline ne fonctionne pas

- Les documents sont automatiquement mis en cache au premier chargement
- Pour forcer le cache, lancez l'app une fois avec Internet, puis testez hors ligne

## 📞 Support

- Documentation GitHub Pages: https://docs.github.com/pages
- Si vous rencontrez des problèmes, vérifiez les fichiers créés dans le dossier `github-pages-legal/`

## 🎉 Prochaines Étapes

1. [ ] Créer le repository GitHub `planea-legal`
2. [ ] Upload les fichiers HTML
3. [ ] Activer GitHub Pages
4. [ ] Personnaliser les placeholders dans les documents
5. [ ] Mettre à jour l'URL dans `LegalDocumentService.swift`
6. [ ] Ajouter le fichier au projet Xcode
7. [ ] Compiler et tester l'application
8. [ ] Vérifier le fonctionnement online et offline

Une fois ces étapes complétées, vos documents légaux seront hébergés de manière professionnelle et pourront être mis à jour instantanément sans recompiler l'app!
