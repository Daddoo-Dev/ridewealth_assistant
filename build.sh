#!/bin/bash
set -e

# Install Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PWD/flutter/bin:$PATH"

# Accept Flutter licenses
flutter doctor --android-licenses || true

# Generate env.json from Netlify environment variables
echo "{\"SUPABASE_URL\":\"$SUPABASE_URL\",\"SUPABASE_KEY\":\"$SUPABASE_KEY\"}" > env.json

# Get dependencies and build
flutter pub get
flutter build web
