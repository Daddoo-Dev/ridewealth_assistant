# Development run script for Windows PowerShell

Write-Host "Starting Android emulator..."
# Launch the pixel_7 emulator using Flutter
flutter emulators --launch pixel_7

Write-Host "Waiting for emulator to be ready..."
# Wait for emulator to be fully booted
adb wait-for-device
Write-Host "Emulator is ready!"

Write-Host "Running Flutter app with environment variables from env.json..."
flutter run --dart-define-from-file=env.json $args 