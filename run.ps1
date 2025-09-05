# Meta-runner for Quickstarts (PowerShell)
# Usage examples:
#   ./run.ps1 -Flow rag -Provider openai -Model gpt-4o-mini
#   ./run.ps1 -Flow paper -Provider anthropic -Topic "Productivity impacts of remote work"
#   ./run.ps1 -Flow analysis -Provider openai -Dataset dataset.md
#   ./run.ps1 -Flow kb -Provider azure -Sources sources.txt

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$true)][ValidateSet('rag','paper','analysis','kb')][string]$Flow,
  [ValidateSet('openai','anthropic','azure','ollama')][string]$Provider = 'openai',
  [string]$Model,
  [string]$Topic,
  [string]$Context,
  [string]$Question,
  [string]$Dataset,
  [string]$Sources
)

$qs = Join-Path $PSScriptRoot 'Examples/quickstarts'

switch ($Flow) {
  'rag' {
    $args = @('-Provider', $Provider)
    if ($Model)   { $args += @('-Model', $Model) }
    if ($Context) { $args += @('-Context', $Context) }
    if ($Question){ $args += @('-Question', $Question) }
    & (Join-Path $qs 'run_rag.ps1') @args
  }
  'paper' {
    if (-not $Topic) { throw 'Topic is required for -Flow paper (use -Topic "...")' }
    $args = @('-Provider', $Provider, '-Topic', $Topic)
    if ($Model)   { $args += @('-Model', $Model) }
    if ($Context) { $args += @('-Context', $Context) }
    & (Join-Path $qs 'run_paper.ps1') @args
  }
  'analysis' {
    $args = @('-Provider', $Provider)
    if ($Model)   { $args += @('-Model', $Model) }
    if ($Dataset) { $args += @('-Dataset', $Dataset) }
    & (Join-Path $qs 'run_analysis.ps1') @args
  }
  'kb' {
    $args = @('-Provider', $Provider)
    if ($Sources) { $args += @('-Sources', $Sources) }
    & (Join-Path $qs 'run_kb.ps1') @args
  }
}

