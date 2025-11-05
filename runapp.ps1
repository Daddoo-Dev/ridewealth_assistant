# Simple app runner script

Write-Host "Running Flutter app with environment variables from env.json..."

# Run the app with environment variables from env.json
flutter run --dart-define-from-file=env.json $args 