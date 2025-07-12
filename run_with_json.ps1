# Development run script using JSON config file
Write-Host "Running Flutter app with JSON config..." -ForegroundColor Green
flutter run --dart-define-from-file=env.json 