# Subscription Setup - App Store Connect & RevenueCat Configuration

## App Store Connect Subscription Details

### Product Information
- **Product ID:** `1000001`
- **Reference Name:** Annual
- **Group Reference Name:** Annual
- **Apple ID:** 6737458824
- **Subscription Duration:** 1 year
- **Status:** Missing Metadata (complete before submission)

### Pricing & Availability
- **Pricing:** Set in Subscription Pricing section
- **Availability:** All countries/regions
- **Family Sharing:** Enabled

### Introductory Offer
- **Type:** Free
- **Duration:** 30 days (1 month)
- **Date Range:** Set start date and end date (set end date far in future for ongoing availability)
- **Eligibility:** All Users or New Subscribers Only

### Localization (Required)
- **English (U.S.):**
  - Display Name: Ridewealth Assistant Annual
  - Description: Required subscription for full app access

### Before Submission
- Complete all metadata (localizations, image optional)
- Add subscription to app version before submitting to App Review
- First subscription must be submitted with a new app version

---

## RevenueCat Configuration

### 1. Add Product
- **Dashboard:** Products → Add Product
- **Store Identifier:** `1000001` (must match App Store Connect exactly)
- **Type:** Subscription
- **Store:** Apple App Store
- **Display Name:** Ridewealth Assistant Annual (optional, for your reference)

### 2. Create Entitlement
- **Dashboard:** Entitlements → Create Entitlement
- **Identifier:** `premium` or `pro` (your choice)
- **Attach Product:** `1000001`
- **Display Name:** Premium Access (optional)

### 3. Create Offering
- **Dashboard:** Offerings → Create Offering
- **Identifier:** `default` (or match what code expects)
- **Add Entitlement:** Add the entitlement created above
- **Set as Current:** Yes (make this the active offering)

### 4. Verify Configuration
- Product ID `1000001` matches App Store Connect
- Entitlement is attached to product
- Offering includes the entitlement
- Offering is set as current/default

---

## Google Play Configuration

### Product ID
- **Product ID:** `com.ridwealthassistant.subscribe.annual`
- Configure in Google Play Console → Monetize → Products → Subscriptions

### Licensing Key (From Google Play Console)
- **Base64 RSA Public Key:** `MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA89P3hB11gQezMEog/AXaGNPwJPY49U0pzaG1Yk8hQPGEkx5wmJcDMojLxyrBxhG75PFdt9OW9Vhy52T48miPygr35+Y+krq78hUNNX3fgPnWnmxo0Nz54j3NAIptiSK2xt1awv8weZ+wATWIHRl9xC4Kuuf40x5PT+UXoRYs0PHlFfb2+MNSMT7MmHLJ58jDEBx4IUya9eG+QsdJ71YsB6md8PP64ZzBCVJYf8HAz2Owwy2pEVAzZPxik04ojkeMjxedJa4XUkr8/xDdNzI+bD1KXNhgr6C5TL4qui16UmQh/T+jRqqwuoWx7yB5LENMm5Jvv6aOdZBCZGIwVvc02wIDAQAB`
- **Note:** With RevenueCat, you typically don't need to embed this in your app code. RevenueCat handles Google Play Billing integration. You may need to configure it in RevenueCat dashboard if required.

### Testing Setup
- Use Google Group for Testers Community
- Configure free subscriptions ($0.00) for Internal/Closed testing track
- Testers get free access automatically when in testing track

---

## Test Account Credentials

See `android/testcredentials.md` for store reviewer test account details.

---

## Notes

- Product ID `1000001` matches code in `lib/in_app_purchase_manager.dart` and `lib/apple_iap_service.dart`
- RevenueCat handles subscription management - no code changes needed once configured
- Introductory offer (30-day free trial) works automatically once configured
- Test subscriptions work automatically in sandbox (iOS) and testing tracks (Android)
