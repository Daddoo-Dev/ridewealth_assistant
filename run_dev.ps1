# Development run script for Windows PowerShell

Write-Host "Starting Android emulator..."
# Launch the pixel_7 emulator using Flutter
flutter emulators --launch pixel_7

Write-Host "Waiting for emulator to be ready..."
# Wait for emulator to be fully booted
adb wait-for-device
Write-Host "Emulator is ready!"

Write-Host "Running Flutter app with environment variables..."
flutter run `
  --dart-define=SUPABASE_URL=https://ygreztutwejfiqyzdpnd.supabase.co `
  --dart-define=RESEND_KEY=re_PWCkxuZF_HHiEmmdMyxdXjt8eYgiCa6iw `
  --dart-define=SENTRY_DSN=https://ef998c0a011679bc05ce2617525a8662@o4509657807060992.ingest.us.sentry.io/4509657808371712 `
  $args 