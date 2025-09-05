# Quickstarts: End-to-End Workflows

This folder contains copy-pasteable quickstarts that chain retrieval-augmented generation (RAG), rubric-based evaluation, and document/asset generation. Each guide includes both Bash and PowerShell variants and covers multiple providers (OpenAI/Azure, Anthropic, and local Ollama) where applicable. Each quickstart includes end-to-end one-block scripts and per-step commands.

## Prerequisites
- Environment variables:
  - OpenAI: `OPENAI_API_KEY` (and optionally `OPENAI_MODEL`, default `gpt-4o-mini`)
  - Azure OpenAI: `AZURE_OPENAI_KEY`, `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_DEPLOYMENT`, `AZURE_OPENAI_API_VERSION`
  - Anthropic: `ANTHROPIC_API_KEY`
  - Ollama (local): `OLLAMA_MODEL` (default `llama3.1`)
- Tools:
  - Bash: `curl`, `jq`
  - PowerShell: `Invoke-RestMethod`, `ConvertTo-Json`
  - Optional: `python3` with `pip install jsonschema` (for schema validation)
  - Optional: `node` with `npx ajv` (schema validation alternative)
- Optional local LLM: [Ollama](https://ollama.com) running at `http://localhost:11434`.

## Quick Env Setup Snippets
- Bash (OpenAI): `export OPENAI_API_KEY=sk-...; export OPENAI_MODEL=gpt-4o-mini`
- PowerShell (OpenAI): `$env:OPENAI_API_KEY='sk-...'; $env:OPENAI_MODEL='gpt-4o-mini'`
- Azure (Bash): `export AZURE_OPENAI_KEY=...; export AZURE_OPENAI_ENDPOINT=...; export AZURE_OPENAI_DEPLOYMENT=...; export AZURE_OPENAI_API_VERSION=2024-02-01`
- Anthropic (Bash): `export ANTHROPIC_API_KEY=...`

## Uses These Guides & Schemas
- Guides: `Guides/retrieval-augmented-generation.md`, `Guides/self-critique-and-evaluation.md`, `Guides/prompt-ops-and-versioning.md`.
- Applications: `Applications/technical-documentation.md`, `Applications/data-analysis-and-visualization.md`.
- JSON Schemas: `JSON-Schemas/prompt-eval-rubric.json`, `JSON-Schemas/data-analysis-report.json`.

## Quickstart Index

### Original Workflows
- `rag-rubric-docs.md`: RAG answer → rubric evaluation → research brief.
- `academic-paper-rag-latex-zotero.md`: RAG → Overleaf-safe LaTeX → Zotero TODO.
- `data-analysis-report-and-charts.md`: Analysis plan → results JSON → Vega-Lite charts.
- `kb-graph-update.md`: Entities/relations graph → trust scores → update plan.
- `ci-eval-github-actions.md`: Wire evaluation into CI with JSON artifacts.
- `local-ollama.md`: Run the RAG → Eval → Doc flow locally with Ollama.

### Phase 1 Expansion: Industry-Specific Workflows
- `scientific-research-pipeline.md`: Hypothesis → Experiment Design → Data Analysis → Publication
- `business-intelligence-suite.md`: Market Analysis → Competitive Intelligence → Strategy Reports
- `software-development-chain.md`: Requirements → Architecture → Implementation → Testing

### Coming Soon (Phase 2)
- Content Creation Workflow: Research → Outline → Draft → SEO Optimization
- Legal Document Automation: Contract Analysis → Risk Assessment → Compliance Review
- Healthcare R&D Pipeline: Drug Discovery → Clinical Trial Design → Regulatory Strategy
- Financial Services Suite: Risk Assessment → Fraud Detection → Investment Research

Tip: Each guide writes outputs to files in the current directory for easy inspection and versioning. Prefer the “one-block” sections to run the entire flow in a single paste.
