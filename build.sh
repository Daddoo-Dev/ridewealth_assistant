#!/bin/bash
set -e

# Install Flutter
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

export PATH="$PWD/flutter/bin:$PATH"

# Accept Flutter licenses
flutter doctor --android-licenses || true

# Get dependencies and build
flutter pub get
flutter build web

# Copy static pages and shared logo to build output
cp -r static/delete-account build/web/
cp -r static/support build/web/
cp -r static/marketing build/web/
cp -r static/terms build/web/
mkdir -p build/web/assets/images
cp assets/images/RWAlogo.png build/web/assets/images/
