# Building for iOS and macOS with GitHub Actions

## iOS Build Setup (Primary)

### 1. Prepare the Project
- Ensure all dependencies in `pubspec.yaml` are compatible with Flutter 3.22.1/Dart 3.4.1
- Run `flutter pub get`
- Run `pod install` in the `ios` directory:
  ```sh
  cd ios
  pod install
  cd ..
  ```
- Open `ios/Runner.xcworkspace` in Xcode if you need to update signing, bundle ID, or capabilities
- Add any required iOS-specific assets or permissions (e.g., Info.plist updates)

### 2. Environment Configuration
- Use `--dart-define` for environment variables:
  ```bash
  flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_KEY=your-key
  ```
- Or use JSON config file with `--dart-define-from-file=env.json`
- Make sure `env.json` exists in the project root before building

### 3. GitHub Actions Workflow Example
- Add a workflow file (e.g., `.github/workflows/ios.yml`):
  ```yaml
  name: Build iOS App
  on:
    push:
      branches: [ main, supabase ]
    pull_request:
      branches: [ main, supabase ]
  jobs:
    build:
      runs-on: macos-latest
      steps:
        - uses: actions/checkout@v4
        - uses: subosito/flutter-action@v2
          with:
            flutter-version: '3.22.1'
        - name: Install CocoaPods
          run: sudo gem install cocoapods
        - name: Get dependencies
          run: flutter pub get
        - name: Build iOS
          run: |
            cd ios
            pod install
            cd ..
            flutter build ipa --release
        - uses: actions/upload-artifact@v4
          with:
            name: ios-app
            path: build/ios/ipa/*.ipa
  ```
- For code signing and App Store/TestFlight upload, use [fastlane](https://docs.fastlane.tools/) and GitHub Secrets for certificates and provisioning profiles if needed.

### 4. Manual Steps for App Store/TestFlight
- Download the `.ipa` artifact from GitHub Actions
- Upload to App Store Connect using Xcode or Transporter app

---

## macOS Build Setup (Secondary)

### 1. Prepare the Project
- Ensure all dependencies are compatible
- Run `flutter pub get`

### 2. GitHub Actions Workflow Example (e.g., `.github/workflows/macos.yml`):
  ```yaml
  name: Build macOS App
  on:
    push:
      branches: [ main, supabase ]
    pull_request:
      branches: [ main, supabase ]
  jobs:
    build:
      runs-on: macos-latest
      steps:
        - uses: actions/checkout@v4
        - uses: subosito/flutter-action@v2
          with:
            flutter-version: '3.22.1'
        - name: Get dependencies
          run: flutter pub get
        - name: Build macOS
          run: flutter build macos --release
        - uses: actions/upload-artifact@v4
          with:
            name: macos-app
            path: build/macos/Build/Products/Release/*.app
  ```

---

## Tips
- Keep environment variables in sync across environments using `--dart-define`
- For iOS, use fastlane and GitHub Secrets for code signing automation if needed
- Test builds locally before pushing to CI
- Update `dependency_analysis.md` if you change dependency versions



