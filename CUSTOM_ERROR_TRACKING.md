# Custom Error Tracking System

This document describes the custom error tracking system that replaces Sentry with Supabase database storage.

## Overview

The custom error tracking system captures all application errors and stores them in a dedicated `error_tracking` table in your Supabase database. This provides the same functionality as Sentry but with full control over your data and no external dependencies.

## Database Schema

### `error_tracking` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key (auto-generated) |
| `error_type` | TEXT | Type of error: 'authentication', 'database', 'ui', 'general' |
| `error_message` | TEXT | The error message/description |
| `stack_trace` | TEXT | Full stack trace (optional) |
| `user_id` | UUID | User ID (references users table) |
| `platform` | TEXT | Platform: 'android', 'ios', 'windows', 'macos', 'linux', 'web' |
| `app_version` | TEXT | App version (auto-extracted from device_info) |
| `device_info` | JSONB | Detailed device/platform information |
| `context` | JSONB | Additional context data |
| `tags` | JSONB | Error tags for categorization |
| `created_at` | TIMESTAMPTZ | When the error occurred |
| `resolved_at` | TIMESTAMPTZ | When the error was resolved (optional) |
| `resolved_by` | UUID | Who resolved the error (optional) |
| `resolution_notes` | TEXT | Resolution notes (optional) |

### `error_analytics` View

A pre-aggregated view for error statistics:
- Error counts by type, platform, and date
- Affected user counts
- Resolution statistics

## Error Types

### 1. Authentication Errors
- **Type**: `authentication`
- **Captures**: Login failures, OAuth issues, callback URI mismatches
- **Context**: Auth method, user ID, OAuth provider details

### 2. Database Errors
- **Type**: `database`
- **Captures**: Supabase operation failures, user creation issues
- **Context**: Operation type, table name, user ID

### 3. UI Errors
- **Type**: `ui`
- **Captures**: Button click failures, dialog errors, screen-specific issues
- **Context**: Screen name, action performed, user ID

### 4. General Errors
- **Type**: `general`
- **Captures**: App crashes, startup errors, unexpected exceptions
- **Context**: Custom context, user ID, additional data

## Usage Examples

### Authentication Error (OAuth Callback URI Mismatch)
```dart
await ErrorTrackingService.captureAuthError(
  'Invalid callback URI: https://example.com/callback',
  StackTrace.current,
  authMethod: 'google',
  userId: 'user-123',
  extra: {
    'callback_uri': 'https://example.com/callback',
    'expected_uri': 'https://yourapp.com/auth/callback',
    'oauth_provider': 'google',
  },
);
```

### Database Error
```dart
await ErrorTrackingService.captureDatabaseError(
  'Failed to create user document',
  StackTrace.current,
  operation: 'create_user',
  table: 'users',
  userId: 'user-123',
);
```

### UI Error
```dart
await ErrorTrackingService.captureUIError(
  'Button click failed',
  StackTrace.current,
  screen: 'auth_screen',
  action: 'google_signin_button',
  userId: 'user-123',
);
```

### Custom Error
```dart
await ErrorTrackingService.captureCustomError(
  'callback_uri_mismatch',
  'OAuth callback URI does not match configured URI',
  stackTrace: StackTrace.current,
  userId: 'user-123',
  context: {
    'oauth_provider': 'google',
    'received_uri': 'https://example.com/callback',
    'expected_uri': 'https://yourapp.com/auth/callback',
  },
  tags: {
    'severity': 'high',
    'category': 'oauth',
  },
);
```

## Device Information Captured

The system automatically captures:
- Platform (Android, iOS, Windows, macOS, Linux, Web)
- Platform version
- App version
- Dart version
- Debug mode status
- Timestamp

## Security & Privacy

### Row Level Security (RLS)
- Users can only insert/view their own errors
- Service role can access all errors
- Anonymous users can insert errors (for unauthenticated errors)

### Data Protection
- No sensitive user data is stored in error messages
- Stack traces are stored but can be filtered
- Device info is captured for debugging but doesn't include personal data

## Error Analytics

### Query Error Statistics
```dart
final stats = await ErrorTrackingService.getErrorStats(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
  errorType: 'authentication',
  platform: 'android',
);
```

### Common Queries

**Most Common Errors (Last 7 Days)**
```sql
SELECT error_type, COUNT(*) as count
FROM error_tracking
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY error_type
ORDER BY count DESC;
```

**Authentication Errors by Provider**
```sql
SELECT 
  tags->>'auth_method' as auth_method,
  COUNT(*) as count
FROM error_tracking
WHERE error_type = 'authentication'
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY tags->>'auth_method'
ORDER BY count DESC;
```

**Errors by Platform**
```sql
SELECT platform, COUNT(*) as count
FROM error_tracking
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY platform
ORDER BY count DESC;
```

## Migration from Sentry

### What Was Removed
1. `sentry_flutter` dependency from `pubspec.yaml`
2. Sentry initialization from `main.dart`
3. `SENTRY_DSN` from environment variables
4. All Sentry-specific imports

### What Was Added
1. `error_tracking` table in Supabase
2. Custom `ErrorTrackingService` class
3. Error analytics view
4. Row Level Security policies

### Benefits
- **Full Control**: Your error data stays in your database
- **No External Dependencies**: No reliance on third-party services
- **Cost Effective**: No per-error pricing
- **Customizable**: Add any fields or logic you need
- **Integrated**: Works seamlessly with your existing Supabase setup

## Testing

Run the test script to verify the system works:
```bash
dart test_error_tracking.dart
```

Make sure to update the Supabase URL and anon key in the test file before running.

## Monitoring & Alerts

Consider setting up:
1. **Database triggers** for high-priority errors
2. **Supabase Edge Functions** for email notifications
3. **Dashboard queries** for error trends
4. **Automated resolution** for known issues

## Troubleshooting

### Common Issues

**Errors not being captured**
- Check Supabase connection
- Verify RLS policies
- Check user authentication status

**Database connection errors**
- Ensure Supabase client is initialized
- Check network connectivity
- Verify API keys

**Missing device info**
- Check platform detection
- Verify app version in pubspec.yaml
- Check debug mode settings

The system includes fallback console logging for all error capture methods, so errors will still be visible in logs even if database storage fails.
