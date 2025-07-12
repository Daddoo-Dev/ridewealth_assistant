#!/bin/bash

# Build web with environment variables
# Use --dart-define-from-file=env.json or pass variables directly

flutter build web \
  --dart-define-from-file=env.json

# Note: Firebase variables are now handled via env.json
# If you need Firebase config, add it to env.json:
# {
#   "FIREBASE_API_KEY": "your-key",
#   "FIREBASE_AUTH_DOMAIN": "your-domain",
#   "FIREBASE_PROJECT_ID": "your-project-id",
#   "FIREBASE_STORAGE_BUCKET": "your-bucket",
#   "FIREBASE_MESSAGING_SENDER_ID": "your-sender-id",
#   "FIREBASE_APP_ID": "your-app-id",
#   "FIREBASE_MEASUREMENT_ID": "your-measurement-id"
# }