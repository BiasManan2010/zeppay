#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
source "$ROOT/.cursor/load-env.sh"

cd backend
if [[ ! -d node_modules ]]; then
  npm ci --omit=dev 2>/dev/null || npm install --omit=dev
fi
exec npm start
