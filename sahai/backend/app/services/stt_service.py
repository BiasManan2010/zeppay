"""Speech-to-text via OpenAI Whisper (local)."""

import os

import whisper

_model = None


def _model_name() -> str:
    return os.getenv("WHISPER_MODEL", "base")


def _load_model():
    global _model
    if _model is None:
        _model = whisper.load_model(_model_name())
    return _model


def transcribe_audio(file_path: str) -> dict:
    model = _load_model()
    result = model.transcribe(file_path)
    transcript = result.get("text", "").strip()
    segments = result.get("segments", []) or []

    mean_logprob = None
    asr_confidence = None
    if segments:
        logprobs = [s.get("avg_logprob", -1.0) for s in segments if "avg_logprob" in s]
        if logprobs:
            mean_logprob = sum(logprobs) / len(logprobs)
            from app.services.uncertainty_fusion import logprob_to_confidence

            asr_confidence = logprob_to_confidence(mean_logprob)

    return {
        "transcript": transcript,
        "detected_language": result.get("language", "unknown"),
        "asr_confidence": asr_confidence,
        "mean_logprob": mean_logprob,
        "segment_count": len(segments),
    }
