# Self-Critique, Rubrics, and Automated Evaluation

Prompts for reflective improvement, rubric-driven scoring, and error analysis to boost accuracy and integrity.

## System: Critical, Evidence-First Reasoning
```
Act as a careful reviewer. Prefer precise, falsifiable statements. Separate facts from interpretations. Always propose tests to validate claims.
```

## Two-Pass Draft + Review
```
Pass 1 — Draft:
- Produce the best answer succinctly.

Pass 2 — Review:
- Identify unsupported claims, ambiguous language, logical gaps, and style issues.
- Propose corrections and cite sources or mark as Unverified.

Return: revised answer + list of corrections.
```

## Rubric-Oriented Generation
```
Rubric (1–5 each):
- Accuracy: evidence-backed; no speculation
- Completeness: covers required aspects
- Clarity: concise, structured, readable
- Integrity: citations, disclosures, originality
- Actionability: concrete steps or outputs

Task: Generate content optimized to score ≥4 on all criteria. Include a brief self-score with justifications.
```

## Adversarial Self-Red Teaming
```
1) Produce answer A.
2) As an adversary, try to break A: find contradictions, missing evidence, alternative interpretations.
3) Revise to answer B with fixes and citations.
Return: A, critique, B.
```

## Error Taxonomy + Remediation
```
Analyze this output and classify any issues:
- Hallucination (unsupported fact)
- Overreach (beyond scope)
- Ambiguity (unclear wording)
- Leakage (format/spec violations)
- Bias/tone issues
For each: propose a minimal edit to remediate.
```

## Evaluation as JSON (for CI integration)
```
Return JSON:
{
  "score": number,
  "criteria": {
    "accuracy": {"score": number, "notes": string},
    "completeness": {"score": number, "notes": string},
    "clarity": {"score": number, "notes": string},
    "integrity": {"score": number, "notes": string},
    "actionability": {"score": number, "notes": string}
  },
  "issues": [
    {"type": "Hallucination|Overreach|Ambiguity|Leakage|Bias", "span": string, "fix": string}
  ]
}
```

## Fact-First Rewrite
```
Rewrite the text to:
- Keep only claims with explicit citations (APA/IEEE)
- Mark uncited claims as [Unverified]
- Remove rhetorical filler
- Compress to ≤25% length while preserving key evidence
```

## Confidence Calibration
```
For each claim, assign a confidence level with rationale:
- High: directly supported by multiple sources
- Medium: supported by one source or indirect logic
- Low: weak or conflicting evidence
Return a table claim -> confidence -> sources.
```

