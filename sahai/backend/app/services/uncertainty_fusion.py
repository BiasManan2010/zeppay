"""Multi-source uncertainty signals and calibrated deferral (Direction 1 research layer)."""

import json
import math
import os
from dataclasses import asdict, dataclass
from enum import Enum
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
LOG_PATH = ROOT / "data" / "research" / "pipeline_logs.jsonl"

# Fused deferral threshold — tune on dev split during experiments
DEFAULT_DEFER_THRESHOLD = float(os.getenv("UNCERTAINTY_DEFER_THRESHOLD", "0.45"))


class EscalationPolicy(str, Enum):
    """Evaluation baselines from research design §6.3."""
    B1_NO_UNCERTAINTY = "b1_no_uncertainty"
    B2_ASR_ONLY = "b2_asr_only"
    B2_CLASSIFIER_ONLY = "b2_classifier_only"
    B2_LLM_ONLY = "b2_llm_only"
    B3_FUSED = "b3_fused"


@dataclass
class UncertaintySignals:
    asr_confidence: float | None = None
    classifier_confidence: float | None = None
    classifier_entropy: float | None = None
    llm_uncertainty: float | None = None
    retrieval_margin: float | None = None

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class TriageDecision:
    action: str  # escalate | routine | defer
    risk_level: str
    fused_confidence: float
    should_defer: bool
    policy: str
    signals: UncertaintySignals
    reason: str


def entropy_from_proba(proba: list[float]) -> float:
    """Normalized entropy in [0, 1] for n-class distribution."""
    n = len(proba)
    if n <= 1:
        return 0.0
    ent = 0.0
    for p in proba:
        if p > 0:
            ent -= p * math.log(p)
    return ent / math.log(n)


def logprob_to_confidence(mean_logprob: float) -> float:
    """Map Whisper segment avg_logprob to [0, 1] confidence proxy."""
    # Typical good speech: -0.2 to -0.8; noisy: below -1.0
    return max(0.0, min(1.0, math.exp(mean_logprob)))


def fuse_confidence(
    signals: UncertaintySignals,
    method: str = "weighted",
) -> float:
    """
    Combine heterogeneous signals into a single confidence score [0, 1].
    Higher = more confident the pipeline output is reliable.
    """
    parts: list[tuple[float, float]] = []

    if signals.asr_confidence is not None:
        parts.append((signals.asr_confidence, 0.25))
    if signals.classifier_confidence is not None:
        parts.append((signals.classifier_confidence, 0.35))
    if signals.llm_uncertainty is not None:
        parts.append((1.0 - signals.llm_uncertainty, 0.25))
    if signals.retrieval_margin is not None:
        parts.append((signals.retrieval_margin, 0.15))

    if not parts:
        return 0.5

    if method == "min":
        return min(w for w, _ in parts)

    total_w = sum(w for _, w in parts)
    return sum(val * w for val, w in parts) / total_w


def should_defer(
    signals: UncertaintySignals,
    fused_confidence: float,
    policy: EscalationPolicy,
    threshold: float = DEFAULT_DEFER_THRESHOLD,
) -> bool:
    if policy == EscalationPolicy.B1_NO_UNCERTAINTY:
        return False

    if policy == EscalationPolicy.B2_ASR_ONLY:
        if signals.asr_confidence is None:
            return False
        return signals.asr_confidence < threshold

    if policy == EscalationPolicy.B2_CLASSIFIER_ONLY:
        if signals.classifier_confidence is None:
            return False
        return signals.classifier_confidence < threshold

    if policy == EscalationPolicy.B2_LLM_ONLY:
        if signals.llm_uncertainty is None:
            return False
        return signals.llm_uncertainty > (1.0 - threshold)

    # B3_FUSED
    if fused_confidence < threshold:
        return True
    if signals.asr_confidence is not None and signals.asr_confidence < 0.35:
        return True
    if signals.classifier_entropy is not None and signals.classifier_entropy > 0.85:
        return True
    return False


def decide_escalation(
    risk_level: str,
    symptom_escalate: bool,
    signals: UncertaintySignals,
    policy: EscalationPolicy = EscalationPolicy.B3_FUSED,
    threshold: float = DEFAULT_DEFER_THRESHOLD,
) -> TriageDecision:
    fused = fuse_confidence(signals)
    defer = should_defer(signals, fused, policy, threshold)

    if defer:
        return TriageDecision(
            action="defer",
            risk_level=risk_level,
            fused_confidence=fused,
            should_defer=True,
            policy=policy.value,
            signals=signals,
            reason="Uncertainty above threshold — defer to supervising nurse for review",
        )

    escalate = risk_level == "high" or symptom_escalate
    action = "escalate" if escalate else "routine"
    reason = (
        "High vitals risk or danger-sign keywords detected"
        if escalate
        else "Low/mid risk with acceptable confidence"
    )

    return TriageDecision(
        action=action,
        risk_level=risk_level,
        fused_confidence=fused,
        should_defer=False,
        policy=policy.value,
        signals=signals,
        reason=reason,
    )


def log_pipeline_event(event: dict) -> None:
    """Append one JSON line for offline selective-prediction analysis."""
    LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    with LOG_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(event, default=str) + "\n")
