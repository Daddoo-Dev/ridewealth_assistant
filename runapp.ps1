# Simple app runner script

Write-Host "Running Flutter app..."

# Run the app with environment variables
flutter run --dart-define=SUPABASE_URL=https://ygreztutwejfiqyzdpnd.supabase.co --dart-define=RESEND_KEY=re_PWCkxuZF_HHiEmmdMyxdXjt8eYgiCa6iw --dart-define=SENTRY_DSN=https://ef998c0a011679bc05ce2617525a8662@o4509657807060992.ingest.us.sentry.io/4509657808371712 $args 