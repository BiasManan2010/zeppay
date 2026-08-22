"""SahAI — voice-first postnatal danger-sign triage API."""

import os
import tempfile
import uuid
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from app.models import db
from app.models.schemas import (
    ChatRequest,
    ChatResponse,
    DashboardResponse,
    EscalateRequest,
    EscalateResponse,
    TopFactor,
    VitalsRequest,
    VitalsResponse,
    VoiceResponse,
)
from app.services.escalation_service import send_escalation
from app.services.rag_chat_service import get_demo_response, get_llm_response
from app.services.risk_service import predict_risk
from app.services.stt_service import transcribe_audio

load_dotenv()

# In-memory session history — move to Redis for production
session_store: dict[str, list[dict]] = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    db.init_db()
    yield


def _allowed_origins() -> list[str]:
    raw = os.getenv(
        "ALLOWED_ORIGINS",
        "http://localhost:5173,http://127.0.0.1:5173",
    )
    return [o.strip() for o in raw.split(",") if o.strip()]


app = FastAPI(
    title="SahAI API",
    description="Voice-first postnatal danger-sign triage for community health workers",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health_root():
    return {"ok": True, "service": "sahai-backend"}


@app.get("/api/health")
@app.get("/api/health/")
def health_api():
    return {"status": "ok", "service": "sahai-backend"}


@app.post("/api/vitals", response_model=VitalsResponse)
def post_vitals(body: VitalsRequest):
    case_id = str(uuid.uuid4())
    result = predict_risk(
        age=body.age,
        systolic_bp=body.systolic_bp,
        diastolic_bp=body.diastolic_bp,
        blood_sugar=body.blood_sugar,
        body_temp=body.body_temp,
        heart_rate=body.heart_rate,
    )

    escalation_status = "none"
    if result["risk_level"] == "high":
        esc = send_escalation(
            case_id=case_id,
            risk_level=result["risk_level"],
            mother_name=body.mother_name,
            symptoms_summary=f"Vitals flagged high risk (confidence {result['confidence']:.0%})",
        )
        escalation_status = esc["status"]

    vitals_dict = {
        "systolic_bp": body.systolic_bp,
        "diastolic_bp": body.diastolic_bp,
        "blood_sugar": body.blood_sugar,
        "body_temp": body.body_temp,
        "heart_rate": body.heart_rate,
    }

    db.insert_case(
        case_id=case_id,
        mother_name=body.mother_name,
        age=body.age,
        vitals=vitals_dict,
        transcript=None,
        risk_level=result["risk_level"],
        confidence=result["confidence"],
        escalation_status=escalation_status,
    )

    return VitalsResponse(
        case_id=case_id,
        risk_level=result["risk_level"],
        confidence=result["confidence"],
        top_factors=[TopFactor(**f) for f in result["top_factors"]],
        escalation_status=escalation_status,
    )


@app.post("/api/voice", response_model=VoiceResponse)
async def post_voice(audio: UploadFile = File(...)):
    name = audio.filename or "audio.webm"
    suffix = "." + name.rsplit(".", 1)[-1] if "." in name else ".webm"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        content = await audio.read()
        tmp.write(content)
        tmp_path = tmp.name

    try:
        result = transcribe_audio(tmp_path)
    finally:
        os.unlink(tmp_path)

    return VoiceResponse(
        transcript=result["transcript"],
        detected_language=result["detected_language"],
    )


@app.post("/api/chat", response_model=ChatResponse)
def post_chat(body: ChatRequest):
    history = session_store.setdefault(body.session_id, [])

    if os.getenv("ANTHROPIC_API_KEY"):
        try:
            reply = get_llm_response(
                user_message=body.message,
                risk_level=body.risk_level,
                session_history=history,
            )
        except Exception as exc:
            reply = get_demo_response(body.message, body.risk_level)
            reply = f"{reply}\n(API error: {exc})"
    else:
        reply = get_demo_response(body.message, body.risk_level)

    history.append({"role": "user", "content": body.message})
    history.append({"role": "assistant", "content": reply})

    if body.case_id:
        db.update_transcript(body.case_id, body.message)

    return ChatResponse(reply=reply)


@app.post("/api/escalate", response_model=EscalateResponse)
def post_escalate(body: EscalateRequest):
    result = send_escalation(
        case_id=body.case_id,
        risk_level=body.risk_level,
        mother_name=body.mother_name,
        symptoms_summary=body.symptoms_summary or "Manual escalation requested",
    )
    db.update_escalation(body.case_id, result["status"])
    return EscalateResponse(**result)


@app.get("/api/dashboard", response_model=DashboardResponse)
def get_dashboard():
    cases = db.get_all_cases()
    return DashboardResponse(cases=cases)
