# Quickstart: Knowledge Base Graph + Update Plan

Extract entities/relations with provenance, score source trust, and plan updates. Outputs:
- `kb_entities.json`
- `kb_relations.json`
- `source_graph.json`
- `kb_update_plan.md`

References: `Applications/knowledge-base-construction.md`.

## 0) Provide Sources
```bash
cat > sources.txt <<'EOF'
[#A] 2021 Journal Article: "Remote work effects vary by role autonomy" (peer-reviewed)
[#B] 2023 Meta-analysis: "Industry heterogeneity in productivity outcomes" (peer-reviewed)
[#C] Blog 2020: "Remote work always boosts productivity" (non-peer-reviewed)
EOF
```

## 1) Entity-Relation Extraction
```bash
PROMPT=$(cat <<'EOT'
From the context, extract:
- Entities (type, canonical name, aliases)
- Relations (subject, predicate, object, evidence [doc-id:quote])
Return JSON with two arrays: entities, relations. Do not add external facts.
Context:
<<<
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg model "${OPENAI_MODEL:-gpt-4o-mini}" --arg c "${PROMPT}$(cat sources.txt)
>>>" '{
    model: $model, temperature: 0,
    messages: [ {role:"user", content:$c} ], response_format:{type:"json_object"}
  }') \
 | tee kb_extract.json && jq '.entities' kb_extract.json > kb_entities.json && jq '.relations' kb_extract.json > kb_relations.json
```

### PowerShell
```powershell
$PROMPT = @"
From the context, extract:
- Entities (type, canonical name, aliases)
- Relations (subject, predicate, object, evidence [doc-id:quote])
Return JSON with two arrays: entities, relations. Do not add external facts.
Context:
<<<
$(Get-Content -Raw sources.txt)
>>>
"@
$body = @{ model = $env:OPENAI_MODEL; temperature = 0; messages = @(@{role='user';content=$PROMPT}); response_format = @{ type='json_object' } } | ConvertTo-Json -Depth 6
$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
($resp.choices[0].message.content) | Set-Content kb_extract.json
(Get-Content kb_extract.json | ConvertFrom-Json).entities | ConvertTo-Json -Depth 10 | Set-Content kb_entities.json
(Get-Content kb_extract.json | ConvertFrom-Json).relations | ConvertTo-Json -Depth 10 | Set-Content kb_relations.json
```

## 2) Source Graph + Trust Scoring
```bash
PROMPT=$(cat <<'EOT'
Build a source graph with nodes (id, type, venue, year) and edges (citation/derivation). Assign trust scores 0–1 with rationale: peer-reviewed recent > blog. Return JSON {nodes:[], edges:[]}. Use only provided sources.
Sources:
<<<
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg model "${OPENAI_MODEL:-gpt-4o-mini}" --arg c "${PROMPT}$(cat sources.txt)
>>>" '{
    model: $model, temperature: 0,
    messages: [ {role:"user", content:$c} ], response_format:{type:"json_object"}
  }') \
 | jq . | tee source_graph.json
```

### PowerShell
```powershell
$PROMPT = @"
Build a source graph with nodes (id, type, venue, year) and edges (citation/derivation). Assign trust scores 0–1 with rationale: peer-reviewed recent > blog. Return JSON {nodes:[], edges:[]}. Use only provided sources.
Sources:
<<<
$(Get-Content -Raw sources.txt)
>>>
"@
$body = @{ model = $env:OPENAI_MODEL; temperature = 0; messages = @(@{role='user';content=$PROMPT}); response_format = @{ type='json_object' } } | ConvertTo-Json -Depth 6
$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
$resp.choices[0].message.content | Set-Content source_graph.json
```

## 3) Update Plan
```bash
PROMPT=$(cat <<'EOT'
Given new docs below, propose updates to the KB:
- New entities/relations with evidence
- Retractions/contradictions
- Sections to rewrite
Return a concise Markdown plan with priorities.
New Docs:
[#D] 2024 RCT: "Collaboration overhead increases remote latency" (peer-reviewed)
EOT
)
curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg model "${OPENAI_MODEL:-gpt-4o-mini}" --arg p "$PROMPT" '{
    model: $model, temperature: 0,
    messages: [ {role:"user", content:$p} ]
  }') \
 | jq -r '.choices[0].message.content' | tee kb_update_plan.md
```

### PowerShell
```powershell
$PROMPT = @"
Given new docs below, propose updates to the KB:
- New entities/relations with evidence
- Retractions/contradictions
- Sections to rewrite
Return a concise Markdown plan with priorities.
New Docs:
[#D] 2024 RCT: "Collaboration overhead increases remote latency" (peer-reviewed)
"@
$body = @{ model = $env:OPENAI_MODEL; temperature = 0; messages = @(@{role='user';content=$PROMPT}) } | ConvertTo-Json -Depth 6
$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
Set-Content kb_update_plan.md $resp.choices[0].message.content
```

## Notes
- Store `kb_entities.json` and `kb_relations.json` in your knowledge repo; diff on updates.
- Build visualizations from `source_graph.json` to review trust scores with stakeholders.

## One-Block (OpenAI, Bash)
```bash
set -euo pipefail
export OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o-mini}
cat > sources.txt <<'EOF'
[#A] 2021 Journal Article: "Remote work effects vary by role autonomy" (peer-reviewed)
[#B] 2023 Meta-analysis: "Industry heterogeneity in productivity outcomes" (peer-reviewed)
[#C] Blog 2020: "Remote work always boosts productivity" (non-peer-reviewed)
EOF
curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg c "From the context, extract: Entities (type, canonical name, aliases); Relations (subject, predicate, object, evidence [doc-id:quote]). Return JSON with two arrays: entities, relations. Do not add external facts.\nContext:\n<<<\n$(cat sources.txt)\n>>>" '{model:$m,temperature:0,messages:[{role:"user",content:$c}],response_format:{type:"json_object"}}') \
  | tee kb_extract.json >/dev/null
jq '.entities' kb_extract.json > kb_entities.json
jq '.relations' kb_extract.json > kb_relations.json
curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg c "Build a source graph with nodes (id, type, venue, year) and edges (citation/derivation). Assign trust scores 0–1 with rationale: peer-reviewed recent > blog. Return JSON {nodes:[], edges:[]}. Use only provided sources.\nSources:\n<<<\n$(cat sources.txt)\n>>>" '{model:$m,temperature:0,messages:[{role:"user",content:$c}],response_format:{type:"json_object"}}') \
  | jq . | tee source_graph.json
curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg p "Given new docs below, propose updates to the KB:\n- New entities/relations with evidence\n- Retractions/contradictions\n- Sections to rewrite\nReturn a concise Markdown plan with priorities.\nNew Docs:\n[#D] 2024 RCT: \"Collaboration overhead increases remote latency\" (peer-reviewed)" '{model:$m,temperature:0,messages:[{role:"user",content:$p}] }') \
  | jq -r '.choices[0].message.content' | tee kb_update_plan.md
echo 'Done: kb_entities.json, kb_relations.json, source_graph.json, kb_update_plan.md'
```
