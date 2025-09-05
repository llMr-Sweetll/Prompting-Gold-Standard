# Data Analysis Plan + Report JSON + Vega-Lite chart (PowerShell)
# Usage:
#   ./run_analysis.ps1 -Provider openai [-Model gpt-4o-mini] [-Dataset dataset.md]

[CmdletBinding()]
Param(
  [ValidateSet('openai','anthropic','azure')][string]$Provider = 'openai',
  [string]$Model,
  [string]$Dataset
)

function Require-Cmd($name) { if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Missing dependency: $name" } }
Require-Cmd curl

if (-not $Dataset) {
  $Dataset = 'dataset.md'
  @'Dataset: Employee productivity logs (daily), fields: date, employee_id, role, autonomy_score, tasks_completed, meetings_hours.
Goal: Estimate impact of remote work on productivity while controlling for role and autonomy.
Constraints: No PII export; code must run offline.'@ | Set-Content $Dataset
}

$plan = @"Return a JSON analysis plan with fields: questions, features, methods, confounders, validation. Use only the dataset/goals below.
Dataset & Goals:
<<<
$(Get-Content -Raw $Dataset)
>>>
"@
$report = @"Produce a data analysis report matching JSON-Schemas/data-analysis-report.json. Include: summary, findings, metrics, and at least one Vega-Lite spec chart with altText. Keep assumptions and limitations explicit.
Dataset & Goals:
<<<
$(Get-Content -Raw $Dataset)
>>>
"@

function Invoke-OpenAIJson([string]$Prompt){
  if (-not $env:OPENAI_API_KEY) { throw 'OPENAI_API_KEY not set' }
  $m = if ($Model) { $Model } elseif ($env:OPENAI_MODEL) { $env:OPENAI_MODEL } else { 'gpt-4o-mini' }
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
  'openai'    { (Invoke-OpenAIJson $plan).choices[0].message.content | Set-Content analysis_plan.json }
  'azure'     { (Invoke-AzureJson  $plan).choices[0].message.content | Set-Content analysis_plan.json }
  'anthropic' { (Invoke-AnthropicJson $plan).content[0].text | Set-Content analysis_plan.json }
}
Write-Host 'Wrote analysis_plan.json'

switch ($Provider) {
  'openai'    { (Invoke-OpenAIJson $report).choices[0].message.content | Set-Content analysis_report.json }
  'azure'     { (Invoke-AzureJson  $report).choices[0].message.content | Set-Content analysis_report.json }
  'anthropic' { (Invoke-AnthropicJson $report).content[0].text | Set-Content analysis_report.json }
}
Write-Host 'Wrote analysis_report.json'

New-Item -ItemType Directory -Force -Path charts | Out-Null
($json = Get-Content -Raw analysis_report.json | ConvertFrom-Json) | Out-Null
$json.charts[0].vegaLiteSpec | ConvertTo-Json -Depth 15 | Set-Content charts/chart1.json
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
Write-Host 'Done: analysis_plan.json analysis_report.json charts/chart1.json charts/view.html'

