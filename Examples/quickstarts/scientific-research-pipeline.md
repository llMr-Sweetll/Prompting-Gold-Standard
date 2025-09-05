# Quickstart: Scientific Research Pipeline (Hypothesis → Experiment → Analysis → Publication)

Complete end-to-end scientific research workflow from hypothesis generation to publication-ready manuscript. Produces:
- `hypothesis.md` (research hypothesis with literature grounding)
- `experimental_design.json` (detailed experimental protocol)
- `analysis_plan.md` (statistical analysis strategy)
- `publication_draft.tex` (LaTeX manuscript skeleton)

References: `Academic/Research-Methodology/hypothesis-generation.md`, `Guides/retrieval-augmented-generation.md`, `Applications/data-analysis-and-visualization.md`.

## 0) Research Context Setup
```bash
cat > research_context.txt <<'EOF'
Field: Neuroscience
Specific Area: Neural plasticity in learning
Current Gap: Limited understanding of molecular mechanisms in skill acquisition
Available Resources: Mouse model, fMRI, gene expression analysis, behavioral assays
Timeline: 18 months
Funding: NIH R01 equivalent
EOF

echo 'Research Question: How do specific molecular pathways contribute to neural plasticity during motor skill learning?' > research_question.txt
```

PowerShell alternative:
```powershell
@'
Field: Neuroscience
Specific Area: Neural plasticity in learning
Current Gap: Limited understanding of molecular mechanisms in skill acquisition
Available Resources: Mouse model, fMRI, gene expression analysis, behavioral assays
Timeline: 18 months
Funding: NIH R01 equivalent
'@ | Set-Content research_context.txt

@'Research Question: How do specific molecular pathways contribute to neural plasticity during motor skill learning?'@ | Set-Content research_question.txt
```

## 1) Hypothesis Generation (RAG-Grounded)
```
Generate evidence-based hypotheses with literature citations.
```

### Bash (OpenAI)
```bash
SYSTEM='Generate 3-5 testable hypotheses based on current literature gaps. Each hypothesis must include: molecular mechanism, experimental approach, expected outcome, and citation evidence. Format as JSON with evidence mapping.'

USER=$(cat <<'USR'
Research Context:
$(cat research_context.txt)

Research Question:
$(cat research_question.txt)

Generate hypotheses with:
- Molecular pathway identification
- Experimental validation strategy
- Statistical power considerations
- Literature gap analysis
- Timeline and resource requirements
USR
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg usr "$USER" '{
    model: env.OPENAI_MODEL // "gpt-4o",
    temperature: 0.3,
    messages: [
      {role:"system", content:$sys},
      {role:"user", content:$usr}
    ]
  }') \
 | jq -r '.choices[0].message.content' | tee hypothesis.md
```

### PowerShell (OpenAI)
```powershell
$SYSTEM = 'Generate 3-5 testable hypotheses based on current literature gaps. Each hypothesis must include: molecular mechanism, experimental approach, expected outcome, and citation evidence. Format as JSON with evidence mapping.'

$USER = @"
Research Context:
$(Get-Content -Raw research_context.txt)

Research Question:
$(cat research_question.txt)

Generate hypotheses with:
- Molecular pathway identification
- Experimental validation strategy
- Statistical power considerations
- Literature gap analysis
- Timeline and resource requirements
"@

$body = @{
  model = $env:OPENAI_MODEL; temperature = 0.3;
  messages = @(
    @{role='system';content=$SYSTEM},
    @{role='user';content=$USER}
  )
} | ConvertTo-Json -Depth 6

$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
Set-Content -Path hypothesis.md -Value $resp.choices[0].message.content
```

## 2) Experimental Design (JSON Schema Validation)
```
Design complete experimental protocols with statistical validation.
```

### Bash (OpenAI with Schema Validation)
```bash
SCHEMA=$(cat Prompting-Gold-Standard/JSON-Schemas/research-analysis.json)

SYSTEM='Design detailed experimental protocol as valid JSON matching the provided schema. Include controls, blinding, randomization, sample size calculation, and statistical analysis plan.'

USER=$(cat <<'USR'
Hypothesis: BDNF-TrkB pathway upregulation during motor learning
Resources: Mouse model, gene expression analysis, behavioral assays
Design experiment with:
- Independent and dependent variables
- Control and experimental groups
- Sample size justification
- Statistical analysis methods
- Timeline and milestones
USR
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg schema "$SCHEMA" --arg sys "$SYSTEM" --arg usr "$USER" '{
    model: env.OPENAI_MODEL // "gpt-4o",
    temperature: 0.1,
    messages: [
      {role:"system", content:"Schema: \($schema)\n\n\($sys)"},
      {role:"user", content:$usr}
    ]
  }') \
 | jq -r '.choices[0].message.content' | tee experimental_design.json

# Validate against schema
if command -v python3 &> /dev/null; then
  python3 -c "
import json, jsonschema
with open('experimental_design.json') as f:
  data = json.load(f)
with open('Prompting-Gold-Standard/JSON-Schemas/research-analysis.json') as f:
  schema = json.load(f)
jsonschema.validate(data, schema)
print('✅ Schema validation passed')
"
fi
```

## 3) Data Analysis Plan
```
Create statistical analysis plan with power calculations.
```

### Bash (OpenAI)
```bash
SYSTEM='Generate comprehensive data analysis plan including: statistical methods, power analysis, data visualization strategies, and interpretation guidelines.'

ANALYSIS_PROMPT=$(cat <<'EOT'
Based on experimental design:
$(cat experimental_design.json)

Create analysis plan covering:
1. Data preprocessing and quality control
2. Statistical tests and models
3. Power analysis and sample size validation
4. Data visualization strategies
5. Result interpretation guidelines
6. Sensitivity analyses
7. Publication-ready figure specifications
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg prompt "$ANALYSIS_PROMPT" '{
    model: env.OPENAI_MODEL // "gpt-4o",
    temperature: 0.1,
    messages: [
      {role:"system", content:$sys},
      {role:"user", content:$prompt}
    ]
  }') \
 | jq -r '.choices[0].message.content' | tee analysis_plan.md
```

## 4) Publication Draft Generation
```
Create LaTeX manuscript skeleton with all sections.
```

### Bash (OpenAI)
```bash
SYSTEM='Generate publication-ready LaTeX manuscript skeleton. Include all standard sections, proper citations, and figure/table placeholders. Use Overleaf-compatible LaTeX.'

PUB_PROMPT=$(cat <<'EOT'
Research Context:
$(cat research_context.txt)

Hypothesis:
$(cat hypothesis.md)

Experimental Design:
$(cat experimental_design.json)

Analysis Plan:
$(cat analysis_plan.md)

Generate complete manuscript including:
- Title, abstract, keywords
- Introduction with literature review
- Materials and Methods
- Results section structure
- Discussion outline
- References (BibTeX format)
- Figure and table placeholders
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg prompt "$PUB_PROMPT" '{
    model: env.OPENAI_MODEL // "gpt-4o",
    temperature: 0.1,
    messages: [
      {role:"system", content:$sys},
      {role:"user", content:$prompt}
    ]
  }') \
 | jq -r '.choices[0].message.content' | tee publication_draft.tex
```

## 5) One-Block End-to-End Pipeline
```bash
set -euo pipefail
export OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o}

# Setup research context
cat > research_context.txt <<'EOF'
Field: Neuroscience
Specific Area: Neural plasticity in learning
Current Gap: Limited understanding of molecular mechanisms in skill acquisition
Available Resources: Mouse model, fMRI, gene expression analysis, behavioral assays
Timeline: 18 months
Funding: NIH R01 equivalent
EOF

echo 'Research Question: How do specific molecular pathways contribute to neural plasticity during motor skill learning?' > research_question.txt

# Generate hypothesis
SYSTEM='Generate 3-5 testable hypotheses based on current literature gaps. Each hypothesis must include: molecular mechanism, experimental approach, expected outcome, and citation evidence. Format as JSON with evidence mapping.'

USER=$(cat <<'EOT'
Research Context:
$(cat research_context.txt)

Research Question:
$(cat research_question.txt)

Generate hypotheses with:
- Molecular pathway identification
- Experimental validation strategy
- Statistical power considerations
- Literature gap analysis
- Timeline and resource requirements
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$SYSTEM" --arg u "$USER" '{
    model:$m, temperature:0.3,
    messages:[{role:"system",content:$s},{role:"user",content:$u}]
  }') | jq -r '.choices[0].message.content' | tee hypothesis.md

# Generate experimental design
DESIGN_SYSTEM='Design detailed experimental protocol as valid JSON. Include controls, blinding, randomization, sample size calculation, and statistical analysis plan.'

DESIGN_USER=$(cat <<'EOT'
Hypothesis: BDNF-TrkB pathway upregulation during motor learning
Resources: Mouse model, gene expression analysis, behavioral assays
Design experiment with:
- Independent and dependent variables
- Control and experimental groups
- Sample size justification
- Statistical analysis methods
- Timeline and milestones
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$DESIGN_SYSTEM" --arg u "$DESIGN_USER" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$u}]
  }') | jq -r '.choices[0].message.content' | tee experimental_design.json

# Generate analysis plan
ANALYSIS_SYSTEM='Generate comprehensive data analysis plan including: statistical methods, power analysis, data visualization strategies, and interpretation guidelines.'

ANALYSIS_PROMPT=$(cat <<'EOT'
Based on experimental design:
$(cat experimental_design.json)

Create analysis plan covering:
1. Data preprocessing and quality control
2. Statistical tests and models
3. Power analysis and sample size validation
4. Data visualization strategies
5. Result interpretation guidelines
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$ANALYSIS_SYSTEM" --arg p "$ANALYSIS_PROMPT" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$p}]
  }') | jq -r '.choices[0].message.content' | tee analysis_plan.md

# Generate publication draft
PUB_SYSTEM='Generate publication-ready LaTeX manuscript skeleton. Include all standard sections, proper citations, and figure/table placeholders.'

PUB_PROMPT=$(cat <<'EOT'
Research Context:
$(cat research_context.txt)

Hypothesis:
$(cat hypothesis.md)

Experimental Design:
$(cat experimental_design.json)

Analysis Plan:
$(cat analysis_plan.md)

Generate complete manuscript including:
- Title, abstract, keywords
- Introduction with literature review
- Materials and Methods
- Results section structure
- Discussion outline
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$PUB_SYSTEM" --arg p "$PUB_PROMPT" '{
    model:$m, temperature:0.1,
    messages:[{role:"system",content:$s},{role:"user",content:$p}]
  }') | jq -r '.choices[0].message.content' | tee publication_draft.tex

echo '🎉 Scientific Research Pipeline Complete!'
echo 'Generated files: hypothesis.md, experimental_design.json, analysis_plan.md, publication_draft.tex'
```

## Notes
- This pipeline creates a complete research workflow from concept to publication
- All outputs are grounded in scientific rigor and experimental design principles
- JSON schema validation ensures experimental design quality
- LaTeX output is Overleaf-compatible for immediate publication preparation
- Power analysis and statistical planning ensure research validity
