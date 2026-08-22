"""Full triage pipeline with uncertainty instrumentation (research)."""

import os
from datetime import datetime, timezone

from app.services.llm_uncertainty import estimate_llm_uncertainty, retrieval_margin
from app.services.risk_service import predict_risk
from app.services.symptom_extraction import extract_danger_flags
from app.services.uncertainty_fusion import (
    EscalationPolicy,
    UncertaintySignals,
    decide_escalation,
    entropy_from_proba,
    log_pipeline_event,
)
from app.services.escalation_service import send_escalation


def _policy_from_env() -> EscalationPolicy:
    raw = os.getenv("ESCALATION_POLICY", "b3_fused").lower()
    for p in EscalationPolicy:
        if p.value == raw:
            return p
    return EscalationPolicy.B3_FUSED


def assess_triage(
    age: int,
    systolic_bp: int,
    diastolic_bp: int,
    blood_sugar: float,
    body_temp: float,
    heart_rate: int,
    transcript: str | None = None,
    asr_confidence: float | None = None,
    mother_name: str = "Unknown",
    case_id: str | None = None,
    policy: EscalationPolicy | None = None,
    log_event: bool = True,
) -> dict:
    risk = predict_risk(
        age=age,
        systolic_bp=systolic_bp,
        diastolic_bp=diastolic_bp,
        blood_sugar=blood_sugar,
        body_temp=body_temp,
        heart_rate=heart_rate,
    )

    transcript = (transcript or "").strip()
    symptoms = extract_danger_flags(transcript)

    llm_u = estimate_llm_uncertainty(
        transcript or f"vitals-only risk {risk['risk_level']}",
        risk["risk_level"],
    )
    margin = retrieval_margin(transcript) if transcript else None

    proba = risk.get("class_probabilities", [])
    entropy = entropy_from_proba(proba) if proba else None

    signals = UncertaintySignals(
        asr_confidence=asr_confidence,
        classifier_confidence=risk["confidence"],
        classifier_entropy=entropy,
        llm_uncertainty=llm_u,
        retrieval_margin=margin,
    )

    chosen_policy = policy or _policy_from_env()
    decision = decide_escalation(
        risk_level=risk["risk_level"],
        symptom_escalate=symptoms["symptom_escalate"],
        signals=signals,
        policy=chosen_policy,
    )

    escalation_status = "none"
    if decision.action == "escalate" and case_id:
        esc = send_escalation(
            case_id=case_id,
            risk_level=risk["risk_level"],
            mother_name=mother_name,
            symptoms_summary=transcript[:200] or f"Vitals {risk['risk_level']}",
        )
        escalation_status = esc["status"]

    result = {
        "risk_level": risk["risk_level"],
        "confidence": risk["confidence"],
        "top_factors": risk["top_factors"],
        "class_probabilities": proba,
        "transcript": transcript or None,
        "symptom_flags": symptoms,
        "uncertainty": signals.to_dict(),
        "fused_confidence": decision.fused_confidence,
        "triage_action": decision.action,
        "should_defer": decision.should_defer,
        "policy": decision.policy,
        "decision_reason": decision.reason,
        "escalation_status": escalation_status,
    }

    if log_event:
        log_pipeline_event(
            {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "case_id": case_id,
                "mother_name": mother_name,
                "vitals": {
                    "age": age,
                    "systolic_bp": systolic_bp,
                    "diastolic_bp": diastolic_bp,
                    "blood_sugar": blood_sugar,
                    "body_temp": body_temp,
                    "heart_rate": heart_rate,
                },
                **{k: result[k] for k in result if k != "top_factors"},
            }
        )

    return result
