# SahAI Research Blueprint

**From hackathon prototype to publishable research** — based on the senior mentor review for Cosmicathon 2026.

## Bottom-line verdict

The SahAI **engineering stack** (Whisper + XGBoost + RAG + Twilio) is a solid hackathon build but **not a standalone research contribution**. The defensible research opportunity is **Direction 1**:

> **Noise-aware, calibrated escalation for voice-first postnatal triage** — measuring how ASR error propagates through vitals classification and LLM reasoning into wrong escalation decisions, and whether a **fused uncertainty signal** can defer to a human nurse instead of guessing.

This repo now includes a **research layer** on top of the engineering pipeline to run that study.

---

## What is engineering vs. research?

| Component | Classification |
|-----------|----------------|
| Whisper STT | Engineering — unless you study how it fails under noise |
| XGBoost on UCI vitals | Saturated benchmark (~85–90% accuracy, dozens of papers) |
| RAG over WHO text | Engineering — unless you measure faithfulness/hallucination |
| Rule-based SMS escalation | Product feature |
| **ASR → extraction → classifier → escalation error chain** | **Research** |
| **Multi-source uncertainty fusion + deferral policy** | **Research** |

---

## Selected direction (Direction 1)

### Research question

In a voice-first, LLM-mediated postnatal danger-sign triage pipeline, how does ASR error propagate into escalation-decision errors, and can a calibrated multi-source uncertainty signal (ASR confidence ⊕ classifier probability ⊕ LLM semantic uncertainty) reliably identify cases to defer?

### Hypotheses

- **H1:** Escalation error rate increases with ASR word error rate (non-linear around symptom-keyword substitutions).
- **H2:** Fused uncertainty beats any single-source threshold on selective-prediction (accuracy at fixed deferral rate).
- **H3:** There exists an operating point where deferral cuts false alarms without missing emergencies.

### Novel contribution (if experiments support it)

1. First systematic error-propagation study through this **three-stage pipeline** for maternal danger-sign triage.
2. Fusion/calibration across **heterogeneous** signals (acoustic, tabular, retrieval/LLM).
3. Evaluation as **deferral rate vs. missed-emergency vs. false-alarm** — not plain accuracy.

---

## What we implemented in code

| Module | Purpose |
|--------|---------|
| `app/services/uncertainty_fusion.py` | Fuse ASR + classifier + LLM signals; B1–B3 policies |
| `app/services/symptom_extraction.py` | Danger-sign keyword flags from transcript |
| `app/services/llm_uncertainty.py` | Retrieval-margin + ambiguity uncertainty proxy |
| `app/services/triage_service.py` | Full assess pipeline + JSONL logging |
| `POST /api/triage/assess` | End-to-end triage with uncertainty metadata |
| `data/research/scripted_scenarios.json` | Starter gold-label scripts |
| `app/research/evaluate_selective_prediction.py` | Baseline comparison script |

### API: `POST /api/triage/assess`

Combines vitals + optional transcript + ASR confidence. Returns:

```json
{
  "triage_action": "escalate | routine | defer",
  "should_defer": false,
  "fused_confidence": 0.72,
  "uncertainty": {
    "asr_confidence": 0.85,
    "classifier_confidence": 0.91,
    "classifier_entropy": 0.12,
    "llm_uncertainty": 0.35,
    "retrieval_margin": 0.48
  },
  "policy": "b3_fused"
}
```

### Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `ESCALATION_POLICY` | `b3_fused` | `b1_no_uncertainty`, `b2_asr_only`, `b2_classifier_only`, `b2_llm_only`, `b3_fused` |
| `UNCERTAINTY_DEFER_THRESHOLD` | `0.45` | Fused-confidence deferral threshold (tune on dev split) |

### Run evaluation (scripted scenarios)

```bash
cd sahai/backend
export PYTHONPATH=$(pwd)
python -m app.research.evaluate_selective_prediction
python -m app.research.evaluate_selective_prediction --policies b1_no_uncertainty b3_fused
```

Pipeline logs append to `data/research/pipeline_logs.jsonl` for offline analysis.

---

## Experiment sequence (from mentor review §6.6)

| # | Experiment | Status in repo |
|---|------------|----------------|
| 1 | Train/validate UCI classifier | Done (`train_classifier.py`, `risk_model.pkl`) |
| 2 | Record narrations under 3 noise conditions | **You** — use `scripted_scenarios.json` as template |
| 3 | Run full pipeline; log all confidence signals | Done (`/api/triage/assess`, JSONL logs) |
| 4 | Fit fusion/calibration on dev split | **Next** — tune `UNCERTAINTY_DEFER_THRESHOLD` |
| 5 | Compare B0–B3 on risk-coverage curves | Starter script provided |
| 6 | Ablations (remove each signal) | Supported via policy flags |

---

## Data requirements (honest limitations)

- **UCI dataset** is pregnancy-stage vitals, not purpose-built postnatal — state this explicitly in any paper.
- **Scripted audio** ≠ real ASHA field speech — label as limitation; add 5–10 real recordings if possible.
- **Gold labels** should be reviewed by someone with clinical/nursing input before you evaluate.

---

## Suggested venues (once results exist)

- ML4H (calibration + selective prediction)
- ACM COMPASS / CHI4Good / HCI4D tracks (ASHA, India, low-resource)
- Student symposium / Cosmicathon research track (first feedback)

---

## Literature map (starting points — verify before citing)

- ASHABot (CHI 2025) — LLM for ASHA informational needs, not per-patient triage
- Rwanda CHW “Silent Trial” (medRxiv 2026) — LLM referral accuracy, no ASR propagation study
- ASR robustness audits on Indian clinical speech (2025) — WER only, no decision flip
- LLM abstention literature (TACL 2025 survey, AAAI 2025 guided deferral) — mostly English text QA

Run a **2–3 day deep search** before claiming “first study of X” in related work.

---

## Paper framing (critical)

**Do not claim:** “We built an AI triage assistant.”

**Do claim:** “We measured and mitigated a specific failure mode — silent wrong escalation under noisy voice input — in a voice-first postnatal triage pipeline, with ablations and selective-prediction curves.”

The **risk-coverage curve** where fused B3 beats every single-source baseline is the central result. Without it, reviewers will classify this as “glue code.”

---

## Next steps for you

1. Expand `scripted_scenarios.json` to 100–200 cases with independent gold labels.
2. Record audio under clean / moderate / high noise; pair with Whisper transcripts.
3. Tune deferral threshold; plot risk-coverage and calibration (reliability diagrams).
4. Run full ablation table (§6.5 of mentor review).
5. Include 3–5 qualitative failure-case transcripts in the paper.

See also: [SETUP_RUNBOOK.md](./SETUP_RUNBOOK.md) for environment setup.
