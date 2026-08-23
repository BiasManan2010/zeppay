#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/flutter/bin:${PATH:-}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
source "$ROOT/.cursor/load-env.sh"

DEFINES=(
  --dart-define=TWILIO_VERIFY_URL="${TWILIO_VERIFY_URL:-http://127.0.0.1:8787}"
)
if [[ -n "${SUPABASE_URL:-}" ]]; then
  DEFINES+=(--dart-define=SUPABASE_URL="$SUPABASE_URL")
fi
if [[ -n "${SUPABASE_ANON_KEY:-}" ]]; then
  DEFINES+=(--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")
fi

exec flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0 "${DEFINES[@]}"
