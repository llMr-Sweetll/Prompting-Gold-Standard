# RAG -> Rubric Eval -> Research Brief (PowerShell)
# Usage examples:
#   ./run_rag.ps1 -Provider openai -Model gpt-4o-mini
#   ./run_rag.ps1 -Provider anthropic
#   ./run_rag.ps1 -Provider azure
#   ./run_rag.ps1 -Provider ollama -Model llama3.1
#   ./run_rag.ps1 -Provider openai -Context context.txt -Question question.txt

[CmdletBinding()]
Param(
  [ValidateSet('openai','anthropic','azure','ollama')][string]$Provider = 'openai',
  [string]$Model,
  [string]$Context,
  [string]$Question
)

function Require-Cmd($name) { if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Missing dependency: $name" } }
Require-Cmd curl

if (-not $Context) {
  $Context = 'context.txt'
  @'
[#A] 2021 Journal: task roles improve, collaboration roles decline
[#B] 2023 Meta-analysis: heterogeneity by autonomy and industry
'@ | Set-Content $Context
}
if (-not $Question) {
  $Question = 'question.txt'
  @'Summarize productivity impacts of remote work across roles and note uncertainties.'@ | Set-Content $Question
}

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

$USER = @"Context (---):
---
$(Get-Content -Raw $Context)
---

Question:
$(Get-Content -Raw $Question)
"@

function Invoke-OpenAIChat([hashtable]$Body) {
  if (-not $env:OPENAI_API_KEY) { throw 'OPENAI_API_KEY not set' }
  $json = $Body | ConvertTo-Json -Depth 8
  return Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $json
}

function Invoke-AzureChat([hashtable]$Body) {
  foreach ($v in 'AZURE_OPENAI_KEY','AZURE_OPENAI_ENDPOINT','AZURE_OPENAI_DEPLOYMENT','AZURE_OPENAI_API_VERSION') { if (-not (Get-Item env:$v -ErrorAction SilentlyContinue)) { throw "Missing $v" } }
  $json = $Body | ConvertTo-Json -Depth 8
  $uri = "$($env:AZURE_OPENAI_ENDPOINT)/openai/deployments/$($env:AZURE_OPENAI_DEPLOYMENT)/chat/completions?api-version=$($env:AZURE_OPENAI_API_VERSION)"
  return Invoke-RestMethod -Method Post -Uri $uri -Headers @{ 'api-key' = $env:AZURE_OPENAI_KEY } -ContentType 'application/json' -Body $json
}

function Invoke-Anthropic([string]$System,[string]$User,[bool]$JsonOnly,$Temperature=0) {
  if (-not $env:ANTHROPIC_API_KEY) { throw 'ANTHROPIC_API_KEY not set' }
  $sys = $System + ($(if ($JsonOnly) { "`nRespond with JSON only." } else { '' }))
  $body = @{ model = 'claude-3-5-sonnet-20240620'; max_tokens = 2000; temperature = $Temperature; system = $sys; messages = @(@{role='user';content=$User}) }
  $json = $body | ConvertTo-Json -Depth 8
  return Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers @{ 'x-api-key' = $env:ANTHROPIC_API_KEY; 'anthropic-version' = '2023-06-01' } -ContentType 'application/json' -Body $json
}

function Invoke-Ollama([string]$System,[string]$User) {
  $m = if ($Model) { $Model } elseif ($env:OLLAMA_MODEL) { $env:OLLAMA_MODEL } else { 'llama3.1' }
  $body = @{ model = $m; messages = @(@{role='system';content=$System}, @{role='user';content=$User}); stream = $false }
  $json = $body | ConvertTo-Json -Depth 8
  return Invoke-RestMethod -Method Post -Uri 'http://localhost:11434/api/chat' -ContentType 'application/json' -Body $json
}

# Step 1: Answer
switch ($Provider) {
  'openai' {
    $m = if ($Model) { $Model } elseif ($env:OPENAI_MODEL) { $env:OPENAI_MODEL } else { 'gpt-4o-mini' }
    $resp = Invoke-OpenAIChat @{ model = $m; temperature = 0; messages = @(@{role='system';content=$SYSTEM}, @{role='user';content=$USER}) }
    ($resp.choices[0].message.content) | Set-Content rag_answer.md
  }
  'azure' {
    $resp = Invoke-AzureChat @{ temperature = 0; messages = @(@{role='system';content=$SYSTEM}, @{role='user';content=$USER}) }
    ($resp.choices[0].message.content) | Set-Content rag_answer.md
  }
  'anthropic' {
    $resp = Invoke-Anthropic $SYSTEM $USER $false 0
    ($resp.content[0].text) | Set-Content rag_answer.md
  }
  'ollama' {
    $resp = Invoke-Ollama $SYSTEM $USER
    ($resp.message.content) | Set-Content rag_answer.md
  }
}
Write-Host 'Wrote rag_answer.md'

# Step 2: Evaluation
$EVAL = @"Evaluate the following answer against JSON-Schemas/prompt-eval-rubric.json and return JSON only.
Answer:
<<<
$(Get-Content -Raw rag_answer.md)
>>>
"@
switch ($Provider) {
  'openai' {
    $m = if ($Model) { $Model } elseif ($env:OPENAI_MODEL) { $env:OPENAI_MODEL } else { 'gpt-4o-mini' }
    $resp = Invoke-OpenAIChat @{ model = $m; temperature = 0; messages = @(@{role='user';content=$EVAL}); response_format = @{ type = 'json_object' } }
    ($resp.choices[0].message.content) | Set-Content evaluation.json
  }
  'azure' {
    $resp = Invoke-AzureChat @{ temperature = 0; messages = @(@{role='user';content=$EVAL}); response_format = @{ type = 'json_object' } }
    ($resp.choices[0].message.content) | Set-Content evaluation.json
  }
  'anthropic' {
    $resp = Invoke-Anthropic 'Respond with JSON only.' $EVAL $true 0
    ($resp.content[0].text) | Set-Content evaluation.json
  }
  'ollama' {
    $m = if ($Model) { $Model } elseif ($env:OLLAMA_MODEL) { $env:OLLAMA_MODEL } else { 'llama3.1' }
    $body = @{ model = $m; messages = @(@{role='user';content=$EVAL}); stream = $false } | ConvertTo-Json -Depth 8
    $resp = Invoke-RestMethod -Method Post -Uri 'http://localhost:11434/api/chat' -ContentType 'application/json' -Body $body
    ($resp.message.content) | Set-Content evaluation.json
  }
}
Write-Host 'Wrote evaluation.json'

# Step 3: Brief
$BRIEF = @"Write a 1-page research brief:
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
switch ($Provider) {
  'openai' {
    $m = if ($Model) { $Model } elseif ($env:OPENAI_MODEL) { $env:OPENAI_MODEL } else { 'gpt-4o-mini' }
    $resp = Invoke-OpenAIChat @{ model = $m; temperature = 0.2; messages = @(@{role='user';content=$BRIEF}) }
    ($resp.choices[0].message.content) | Set-Content research_brief.md
  }
  'azure' {
    $resp = Invoke-AzureChat @{ temperature = 0.2; messages = @(@{role='user';content=$BRIEF}) }
    ($resp.choices[0].message.content) | Set-Content research_brief.md
  }
  'anthropic' {
    $resp = Invoke-Anthropic '' $BRIEF $false 0.2
    ($resp.content[0].text) | Set-Content research_brief.md
  }
  'ollama' {
    $m = if ($Model) { $Model } elseif ($env:OLLAMA_MODEL) { $env:OLLAMA_MODEL } else { 'llama3.1' }
    $body = @{ model = $m; messages = @(@{role='user';content=$BRIEF}); stream = $false } | ConvertTo-Json -Depth 8
    $resp = Invoke-RestMethod -Method Post -Uri 'http://localhost:11434/api/chat' -ContentType 'application/json' -Body $body
    ($resp.message.content) | Set-Content research_brief.md
  }
}
Write-Host 'Done: rag_answer.md evaluation.json research_brief.md'

