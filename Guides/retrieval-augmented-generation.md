# Retrieval-Augmented Generation (RAG) Prompt Patterns

Practical, copy-pasteable prompts for grounded generation with citations, deduped evidence, and explicit uncertainty handling.

## System: Grounded, Verifiable Answers
```
You are a rigorous research assistant.
Rules:
- Use ONLY the provided context to answer.
- Cite evidence inline with [#doc-id] and page/section when available.
- If context is insufficient, say "Insufficient evidence" and list what’s missing.
- Do not guess. No external knowledge unless explicitly allowed.
- Prefer precise quotes and summarize faithfully.
Output format:
- Answer (2–5 sentences max)
- Evidence list: bullet points with [#doc-id] and quoted spans
- Open questions or missing info, if any
```

## User: Provide Context + Query
```
Context (delimited by ---):
---
[#A] Title: Remote Work Outcomes (2021)
Excerpt: "...productivity improved for task-focused roles but decreased for collaboration-heavy teams..."
---
[#B] Meta-analysis (2023)
Excerpt: "...effect sizes vary by industry and role autonomy..."
---

Query: Summarize productivity impacts of remote work across roles and note uncertainties.
```

## Structured Grounding With JSON
```
Return a JSON object:
{
  "answer": string,
  "claims": [
    {"text": string, "evidence": ["#A:quote", "#B:quote"], "confidence": "low|medium|high"}
  ],
  "gaps": [string]
}
Use only provided context.
```

## Deduplicate and Normalize Evidence
```
Task: Merge overlapping evidence across documents.
Steps:
1) Cluster quotes by semantic similarity
2) Choose the most representative citation
3) Note contradictions explicitly
Return: clusters with representative quote and doc-id
```

## Multi-Hop RAG Synthesis
```
Goal: Derive answer requiring multiple documents.
Process:
- Hop 1: Extract key facts per doc with quotes
- Hop 2: Identify intersections and contradictions
- Hop 3: Synthesize conservative conclusion with caveats
Return: conclusion + table of support/contradiction per doc-id
```

## Audit Trail Prompt
```
Produce an audit trail:
- Decision log: numbered steps
- Evidence mapping: claim -> [doc-id:quote]
- Non-use log: which retrieved docs were not used and why
```

## Hallucination Guard
```
Before final answer, verify:
- [ ] Every claim maps to evidence
- [ ] No external facts introduced
- [ ] Uncertainties labeled
If any check fails, return "Insufficient evidence" with required sources.
```

## Allowlisted External Knowledge Mode (Optional)
```
External knowledge allowed: domain fundamentals only (list below).
Disallowed: statistics, dates, named entities beyond context.
When in doubt, prefer "Unknown".
```

