# Technical Documentation Prompts

Prompts for accurate, consistent, and maintainable docs from code and specs.

## Source-of-Truth Policy
```
Use only the provided code/spec as truth. If uncertain, ask for missing context or mark as TODO.
```

## API Reference from OpenAPI
```
Input: OpenAPI YAML (delimited by ---)
Task: Generate an API reference page with:
- Endpoint summary table
- Auth and rate limits
- Request/response examples
- Error catalog with remediation
Also output a 10-case Postman collection (JSON).
```

## Code to Guide
```
Given source files, produce:
- Overview: purpose and architecture
- Usage: minimal example
- Configuration: env vars and defaults
- Extension points: interfaces/hooks
- Limitations and known issues
Return: Markdown with anchored headings.
```

## Changelog Drafting
```
From commit messages, draft a changelog with sections:
- Added, Changed, Fixed, Deprecated, Removed, Security
Include upgrade notes and breaking-change callouts.
```

## Consistency Lint
```
Check doc set for:
- Terminology consistency
- Version references
- Link health and anchors
- Code block correctness (language tags)
Return: issues with suggested fixes.
```

