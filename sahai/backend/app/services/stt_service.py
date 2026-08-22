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
    return {
        "transcript": result.get("text", "").strip(),
        "detected_language": result.get("language", "unknown"),
    }
