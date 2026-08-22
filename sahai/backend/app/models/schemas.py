from pydantic import BaseModel, Field


class VitalsRequest(BaseModel):
    age: int = Field(..., ge=10, le=70)
    systolic_bp: int = Field(..., ge=70, le=200)
    diastolic_bp: int = Field(..., ge=40, le=150)
    blood_sugar: float = Field(..., ge=6, le=25)
    body_temp: float = Field(..., ge=95, le=105)
    heart_rate: int = Field(..., ge=40, le=180)
    mother_name: str = "Unknown"


class TopFactor(BaseModel):
    feature: str
    impact: float


class VitalsResponse(BaseModel):
    case_id: str
    risk_level: str
    confidence: float
    top_factors: list[TopFactor]
    escalation_status: str | None = None


class VoiceResponse(BaseModel):
    transcript: str
    detected_language: str


class ChatRequest(BaseModel):
    message: str
    session_id: str
    risk_level: str = "low"
    case_id: str | None = None


class ChatResponse(BaseModel):
    reply: str


class EscalateRequest(BaseModel):
    case_id: str
    risk_level: str
    mother_name: str = "Unknown"
    symptoms_summary: str = ""


class EscalateResponse(BaseModel):
    status: str
    message: str | None = None
    sid: str | None = None
    error: str | None = None


class CaseSummary(BaseModel):
    id: str
    mother_name: str
    age: int | None
    vitals: dict | None
    transcript: str | None
    risk_level: str
    confidence: float | None
    escalation_status: str
    created_at: str


class DashboardResponse(BaseModel):
    cases: list[CaseSummary]
