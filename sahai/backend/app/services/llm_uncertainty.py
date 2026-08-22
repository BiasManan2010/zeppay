"""LLM / retrieval uncertainty proxies for fusion layer."""

from app.services.rag_chat_service import retrieve_context
from app.services.symptom_extraction import extract_danger_flags
from sentence_transformers import SentenceTransformer

_embedder = None


def _embedder_model():
    global _embedder
    if _embedder is None:
        _embedder = SentenceTransformer("all-MiniLM-L6-v2")
    return _embedder


def retrieval_margin(query: str, top_k: int = 4) -> float:
    """
    Confidence proxy: similarity gap between top-1 and top-k retrieved chunks.
    Low margin → retrieval is uncertain → higher downstream risk.
    """
    try:
        model = _embedder_model()
        chunks = retrieve_context(query, top_k=top_k)
        if len(chunks) < 2:
            return 0.5
        embeddings = model.encode(chunks)
        query_emb = model.encode([query])[0]
        # Cosine similarity manually
        import numpy as np

        def cos(a, b):
            return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-9))

        sims = [cos(query_emb, e) for e in embeddings]
        margin = max(sims) - (sum(sims) / len(sims))
        return max(0.0, min(1.0, margin * 3.0))
    except Exception:
        return 0.5


def estimate_llm_uncertainty(message: str, risk_level: str) -> float:
    """
    Semantic uncertainty proxy without mandatory multi-sample API calls.
    Combines transcript ambiguity + retrieval margin + risk ambiguity.
    Returns uncertainty in [0, 1] — higher = less reliable.
    """
    flags = extract_danger_flags(message)
    margin = retrieval_margin(message)
    retrieval_uncertainty = 1.0 - margin

    risk_ambiguity = 0.3 if risk_level == "mid" else 0.1

    uncertainty = (
        0.4 * flags["ambiguity_score"]
        + 0.35 * retrieval_uncertainty
        + 0.25 * risk_ambiguity
    )
    return max(0.0, min(1.0, uncertainty))
