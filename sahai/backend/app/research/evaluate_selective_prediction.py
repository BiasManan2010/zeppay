"""
Evaluate selective-prediction baselines B1–B3 on scripted scenarios.

Usage (from sahai/backend with PYTHONPATH set):
  python -m app.research.evaluate_selective_prediction
  python -m app.research.evaluate_selective_prediction --policies b1_no_uncertainty b3_fused
"""

import argparse
import json
from pathlib import Path

from app.services.triage_service import assess_triage
from app.services.uncertainty_fusion import EscalationPolicy

ROOT = Path(__file__).resolve().parents[3]
SCENARIOS_PATH = ROOT / "data" / "research" / "scripted_scenarios.json"


def evaluate_policy(scenarios: list[dict], policy: EscalationPolicy) -> dict:
    n = len(scenarios)
    correct_action = 0
    missed_emergency = 0
    false_alarm = 0
    deferred = 0

    for s in scenarios:
        v = s["vitals"]
        result = assess_triage(
            age=v["age"],
            systolic_bp=v["systolic_bp"],
            diastolic_bp=v["diastolic_bp"],
            blood_sugar=v["blood_sugar"],
            body_temp=v["body_temp"],
            heart_rate=v["heart_rate"],
            transcript=s["script"],
            asr_confidence=0.9 if s.get("noise_condition") == "clean" else 0.55,
            policy=policy,
            log_event=False,
        )

        gold_escalate = s["gold_escalate"]
        action = result["triage_action"]

        if action == "defer":
            deferred += 1
            continue

        predicted_escalate = action == "escalate"
        if predicted_escalate == gold_escalate:
            correct_action += 1
        if gold_escalate and not predicted_escalate:
            missed_emergency += 1
        if not gold_escalate and predicted_escalate:
            false_alarm += 1

    decided = n - deferred
    accuracy_on_decided = correct_action / decided if decided else 0.0

    return {
        "policy": policy.value,
        "n_scenarios": n,
        "deferred": deferred,
        "deferral_rate": deferred / n,
        "accuracy_on_decided": accuracy_on_decided,
        "missed_emergency": missed_emergency,
        "false_alarm": false_alarm,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--policies",
        nargs="*",
        default=[p.value for p in EscalationPolicy],
    )
    args = parser.parse_args()

    scenarios = json.loads(SCENARIOS_PATH.read_text(encoding="utf-8"))
    print(f"Loaded {len(scenarios)} scripted scenarios from {SCENARIOS_PATH}\n")

    for name in args.policies:
        policy = EscalationPolicy(name)
        metrics = evaluate_policy(scenarios, policy)
        print(json.dumps(metrics, indent=2))
        print()


if __name__ == "__main__":
    main()
