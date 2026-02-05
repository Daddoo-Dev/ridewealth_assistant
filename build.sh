#!/bin/bash
set -e

# Install Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PWD/flutter/bin:$PATH"

# Accept Flutter licenses
flutter doctor --android-licenses || true

# Get dependencies and build with environment variables
flutter pub get
flutter build web \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_KEY="$SUPABASE_KEY" \
  --dart-define=SENTRY_DSN="$SENTRY_DSN"

# Copy delete-account page to build output
cp -r delete-account build/web/
