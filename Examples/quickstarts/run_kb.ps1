# Knowledge Base: Entity/Relation extraction + Source trust graph + Update plan (PowerShell)
# Usage:
#   ./run_kb.ps1 -Provider openai [-Sources sources.txt]

[CmdletBinding()]
Param(
  [ValidateSet('openai','anthropic','azure')][string]$Provider = 'openai',
  [string]$Sources
)

function Require-Cmd($name) { if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Missing dependency: $name" } }
Require-Cmd curl

if (-not $Sources) {
  $Sources = 'sources.txt'
  @'
[#A] 2021 Journal Article: "Remote work effects vary by role autonomy" (peer-reviewed)
[#B] 2023 Meta-analysis: "Industry heterogeneity in productivity outcomes" (peer-reviewed)
[#C] Blog 2020: "Remote work always boosts productivity" (non-peer-reviewed)
'@ | Set-Content $Sources
}

$extract = @"From the context, extract:
- Entities (type, canonical name, aliases)
- Relations (subject, predicate, object, evidence [doc-id:quote])
Return JSON with two arrays: entities, relations. Do not add external facts.
Context:
<<<
$(Get-Content -Raw $Sources)
>>>
"@
$graph = @"Build a source graph:
- Nodes: sources with metadata (id, type, venue, year)
- Edges: citation/derivation links
Assign a trust score per node (0–1) with rationale: peer-reviewed recent > blog.
Return JSON {nodes:[], edges:[]} using only provided sources.
Sources:
<<<
$(Get-Content -Raw $Sources)
>>>
"@
$plan = @'
Given new docs below, propose updates to the KB:
- New entities/relations with evidence
- Retractions/contradictions
- Sections to rewrite
Return a concise Markdown plan with priorities.
New Docs:
[#D] 2024 RCT: "Collaboration overhead increases remote latency" (peer-reviewed)
'@

function Invoke-OpenAIJson([string]$Prompt){
  if (-not $env:OPENAI_API_KEY) { throw 'OPENAI_API_KEY not set' }
  $m = if ($env:OPENAI_MODEL) { $env:OPENAI_MODEL } else { 'gpt-4o-mini' }
  $body = @{ model = $m; temperature = 0; messages = @(@{role='user';content=$Prompt}); response_format = @{ type = 'json_object' } } | ConvertTo-Json -Depth 8
  return Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body $body
}
function Invoke-AzureJson([string]$Prompt){
  foreach ($v in 'AZURE_OPENAI_KEY','AZURE_OPENAI_ENDPOINT','AZURE_OPENAI_DEPLOYMENT','AZURE_OPENAI_API_VERSION') { if (-not (Get-Item env:$v -ErrorAction SilentlyContinue)) { throw "Missing $v" } }
  $body = @{ temperature = 0; messages = @(@{role='user';content=$Prompt}); response_format = @{ type = 'json_object' } } | ConvertTo-Json -Depth 8
  $uri = "$($env:AZURE_OPENAI_ENDPOINT)/openai/deployments/$($env:AZURE_OPENAI_DEPLOYMENT)/chat/completions?api-version=$($env:AZURE_OPENAI_API_VERSION)"
  return Invoke-RestMethod -Method Post -Uri $uri -Headers @{ 'api-key' = $env:AZURE_OPENAI_KEY } -ContentType 'application/json' -Body $body
}
function Invoke-AnthropicJson([string]$Prompt){
  if (-not $env:ANTHROPIC_API_KEY) { throw 'ANTHROPIC_API_KEY not set' }
  $body = @{ model = 'claude-3-5-sonnet-20240620'; max_tokens = 2000; temperature = 0; system = 'Respond with JSON only'; messages = @(@{role='user';content=$Prompt}) } | ConvertTo-Json -Depth 8
  return Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers @{ 'x-api-key' = $env:ANTHROPIC_API_KEY; 'anthropic-version' = '2023-06-01' } -ContentType 'application/json' -Body $body
}

switch ($Provider) {
  'openai'    { (Invoke-OpenAIJson $extract).choices[0].message.content | Set-Content kb_extract.json
                (Invoke-OpenAIJson $graph).choices[0].message.content   | Set-Content source_graph.json
                $planText = (Invoke-RestMethod -Method Post -Uri 'https://api.openai.com/v1/chat/completions' -Headers @{Authorization = "Bearer $env:OPENAI_API_KEY"} -ContentType 'application/json' -Body (@{ model = $env:OPENAI_MODEL; temperature = 0; messages = @(@{role='user';content=$plan}) } | ConvertTo-Json -Depth 8)).choices[0].message.content | Set-Content kb_update_plan.md }
  'azure'     { (Invoke-AzureJson  $extract).choices[0].message.content | Set-Content kb_extract.json
                (Invoke-AzureJson  $graph).choices[0].message.content   | Set-Content source_graph.json
                (Invoke-RestMethod -Method Post -Uri "$($env:AZURE_OPENAI_ENDPOINT)/openai/deployments/$($env:AZURE_OPENAI_DEPLOYMENT)/chat/completions?api-version=$($env:AZURE_OPENAI_API_VERSION)" -Headers @{ 'api-key' = $env:AZURE_OPENAI_KEY } -ContentType 'application/json' -Body (@{ temperature = 0; messages = @(@{role='user';content=$plan}) } | ConvertTo-Json -Depth 8)).choices[0].message.content | Set-Content kb_update_plan.md }
  'anthropic' { (Invoke-AnthropicJson $extract).content[0].text        | Set-Content kb_extract.json
                (Invoke-AnthropicJson $graph).content[0].text          | Set-Content source_graph.json
                (Invoke-RestMethod -Method Post -Uri 'https://api.anthropic.com/v1/messages' -Headers @{ 'x-api-key' = $env:ANTHROPIC_API_KEY; 'anthropic-version' = '2023-06-01' } -ContentType 'application/json' -Body (@{ model = 'claude-3-5-sonnet-20240620'; max_tokens = 2000; temperature = 0; messages = @(@{role='user';content=$plan}) } | ConvertTo-Json -Depth 8)).content[0].text | Set-Content kb_update_plan.md }
}

(Get-Content -Raw kb_extract.json | ConvertFrom-Json).entities | ConvertTo-Json -Depth 12 | Set-Content kb_entities.json
(Get-Content -Raw kb_extract.json | ConvertFrom-Json).relations | ConvertTo-Json -Depth 12 | Set-Content kb_relations.json
Write-Host 'Done: kb_entities.json kb_relations.json source_graph.json kb_update_plan.md'

