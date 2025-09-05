# Jupyter Notebook Workflows

Prompts for reproducible academic analyses with checkpoints and exportable artifacts.

## Notebook Skeleton
```
Generate a notebook plan with cells:
1) Environment + seed
2) Data load + schema print
3) EDA visuals (accessible)
4) Method implementation
5) Results + tables
6) Limitations + next steps
Return: JSON with cell titles and brief contents.
```

## Result Reproduction Checklist
```
- Deterministic seeds
- Dependency versions pinned
- Data provenance recorded
- Figures saved with captions and alt text
- Metrics computed with CI-friendly printing
```

## Paper Figure Export
```
Task: Provide Matplotlib code to export a 2x2 figure grid in \textwidth with vector graphics and readable fonts. Include caption suggestions.
```

