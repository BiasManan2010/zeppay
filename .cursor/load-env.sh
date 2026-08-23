#!/usr/bin/env bash
# Sources backend/.env when present (local dev). Cloud Agent secrets map to the
# same variable names and do not need this file.
set -a
if [[ -f "${CURSOR_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}/backend/.env" ]]; then
  # shellcheck disable=SC1091
  source "${CURSOR_WORKSPACE:-$(git rev-parse --show-toplevel)}/backend/.env"
fi
set +a
