# Subscription System Setup Guide

This guide explains how to configure and test the App Store subscription system for Planea.

## Overview

Planea uses StoreKit 2 for subscription management with:
- **Monthly Plan**: $5 CAD/month with 30-day free trial
- **Annual Plan**: $55 CAD/year with 30-day free trial (save $5)
- Developer access codes for testing and family

## Product Identifiers

- Monthly: `com.planea.subscription.monthly`
- Annual: `com.planea.subscription.yearly`

## Xcode Configuration

### 1. Add In-App Purchase Capability

1. Open the Xcode project (`Planea.xcodeproj`)
2. Select the **Planea** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **In-App Purchase**

### 2. Create StoreKit Configuration File (for local testing)

1. In Xcode, go to **File > New > File**
2. Search for "StoreKit Configuration File"
3. Name it `Planea.storekit`
4. Save it in the `Planea-iOS/Planea/Planea/` directory

**Add Products to Configuration File:**

```json
{
  "identifier": "PLANEA_PRODUCTS",
  "nonRenewingSubscriptions": [],
  "products": [],
  "settings": {
    "_applicationInternalID": "123456789",
    "_developerTeamID": "YOUR_TEAM_ID",
    "_failTransactionsEnabled": false,
    "_lastAutoRenewableSubscriptionGroupID": "123456",
    "_locale": "en_US",
    "_storefront": "USA",
    "_storeKitErrors": []
  },
  "subscriptionGroups": [
    {
      "id": "123456",
      "localizations": [],
      "name": "Planea Premium",
      "subscriptions": [
        {
          "adHocOffers": [],
          "codeOffers": [],
          "displayPrice": "5.00",
          "familyShareable": false,
          "groupNumber": 1,
          "internalID": "6736449874",
          "introductoryOffer": {
            "internalID": "3840847393",
            "numberOfPeriods": 1,
            "paymentMode": "free",
            "subscriptionPeriod": "P1M"
          },
          "localizations": [
            {
              "description": "Full access to all features",
              "displayName": "Monthly",
              "locale": "en_US"
            }
          ],
          "productID": "com.planea.subscription.monthly",
          "recurringSubscriptionPeriod": "P1M",
          "referenceName": "Monthly Subscription",
          "subscriptionGroupID": "123456",
          "type": "RecurringSubscription"
        },
        {
          "adHocOffers": [],
          "codeOffers": [],
          "displayPrice": "55.00",
          "familyShareable": false,
          "groupNumber": 1,
          "internalID": "6736449875",
          "introductoryOffer": {
            "internalID": "3840847394",
            "numberOfPeriods": 1,
            "paymentMode": "free",
            "subscriptionPeriod": "P1M"
          },
          "localizations": [
            {
              "description": "Best value - Save $10 per year",
              "displayName": "Annual",
              "locale": "en_US"
            }
          ],
          "productID": "com.planea.subscription.yearly",
          "recurringSubscriptionPeriod": "P1Y",
          "referenceName": "Annual Subscription",
          "subscriptionGroupID": "123456",
          "type": "RecurringSubscription"
        }
      ]
    }
  ],
  "version": {
    "major": 3,
    "minor": 0
  }
}
```

### 3. Enable StoreKit Testing in Xcode

1. Select your app scheme (next to the run button)
2. Choose **Edit Scheme**
3. Select **Run** in the left sidebar
4. Go to **Options** tab
5. For **StoreKit Configuration**, select `Planea.storekit`

## App Store Connect Configuration

### 1. Create Subscription Group

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** > **Planea** > **Subscriptions**
3. Click **+** next to **Subscription Groups**
4. Name: `Planea Premium`
5. Click **Create**

### 2. Create Monthly Subscription

1. Inside the subscription group, click **+** to add a subscription
2. **Reference Name**: `Monthly Subscription`
3. **Product ID**: `com.planea.subscription.monthly`
4. Click **Create**

**Configure the product:**

- **Subscription Duration**: 1 month
- **Subscription Prices**:
  - Canada: CAD 5.00
  - United States: USD 5.00
  - (Add other countries as needed)

**Free Trial Offer:**
- Click **+** next to **Introductory Offers**
- **Start Date**: Today
- **Duration**: 1 month
- **Type**: Free Trial
- **Eligibility**: New subscribers only

**Localizations:**
- **English (Canada)**:
  - Display Name: `Monthly`
  - Description: `Full access to all features`
- **French (Canada)**:
  - Display Name: `Mensuel`
  - Description: `Accès complet à toutes les fonctionnalités`

### 3. Create Annual Subscription

1. In the subscription group, click **+** to add another subscription
2. **Reference Name**: `Annual Subscription`
3. **Product ID**: `com.planea.subscription.yearly`
4. Click **Create**

**Configure the product:**

- **Subscription Duration**: 1 year
- **Subscription Prices**:
  - Canada: CAD 55.00
  - United States: USD 55.00
  - (Add other countries as needed)

**Free Trial Offer:**
- Click **+** next to **Introductory Offers**
- **Start Date**: Today
- **Duration**: 1 month
- **Type**: Free Trial
- **Eligibility**: New subscribers only

**Localizations:**
- **English (Canada)**:
  - Display Name: `Annual`
  - Description: `Best value - Save $10 per year`
- **French (Canada)**:
  - Display Name: `Annuel`
  - Description: `Meilleure valeur - Économisez 10$ par année`

### 4. App Information

In App Store Connect, ensure you have:
- Privacy Policy URL
- Terms of Service URL (required for subscriptions)

## Testing

### Local Testing (Xcode)

1. Run the app in Simulator or on a device
2. The StoreKit Configuration file will be used
3. Purchases are simulated and don't charge real money
4. You can test:
   - Viewing products
   - Making purchases
   - Free trial period
   - Restoring purchases

**Speed up time for testing:**
- In Xcode, with the app running, go to **Debug > StoreKit > Editor > Time Rate**
- Select a faster rate (e.g., 1 hour = 1 minute) to test subscription expiry

### Sandbox Testing

1. Create sandbox test accounts in App Store Connect
2. Go to **Users and Access** > **Sandbox Testers**
3. Click **+** to add testers
4. Use these accounts to test on real devices

**On your device:**
1. Go to **Settings** > **App Store**
2. Scroll to **Sandbox Account**
3. Sign in with your test account
4. Run the app and test purchases

### Developer Access Codes

For family members and internal testing:

**To activate:**
1. Open the app
2. Go to **Settings**
3. Tap the version number 10 times
4. Enter one of the codes:
   - `PLANEA_FAMILY_2025`
   - `DEV_ACCESS_UNLIMITED`

**To change codes:**
Edit `StoreManager.swift` and modify the `validAccessCodes` array.

## Promotional Codes (App Store)

To give free subscriptions to family/friends:

1. In App Store Connect, go to your app
2. Navigate to **Subscriptions**
3. Select a subscription product
4. Click **Promotional Offers** or **Offer Codes**
5. Create an offer code:
   - Duration: 12 months (or custom)
   - Number of codes: Up to 100
6. Generate codes and share with family

**Users redeem in App Store:**
- Open App Store app
- Tap profile picture
- Tap **Redeem Gift Card or Code**
- Enter promotional code

## Subscription Features in the App

### For Users

1. **Onboarding**: Welcome message showing 30-day free trial
2. **Settings**: View subscription status, manage, or subscribe
3. **Paywall**: Shown when trial expires (cannot be dismissed)
4. **Trial Reminder**: Notification at 7 days remaining (to be implemented)

### Trial Period

- Both subscriptions offer 30 days free
- Managed by Apple automatically
- User must actively cancel before trial ends to avoid charges
- Auto-renews after trial unless cancelled

### After Subscribe

- Full access to all app features
- Manage subscription in App Store
- Badge in Settings showing status

## Important Notes

### App Review Guidelines

1. **Don't circumvent IAP**: The developer code system is for internal use only
   - Never mention it in App Store description
   - Never advertise it publicly
   - Keep it hidden (10-tap gesture)

2. **Required Links**:
   - Privacy Policy (required)
   - Terms of Service (required for subscriptions)
   - Both must be publicly accessible URLs

3. **Restore Purchases**: Must be clearly available (implemented in paywall)

### Pricing Strategy

Current pricing:
- Monthly: $5 CAD = $60/year
- Annual: $55 CAD = $5 savings

Consider:
- Market research for your target audience
- Competitor pricing
- Regional pricing adjustments

### Monitoring

After launch, monitor in App Store Connect:
- **Sales and Trends**: Track subscriptions
- **Analytics**: Conversion rates, trials vs paid
- **Subscription Reports**: Retention, churn

## Troubleshooting

### Products not loading

- Verify product IDs match exactly in code and App Store Connect
- Ensure products are in "Ready to Submit" state
- Wait up to 24 hours for new products to propagate
- Check your App Store Connect agreements are signed

### Purchases not working in sandbox

- Sign out of real App Store account first
- Use a sandbox tester account
- Clear app data and reinstall if needed
- Check sandbox account isn't locked

### Trial not appearing

- Verify introductory offer is properly configured
- Check eligibility (only for new subscribers)
- Ensure offer has a start date in the past

## Next Steps

1. **Before submitting to App Store**:
   - Add Privacy Policy and Terms URLs
   - Complete all product metadata
   - Upload app screenshots showing subscription features
   - Test thoroughly in sandbox

2. **App Review**:
   - Provide test account credentials
   - Explain subscription benefits clearly
   - Be prepared to answer questions about IAP

3. **After Launch**:
   - Monitor subscription metrics
   - Collect user feedback
   - Consider A/B testing prices
   - Plan marketing campaigns

## Support

For issues:
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
