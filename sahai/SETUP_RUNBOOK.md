# SahAI — Full Setup Runbook

**Phase 0:** project scaffold, environment setup, and first successful run.

Consolidated record of prompts and steps to scaffold and run SahAI end-to-end. Use this on a new machine or with a teammate. The repo under `sahai/` now includes Phases 1–8 (trained XGBoost model, FAISS RAG, vitals form, dashboard) — not just the original skeleton stubs.

---

## 1. Original project request

```
I'm starting a new project called SahAI: a voice-first maternal health
triage assistant for community health workers in India. My stack is:
- Backend: Python 3.14 (fallback 3.12), FastAPI
- ML: XGBoost + SHAP
- STT: OpenAI Whisper (local, open-source)
- RAG: FAISS or Chroma + Claude API
- Notifications: Twilio (simulated for demo)
- Frontend: React (mobile-first PWA)

Set up the initial project skeleton with this structure:
sahai/backend/ (with subfolders app/, app/models/, app/routes/,
app/services/, data/)
sahai/frontend/ (create-react-app or Vite React app)
A root requirements.txt for backend and package.json for frontend.
A .env.example listing ANTHROPIC_API_KEY, TWILIO_SID,
TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER.
A .gitignore covering Python, Node, .env, and model/vector-store
artifacts.
```

**Current repo layout:**

```
sahai/
├── backend/app/
│   ├── main.py              # FastAPI routes
│   ├── models/              # schemas, db, train_classifier, risk_model.pkl
│   └── services/            # risk, stt, rag, escalation, vector_store
├── frontend/src/
│   ├── components/          # VitalsForm, VoiceChat, ResultScreen, Dashboard
│   └── lib/api.js
├── data/
│   ├── maternal_risk.csv
│   ├── who_postnatal_guidelines.txt
│   └── faiss_store/         # after ingest (default)
├── requirements.txt
├── requirements-windows.txt
├── .env.example
└── SETUP_RUNBOOK.md         # this file
```

---

## 2. Backend environment setup

### Linux / macOS

```bash
cd sahai
cp .env.example .env
python3.12 -m venv sahai-env
source sahai-env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
# Ubuntu/Debian: sudo apt install ffmpeg
```

### Windows (PowerShell)

```powershell
cd sahai
Copy-Item .env.example .env
cd backend
py -3.12 -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r ..\requirements-windows.txt
pip install --no-build-isolation openai-whisper==20231117
```

### Issue 1 — Python 3.14 has no prebuilt wheels for scikit-learn / SHAP

scikit-learn may try to compile from source and fail (Windows/ninja build bugs).

**Fix:** use **Python 3.12** for the whole project.

```powershell
deactivate
Remove-Item -Recurse -Force .venv
py -0                                 # list installed versions
winget install Python.Python.3.12     # if 3.12 not listed
py -3.12 -m venv .venv
.venv\Scripts\Activate.ps1
```

### Issue 2 — openai-whisper build fails (`pkg_resources`)

Caused by pip’s isolated build environment pulling setuptools 81+ (dropped `pkg_resources`).

**Fix:**

```powershell
pip install "setuptools<81"
pip install --no-build-isolation openai-whisper==20231117
```

### Issue 3 — chromadb fails to build on Windows

Error: *Microsoft Visual C++ 14.0 or greater is required* (chroma-hnswlib).

**Fix (recommended):** use **FAISS** — already the default (`VECTOR_BACKEND=faiss` in `.env.example`). No Chroma install needed.

**Alternative if you need Chroma:** install Visual Studio Build Tools with “Desktop development with C++”, add `chromadb>=0.5.0` to requirements, set `VECTOR_BACKEND=chroma`, reinstall.

### One-time ML + RAG setup

From `sahai/backend` with venv active:

```bash
export PYTHONPATH=$(pwd)          # Linux/macOS
# PowerShell: $env:PYTHONPATH = (Get-Location).Path

python -m app.models.train_classifier    # trains risk_model.pkl (~82% accuracy)
python -m app.services.ingest_guidelines   # builds data/faiss_store/
```

Place full WHO PDF at `data/who_postnatal_2022.pdf` or use bundled `who_postnatal_guidelines.txt`.

### Run the backend

```bash
cd backend
export PYTHONPATH=$(pwd)   # or $env:PYTHONPATH on Windows
uvicorn app.main:app --reload
```

**Verify:**

- Swagger UI: http://localhost:8000/docs
- Health check:

```bash
curl http://localhost:8000/api/health/
# Expect: {"status":"ok","service":"sahai-backend"}
```

Leave this terminal running. `Application startup complete` with no further output is normal — the server is idle until requests arrive.

---

## 3. Frontend environment setup

Open a **second terminal**; keep the backend running.

### Issue — Node.js not installed (Windows)

```powershell
winget install OpenJS.NodeJS.LTS --source winget
```

If winget shows an ambiguous-source error, pass `--source winget` explicitly. Close and reopen the terminal (or restart the machine) so PATH updates.

```powershell
node --version   # needs ≥ 18
npm --version
```

### Install and run

```bash
cd sahai/frontend
npm install
npm run dev
```

Expected:

```
VITE v5.x.x  ready in xxx ms
➜  Local:   http://localhost:5173/
```

Open http://localhost:5173. Vite proxies `/api` to `http://localhost:8000` — no hardcoded API URL required for local dev.

Production / deployed frontend: set `VITE_API_BASE_URL` to your Render backend URL.

---

## 4. End-to-end test

| Step | Action | Expected |
|------|--------|----------|
| Vitals | Enter mother name, age, BP, sugar, temp, HR → **Check risk** | Result screen with colored risk badge + SHAP factors |
| Low risk | e.g. age 25, BP 90/60, BS 7, temp 98, HR 70 | Green **LOW RISK** |
| High risk | e.g. age 35, BP 140/90, BS 15, temp 98, HR 70 | Red **HIGH RISK** + nurse notification (simulated SMS in logs) |
| Voice | Voice screen → **Start voice intake** → allow mic → speak → **Stop recording** | Transcript appears; first run downloads Whisper `base` model (~150MB, one-time) |
| Chat | After transcript, LLM follow-up in chat bubbles | WHO-grounded reply (demo mode without `ANTHROPIC_API_KEY`) |
| Dashboard | Open supervisor dashboard | Cases listed, sorted by risk |

Watch the backend terminal for request logs confirming each round trip.

---

## 5. Status after Phase 0 + full build

### Working

| Component | Status |
|-----------|--------|
| FastAPI backend | All routes wired (`/api/vitals`, `/api/voice`, `/api/chat`, `/api/escalate`, `/api/dashboard`, `/api/health/`) |
| React/Vite PWA | Vitals form, voice/chat, result screen, dashboard |
| XGBoost + SHAP | Trained model at `backend/app/models/risk_model.pkl` |
| FAISS RAG | Default vector store; Chroma optional via `VECTOR_BACKEND=chroma` |
| Whisper STT | Local transcription (`WHISPER_MODEL=base` default) |
| Twilio | Wired with `SIMULATE_SMS=true` (logs instead of sending) |
| SQLite case log | Supervisor dashboard persistence (local disk) |

### Environment variables (`.env`)

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Full Claude chat (demo fallback if unset) |
| `TWILIO_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER`, `SUPERVISOR_PHONE` | Live SMS |
| `SIMULATE_SMS=true` | Demo mode — print SMS instead of sending |
| `VECTOR_BACKEND=faiss` | Use FAISS (Windows-friendly) or `chroma` |
| `WHISPER_MODEL=base` | Whisper size: `base`, `small`, `medium` |
| `ALLOWED_ORIGINS` | CORS for production frontend URL |

---

## 6. Suggested next steps

- [ ] Add full WHO Postnatal Care Guidelines 2022 PDF and re-run `ingest_guidelines`
- [ ] Set `ANTHROPIC_API_KEY` for production-quality chat
- [ ] Deploy backend (Render) + frontend (Vercel) — see `README.md` and `render.yaml`
- [ ] Phase 9 demo checklist on deployed URLs
- [ ] Optional Phase 10: uncertainty / “defer to nurse” research module

---

## Quick reference — docs

| Topic | URL |
|-------|-----|
| FastAPI | https://fastapi.tiangolo.com |
| Whisper | https://github.com/openai/whisper |
| FAISS | https://faiss.ai |
| XGBoost | https://xgboost.readthedocs.io |
| SHAP | https://shap.readthedocs.io |
| Anthropic API | https://docs.claude.com |
| Twilio SMS | https://www.twilio.com/docs/sms/quickstart/python |
| Vite | https://vite.dev |
