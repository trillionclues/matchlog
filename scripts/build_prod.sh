#!/bin/bash
# Build MatchLog for production (Android App Bundle + iOS IPA).
# Reads from .env if it exists.
#
# Usage: ./scripts/build_prod.sh android
#        ./scripts/build_prod.sh ios

set -e

if [ -f .env ]; then
  export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

PLATFORM=${1:-android}

DART_DEFINES=(
  "--dart-define=ENV=prod"
  "--dart-define=FOOTBALL_API_KEY=${FOOTBALL_API_KEY:-1}"
  "--dart-define=FOOTBALL_API_URL=${FOOTBALL_API_URL:-https://www.thesportsdb.com/api/v1/json}"
  "--dart-define=GEMINI_API_KEY=${GEMINI_API_KEY:-}"
)

case $PLATFORM in
  android)
    echo "Building Android App Bundle (prod)..."
    flutter build appbundle --release "${DART_DEFINES[@]}"
    echo "Output: build/app/outputs/bundle/release/app-release.aab"
    ;;
  ios)
    echo "Building iOS IPA (prod)..."
    flutter build ipa --release "${DART_DEFINES[@]}"
    echo "Output: build/ios/ipa/"
    ;;
  *)
    echo "Usage: $0 [android|ios]"
    exit 1
    ;;
esac
