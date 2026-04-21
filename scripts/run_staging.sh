#!/bin/bash
# Run MatchLog in staging mode.
# Reads from .env if it exists, otherwise uses defaults.
#
# Usage: ./scripts/run_staging.sh
#        ./scripts/run_staging.sh -d <device_id>

set -e

# Load .env if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | grep -v '^$' | xargs)
fi

flutter run \
  --dart-define=ENV=${ENV:-staging} \
  --dart-define=FOOTBALL_API_KEY=${FOOTBALL_API_KEY:-1} \
  --dart-define=FOOTBALL_API_URL=${FOOTBALL_API_URL:-https://www.thesportsdb.com/api/v1/json} \
  --dart-define=GEMINI_API_KEY=${GEMINI_API_KEY:-} \
  "$@"
