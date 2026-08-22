"""Shared WHO guideline text extraction and chunking."""

from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[3]
PDF_PATH = ROOT / "data" / "who_postnatal_2022.pdf"
TEXT_FALLBACK = ROOT / "data" / "who_postnatal_guidelines.txt"
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
    chunks: list[str] = []
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
