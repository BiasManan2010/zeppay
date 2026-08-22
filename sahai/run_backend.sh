#!/usr/bin/env bash
# Run SahAI FastAPI backend from repo root
cd "$(dirname "$0")/backend"
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
