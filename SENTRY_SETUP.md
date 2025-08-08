# Sentry Error Tracking Setup

This guide will help you set up Sentry for comprehensive error tracking across all devices, especially for authentication issues.

## What's Been Implemented

✅ **Comprehensive Error Tracking**
- Authentication errors (Google, Apple, Email/Password)
- Database errors (user creation/updates)
- UI errors (button clicks, dialog interactions)
- General app errors with context

✅ **Mobile-First Configuration**
- Captures errors on iOS and Android devices
- No user-facing error logs (clean UX)
- Detailed error context for developers
- User context tracking for better debugging

✅ **Authentication-Specific Tracking**
- Google Sign-In errors
- Apple Sign-In errors  
- Email/Password authentication errors
- OAuth redirect issues
- Database user creation errors

## Setup Steps

### 1. Create Sentry Project

1. Go to [https://sentry.io](https://sentry.io)
2. Create a new account or sign in
3. Create a new project
4. Select **Flutter** as your platform
5. Copy your DSN (looks like: `https://xxxxx@xxxxx.ingest.sentry.io/xxxxx`)

### 2. Set Environment Variable

**Option A: Use the Setup Script**
```powershell
.\setup_sentry.ps1
```

**Option B: Manual Setup**
```powershell
# Set for current session
$env:SENTRY_DSN = "your-sentry-dsn-here"

# Set permanently for user
[Environment]::SetEnvironmentVariable("SENTRY_DSN", "your-sentry-dsn-here", "User")
```

### 3. Test the Setup

Run your app:
```bash
flutter run -d chrome --web-port=5000
```

## What You'll See in Sentry

### Error Categories
- **Authentication Errors**: All sign-in failures with method context
- **Database Errors**: User creation/update failures
- **UI Errors**: Button click failures, dialog errors
- **General Errors**: App crashes, startup errors

### Error Context
Each error includes:
- Device platform (iOS/Android/Web)
- Authentication method used
- User ID (when available)
- Screen/action context
- Full stack traces
- Environment tags

### Example Error Reports
```
Error: Google Sign-In Failed
Tags: 
  - error_type: authentication
  - auth_method: google
  - platform: ios
  - environment: production

Error: Database User Creation Failed  
Tags:
  - error_type: database
  - operation: create_user
  - table: users
  - platform: android
```

## Troubleshooting Authentication Issues

### iOS Google Sign-In Not Working
1. Check Sentry for specific error messages
2. Verify OAuth redirect URL configuration
3. Check iOS bundle identifier matches
4. Verify Google Cloud Console settings

### Apple Sign-In Not Working
1. Check Sentry for Apple-specific errors
2. Verify Apple Developer account configuration
3. Check iOS provisioning profiles
4. Verify Apple Sign-In capability enabled

### General Authentication Issues
1. Check Sentry for network errors
2. Verify Supabase configuration
3. Check environment variables
4. Review OAuth provider settings

## Monitoring Dashboard

In your Sentry dashboard, you can:
- View real-time error rates
- Filter by authentication method
- See device-specific issues
- Track user impact
- Set up alerts for critical errors

## Best Practices

1. **Check Sentry Daily**: Monitor for new authentication errors
2. **Set Up Alerts**: Get notified of critical authentication failures
3. **Review User Context**: Use user IDs to debug specific user issues
4. **Monitor Trends**: Watch for patterns in authentication failures

## Environment Variables Required

Make sure these are set:
- `SENTRY_DSN`: Your Sentry project DSN
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_KEY`: Your Supabase anon key

## Support

If you encounter issues:
1. Check Sentry dashboard for error details
2. Verify environment variables are set
3. Test on different devices/platforms
4. Review authentication provider configurations 