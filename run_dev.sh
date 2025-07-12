#!/bin/bash
# Development run script for macOS/Linux
# Replace these values with your actual Supabase credentials
SUPABASE_URL="https://your-project.supabase.co"
SUPABASE_KEY="your-anon-key"

echo "Running Flutter app with Supabase credentials..."
flutter run --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_KEY=$SUPABASE_KEY 