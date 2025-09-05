# Prompt Templates: Integrity, Accuracy, and Attribution

## Grounded Answer with Citations

```
Task: Answer the question using cited evidence.
Question: [insert]

Instructions:
- Provide concise, accurate answers with in-text citations
- Add a reference list with DOIs/URLs and retrieval dates
- If a claim cannot be verified, label it Unverified and suggest how to verify
```

## Fact-Check Log (JSON)

```
For the draft below, produce a fact-check report using JSON-Schemas/fact-check-report.json. Include status and sources for every claim.
Draft:
[paste]
```

## Plagiarism-Free Transformation

```
Transform this AI draft by:
- Reframing with a new outline and thesis
- Adding original analysis and domain-specific examples
- Citing sources and removing unsupported claims
Return: revised draft + list of added sources
```

## Refusal/Deferral on Insufficient Evidence

```
If evidence quality is inadequate, do not speculate. Explain what is unknown, what sources are needed, and provide next steps.
```

## Disclosure Snippet

```
Add a one-line disclosure of AI assistance suitable for academic or professional contexts.
```

