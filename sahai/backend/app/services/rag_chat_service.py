"""RAG retrieval + Claude conversational layer."""

import os
from pathlib import Path

import chromadb
from anthropic import Anthropic
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer

load_dotenv()

ROOT = Path(__file__).resolve().parents[3]
CHROMA_PATH = ROOT / "data" / "chroma_store"
COLLECTION_NAME = "who_postnatal"
CLAUDE_MODEL = "claude-sonnet-4-20250514"

_embedder = None
_collection = None
_client = None


def _get_embedder():
    global _embedder
    if _embedder is None:
        _embedder = SentenceTransformer("all-MiniLM-L6-v2")
    return _embedder


def _get_collection():
    global _collection
    if _collection is None:
        if not CHROMA_PATH.exists():
            raise FileNotFoundError(
                f"Chroma store not found at {CHROMA_PATH}. "
                "Run: python -m app.services.ingest_guidelines"
            )
        client = chromadb.PersistentClient(path=str(CHROMA_PATH))
        _collection = client.get_or_create_collection(name=COLLECTION_NAME)
    return _collection


def _get_client():
    global _client
    if _client is None:
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            raise ValueError("ANTHROPIC_API_KEY not set in environment")
        _client = Anthropic(api_key=api_key)
    return _client


def retrieve_context(query: str, top_k: int = 4) -> list[str]:
    embedder = _get_embedder()
    collection = _get_collection()
    query_embedding = embedder.encode([query]).tolist()
    results = collection.query(query_embeddings=query_embedding, n_results=top_k)
    docs = results.get("documents", [[]])
    return docs[0] if docs else []


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
    snippet = chunks[0][:200] if chunks else "No guideline text loaded."
    return (
        f"[Demo mode — set ANTHROPIC_API_KEY for full Claude replies] "
        f"Risk level is {risk_level}. Based on WHO guidelines: {snippet}... "
        "Can you describe any other symptoms such as fever, heavy bleeding, "
        "or difficulty breathing?"
    )
