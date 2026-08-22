"""Danger-sign keyword flags from transcript (research symptom layer)."""

import re

# Colloquial + clinical phrases — extend via Direction 3 ontology work
DANGER_PATTERNS = [
    r"\bbleed",
    r"\bheavy bleeding",
    r"\bfever",
    r"\bhigh fever",
    r"\bheadache",
    r"\bblurred vision",
    r"\bbreath",
    r"\bshortness of breath",
    r"\bchills",
    r"\bfoul",
    r"\bsmell",
    r"\bdischarge",
    r"\bseizure",
    r"\bconvuls",
    r"\bdizzy",
    r"\bfaint",
    r"\bchest pain",
    r"\bred breast",
    r"\bwound",
    r"\binfection",
    # Hindi / Punjabi transliterations (starter set)
    r"\bkhoon",
    r"\bbukhar",
    r"\bsirdard",
    r"\bchakkar",
]

_COMPILED = [re.compile(p, re.IGNORECASE) for p in DANGER_PATTERNS]


def extract_danger_flags(transcript: str) -> dict:
    text = (transcript or "").strip()
    if not text:
        return {
            "danger_keyword_count": 0,
            "matched_keywords": [],
            "symptom_escalate": False,
            "ambiguity_score": 1.0,
        }

    matched = []
    for pattern in _COMPILED:
        if pattern.search(text):
            matched.append(pattern.pattern.replace("\\b", ""))

    count = len(matched)
    # Short, vague narrations → higher ambiguity for uncertainty fusion
    word_count = len(text.split())
    ambiguity = 1.0 if word_count < 4 else max(0.0, 1.0 - min(count, 3) / 3.0)

    return {
        "danger_keyword_count": count,
        "matched_keywords": matched[:8],
        "symptom_escalate": count >= 2 or any(
            k in text.lower() for k in ("bleed", "seizure", "breath", "khoon")
        ),
        "ambiguity_score": ambiguity,
    }
