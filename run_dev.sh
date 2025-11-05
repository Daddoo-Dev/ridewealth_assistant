#!/bin/bash
# Development run script for macOS/Linux

echo "Starting Android emulator..."
# Start the first available emulator
emulator -avd $(emulator -list-avds | head -n 1) &

echo "Waiting for emulator to be ready..."
# Wait for emulator to be fully booted
adb wait-for-device
echo "Emulator is ready!"

echo "Running Flutter app with environment variables from env.json..."
flutter run --dart-define-from-file=env.json "$@" 