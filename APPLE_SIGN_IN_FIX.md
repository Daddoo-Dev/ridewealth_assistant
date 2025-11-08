# Apple Sign In - Fix Required

## Current Status
- Apple OAuth launches successfully
- User completes authentication on Apple's side
- Deep link callback works
- **Error:** "Unable to exchange external code" - Supabase cannot exchange the authorization code

## Root Cause
The Secret Key in Supabase was generated with the wrong Client ID. It was generated for `com.ridewealthassistant.app` (Bundle ID) but needs to be generated for `service.com.ridewealthassistant.app` (Service ID).

## What You Need to Do

### 1. Regenerate Apple Secret Key
Use the Supabase docs tool (or your own script) with these parameters:
- **Client ID:** `service.com.ridewealthassistant.app`
- **Team ID:** Your Apple Team ID
- **Key ID:** Your signing key ID
- **.p8 file:** Your signing key file from Apple Developer Console

### 2. Update Supabase
- Go to Supabase Dashboard > Authentication > Providers > Apple
- Paste the new secret key into the **Secret Key (for OAuth)** field
- Client IDs should already be: `service.com.ridewealthassistant.app`
- Click **Save**

### 3. Test
- Run the app
- Click Sign in with Apple
- Complete authentication
- Should redirect back and successfully authenticate

## Current Configuration (Confirmed Working)
- ✅ Apple Developer Console: Service ID configured with correct redirect URL
- ✅ Supabase Client IDs: `service.com.ridewealthassistant.app`
- ✅ Deep link configuration in AndroidManifest
- ✅ Environment variables loading correctly
- ❌ Secret Key: Wrong - needs regeneration

## Files Involved
- `lib/authmethod.dart` - Sign in method (no changes needed)
- `android/app/src/main/AndroidManifest.xml` - Deep link config (correct)
- `lib/main.dart` - Supabase initialization (correct)

