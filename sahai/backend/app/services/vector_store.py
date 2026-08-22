"""Vector store for RAG — FAISS default (Windows-friendly); Chroma optional."""

import json
import os
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[3]
FAISS_DIR = ROOT / "data" / "faiss_store"
CHROMA_PATH = ROOT / "data" / "chroma_store"
COLLECTION_NAME = "who_postnatal"


def _backend() -> str:
    return os.getenv("VECTOR_BACKEND", "faiss").lower()


def ingest(chunks: list[str], embeddings: np.ndarray) -> None:
    if _backend() == "chroma":
        _ingest_chroma(chunks, embeddings)
    else:
        _ingest_faiss(chunks, embeddings)


def retrieve(query_embedding: np.ndarray, top_k: int = 4) -> list[str]:
    if _backend() == "chroma":
        return _retrieve_chroma(query_embedding, top_k)
    return _retrieve_faiss(query_embedding, top_k)


def _ingest_faiss(chunks: list[str], embeddings: np.ndarray) -> None:
    import faiss

    FAISS_DIR.mkdir(parents=True, exist_ok=True)
    vectors = embeddings.astype(np.float32)
    faiss.normalize_L2(vectors)
    index = faiss.IndexFlatIP(vectors.shape[1])
    index.add(vectors)
    faiss.write_index(index, str(FAISS_DIR / "index.faiss"))
    (FAISS_DIR / "chunks.json").write_text(json.dumps(chunks), encoding="utf-8")


def _retrieve_faiss(query_embedding: np.ndarray, top_k: int) -> list[str]:
    import faiss

    index_path = FAISS_DIR / "index.faiss"
    chunks_path = FAISS_DIR / "chunks.json"
    if not index_path.exists():
        raise FileNotFoundError(
            f"FAISS index not found at {FAISS_DIR}. "
            "Run: python -m app.services.ingest_guidelines"
        )
    index = faiss.read_index(str(index_path))
    chunks = json.loads(chunks_path.read_text(encoding="utf-8"))
    query = query_embedding.astype(np.float32)
    faiss.normalize_L2(query)
    _, indices = index.search(query, min(top_k, len(chunks)))
    return [chunks[i] for i in indices[0] if i >= 0]


def _ingest_chroma(chunks: list[str], embeddings: np.ndarray) -> None:
    import chromadb

    CHROMA_PATH.mkdir(parents=True, exist_ok=True)
    client = chromadb.PersistentClient(path=str(CHROMA_PATH))
    try:
        client.delete_collection(COLLECTION_NAME)
    except Exception:
        pass
    collection = client.create_collection(
        name=COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"},
    )
    collection.add(
        ids=[f"chunk_{i}" for i in range(len(chunks))],
        documents=chunks,
        embeddings=embeddings.tolist(),
    )


def _retrieve_chroma(query_embedding: np.ndarray, top_k: int) -> list[str]:
    import chromadb

    if not CHROMA_PATH.exists():
        raise FileNotFoundError(
            f"Chroma store not found at {CHROMA_PATH}. "
            "Set VECTOR_BACKEND=chroma and run ingest_guidelines"
        )
    client = chromadb.PersistentClient(path=str(CHROMA_PATH))
    collection = client.get_or_create_collection(name=COLLECTION_NAME)
    results = collection.query(
        query_embeddings=[query_embedding.tolist()],
        n_results=top_k,
    )
    docs = results.get("documents", [[]])
    return docs[0] if docs else []
