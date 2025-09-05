# Quickstart: Data Analysis Report + Vega‑Lite Charts

Produce an analysis plan, compute metrics, and generate chart specifications. Outputs:
- `analysis_plan.json`
- `analysis_report.json` (matches `JSON-Schemas/data-analysis-report.json`)
- `charts/chart1.json` and `charts/view.html` (to preview specs)

References: `Applications/data-analysis-and-visualization.md`, `JSON-Schemas/data-analysis-report.json`.

## 0) Describe Dataset and Goals
```bash
cat > dataset.md <<'EOF'
Dataset: Employee productivity logs (daily), fields: date, employee_id, role, autonomy_score, tasks_completed, meetings_hours.
Goal: Estimate impact of remote work on productivity while controlling for role and autonomy.
Constraints: No PII export; code must run offline.
EOF
```

PowerShell:
```powershell
@'Dataset: Employee productivity logs (daily), fields: date, employee_id, role, autonomy_score, tasks_completed, meetings_hours.
Goal: Estimate impact of remote work on productivity while controlling for role and autonomy.
Constraints: No PII export; code must run offline.'@ | Set-Content dataset.md
```

## 1) Analysis Plan (JSON)
### Bash
```bash
PROMPT=$(cat <<'EOT'
Return a JSON analysis plan with fields: questions, features, methods, confounders, validation. Use only the dataset/goals below.
Dataset & Goals:
<<<
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg model "${OPENAI_MODEL:-gpt-4o-mini}" --arg d "${PROMPT}$(cat dataset.md)
>>>" '{
    model: $model, temperature: 0,
    messages: [ {role:"user", content:$d} ], response_format:{type:"json_object"}
  }') \
 | jq . | tee analysis_plan.json
```

### PowerShell
```powershell
$INPUT = @"
Return a JSON analysis plan with fields: questions, features, methods, confounders, validation. Use only the dataset/goals below.
Dataset & Goals:
<<<
$(Get-Content -Raw dataset.md)
>>>
"@

$body = @{ 
  model = $env:OPENAI_MODEL; temperature = 0;
  messages = @(@{role='user';content=$INPUT});
  response_format = @{ type = 'json_object' }
} | ConvertTo-Json -Depth 6

$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
$resp.choices[0].message.content | Set-Content analysis_plan.json
```

## 2) Report with Charts (JSON)
You can use OpenAI, Anthropic, or Azure. Below are OpenAI examples; Anthropic/Azure variants follow.
### Bash
```bash
PROMPT=$(cat <<'EOT'
Produce a data analysis report matching JSON-Schemas/data-analysis-report.json. Include: summary, findings, metrics, and at least one Vega-Lite spec chart with altText. Keep assumptions and limitations explicit.
Dataset & Goals:
<<<
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg model "${OPENAI_MODEL:-gpt-4o-mini}" --arg d "${PROMPT}$(cat dataset.md)
>>>" '{
    model: $model, temperature: 0,
    messages: [ {role:"user", content:$d} ], response_format:{type:"json_object"}
  }') \
 | tee analysis_report.json | jq -r '.charts[0].vegaLiteSpec' > charts/chart1.json

mkdir -p charts
cat > charts/view.html <<'HTML'
<!doctype html>
<meta charset="utf-8">
<script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
<div id="vis"></div>
<script>
fetch('chart1.json').then(r=>r.json()).then(spec=>vegaEmbed('#vis', spec));
</script>
HTML
```

### PowerShell
```powershell
$PROMPT = @"
Produce a data analysis report matching JSON-Schemas/data-analysis-report.json. Include: summary, findings, metrics, and at least one Vega-Lite spec chart with altText. Keep assumptions and limitations explicit.
Dataset & Goals:
<<<
$(Get-Content -Raw dataset.md)
>>>
"@

$body = @{ 
  model = $env:OPENAI_MODEL; temperature = 0;
  messages = @(@{role='user';content=$PROMPT});
  response_format = @{ type = 'json_object' }
} | ConvertTo-Json -Depth 6

$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
$json = $resp.choices[0].message.content
New-Item -ItemType Directory -Force -Path charts | Out-Null
Set-Content analysis_report.json $json
($json | ConvertFrom-Json).charts[0].vegaLiteSpec | ConvertTo-Json -Depth 10 | Set-Content charts/chart1.json
$html = @'
<!doctype html>
<meta charset="utf-8">
<script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
<div id="vis"></div>
<script>
fetch('chart1.json').then(r=>r.json()).then(spec=>vegaEmbed('#vis', spec));
</script>
'@
Set-Content charts/view.html $html
```

### Anthropic (Bash)
```bash
PROMPT=$(cat <<'EOT'
Produce a data analysis report matching JSON-Schemas/data-analysis-report.json. Include: summary, findings, metrics, and at least one Vega-Lite spec chart with altText. Keep assumptions and limitations explicit.
Dataset & Goals:
<<<
EOT
)
curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "content-type: application/json" \
  -d @<(jq -n --arg d "${PROMPT}$(cat dataset.md)
>>>" '{
    model: "claude-3-5-sonnet-20240620",
    max_tokens: 2000,
    messages: [ {role:"user", content:$d} ],
    temperature: 0,
    system: "Respond with JSON only"
  }') | tee analysis_report.json
mkdir -p charts
jq -r '.charts[0].vegaLiteSpec' analysis_report.json > charts/chart1.json
```

### Azure OpenAI (Bash)
```bash
PROMPT=$(cat <<'EOT'
Produce a data analysis report matching JSON-Schemas/data-analysis-report.json. Include: summary, findings, metrics, and at least one Vega-Lite spec chart with altText. Keep assumptions and limitations explicit.
Dataset & Goals:
<<<
EOT
)
curl -s "$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_OPENAI_API_VERSION" \
  -H "api-key: $AZURE_OPENAI_KEY" -H "content-type: application/json" \
  -d @<(jq -n --arg p "${PROMPT}$(cat dataset.md)
>>>" '{
    temperature: 0,
    messages: [ {role:"user", content:$p} ],
    response_format:{type:"json_object"}
  }') | tee analysis_report.json
mkdir -p charts
jq -r '.charts[0].vegaLiteSpec' analysis_report.json > charts/chart1.json
```

## 3) Next Steps
- Validate results against ground truth where possible.
- Save chart specs to your BI/analytics repo; embed via Vega/Vega-Lite.
- Use `Examples/rubrics.md` to score clarity and actionability.

## 4) One-Block (OpenAI, Bash)
```bash
set -euo pipefail
export OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o-mini}
cat > dataset.md <<'EOF'
Dataset: Employee productivity logs (daily), fields: date, employee_id, role, autonomy_score, tasks_completed, meetings_hours.
Goal: Estimate impact of remote work on productivity while controlling for role and autonomy.
Constraints: No PII export; code must run offline.
EOF
curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg d "Return a JSON analysis plan with fields: questions, features, methods, confounders, validation. Use only the dataset/goals below.\nDataset & Goals:\n<<<\n$(cat dataset.md)\n>>>" '{model:$m,temperature:0,messages:[{role:"user",content:$d}],response_format:{type:"json_object"}}') \
  | jq . | tee analysis_plan.json
curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg d "Produce a data analysis report matching JSON-Schemas/data-analysis-report.json. Include: summary, findings, metrics, and at least one Vega-Lite spec chart with altText. Keep assumptions and limitations explicit.\nDataset & Goals:\n<<<\n$(cat dataset.md)\n>>>" '{model:$m,temperature:0,messages:[{role:"user",content:$d}],response_format:{type:"json_object"}}') \
  | tee analysis_report.json >/dev/null
mkdir -p charts
jq -r '.charts[0].vegaLiteSpec' analysis_report.json > charts/chart1.json
cat > charts/view.html <<'HTML'
<!doctype html>
<meta charset="utf-8">
<script src="https://cdn.jsdelivr.net/npm/vega@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>
<script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>
<div id="vis"></div>
<script>
fetch('chart1.json').then(r=>r.json()).then(spec=>vegaEmbed('#vis', spec));
</script>
HTML
echo 'Done: analysis_plan.json, analysis_report.json, charts/chart1.json, charts/view.html'
```
