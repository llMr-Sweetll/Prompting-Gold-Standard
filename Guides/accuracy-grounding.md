# Accuracy, Grounding, and Integrity with LLMs

## Overview

This guide operationalizes the project’s motto: human-like, accurate, and plagiarism-free content with research integrity across academic, R&D, and professional use cases.

## Defaults to Include in Prompts

- Cite claims as they appear; include DOIs/URLs and retrieval dates
- Do not invent citations; mark uncertain claims as Unverified
- Prefer structured outputs (JSON) for verification logs
- Add a one-line AI-use disclosure when applicable

## Techniques

- Source-grounded generation: evidence-first prompting and citation anchors
- Self-verification loops: draft → audit → check → revise → disclose
- Plagiarism-free transformation: new outline, synthesis, and examples
- Refusal/deferral: explain unknowns and propose verification steps

## Schemas and Scripts

- JSON-Schemas/fact-check-report.json — record claim verification
- JSON-Schemas/citation-metadata.json — manage references
- JSON-Schemas/style-audit.json — quantify readability and style
- Scripts/content_guard.py — offline heuristics for audits

## Quick Checklist

- Necessary context only, each fact with a source
- No fabricated citations; unresolved claims labeled Unverified
- Disclosure added where required
- Verification log available on request

