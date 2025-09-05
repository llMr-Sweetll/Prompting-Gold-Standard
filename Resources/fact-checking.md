# Fact-Checking and Source Grounding

## Purpose

Ensure AI-assisted content is accurate, verifiable, and grounded in reliable sources.

## Principles

- Verify as you write; do not defer all checks to the end
- Cite where claims appear; include retrieval dates for web sources
- Prefer primary/peer-reviewed sources for high-stakes claims
- Never invent citations; label uncertain claims as Unverified

## Workflow

1) Extract claims (numbers, named entities, quotes, strong assertions)
2) Gather sources: DOI/URL, publication details, and retrieval date
3) Validate: check consistency, scope, and limitations
4) Annotate: add in-text citations and a references section
5) Log: produce a JSON fact-check record (see JSON-Schemas/fact-check-report.json)

## Prompt Templates

Claim extraction:
```
Identify all factual claims requiring citations. Return JSON with {id, claim, category}.
```

Verification assistance:
```
For each claim, propose suitable source types (primary/secondary). Flag claims that likely need peer-reviewed or official sources.
```

Unverified handling:
```
If evidence is insufficient, label the claim Unverified and propose next steps to obtain evidence.
```

## Reference Hygiene

- Keep consistent citation style
- Record retrieval dates for non-DOI sources
- Validate DOIs and URLs before submission
- Remove any unresolved or placeholder citations

