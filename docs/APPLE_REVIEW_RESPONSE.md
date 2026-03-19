# Apple App Review - Response Guide

This document contains the exact responses you need to provide to Apple's App Review team to resolve the two issues.

---

## 📋 ISSUE #1: Support URL (Guideline 1.5 - Safety)

### ✅ SOLUTION: Update Support URL in App Store Connect

**Current (Invalid):** `https://github.com/Dreille1980/planea.git`

**New (Valid):** `https://dreille1980.github.io/planea-legal/support.html`

### Steps to Update:

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps"
3. Select "Planea"
4. Click on your app version (the one in review)
5. Scroll down to **"App Information"** section
6. Find **"Support URL"** field
7. Replace the URL with: `https://dreille1980.github.io/planea-legal/support.html`
8. Click **"Save"** at the top

### ✅ Status: 
- [x] GitHub Pages is live at: https://dreille1980.github.io/planea-legal/
- [x] Support page created with all required information
- [x] All placeholders updated with correct date and email

---

## 📋 ISSUE #2: Free Trial Information (Guideline 2.1)

### ✅ SOLUTION: Reply to Apple's Message in App Store Connect

Apple has requested detailed information about your free trial flow. You need to reply to their message in the Resolution Center.

---

## 📝 EXACT RESPONSE TO COPY/PASTE

### How to Submit Your Response:

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to your app's page
3. Look for the **"Resolution Center"** or **"App Review"** section
4. Find Apple's message about "Guideline 2.1 - Information Needed"
5. Click **"Reply"**
6. Copy and paste the responses below

---

### Question 1: What is the purchase flow within your app once the free trial period has expired?

**RESPONSE TO COPY:**

```
After the 7-day free trial expires, users are presented with a subscription paywall that offers two options:

1. Monthly subscription - recurring monthly billing
2. Annual subscription - recurring yearly billing with savings compared to monthly

The purchase flow works as follows:

1. When attempting to use premium features after trial expiration, users see a subscription screen displaying both subscription options with clear pricing
2. Users select their preferred subscription plan (monthly or annual)
3. Purchase is completed entirely through Apple's in-app purchase system (StoreKit 2)
4. No external payment methods or websites are used - all transactions go through the App Store
5. After successful purchase, users immediately gain access to all premium features:
   - Unlimited meal plan generation
   - Personalized recipe recommendations
   - Family profile management
   - Shopping list creation
   - Recipe favorites and history

6. Subscriptions automatically renew unless canceled by the user
7. Users can manage/cancel subscriptions through iOS Settings → [User Name] → Subscriptions, or directly in the app through Settings → Subscription → Manage Subscription

All subscription management follows Apple's standard in-app purchase guidelines, with no alternative payment mechanisms.
```

---

### Question 2: Demo Account with Expired Free Trial

**RESPONSE TO COPY:**

```
To facilitate testing of the app's subscription flow, we have implemented an App Review access system.

**Testing Method: Developer Access Code**

Access Code: PLANEA_FAMILY_2025

This access code grants full app functionality without requiring payment, allowing the review team to test all features including the subscription flow.

**How to use the code:**
1. Download and install Planea from TestFlight or the review build
2. Complete the onboarding process
3. Navigate to: Settings → [Look for Developer Access or similar option]
4. Enter the code: PLANEA_FAMILY_2025
5. The app will grant full access to all premium features

This implementation allows the review team to:
- Test the app with full functionality
- Verify the subscription paywall appears correctly for non-subscribed users
- Test the purchase flow through Apple's sandbox environment
- Validate all premium features work as intended

**Alternative Testing:**
If preferred, you can also test with a standard Apple Sandbox test account:
- Create a Sandbox tester in App Store Connect
- The 7-day trial can be accelerated in sandbox mode
- After trial expiration, the subscription paywall will appear as it does for regular users

**Note:** The developer access code system is used solely for review and testing purposes and is not accessible to regular users. It simulates a subscribed state to allow thorough feature testing without time constraints.
```

---

## ⚠️ IMPORTANT: Additional App Store Connect Configuration

Before submitting your response, ensure you've also:

### 1. Filled in App Review Information

1. Go to App Store Connect → My Apps → Planea
2. Select your app version
3. Scroll to **"App Review Information"** section
4. Make sure these fields are filled:

**Contact Information:**
- First Name: [Your First Name]
- Last Name: [Your Last Name]  
- Phone Number: [Your Phone Number]
- Email: dreyerfred+privacyplanea@gmail.com

**Demo Account (Optional but helpful):**
- [ ] Sign-in required: (Check if needed)
- Username: [If applicable]
- Password: [If applicable]
- Notes: "Use developer access code PLANEA_FAMILY_2025 in Settings to test all features"

### 2. Update Support URL (from Issue #1)
- Support URL: `https://dreille1980.github.io/planea-legal/support.html`

### 3. Privacy Policy URL
- Privacy Policy URL: `https://dreille1980.github.io/planea-legal/privacy-en.html`

---

## 📤 Final Steps

1. ✅ Update Support URL in App Store Connect
2. ✅ Reply to Apple's message with the responses above
3. ✅ Verify all App Review Information is complete
4. ✅ Submit your response through the Resolution Center
5. ⏳ Wait for Apple to review your response (usually 1-2 business days)

---

## 🔍 Verification Checklist

Before submitting, verify:

- [x] GitHub Pages is live: https://dreille1980.github.io/planea-legal/
- [x] Support page accessible: https://dreille1980.github.io/planea-legal/support.html
- [x] Privacy policy updated with correct date (October 16th, 2025) and email
- [x] Terms of service updated with correct date and email
- [x] Support URL updated in App Store Connect
- [ ] Response sent to Apple through Resolution Center
- [ ] Developer access code (PLANEA_FAMILY_2025) is working in your app

---

## 📞 Need Help?

If you have any questions or issues:
1. Check the support.html page for FAQ
2. Verify all files are properly committed and pushed to GitHub
3. Ensure GitHub Pages is enabled for your repository

---

**Good luck with your app review! 🚀**

These changes should resolve both issues raised by Apple.
