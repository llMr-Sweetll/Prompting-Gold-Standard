# Zotero Citation Workflows

Prompts to streamline literature collection, tagging, and citation integrity.

## Deduplicated Import Plan
```
Given a list of DOIs/titles, plan the import:
- Identify duplicates by DOI/title similarity
- Assign collections and tags
- Flag missing metadata (DOI, pages, issue)
Return JSON plan: add/update/skip with reasons.
```

## Citation Integrity Check
```
Input: manuscript text + Zotero collection export (JSON)
Task: Ensure every in-text citation resolves to a library entry.
Output: missing, mismatched (year/author), unused references. Propose fixes.
```

## Reading Queue Prioritization
```
From abstracts and venues, prioritize reading:
- Impact (venue rank), recency, relevance
- Diversity of methods and viewpoints
Return: top N with rationales and expected contribution to manuscript sections.
```

