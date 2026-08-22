# SahAI

Voice-first postnatal danger-sign triage assistant for community health workers in India.

## Stack

| Layer | Technology |
| --- | --- |
| Backend | Python 3.12, FastAPI, Uvicorn |
| ML | XGBoost + SHAP (UCI Maternal Health Risk dataset) |
| STT | OpenAI Whisper (local, `small` model) |
| RAG | Chroma + sentence-transformers + Claude API |
| SMS | Twilio (with `SIMULATE_SMS=true` demo mode) |
| Frontend | React + Vite (mobile-first PWA) |
| Cases | SQLite |

## Project structure

```
sahai/
├── backend/app/          # FastAPI application
├── frontend/             # React PWA
├── data/                 # datasets, WHO text, Chroma store
├── requirements.txt
└── .env.example
```

## Quick start

### 1. Python environment

```bash
cd sahai
python3.12 -m venv sahai-env
source sahai-env/bin/activate
pip install -r requirements.txt
pip install matplotlib   # for SHAP summary plot during training
```

Requires **ffmpeg** (`apt install ffmpeg` on Ubuntu).

### 2. Train model & ingest guidelines (one-time)

```bash
cd backend
export PYTHONPATH=$(pwd)
python -m app.models.train_classifier
python -m app.services.ingest_guidelines
```

Place `data/who_postnatal_2022.pdf` for full WHO text, or use the bundled `who_postnatal_guidelines.txt`.

### 3. Environment variables

Copy `.env.example` to `.env` in `sahai/`:

```bash
cp .env.example .env
```

Set `ANTHROPIC_API_KEY` for full Claude chat. Leave `SIMULATE_SMS=true` for demos without Twilio.

### 4. Run backend

```bash
cd backend
export PYTHONPATH=$(pwd)
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Open http://localhost:8000/docs for Swagger UI.

### 5. Run frontend

```bash
cd frontend
npm install
npm run dev
```

Open http://localhost:5173

## API routes

| Route | Description |
| --- | --- |
| `POST /api/vitals` | Score vitals → risk level + SHAP factors |
| `POST /api/voice` | Upload audio → Whisper transcript |
| `POST /api/chat` | Symptom chat with RAG + Claude |
| `POST /api/escalate` | Manual SMS escalation |
| `GET /api/dashboard` | Supervisor case list |

High-risk vitals auto-trigger escalation (SMS or simulated log).

## Deployment

### Render (backend)

- **Root directory:** `sahai/backend`
- **Build:** `pip install -r ../requirements.txt`
- **Start:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Set env vars from `.env.example`
- Add `ALLOWED_ORIGINS` with your Vercel URL

**Note:** Whisper `small` model may timeout on free-tier cold starts. Use `base` in `stt_service.py` or upgrade instance.

### Vercel (frontend)

- **Root directory:** `sahai/frontend`
- **Build:** `npm run build`
- **Output:** `dist`
- Env: `VITE_API_BASE_URL=https://your-render-app.onrender.com`

### Common deployment issues

1. **CORS** — add Vercel URL to `ALLOWED_ORIGINS`
2. **Missing env vars** — check Render dashboard for API keys
3. **Whisper cold start** — use smaller model or paid Render tier
4. **SQLite not persisting** — Render ephemeral disk; use external DB for production
5. **Chroma/model paths** — ensure build step runs train + ingest, or commit artifacts

## Demo checklist

1. Low-risk vitals → green badge, no SMS
2. High-risk vitals (e.g. Age 35, BP 140/90, BS 15) → red badge + escalation
3. Voice symptom recording → transcript + LLM follow-up
4. Dashboard shows cases sorted by risk
5. Repeat on deployed URLs

## License

Hackathon / educational use. Not a substitute for clinical judgment.
