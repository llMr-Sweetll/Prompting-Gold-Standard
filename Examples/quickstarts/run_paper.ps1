# Academic paper skeleton (LaTeX) + Zotero hydration TODO (PowerShell)
# Usage:
#   ./run_paper.ps1 -Provider openai -Topic "Productivity impacts of remote work" [-Context ctx.txt] [-Model gpt-4o-mini]

[CmdletBinding()]
Param(
  [ValidateSet('openai','anthropic','azure')][string]$Provider = 'openai',
  [Parameter(Mandatory=$true)][string]$Topic,
  [string]$Context,
  [string]$Model
)

function Require-Cmd($name) { if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Missing dependency: $name" } }
Require-Cmd curl

if (-not $Context) {
  $Context = 'context.txt'
  @'
[#1] Smith 2021 (Journal of Productivity) "...remote work effects vary by autonomy..."
[#2] Meta 2023 (Meta-analysis) "...heterogeneity by industry and collaboration intensity..."
'@ | Set-Content $Context
}

$SYSTEM = 'Output LaTeX only. Compile-safe macros. Use \section, \subsection, \label. Use \cite{key} only if a real key is provided; otherwise write [to-collect: key-hint]. No commentary.'
$USER = @"Context (--- delimited, cite with [#id] in text, not \cite):
---
$(Get-Content -Raw $Context)
---

Task: Create a paper skeleton for:
$Topic

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
function Invoke-Anthropic([string]$System,[string]$User,[double]$Temp) {
  if (-not $env:ANTHROPIC_API_KEY) { throw 'ANTHROPIC_API_KEY not set' }
  $body = @{ model = 'claude-3-5-sonnet-20240620'; max_tokens = 2000; temperature = $Temp; system = $System; messages = @(@{role='user';content=$User}) } | ConvertTo-Json -Depth 8
  return Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers @{ 'x-api-key' = $env:ANTHROPIC_API_KEY; 'anthropic-version' = '2023-06-01' } -ContentType 'application/json' -Body $body
}

# Generate LaTeX
switch ($Provider) {
  'openai' {
    $m = if ($Model) { $Model } elseif ($env:OPENAI_MODEL) { $env:OPENAI_MODEL } else { 'gpt-4o-mini' }
    $resp = Invoke-OpenAIChat @{ model = $m; temperature = 0.1; messages = @(@{role='system';content=$SYSTEM}, @{role='user';content=$USER}) }
    $resp.choices[0].message.content | Set-Content paper.tex
  }
  'azure' {
    $resp = Invoke-AzureChat @{ temperature = 0.1; messages = @(@{role='system';content=$SYSTEM}, @{role='user';content=$USER}) }
    $resp.choices[0].message.content | Set-Content paper.tex
  }
  'anthropic' {
    $resp = Invoke-Anthropic $SYSTEM $USER 0.1
    $resp.content[0].text | Set-Content paper.tex
  }
}
Write-Host 'Wrote paper.tex'

# Zotero TODO
$PROMPT = @"
From the outline topics and inline [#id] mentions, list the key references to collect. Do not fabricate. For each item output: [to-collect] title | venue | year | DOI/URL if known | suggested BibTeX key.
Outline:
<<<
$(Get-Content -Raw paper.tex)
>>>
"@
switch ($Provider) {
  'openai' {
    $m = if ($Model) { $Model } elseif ($env:OPENAI_MODEL) { $env:OPENAI_MODEL } else { 'gpt-4o-mini' }
    $resp = Invoke-OpenAIChat @{ model = $m; temperature = 0; messages = @(@{role='user';content=$PROMPT}) }
    $resp.choices[0].message.content | Set-Content zotero_todo.md
  }
  'azure' {
    $resp = Invoke-AzureChat @{ temperature = 0; messages = @(@{role='user';content=$PROMPT}) }
    $resp.choices[0].message.content | Set-Content zotero_todo.md
  }
  'anthropic' {
    $resp = Invoke-Anthropic '' $PROMPT 0.0
    $resp.content[0].text | Set-Content zotero_todo.md
  }
}
Write-Host 'Done: paper.tex zotero_todo.md'

