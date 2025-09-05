# PromptOps: Versioning, A/B Tests, and Continuous Improvement

Operational patterns to manage prompts like product artifacts.

## Prompt Spec Template
```
id: short-handle
owner: team/name
intent: what success looks like
inputs: required fields and constraints
outputs: schema and examples
guardrails: refusal conditions; banned content
evaluation: metrics, datasets, thresholds
change-notes: semantic version + rationale
```

## A/B Test Plan
```
Goal: Improve correctness on dataset X by 5%.
Variants:
- A: current baseline prompt
- B: adds explicit evidence mapping
Dataset: 100 labeled cases with gold answers
Metrics: exact-match, citation-coverage, integrity-violations
Decision rule: ship if B ≥ A +5% with p<0.05
```

## Rollout Checklist
```
- [ ] Version bump + changelog
- [ ] Backward compatibility of outputs
- [ ] Guardrail regression tests pass
- [ ] Shadow deploy on 10% traffic
- [ ] Monitoring: error rate, refusals, latency
```

## Prompt Lint (Human-in-the-Loop)
```
Lint these aspects:
- Clarity: explicit roles, inputs, outputs
- Grounding: source and citation requirements
- Determinism: fixed delimiters, schemas, constraints
- Safety: refusal and uncertainty language
- Testability: examples + measurable criteria
Return: pass/fail per item with suggested edit.
```

## Change Minimality Pattern
```
When revising: modify the smallest set of instructions to fix the observed failure. Keep all other text identical. List exactly which line(s) changed and why.
```

## Dataset-Coupled Prompts
```
Tie prompts to evaluation datasets. If the dataset schema changes, fail fast and block deploy until prompts are updated.
```

