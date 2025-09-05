# Quickstart: RAG → Rubric Evaluation → Doc Generation (Multi‑Provider)

End‑to‑end workflow that:
1) Generates a grounded RAG answer with citations.
2) Scores it against a rubric (JSON schema).
3) Produces a polished research brief (Markdown).

Outputs written to:
- `rag_answer.md`
- `evaluation.json`
- `research_brief.md`

References: `Guides/retrieval-augmented-generation.md`, `Guides/self-critique-and-evaluation.md`, `JSON-Schemas/prompt-eval-rubric.json`.

## 0) Define Context and Question
Replace the example context with your own documents. Doc-ids like `#A`, `#B` are referenced in citations.

### Bash
```bash
cat > context.txt <<'EOF'
[#A] Title: Remote Work Outcomes (2021)
Excerpt: "...productivity improved for task-focused roles but decreased for collaboration-heavy teams..."

[#B] Meta-analysis (2023)
Excerpt: "...effect sizes vary by industry and role autonomy..."
EOF

cat > question.txt <<'EOF'
Summarize productivity impacts of remote work across roles and note uncertainties.
EOF
```

### PowerShell
```powershell
@'
[#A] Title: Remote Work Outcomes (2021)
Excerpt: "...productivity improved for task-focused roles but decreased for collaboration-heavy teams..."

[#B] Meta-analysis (2023)
Excerpt: "...effect sizes vary by industry and role autonomy..."
'@ | Set-Content context.txt

@'Summarize productivity impacts of remote work across roles and note uncertainties.'@ | Set-Content question.txt
```

## 1) RAG Answer (Grounded + Citations)
System prompt from `Guides/retrieval-augmented-generation.md` adapted for API use.

```
You are a rigorous research assistant.
Rules:
- Use ONLY the provided context.
- Cite evidence inline with [#doc-id] and quotes.
- If context is insufficient, say "Insufficient evidence" and list missing info.
- Do not guess; no external knowledge unless allowed.
Output sections:
- Answer (2–5 sentences)
- Evidence (bullets: [#doc-id] + quoted spans)
- Open Questions (if any)
```

### OpenAI (Bash)
```bash
export OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o-mini}

SYSTEM=$(cat <<'SYS'
You are a rigorous research assistant.
Rules:
- Use ONLY the provided context.
- Cite evidence inline with [#doc-id] and quotes.
- If context is insufficient, say "Insufficient evidence" and list missing info.
- Do not guess; no external knowledge unless allowed.
Output sections:
- Answer (2–5 sentences)
- Evidence (bullets: [#doc-id] + quoted spans)
- Open Questions (if any)
SYS
)

USER=$(cat <<'USR'
Context (--- delimited):
---
$(cat context.txt)
---

Question:
$(cat question.txt)
USR
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg usr "$USER" --arg model "$OPENAI_MODEL" '{
        model: $model,
        temperature: 0,
        messages: [
          {role:"system", content:$sys},
          {role:"user", content:$usr}
        ]
      }') \
 | jq -r '.choices[0].message.content' | tee rag_answer.md
```

### OpenAI (PowerShell)
```powershell
$env:OPENAI_MODEL = $env:OPENAI_MODEL -ne $null ? $env:OPENAI_MODEL : 'gpt-4o-mini'

$SYSTEM = @'
You are a rigorous research assistant.
Rules:
- Use ONLY the provided context.
- Cite evidence inline with [#doc-id] and quotes.
- If context is insufficient, say "Insufficient evidence" and list missing info.
- Do not guess; no external knowledge unless allowed.
Output sections:
- Answer (2–5 sentences)
- Evidence (bullets: [#doc-id] + quoted spans)
- Open Questions (if any)
'@

$USER = @"Context (--- delimited):
---
$(Get-Content -Raw context.txt)
---

Question:
$(Get-Content -Raw question.txt)
"@

$body = @{ 
  model = $env:OPENAI_MODEL; temperature = 0;
  messages = @(@{role='system';content=$SYSTEM}, @{role='user';content=$USER})
} | ConvertTo-Json -Depth 6

$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
$answer = $resp.choices[0].message.content
Set-Content -Path rag_answer.md -Value $answer
```

### Anthropic (Bash)
```bash
curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg usr "$USER" '{
      model: "claude-3-5-sonnet-20240620",
      max_tokens: 1500,
      system: $sys,
      messages: [ {role:"user", content:$usr} ]
    }') \
 | jq -r '.content[0].text' | tee rag_answer.md
```

### Anthropic (PowerShell)
```powershell
$SYSTEM = $SYSTEM # reuse defined earlier
$USER = $USER     # reuse defined earlier
$body = @{ 
  model = 'claude-3-5-sonnet-20240620'; max_tokens = 1500; temperature = 0;
  system = $SYSTEM; messages = @(@{role='user';content=$USER})
} | ConvertTo-Json -Depth 6
$resp = Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers @{ 'x-api-key' = $env:ANTHROPIC_API_KEY; 'anthropic-version' = '2023-06-01' } -ContentType 'application/json' -Body $body
Set-Content -Path rag_answer.md -Value $resp.content[0].text
```

### Azure OpenAI (Bash)
```bash
curl -s "$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_OPENAI_API_VERSION" \
  -H "api-key: $AZURE_OPENAI_KEY" -H "content-type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg usr "$USER" '{
      temperature: 0,
      messages: [ {role:"system",content:$sys}, {role:"user",content:$usr} ]
    }') \
 | jq -r '.choices[0].message.content' | tee rag_answer.md
```

### Azure OpenAI (PowerShell)
```powershell
$body = @{ 
  temperature = 0;
  messages = @(@{role='system';content=$SYSTEM}, @{role='user';content=$USER})
} | ConvertTo-Json -Depth 6
$uri = "$env:AZURE_OPENAI_ENDPOINT/openai/deployments/$env:AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$env:AZURE_OPENAI_API_VERSION"
$resp = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ 'api-key' = $env:AZURE_OPENAI_KEY } -ContentType 'application/json' -Body $body
Set-Content -Path rag_answer.md -Value $resp.choices[0].message.content
```

## 2) Rubric Evaluation (JSON)
Scores the answer against `JSON-Schemas/prompt-eval-rubric.json`.

### Prompt
```
Evaluate the following answer. Return JSON matching prompt-eval-rubric.json.
Answer:
<<<
[paste rag_answer.md]
>>>
```

### OpenAI (Bash)
```bash
EVAL_PROMPT=$(cat <<'EOT'
Evaluate the following answer. Return JSON matching JSON-Schemas/prompt-eval-rubric.json.
Answer:
<<<
EOT
)

EVAL_INPUT="${EVAL_PROMPT}$(cat rag_answer.md)
>>>
"

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d @<(jq -n --arg model "$OPENAI_MODEL" --arg prompt "$EVAL_INPUT" '{
        model: $model,
        temperature: 0,
        messages: [ {role:"user", content:$prompt} ],
        response_format: {type: "json_object"}
      }') \
 | jq -r '.choices[0].message.content' | tee evaluation.json
```

### OpenAI (PowerShell)
```powershell
$EVAL_INPUT = @"
Evaluate the following answer. Return JSON matching JSON-Schemas/prompt-eval-rubric.json.
Answer:
<<<
$(Get-Content -Raw rag_answer.md)
>>>
"@

$body = @{ 
  model = $env:OPENAI_MODEL; temperature = 0;
  messages = @(@{role='user';content=$EVAL_INPUT});
  response_format = @{ type = 'json_object' }
} | ConvertTo-Json -Depth 6

$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
$json = $resp.choices[0].message.content
Set-Content -Path evaluation.json -Value $json
```

## 3) Research Brief (Markdown)
Produces a polished brief using the grounded answer + key uncertainties.

### Prompt
```
Write a 1-page research brief:
- Context and question
- What the evidence says (with [#doc-id] citations)
- Uncertainties and gaps
- Practical implications
Tone: concise, neutral, non-speculative. Use content from the Answer below.
Answer:
<<<
[paste rag_answer.md]
>>>
```

### OpenAI (Bash)
```bash
BRIEF_PROMPT=$(cat <<'EOT'
Write a 1-page research brief:
- Context and question
- What the evidence says (with [#doc-id] citations)
- Uncertainties and gaps
- Practical implications
Tone: concise, neutral, non-speculative. Use content from the Answer below.
Answer:
<<<
EOT
)

BRIEF_INPUT="${BRIEF_PROMPT}$(cat rag_answer.md)
>>>
"

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d @<(jq -n --arg model "$OPENAI_MODEL" --arg prompt "$BRIEF_INPUT" '{
        model: $model,
        temperature: 0.2,
        messages: [ {role:"user", content:$prompt} ]
      }') \
 | jq -r '.choices[0].message.content' | tee research_brief.md
```

### OpenAI (PowerShell)
```powershell
$BRIEF_INPUT = @"
Write a 1-page research brief:
- Context and question
- What the evidence says (with [#doc-id] citations)
- Uncertainties and gaps
- Practical implications
Tone: concise, neutral, non-speculative. Use content from the Answer below.
Answer:
<<<
$(Get-Content -Raw rag_answer.md)
>>>
"@

$body = @{ 
  model = $env:OPENAI_MODEL; temperature = 0.2;
  messages = @(@{role='user';content=$BRIEF_INPUT})
} | ConvertTo-Json -Depth 6

$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
Set-Content -Path research_brief.md -Value $resp.choices[0].message.content
```

## Optional: Validate `evaluation.json` Against Schema
Use either Python or Node to validate the JSON against `JSON-Schemas/prompt-eval-rubric.json`.

### Python (Bash)
```bash
python3 - <<'PY'
import json, sys
from jsonschema import validate
schema = json.load(open('Prompting-Gold-Standard/JSON-Schemas/prompt-eval-rubric.json'))
data = json.load(open('evaluation.json'))
validate(instance=data, schema=schema)
print('evaluation.json is valid')
PY
```

### Node (Bash)
```bash
npx --yes ajv-cli -s Prompting-Gold-Standard/JSON-Schemas/prompt-eval-rubric.json -d evaluation.json --valid || exit 1
```

## One-Block End-to-End (Copy-Paste)

### Bash (OpenAI)
```bash
set -euo pipefail
export OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o-mini}
cat > context.txt <<'EOF'
[#A] 2021 Journal: task roles improve, collaboration roles decline
[#B] 2023 Meta-analysis: heterogeneity by autonomy and industry
EOF
echo 'Summarize productivity impacts of remote work across roles and note uncertainties.' > question.txt
SYSTEM='You are a rigorous research assistant. Use ONLY the provided context. Cite [#doc-id] with quotes. If insufficient, say "Insufficient evidence".'
USER=$(cat <<'EOT'
Context (---):
---
$(cat context.txt)
---
Question:
$(cat question.txt)
EOT
)
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$SYSTEM" --arg u "$USER" '{model:$m,temperature:0,messages:[{role:"system",content:$s},{role:"user",content:$u}] }') \
  | jq -r '.choices[0].message.content' | tee rag_answer.md
EVAL=$(cat <<'EOT'
Evaluate the following answer against JSON-Schemas/prompt-eval-rubric.json and return JSON only.
Answer:
<<<
EOT
)
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg p "${EVAL}$(cat rag_answer.md)
>>>" '{model:$m,temperature:0,messages:[{role:"user",content:$p}],response_format:{type:"json_object"}}') \
  | tee evaluation.json >/dev/null
BRIEF=$(cat <<'EOT'
Write a 1-page research brief using the Answer below. Sections: Context & Question, Evidence ([#id] citations), Uncertainties, Practical Implications.
Answer:
<<<
EOT
)
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg p "${BRIEF}$(cat rag_answer.md)
>>>" '{model:$m,temperature:0.2,messages:[{role:"user",content:$p}] }') \
  | jq -r '.choices[0].message.content' | tee research_brief.md
echo 'Done: rag_answer.md, evaluation.json, research_brief.md'
```

### PowerShell (OpenAI)
```powershell
Set-StrictMode -Version Latest
$env:OPENAI_MODEL = $env:OPENAI_MODEL ? $env:OPENAI_MODEL : 'gpt-4o-mini'
@'
[#A] 2021 Journal: task roles improve, collaboration roles decline
[#B] 2023 Meta-analysis: heterogeneity by autonomy and industry
'@ | Set-Content context.txt
@'Summarize productivity impacts of remote work across roles and note uncertainties.'@ | Set-Content question.txt
$SYSTEM = 'You are a rigorous research assistant. Use ONLY the provided context. Cite [#doc-id] with quotes. If insufficient, say "Insufficient evidence".'
$USER = @"Context (---):
---
$(Get-Content -Raw context.txt)
---
Question:
$(Get-Content -Raw question.txt)
"@
$body = @{ model = $env:OPENAI_MODEL; temperature = 0; messages = @(@{role='system';content=$SYSTEM}, @{role='user';content=$USER}) } | ConvertTo-Json -Depth 6
$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
$answer = $resp.choices[0].message.content; Set-Content rag_answer.md $answer
$EVAL = @"Evaluate the following answer against JSON-Schemas/prompt-eval-rubric.json and return JSON only.
Answer:
<<<
$answer
>>>"@
$body = @{ model = $env:OPENAI_MODEL; temperature = 0; messages = @(@{role='user';content=$EVAL}); response_format = @{type='json_object'} } | ConvertTo-Json -Depth 6
$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
Set-Content evaluation.json $resp.choices[0].message.content
$BRIEF = @"Write a 1-page research brief using the Answer below. Sections: Context & Question, Evidence ([#id] citations), Uncertainties, Practical Implications.
Answer:
<<<
$answer
>>>"@
$body = @{ model = $env:OPENAI_MODEL; temperature = 0.2; messages = @(@{role='user';content=$BRIEF}) } | ConvertTo-Json -Depth 6
$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
Set-Content research_brief.md $resp.choices[0].message.content
Write-Host 'Done: rag_answer.md, evaluation.json, research_brief.md'
```

## Notes
- For stricter grounding, include longer context and use the multi-hop synthesis pattern in `Guides/retrieval-augmented-generation.md`.
- Use `Examples/prompt-review-checklist.md` before shipping prompts to production.
- Add CI integration using `Examples/quickstarts/ci-eval-github-actions.md` to ensure regressions are caught.
