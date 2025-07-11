# Dependency Analysis for Dart 3.4.1 Compatibility

## Current Situation
- **Local Environment**: Flutter 3.32.6, Dart 3.8.1
- **GitHub Actions**: Flutter 3.22.1, Dart 3.4.1
- **Problem**: Dependencies resolved for newer Dart SDK are incompatible with older Dart SDK

## FINAL WORKING DEPENDENCIES FOR DART 3.4.1

### Direct Dependencies (Confirmed Working)
```yaml
dependencies:
  flutter:
    sdk: flutter
  english_words:
  provider:
  google_sign_in: ^6.1.6
  sign_in_with_apple: ^7.0.1
  shared_preferences: ^2.3.3
  csv: ^5.1.1
  http: ^1.1.2
  intl: ^0.19.0
  universal_html: ^2.2.4
  path_provider: ^2.1.2
  collection: ^1.18.0
  fluttertoast: ^8.2.8
  url_launcher: ^6.3.1
  in_app_purchase: ^3.1.13
  share_plus: ^10.0.0
  permission_handler: ^11.3.1
  in_app_purchase_storekit: ^0.3.0
  supabase_flutter: ^2.8.0
  flutter_dotenv: ^5.1.0
  connectivity_plus: ^5.0.2
  dynamic_color: ^1.6.8
  purchases_flutter: ^8.0.0
  flutter_plugin_android_lifecycle: ^2.0.15
  google_sign_in_android: ^6.1.21

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

### Key Changes Made for Dart 3.4.1 Compatibility
1. **flutter_lints**: ^6.0.0 → ^4.0.0 (requires Dart 3.8+)
2. **google_sign_in**: ^6.3.0 → ^6.1.6 (requires Dart 3.6+)
3. **shared_preferences**: ^2.3.4 → ^2.3.3 (requires Dart 3.5+)
4. **permission_handler**: ^12.0.1 → ^11.3.1 (requires Dart 3.5+)
5. **in_app_purchase**: ^3.2.2 → ^3.1.13 (requires Dart 3.5+)
6. **share_plus**: ^11.0.0 → ^10.0.0 (requires Dart 3.5+)
7. **supabase_flutter**: unpinned → ^2.8.0 (for stability)
8. **flutter_dotenv**: unpinned → ^5.1.0 (for stability)
9. **purchases_flutter**: ^8.10.5 → ^8.0.0 (for stability)

### Android Configuration Fix
- **Removed hardcoded Java path**: `org.gradle.java.home=C:\\Program Files\\Java\\jdk-21` from `android/gradle.properties`
- Now uses system default Java installation (works in CI/CD)

## Dependencies That Need Downgrading

### 1. Direct Dependencies (from pubspec.yaml)

| Package | Current Version | Compatible Version for Dart 3.4.1 | Reason |
|---------|----------------|-----------------------------------|---------|
| `collection` | 1.19.1 | 1.18.0 | ✅ Already correct in pubspec.yaml |
| `connectivity_plus` | 5.0.2 | 5.0.2 | ✅ Already correct |
| `dynamic_color` | 1.7.0 | 1.6.8 | ✅ Already correct in pubspec.yaml |
| `flutter_plugin_android_lifecycle` | 2.0.28 | 2.0.15 | ✅ Already correct in pubspec.yaml |
| `google_sign_in` | 6.3.0 | 6.3.0 | ✅ Already correct |
| `google_sign_in_android` | 6.2.1 | 6.1.21 | ✅ Already correct in pubspec.yaml |
| `http` | 1.4.0 | 1.1.2 | ✅ Already correct in pubspec.yaml |
| `intl` | 0.19.0 | 0.19.0 | ✅ Already correct |
| `path_provider` | 2.1.5 | 2.1.2 | ✅ Already correct in pubspec.yaml |
| `permission_handler` | 12.0.1 | 12.0.1 | ✅ Already correct |
| `purchases_flutter` | 8.10.5 | 8.10.5 | ✅ Already correct |
| `share_plus` | 11.0.0 | 11.0.0 | ✅ Already correct |
| `sign_in_with_apple` | 7.0.1 | 7.0.1 | ✅ Already correct |
| `supabase_flutter` | 2.9.1 | 2.9.1 | ✅ Already correct |

### 2. Transitive Dependencies That Need Attention

| Package | Current Version | Compatible Version | Issue |
|---------|----------------|-------------------|-------|
| `flutter_lints` | 6.0.0 | 5.0.0 | Requires Dart 3.8+ |
| `flutter_dotenv` | 5.2.1 | 5.1.0 | May have compatibility issues |
| `csv` | 5.1.1 | 5.1.1 | ✅ Already correct |
| `fluttertoast` | 8.2.12 | 8.2.8 | ✅ Already correct in pubspec.yaml |
| `url_launcher` | 6.3.1 | 6.3.1 | ✅ Already correct |
| `in_app_purchase` | 3.2.3 | 3.2.3 | ✅ Already correct |
| `in_app_purchase_android` | 0.4.0+2 | 0.4.0+2 | ✅ Already correct |
| `in_app_purchase_storekit` | 0.4.3 | 0.4.3 | ✅ Already correct |
| `universal_html` | 2.2.4 | 2.2.4 | ✅ Already correct |

## Root Cause Analysis

The main issue is in your `pubspec.lock` file, which shows:
```
sdks:
  dart: ">=3.8.0 <4.0.0"
  flutter: ">=3.27.0"
```

But your `pubspec.yaml` correctly specifies:
```yaml
environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.22.1"
```

## Solution Steps

### Step 1: Clean and Regenerate pubspec.lock
```bash
flutter clean
flutter pub get
```

### Step 2: Force SDK Constraints
The `pubspec.lock` should reflect the constraints from `pubspec.yaml`, not newer versions.

### Step 3: Specific Package Fixes

#### Fix flutter_lints
```yaml
dev_dependencies:
  flutter_lints: ^5.0.0  # Downgrade from 6.0.0
```

#### Fix flutter_dotenv (if needed)
```yaml
dependencies:
  flutter_dotenv: ^5.1.0  # Downgrade if issues persist
```

## Verification Commands

After making changes, run:
```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --release
```

## Expected Outcome

After these changes, your project should:
1. ✅ Build successfully in GitHub Actions with Flutter 3.22.1
2. ✅ Work with Dart 3.4.1
3. ✅ Maintain compatibility with your local development environment
4. ✅ Have consistent dependency resolution

## Additional Recommendations

1. **Pin Flutter Version**: Consider using the exact Flutter version in GitHub Actions that matches your local development
2. **Use Dependency Overrides**: For critical packages, consider using `dependency_overrides` in `pubspec.yaml`
3. **Regular Updates**: Schedule regular dependency updates to avoid large version gaps

## Quick Fix Script

```bash
# Clean everything
flutter clean
rm pubspec.lock

# Update pubspec.yaml with correct versions
# (see specific changes above)

# Regenerate with correct constraints
flutter pub get

# Verify
flutter analyze
``` 