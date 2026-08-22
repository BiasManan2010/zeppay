"""RAG retrieval + Claude conversational layer."""

import os

from anthropic import Anthropic
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer

from app.services.guideline_text import extract_text
from app.services.vector_store import retrieve

load_dotenv()

CLAUDE_MODEL = "claude-sonnet-4-20250514"

_embedder = None
_client = None
_static_fallback: str | None = None


def _get_embedder():
    global _embedder
    if _embedder is None:
        _embedder = SentenceTransformer("all-MiniLM-L6-v2")
    return _embedder


def _get_client():
    global _client
    if _client is None:
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            raise ValueError("ANTHROPIC_API_KEY not set in environment")
        _client = Anthropic(api_key=api_key)
    return _client


def _static_guideline_snippet() -> str:
    global _static_fallback
    if _static_fallback is None:
        try:
            _static_fallback = extract_text()[:500]
        except FileNotFoundError:
            _static_fallback = "No guideline text loaded."
    return _static_fallback


def retrieve_context(query: str, top_k: int = 4) -> list[str]:
    try:
        embedder = _get_embedder()
        query_embedding = embedder.encode([query])
        return retrieve(query_embedding, top_k=top_k)
    except FileNotFoundError:
        return [_static_guideline_snippet()]


def get_llm_response(
    user_message: str,
    risk_level: str,
    session_history: list[dict],
) -> str:
    chunks = retrieve_context(user_message)
    context_block = "\n---\n".join(chunks) if chunks else "No guideline excerpts retrieved."

    system_prompt = (
        "You are a clinical assistant helping a community health worker "
        "interpret postnatal danger signs in India. "
        "Only use the WHO guideline excerpts provided below as your medical "
        "grounding. If the excerpts do not cover the situation, say so honestly "
        "instead of guessing. Ask one clarifying follow-up question if symptoms "
        "are ambiguous; otherwise explain the risk_level flag in simple, "
        "non-technical language suitable for a frontline worker. "
        "Keep replies under 120 words.\n\n"
        f"Current risk_level from vitals classifier: {risk_level}\n\n"
        f"WHO guideline excerpts:\n{context_block}"
    )

    messages = []
    for entry in session_history:
        role = entry.get("role", "user")
        if role in ("user", "assistant"):
            messages.append({"role": role, "content": entry.get("content", "")})
    messages.append({"role": "user", "content": user_message})

    client = _get_client()
    response = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=512,
        system=system_prompt,
        messages=messages,
    )
    return response.content[0].text


def get_demo_response(user_message: str, risk_level: str) -> str:
    """Fallback when ANTHROPIC_API_KEY is not configured."""
    chunks = retrieve_context(user_message, top_k=2)
    snippet = chunks[0][:200] if chunks else _static_guideline_snippet()[:200]
    return (
        f"[Demo mode — set ANTHROPIC_API_KEY for full Claude replies] "
        f"Risk level is {risk_level}. Based on WHO guidelines: {snippet}... "
        "Can you describe any other symptoms such as fever, heavy bleeding, "
        "or difficulty breathing?"
    )
