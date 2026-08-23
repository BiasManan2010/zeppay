#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/flutter/bin:${PATH:-}"
cd "${CURSOR_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

flutter pub get

if [[ ! -f web/index.html ]]; then
  flutter create . --platforms=web --org in.zeppay --project-name zeppay
fi
