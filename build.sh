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

# Copy static pages to build output
cp -r delete-account build/web/
cp -r support build/web/
cp -r marketing build/web/
