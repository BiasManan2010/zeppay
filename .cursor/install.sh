#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/flutter/bin:${PATH:-}"
cd "${CURSOR_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

flutter pub get

if [[ -d backend ]] && command -v npm >/dev/null 2>&1; then
  (cd backend && npm ci --omit=dev 2>/dev/null || npm install --omit=dev)
fi

if [[ ! -f web/index.html ]]; then
  flutter create . --platforms=web --org in.zeppay --project-name zeppay
fi
