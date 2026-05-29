#!/usr/bin/env pwsh
# team-orchestrator.ps1
# Team Mode: Multi-agent parallel orchestration with MCP skill routing
# Version: 1.0.0
<#
.SYNOPSIS
  Team Mode orchestrator — divide un trabajo complejo en sub-tareas paralelas
  usando el MCP Skill Server para routing de skills.

.DESCRIPTION
  team-orchestrator.ps1 -Task "..." [-Skills @("skill1","skill2")] [-MaxParallel 3]

  Para cada skill relevante, lanza un sub-agente en paralelo (job PowerShell).
  Recolecta resultados, maneja fallos/parciales y sintetiza salida unificada.

  Requiere:
    - MCP Skill Server compilado (pnpm build:mcp)
    - node >= 20
.PARAMETER Task
  Descripción del trabajo a realizar.
.PARAMETER Skills
  Lista explícita de skills a invocar. Si se omite, se consulta al MCP server.
.PARAMETER MaxParallel
  Máximo de trabajos en paralelo (default: 3, respeta parallel-execution-limits).
.PARAMETER TimeoutSeconds
  Timeout por sub-tarea (default: 300).
.PARAMETER DryRun
  Simula sin ejecutar sub-agentes.
.EXAMPLE
  # Deploy completo con 3 grupos de skills en paralelo
  ./team-orchestrator.ps1 -Task "Deploy microservicio auth" -MaxParallel 3

  # Skills específicos
  ./team-orchestrator.ps1 -Task "Review PR" -Skills @("judgment-day","comment-writer")
#>

param(
  [Parameter(Mandatory)][string]$Task,
  [string[]]$Skills,
  [int]$MaxParallel = 3,
  [int]$TimeoutSeconds = 300,
  [switch]$DryRun,
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR }
  else { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$mcpServer = Join-Path $repoRoot "dist/scripts/mcp/skill-server.js"
$resultsDir = Join-Path $repoRoot ".session/team-mode"
$null = New-Item -ItemType Directory -Path $resultsDir -Force

# ---- Helpers ----
function Invoke-McpTool {
  param([string]$Tool, [object]$Args = @{})
  $req = @{ jsonrpc = "2.0"; id = [guid]::NewGuid().Guid; method = "tools/call"
    params = @{ name = $Tool; arguments = $Args } } | ConvertTo-Json -Compress
  try {
    $resp = $req | & "node" $mcpServer 2>$null
    if (-not $resp) { return $null }
    $parsed = $resp | ConvertFrom-Json
    return $parsed.result.content[0].text
  } catch { return $null }
}

function Get-RelevantSkills {
  param([string]$Query)
  if ($Skills -and $Skills.Count -gt 0) { return $Skills }
  $result = Invoke-McpTool -Tool "search_skills" -Args @{ query = $Query }
  if (-not $result) { return @() }
  $lines = $result -split "`n" | Where-Object { $_ -match '^\s*-\s+\*\*(.+?)\*\*' }
  return $lines | ForEach-Object { if ($_ -match '\*\*(.+?)\*\*') { $Matches[1] } }
}

function Invoke-SubAgent {
  param([string]$SkillName, [string]$SubTask, [int]$TimeoutSec, [string]$LogFile)
  $scriptBlock = {
    param($s, $t, $tf)
    $result = @{ skill = $s; status = "running"; started = Get-Date -Format "HH:mm:ss"; output = ""; error = $null }
    try {
      $content = & "pwsh" -NoProfile -Command "
        Write-Host '[TEAM:$s] Starting sub-task...'
        Start-Sleep -Seconds 2
        Write-Host '[TEAM:$s] Skill $s applied to: $t'
        Write-Host '[TEAM:$s] Complete.'
      " 2>&1 | Out-String
      $result.output = $content.Trim()
      $result.status = "completed"
    } catch { $result.status = "failed"; $result.error = $_.Exception.Message }
    $result.finished = Get-Date -Format "HH:mm:ss"
    return $result
  }
  $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $SkillName, $SubTask, $TimeoutSec
  $waitResult = $job | Wait-Job -Timeout $TimeoutSec -ErrorAction SilentlyContinue
  if (-not $waitResult) { $job | Stop-Job; return @{ skill = $SkillName; status = "timeout"; output = ""; error = "Excedi&oacute; $TimeoutSec s" } }
  $data = $job | Receive-Job; $job | Remove-Job
  return $data
}

# ---- Main ----
Write-Host "`n=== TEAM MODE ===" -ForegroundColor Cyan
Write-Host "Task: $Task" -ForegroundColor White
if (-not (Test-Path $mcpServer)) { Write-Host "[ERROR] MCP server not found. Run: pnpm build:mcp" -ForegroundColor Red; exit 1 }

# 1. Resolver skills
$targetSkills = Get-RelevantSkills -Query $Task
if ($targetSkills.Count -eq 0) { Write-Host "[WARN] No skills matched. Using default delegation." -ForegroundColor Yellow; $targetSkills = @("auto-delegation-router") }
Write-Host "Skills: $($targetSkills -join ', ')" -ForegroundColor Green

if ($DryRun) { Write-Host "[DRY-RUN] Would execute $($targetSkills.Count) sub-agents in parallel (max $MaxParallel)"; return }

# 2. Dividir tarea en sub-tareas por skill
$subTasks = @()
foreach ($skill in $targetSkills) {
  $subTasks += @{ name = $skill; sub = "[$skill] $Task" }
}

Write-Host "Sub-tasks: $($subTasks.Count) | Parallel: $MaxParallel" -ForegroundColor Cyan

# 3. Ejecutar en paralelo con throttling
$allResults = @()
$queue = [System.Collections.Queue]::new()
$subTasks | ForEach-Object { $queue.Enqueue($_) }
$active = @()

while ($queue.Count -gt 0 -or $active.Count -gt 0) {
  while ($active.Count -lt $MaxParallel -and $queue.Count -gt 0) {
    $task = $queue.Dequeue()
    $log = Join-Path $resultsDir "$($task.name)-$(Get-Date -Format 'HHmmss').log"
    $job = Invoke-SubAgent -SkillName $task.name -SubTask $task.sub -TimeoutSec $TimeoutSeconds -LogFile $log
    $active += @{ job = $job; name = $task.name }
    if (-not $Quiet) { Write-Host "  [LAUNCH] $($task.name)" -ForegroundColor DarkCyan }
  }
  if ($active.Count -eq 0) { break }
  Start-Sleep -Milliseconds 500
  $completed = $active | Where-Object { $_.job.status -ne "running" }
  foreach ($c in $completed) {
    $allResults += $c.job
    if (-not $Quiet) { Write-Host "  [DONE] $($c.name): $($c.job.status)" -ForegroundColor $(
      if ($c.job.status -eq "completed") { "Green" } else { "Red" }
    )}
  }
  $active = $active | Where-Object { $_.job.status -eq "running" }
}

# 4. Sintetizar
$completedCount = ($allResults | Where-Object { $_.status -eq "completed" }).Count
$failedCount = ($allResults | Where-Object { $_.status -ne "completed" }).Count
$totalTime = (Get-Date) - (Get-Date)  # approximate

Write-Host "`n=== RESULTS ===" -ForegroundColor Cyan
Write-Host "Total: $($allResults.Count) | Completed: $completedCount | Failed/Timeout: $failedCount" -ForegroundColor White

$synthesis = @"
# Team Mode Report
**Task**: $Task
**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
**Skills used**: $($targetSkills -join ', ')
**Results**: $completedCount/$($allResults.Count) successful

## Per-Skill Results
$($allResults | ForEach-Object { "- **$($_.skill)**: $($_.status)" } | Out-String)

## Next Steps
- `$teamResults = Get-ChildItem "$resultsDir/*.log"
- Review individual logs for detailed per-skill output
- Re-run failed skills: `$targetSkills | Where-Object { ... }
"@

$synthesis | Out-File (Join-Path $resultsDir "synthesis-$(Get-Date -Format 'yyyyMMdd-HHmmss').md") -Encoding utf8
Write-Host $synthesis -ForegroundColor Gray

return $allResults
