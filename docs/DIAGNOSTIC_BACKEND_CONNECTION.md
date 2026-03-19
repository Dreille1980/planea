# 🔍 Diagnostic du problème de connexion backend - Planea

## 📋 Résumé du problème

**Symptôme:** L'application iOS affiche des "recettes simples de souper" au lieu de recettes personnalisées.

**Cause identifiée:** Problème de connexion entre l'app iOS et le backend Render.

**Erreur observée:** `nw_connection_copy_connected_local_endpoint_block_invoke [C9] Connection has no local endpoint`

## ✅ Ce qui a été fait

### 1. Vérification du backend Render
- ✅ Script de test créé: `test_backend.sh`
- ✅ Backend testé: **FONCTIONNEL** ✨
- ✅ Endpoints meal-prep: **OPÉRATIONNELS** (HTTP 200)

### 2. Amélioration des logs de diagnostic
- ✅ `MealPrepService.swift` - Logs détaillés ajoutés
- ✅ `IAService.swift` - Logs détaillés ajoutés
- ✅ Affichage de: URL, payload, statut HTTP, réponses

### 3. Configuration vérifiée
- ✅ `Info.plist` - Configuration réseau correcte
- ✅ `Config.swift` - URL backend correcte
- ✅ ATS (App Transport Security) - Configuré

## 🧪 Guide de test

### Étape 1: Lancer l'app en mode Debug dans Xcode

1. Ouvrez le projet dans Xcode:
   ```bash
   cd /Users/T979672/developer/planea/Planea-iOS/Planea
   open Planea.xcodeproj
   ```

2. Sélectionnez un simulateur iOS (ex: iPhone 15 Pro)

3. Lancez l'app en mode Debug (`Cmd + R`)

4. **Ouvrez la Console** (`Cmd + Shift + Y`) pour voir les logs

### Étape 2: Tester la fonctionnalité Meal Prep

1. Dans l'app, allez à l'onglet **Meal Prep**

2. Cliquez sur **"Créer un nouveau meal prep"** ou bouton similaire

3. **Remplissez le wizard:**
   - Step 1: Sélectionnez des jours (ex: Lundi à Vendredi)
   - Step 2: Configurez les préférences
   - Step 3: **ATTENTION - C'est ici qu'on teste les concepts**

4. **Observez la Console Xcode** - Vous devriez voir:
   ```
   🎨 Generating meal prep concepts...
   📍 URL: https://planea-backend.onrender.com/ai/meal-prep-concepts
   📦 Payload: ...
   ✅ Response status: 200
   📥 Raw response: ...
   ✅ Successfully decoded X concepts
   ```

### Étape 3: Analyser les logs

#### ✅ Si vous voyez ceci - C'EST BON:
```
✅ Response status: 200
✅ Successfully decoded 3 concepts
```
→ Le backend fonctionne! Le problème est ailleurs.

#### ❌ Si vous voyez ceci - PROBLÈME RÉSEAU:
```
⚠️ Request attempt 1 failed with: The Internet connection appears to be offline
```
ou
```
⚠️ Request attempt 1 failed with: Could not connect to the server
```
→ Problème de connexion réseau du simulateur.

#### ❌ Si vous voyez ceci - PROBLÈME BACKEND:
```
✅ Response status: 500
```
ou
```
✅ Response status: 404
```
→ Le backend a un problème.

## 🔧 Solutions selon le diagnostic

### Solution A: Problème réseau du simulateur

**Symptômes:**
- Erreur "connection appears to be offline"
- Timeout après 120 secondes
- Pas de connexion au backend

**Solutions:**

1. **Vérifier la connexion Internet du Mac**
   ```bash
   ping planea-backend.onrender.com
   ```

2. **Redémarrer le simulateur**
   - Menu: Device → Erase All Content and Settings
   - Puis relancer l'app

3. **Tester avec un iPhone physique**
   - Connecter votre iPhone
   - Sélectionner comme destination dans Xcode
   - Relancer l'app

### Solution B: Backend en veille (Cold Start)

**Symptômes:**
- Premier appel timeout
- Deuxième appel fonctionne
- Long délai (30-60s)

**Solutions:**

1. **Attendre et réessayer**
   - Les services Render gratuits se mettent en veille
   - Le premier appel prend 30-60 secondes pour "réveiller" le serveur
   - Les appels suivants sont rapides

2. **Pré-réveiller le backend avant de tester**
   ```bash
   ./test_backend.sh
   ```
   Attendez que tous les tests soient verts, puis testez l'app immédiatement.

### Solution C: Problème de décodage JSON

**Symptômes:**
- Status 200 mais erreur de décodage
- "❌ Decoding error: ..."
- Données affichées mais incorrectes

**Solution:**
1. Copiez la réponse brute de la console
2. Vérifiez le format JSON
3. Comparez avec les modèles dans `MealPrepModels.swift`

### Solution D: Contraintes familiales non envoyées

**Symptômes:**
- Backend répond mais recettes génériques
- Pas de personnalisation
- Logs montrent: `📦 Payload keys: days, meals, servings_per_meal...`

**Solution:**
1. Vérifiez que vous avez configuré votre famille:
   - Menu Settings → Family Management
   - Ajoutez des membres avec restrictions

2. Vérifiez les préférences:
   - Menu Settings → Generation Preferences
   - Sélectionnez protéines, cuisine, etc.

3. Dans les logs, vérifiez que `constraints` contient vos données:
   ```
   📦 Payload: ["language": "fr", "constraints": ["diet": "omnivore", "evict": [...], ...]]
   ```

## 📝 Rapporter vos résultats

Après avoir testé, notez:

1. **Les logs complets de la console** (copier-coller)
2. **Le statut HTTP reçu** (200, 404, 500, timeout?)
3. **Le moment où ça échoue** (concepts, kits, autre?)
4. **L'erreur exacte** si affichée

## 🎯 Prochaines étapes

Une fois le diagnostic fait, nous pourrons:

1. **Si backend fonctionne** → Améliorer la gestion d'erreur et UX
2. **Si problème réseau** → Ajouter un système de fallback/cache
3. **Si cold start** → Ajouter un indicateur "Réveil du serveur..."
4. **Si décodage** → Corriger les modèles de données

---

## 🚀 Test rapide du backend (depuis terminal)

```bash
# Rendre le script exécutable (si pas déjà fait)
chmod +x ./test_backend.sh

# Exécuter le test
./test_backend.sh
```

Si tous les tests sont ✅, le problème est dans l'app iOS, pas le backend.
