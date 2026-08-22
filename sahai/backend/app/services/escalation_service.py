"""Twilio SMS escalation with simulate mode for demos."""

import os

from dotenv import load_dotenv

load_dotenv()


def send_escalation(
    case_id: str,
    risk_level: str,
    mother_name: str,
    symptoms_summary: str,
) -> dict:
    message = (
        f"SahAI ALERT: {risk_level.upper()}-risk postnatal case flagged. "
        f"Patient: {mother_name}. Summary: {symptoms_summary}. "
        f"Case ID: {case_id}. Please review."
    )

    simulate = os.getenv("SIMULATE_SMS", "true").lower() == "true"
    if simulate:
        print(f"[SIMULATE SMS] {message}")
        return {"status": "simulated", "message": message}

    try:
        from twilio.rest import Client

        sid = os.getenv("TWILIO_SID")
        token = os.getenv("TWILIO_AUTH_TOKEN")
        from_number = os.getenv("TWILIO_FROM_NUMBER")
        supervisor = os.getenv("SUPERVISOR_PHONE")

        if not all([sid, token, from_number, supervisor]):
            return {
                "status": "failed",
                "error": "Twilio credentials or SUPERVISOR_PHONE not configured",
            }

        client = Client(sid, token)
        twilio_msg = client.messages.create(
            body=message,
            from_=from_number,
            to=supervisor,
        )
        return {"status": "sent", "sid": twilio_msg.sid, "message": message}
    except Exception as exc:
        return {"status": "failed", "error": str(exc)}
