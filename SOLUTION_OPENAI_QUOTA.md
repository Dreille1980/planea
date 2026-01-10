# 🚨 Solution: Problème OpenAI (fonctionnait hier, pas aujourd'hui)

## 🎯 Diagnostic

Si l'application **fonctionnait hier** mais plus aujourd'hui **sans aucun changement de code**, c'est un problème **OpenAI**, pas votre code!

## Causes possibles

### 1. Quota OpenAI dépassé ⚠️ (PLUS PROBABLE)

**Symptôme:** Limite mensuelle gratuite atteinte ($5 ou $10 selon le compte)

**Vérification:**
1. Allez sur https://platform.openai.com/usage
2. Vérifiez votre **Usage** ce mois-ci
3. Vérifiez votre **Billing limit**

**Solution:**
- Ajoutez un moyen de paiement: https://platform.openai.com/account/billing/payment-methods
- Augmentez votre limite mensuelle
- Ou créez une nouvelle clé API avec un nouveau compte (compte gratuit limité)

### 2. Problème de facturation 💳

**Symptôme:** Carte expirée, paiement échoué

**Vérification:**
1. https://platform.openai.com/account/billing/overview
2. Vérifiez l'état de votre abonnement

**Solution:**
- Mettez à jour votre méthode de paiement
- Vérifiez que la carte n'est pas expirée

### 3. Clé API révoquée 🔑

**Symptôme:** Clé supprimée ou désactivée

**Vérification:**
1. https://platform.openai.com/api-keys
2. Vérifiez que votre clé existe et est active

**Solution:**
- Créez une nouvelle clé API
- Mettez-la à jour sur Render

## 🔍 Voir les VRAIES erreurs OpenAI

Pour confirmer, **vérifiez les logs Render:**

1. Allez sur https://dashboard.render.com
2. Sélectionnez votre service `planea-backend`
3. Cliquez sur **Logs** (dans le menu de gauche)
4. Cherchez les erreurs après avoir tenté une génération:
   ```
   Error generating recipe with OpenAI: [L'ERREUR ICI]
   ```

Les erreurs typiques:
- `insufficient_quota` → Quota dépassé
- `rate_limit_exceeded` → Trop de requêtes
- `invalid_api_key` → Clé invalide
- `billing_hard_limit_reached` → Limite de facturation atteinte

## ✅ Solution rapide (RECOMMANDÉE)

**Option 1: Ajouter du crédit (5-10$)**
1. https://platform.openai.com/account/billing/payment-methods
2. Ajoutez une carte de crédit
3. Définissez une limite mensuelle (ex: $10/mois)
4. Attendez quelques minutes
5. Réessayez l'app

**Option 2: Nouvelle clé API**
1. Créez un nouveau compte OpenAI (nouvel email)
2. Obtenez les $5 de crédit gratuit
3. Créez une nouvelle clé API
4. Sur Render: Environment → Modifier `OPENAI_API_KEY`
5. Save (redémarrage automatique)

## 🧪 Test rapide

Une fois corrigé, testez:
```bash
./test_backend.sh
```

Les recettes devraient redevenir personnalisées!

## 📊 Surveiller l'usage

Pour éviter que ça se reproduise:
- Activez les alertes sur https://platform.openai.com/account/limits
- Définissez une limite mensuelle raisonnable
- Surveillez votre usage hebdomadairement

---

**Note:** Le problème vient d'OpenAI, PAS de votre code. Une fois le compte OpenAI réactivé, tout refonctionnera automatiquement!
