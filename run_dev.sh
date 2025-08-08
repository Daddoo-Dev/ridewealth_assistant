#!/bin/bash
# Development run script for macOS/Linux

echo "Starting Android emulator..."
# Start the first available emulator
emulator -avd $(emulator -list-avds | head -n 1) &

echo "Waiting for emulator to be ready..."
# Wait for emulator to be fully booted
adb wait-for-device
echo "Emulator is ready!"

echo "Running Flutter app with environment variables..."
flutter run \
  --dart-define=SUPABASE_URL=https://ygreztutwejfiqyzdpnd.supabase.co \
  --dart-define=RESEND_KEY=re_PWCkxuZF_HHiEmmdMyxdXjt8eYgiCa6iw \
  --dart-define=SENTRY_DSN=https://ef998c0a011679bc05ce2617525a8662@o4509657807060992.ingest.us.sentry.io/4509657808371712 \
  "$@" 