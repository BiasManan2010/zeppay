"""Lightweight SQLite case log for demo supervisor dashboard."""

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent.parent / "data" / "sahai_cases.db"

RISK_ORDER = {"high": 0, "mid": 1, "low": 2}


def _connect() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with _connect() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS cases (
                id TEXT PRIMARY KEY,
                mother_name TEXT NOT NULL DEFAULT 'Unknown',
                age INTEGER,
                vitals TEXT,
                transcript TEXT,
                risk_level TEXT NOT NULL,
                confidence REAL,
                escalation_status TEXT NOT NULL DEFAULT 'none',
                created_at TEXT NOT NULL
            )
            """
        )
        conn.commit()


def insert_case(
    case_id: str,
    mother_name: str,
    age: int | None,
    vitals: dict | None,
    transcript: str | None,
    risk_level: str,
    confidence: float | None,
    escalation_status: str = "none",
) -> None:
    with _connect() as conn:
        conn.execute(
            """
            INSERT OR REPLACE INTO cases
            (id, mother_name, age, vitals, transcript, risk_level, confidence,
             escalation_status, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                case_id,
                mother_name,
                age,
                json.dumps(vitals) if vitals else None,
                transcript,
                risk_level,
                confidence,
                escalation_status,
                datetime.now(timezone.utc).isoformat(),
            ),
        )
        conn.commit()


def update_escalation(case_id: str, escalation_status: str) -> None:
    with _connect() as conn:
        conn.execute(
            "UPDATE cases SET escalation_status = ? WHERE id = ?",
            (escalation_status, case_id),
        )
        conn.commit()


def update_transcript(case_id: str, transcript: str) -> None:
    with _connect() as conn:
        conn.execute(
            "UPDATE cases SET transcript = ? WHERE id = ?",
            (transcript, case_id),
        )
        conn.commit()


def get_all_cases() -> list[dict]:
    with _connect() as conn:
        rows = conn.execute(
            "SELECT * FROM cases ORDER BY created_at DESC"
        ).fetchall()
    cases = []
    for row in rows:
        cases.append(
            {
                "id": row["id"],
                "mother_name": row["mother_name"],
                "age": row["age"],
                "vitals": json.loads(row["vitals"]) if row["vitals"] else None,
                "transcript": row["transcript"],
                "risk_level": row["risk_level"],
                "confidence": row["confidence"],
                "escalation_status": row["escalation_status"],
                "created_at": row["created_at"],
            }
        )
    cases.sort(
        key=lambda c: (
            RISK_ORDER.get(c["risk_level"], 99),
            c["created_at"],
        )
    )
    return cases
