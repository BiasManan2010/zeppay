"""One-time WHO guideline ingestion into FAISS (default) or Chroma vector store."""

from sentence_transformers import SentenceTransformer

from app.services.guideline_text import chunk_text, extract_text
from app.services.vector_store import _backend, FAISS_DIR, CHROMA_PATH, ingest


def main() -> None:
    text = extract_text()
    chunks = chunk_text(text)
    print(f"Created {len(chunks)} chunks from guideline text")

    model = SentenceTransformer("all-MiniLM-L6-v2")
    embeddings = model.encode(chunks, show_progress_bar=True)

    ingest(chunks, embeddings)
    backend = _backend()
    if backend == "chroma":
        print(f"Stored {len(chunks)} chunks in {CHROMA_PATH}")
    else:
        print(f"Stored {len(chunks)} chunks in {FAISS_DIR}")


if __name__ == "__main__":
    main()
