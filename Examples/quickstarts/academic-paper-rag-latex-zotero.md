# Quickstart: Academic Paper Flow (RAG → LaTeX → Zotero TODO)

Generate Overleaf-safe LaTeX sections grounded in sources, then produce a Zotero hydration TODO list. Produces:
- `paper.tex` (compilable LaTeX skeleton + section stubs)
- `zotero_todo.md` (non-fabricated BibTeX fetch list)

References: `Academic/Software-Integration/overleaf-latex-prompts.md`, `Guides/retrieval-augmented-generation.md`.

## 0) Context and Topic
```bash
cat > context.txt <<'EOF'
[#1] Smith 2021 (Journal of Productivity) "...remote work effects vary by autonomy..."
[#2] Meta 2023 (Meta-analysis) "...heterogeneity by industry and collaboration intensity..."
EOF

echo 'Topic: Productivity impacts of remote work across roles' > topic.txt
```

PowerShell alternative:
```powershell
@'
[#1] Smith 2021 (Journal of Productivity) "...remote work effects vary by autonomy..."
[#2] Meta 2023 (Meta-analysis) "...heterogeneity by industry and collaboration intensity..."
'@ | Set-Content context.txt

@'Topic: Productivity impacts of remote work across roles'@ | Set-Content topic.txt
```

## 1) Generate LaTeX Sections (OpenAI)
```
Policy: Output LaTeX only. Compile-safe macros. Use \cite{key} without inventing keys; write [to-collect: key-hint] where keys are unknown.
```

### Bash
```bash
SYSTEM=$(cat <<'SYS'
Output LaTeX only. Compile-safe macros. Use \section, \subsection, \label. Use \cite{key} only if a real key is provided; otherwise write [to-collect: key-hint]. No commentary.
SYS
)

USER=$(cat <<'USR'
Context (--- delimited, cite with [#id] in text, not \cite):
---
$(cat context.txt)
---

Task: Create a paper skeleton for:
$(cat topic.txt)

Include:
- \section{Introduction} (1 paragraph; [#id] inline citations)
- \section{Related Work}
- \section{Method}
- \section{Results}
- \section{Discussion}
- \section{Limitations}
- \section{Conclusion}
Add one figure and one table stub with \label.
USR
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg usr "$USER" '{
    model: env.OPENAI_MODEL // "gpt-4o-mini",
    temperature: 0.1,
    messages: [ {role:"system", content:$sys}, {role:"user", content:$usr} ]
  }') \
 | jq -r '.choices[0].message.content' | tee paper.tex
```

### PowerShell
```powershell
$SYSTEM = 'Output LaTeX only. Compile-safe macros. Use \section, \subsection, \label. Use \cite{key} only if a real key is provided; otherwise write [to-collect: key-hint]. No commentary.'
$USER = @"Context (--- delimited, cite with [#id] in text, not \cite):
---
$(Get-Content -Raw context.txt)
---

Task: Create a paper skeleton for:
$(Get-Content -Raw topic.txt)

Include:
- \section{Introduction} (1 paragraph; [#id] inline citations)
- \section{Related Work}
- \section{Method}
- \section{Results}
- \section{Discussion}
- \section{Limitations}
- \section{Conclusion}
Add one figure and one table stub with \label.
"@

$body = @{ 
  model = $env:OPENAI_MODEL; temperature = 0.1;
  messages = @(@{role='system';content=$SYSTEM}, @{role='user';content=$USER})
} | ConvertTo-Json -Depth 6

$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
Set-Content -Path paper.tex -Value $resp.choices[0].message.content
```

### Anthropic (Bash)
```bash
curl -s https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "content-type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg usr "$USER" '{
    model: "claude-3-5-sonnet-20240620", max_tokens: 1800, temperature: 0.1,
    system: $sys, messages: [ {role:"user", content:$usr} ]
  }') | jq -r '.content[0].text' | tee paper.tex
```

### Azure OpenAI (Bash)
```bash
curl -s "$AZURE_OPENAI_ENDPOINT/openai/deployments/$AZURE_OPENAI_DEPLOYMENT/chat/completions?api-version=$AZURE_OPENAI_API_VERSION" \
  -H "api-key: $AZURE_OPENAI_KEY" -H "content-type: application/json" \
  -d @<(jq -n --arg sys "$SYSTEM" --arg usr "$USER" '{
    temperature: 0.1,
    messages: [ {role:"system",content:$sys}, {role:"user",content:$usr} ]
  }') | jq -r '.choices[0].message.content' | tee paper.tex
```

## 2) Zotero BibTeX Hydration TODO
Uses `Academic/Software-Integration/zotero-citation-workflows.md` pattern. Produces a non-fabricated list to fetch.

### Bash
```bash
PROMPT=$(cat <<'EOT'
From the outline topics and inline [#id] mentions, list the key references to collect. Do not fabricate. For each item output: [to-collect] title | venue | year | DOI/URL if known | suggested BibTeX key.
EOT
)

curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" \
  -d @<(jq -n --arg prompt "$PROMPT
Outline:
<<<
$(cat paper.tex)
>>>
" '{
    model: env.OPENAI_MODEL // "gpt-4o-mini",
    temperature: 0,
    messages: [ {role:"user", content:$prompt} ]
  }') \
 | jq -r '.choices[0].message.content' | tee zotero_todo.md
```

### PowerShell
```powershell
$PROMPT = @"
From the outline topics and inline [#id] mentions, list the key references to collect. Do not fabricate. For each item output: [to-collect] title | venue | year | DOI/URL if known | suggested BibTeX key.
Outline:
<<<
$(Get-Content -Raw paper.tex)
>>>
"@

$body = @{ 
  model = $env:OPENAI_MODEL; temperature = 0;
  messages = @(@{role='user';content=$PROMPT})
} | ConvertTo-Json -Depth 6

$resp = Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
Set-Content -Path zotero_todo.md -Value $resp.choices[0].message.content
```

## 3) One-Block End-to-End (OpenAI, Bash)
```bash
set -euo pipefail
export OPENAI_MODEL=${OPENAI_MODEL:-gpt-4o-mini}
cat > context.txt <<'EOF'
[#1] Smith 2021 (Journal of Productivity) "...remote work effects vary by autonomy..."
[#2] Meta 2023 (Meta-analysis) "...heterogeneity by industry and collaboration intensity..."
EOF
echo 'Topic: Productivity impacts of remote work across roles' > topic.txt
SYSTEM='Output LaTeX only. Compile-safe macros. Use \section, \subsection, \label. Use \cite{key} only if a real key is provided; otherwise write [to-collect: key-hint]. No commentary.'
USER=$(cat <<'EOT'
Context (--- delimited, cite with [#id] in text, not \cite):
---
$(cat context.txt)
---
Task: Create a paper skeleton for:
$(cat topic.txt)
Include: Intro/Related/Method/Results/Discussion/Limitations/Conclusion; add one figure and table with labels.
EOT
)
curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg s "$SYSTEM" --arg u "$USER" '{model:$m,temperature:0.1,messages:[{role:"system",content:$s},{role:"user",content:$u}] }') \
  | jq -r '.choices[0].message.content' | tee paper.tex
PROMPT=$(cat <<'EOT'
From the outline topics and inline [#id] mentions, list the key references to collect. Do not fabricate. For each item output: [to-collect] title | venue | year | DOI/URL if known | suggested BibTeX key.
Outline:
<<<
EOT
)
curl -s https://api.openai.com/v1/chat/completions -H "Authorization: Bearer $OPENAI_API_KEY" -H 'Content-Type: application/json' \
  -d @<(jq -n --arg m "$OPENAI_MODEL" --arg p "${PROMPT}$(cat paper.tex)
>>>" '{model:$m,temperature:0,messages:[{role:"user",content:$p}] }') \
  | jq -r '.choices[0].message.content' | tee zotero_todo.md
echo 'Done: paper.tex, zotero_todo.md'
```

## Notes
- To compile locally: use `latexmk -pdf paper.tex` or upload `paper.tex` to Overleaf. Resolve `[to-collect]` items by adding BibTeX entries.

## Notes
- Keep [#id] inline citations distinct from BibTeX \cite keys until sources are confirmed in Zotero.
- Replace `[to-collect: key-hint]` with real keys once BibTeX entries are added.
