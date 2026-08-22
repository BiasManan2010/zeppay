"""One-time WHO guideline ingestion into Chroma vector store."""

from pathlib import Path

import chromadb
from pypdf import PdfReader
from sentence_transformers import SentenceTransformer

ROOT = Path(__file__).resolve().parents[3]
PDF_PATH = ROOT / "data" / "who_postnatal_2022.pdf"
TEXT_FALLBACK = ROOT / "data" / "who_postnatal_guidelines.txt"
CHROMA_PATH = ROOT / "data" / "chroma_store"
COLLECTION_NAME = "who_postnatal"
CHUNK_WORDS = 400
OVERLAP_WORDS = 50


def extract_text() -> str:
    if PDF_PATH.exists():
        reader = PdfReader(str(PDF_PATH))
        pages = [page.extract_text() or "" for page in reader.pages]
        return "\n".join(pages)
    if TEXT_FALLBACK.exists():
        return TEXT_FALLBACK.read_text(encoding="utf-8")
    raise FileNotFoundError(
        f"Place WHO PDF at {PDF_PATH} or text at {TEXT_FALLBACK}"
    )


def chunk_text(text: str) -> list[str]:
    words = text.split()
    chunks = []
    start = 0
    while start < len(words):
        end = min(start + CHUNK_WORDS, len(words))
        chunk = " ".join(words[start:end]).strip()
        if chunk:
            chunks.append(chunk)
        if end >= len(words):
            break
        start = end - OVERLAP_WORDS
    return chunks


def main() -> None:
    text = extract_text()
    chunks = chunk_text(text)
    print(f"Created {len(chunks)} chunks from guideline text")

    model = SentenceTransformer("all-MiniLM-L6-v2")
    embeddings = model.encode(chunks, show_progress_bar=True)

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
    print(f"Stored {len(chunks)} chunks in {CHROMA_PATH}")


if __name__ == "__main__":
    main()
