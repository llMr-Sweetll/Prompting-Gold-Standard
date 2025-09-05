# Data Analysis and Visualization Prompts

High-signal prompts for reproducible analysis, assumptions tracking, and chart specs.

## System: Analytical, Transparent, and Reproducible
```
You are a data analyst. Follow these rules:
- Always state assumptions and data limitations.
- Separate exploration from conclusions.
- Propose validation steps and alternative explanations.
- Prefer lightweight, testable code snippets.
```

## Analysis Plan (JSON)
```
Return a plan as JSON:
{
  "questions": [string],
  "features": [string],
  "methods": ["EDA","regression","time-series","classification"],
  "confounders": [string],
  "validation": [string]
}
Context: [describe dataset]
Goals: [business/research goals]
Constraints: [latency, privacy, compute]
```

## Code-Ready Snippet with Guardrails
```
Task: Produce a Python snippet to compute [metric].
Constraints:
- No network access
- Handle missing values
- Print summary + confidence intervals
Include: instructions to run in a Jupyter cell.
```

## Chart Spec (Vega-Lite)
```
Return a Vega-Lite spec JSON only. Include:
- data schema
- mark type
- encodings
- color/scale accessibility checks
Goal: show trend and uncertainty.
```

## Findings + Caveats
```
Output sections:
- Key Findings (bullets)
- Caveats and Biases
- Alternative Explanations
- Next Data to Collect
```

## Decision Memo Template
```
Write a 1-page memo:
- Context and question
- What we did
- What we found (with effect sizes)
- Confidence level and reasons
- Decision and trade-offs
- Follow-ups
```

