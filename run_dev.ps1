# Development run script for Windows
# Replace these values with your actual Supabase credentials
$SUPABASE_URL = "https://your-project.supabase.co"
$SUPABASE_KEY = "your-anon-key"

Write-Host "Running Flutter app with Supabase credentials..." -ForegroundColor Green
flutter run --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_KEY=$SUPABASE_KEY 