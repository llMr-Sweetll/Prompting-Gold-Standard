# Knowledge Base Construction Prompts

Structured prompts to build and maintain living knowledge bases with citations and change logs.

## Entity-Relation Extraction
```
From the context, extract:
- Entities (type, canonical name, aliases)
- Relations (subject, predicate, object, evidence [doc-id:quote])
Return JSON arrays for entities and relations.
```

## Source Graph and Trust Scoring
```
Build a source graph:
- Nodes: sources with metadata (date, venue, author)
- Edges: citation/derivation links
Assign a trust score per node (0–1) with rationale.
```

## Update Planning
```
Given a diff of new documents, propose updates:
- New entities/relations
- Retractions/contradictions
- Sections to rewrite
Return: change plan with priority and estimated effort.
```

## Article Synthesis with Provenance
```
Compose an article:
- Lead: 2–3 sentence summary
- Sections: each with claim -> citations -> quotes
- Provenance appendix: all sources, DOIs/URLs, access dates
Refuse to include uncited claims.
```

