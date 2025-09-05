#!/usr/bin/env python3
"""
content_guard.py

Lightweight, offline heuristics to audit AI-assisted text for:
- citation presence near claims
- potential plagiarism risk indicators (over-quoting, low variability)
- human-like style metrics (very rough)
- disclosure presence

Usage:
  python content_guard.py path/to/file.txt
  echo "text" | python content_guard.py

Outputs a JSON report with recommendations aligned to the repo's integrity focus.
"""

import sys
import json
import re
from collections import Counter


def read_input():
    if not sys.stdin.isatty():
        return sys.stdin.read()
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r', encoding='utf-8', errors='replace') as f:
            return f.read()
    print("Provide text via file path or STDIN", file=sys.stderr)
    sys.exit(1)


def sentence_split(text: str):
    # Simple splitter; not language-aware
    return re.split(r"(?<=[.!?])\s+", text.strip())


def token_count(text: str):
    return len(re.findall(r"\w+", text))


def estimate_readability(sentences):
    # Flesch-like very rough proxy
    words = sum(len(re.findall(r"\w+", s)) for s in sentences) or 1
    sents = max(len(sentences), 1)
    avg_sentence_len = words / sents
    score = max(0, min(100, 100 - (avg_sentence_len - 15) * 5))
    return round(score, 1)


def variability(sentences):
    lengths = [len(re.findall(r"\w+", s)) for s in sentences if s.strip()]
    if not lengths:
        return 0.0
    mean = sum(lengths) / len(lengths)
    var = sum((l - mean) ** 2 for l in lengths) / len(lengths)
    # normalize to 0..1 rough
    return round(min(1.0, var / (mean ** 2 + 1e-6)), 3)


def citation_near_claims(sentences):
    # Detect numbers/named entities heuristically and see if citation-like patterns exist
    citation_patterns = [r"\[(?:S\d+|\d+)\]", r"\(.*\d{4}.*\)", r"doi:\s*10\.\S+", r"https?://\S+"]
    claim_like = []
    for i, s in enumerate(sentences):
        has_number = bool(re.search(r"\d", s))
        has_capitalized_sequence = bool(re.search(r"(?:[A-Z][a-z]+\s){2,}", s))
        if has_number or has_capitalized_sequence:
            claim_like.append((i, s))
    cited = 0
    for _, s in claim_like:
        if any(re.search(p, s) for p in citation_patterns):
            cited += 1
    coverage = round(cited / len(claim_like), 3) if claim_like else 1.0
    return {
        "claim_like_sentences": len(claim_like),
        "with_citation_pattern": cited,
        "coverage_ratio": coverage
    }


def plagiarism_risk_signals(text, sentences):
    quote_ratio = len(re.findall(r"\"[^\"]+\"|'[^']+'", text)) / max(len(sentences), 1)
    repeats = Counter([s.strip().lower() for s in sentences if s.strip()])
    repetition_ratio = max(repeats.values()) / max(len(sentences), 1)
    return {
        "quote_per_sentence": round(quote_ratio, 3),
        "max_sentence_repetition_ratio": round(repetition_ratio, 3)
    }


def disclosure_present(text):
    patterns = [r"AI (?:assistant|tool)", r"assisted", r"disclosure", r"generated with"]
    return any(re.search(p, text, re.IGNORECASE) for p in patterns)


def main():
    text = read_input()
    sentences = sentence_split(text)

    report = {
        "stats": {
            "sentences": len(sentences),
            "tokens": token_count(text)
        },
        "style_audit": {
            "readability": estimate_readability(sentences),
            "sentence_variability": variability(sentences)
        },
        "citation_audit": citation_near_claims(sentences),
        "plagiarism_risk_signals": plagiarism_risk_signals(text, sentences),
        "ai_use_disclosure_present": disclosure_present(text),
        "recommendations": []
    }

    if report["citation_audit"]["coverage_ratio"] < 0.6:
        report["recommendations"].append(
            "Add in-text citations next to claims and include a references section."
        )
    if not report["ai_use_disclosure_present"]:
        report["recommendations"].append(
            "Add a one-line AI-use disclosure if required by your context."
        )
    if report["style_audit"]["readability"] < 45:
        report["recommendations"].append(
            "Improve clarity: shorten sentences and reduce jargon."
        )

    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

