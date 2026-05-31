#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Cross-component health check for Gentle-Vanguard platform
.DESCRIPTION
  Verifies MCP server, Team Mode, Session Reference System, Skill Factory,
  SDD Pipeline, pnpm config, and lefthook hooks are all functional.
  Exit code = number of failed checks (0 = all pass).
.PARAMETER Component
  Single component to check (mcp|team|session|factory|sdd|pnpm|lefthook|all)
  Default: all
.PARAMETER Quiet
  Only output failures, no success messages
.EXAMPLE
  ./health-check.ps1
  ./health-check.ps1 -Component mcp
#>

param(
  [ValidateSet("mcp","team","session","factory","sdd","pnpm","lefthook","optimization","gateguard","costtracking","all")]
  [string]$Component = "all",
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$script:exitCode = 0
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Write-Check {
  param([string]$Name, [bool]$Passed, [string]$Detail)
  if (-not $Quiet -or -not $Passed) {
    $icon = if ($Passed) { "[PASS]" } else { "[FAIL]" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "$icon $Name" -ForegroundColor $color
    if ($Detail) { Write-Host "       $Detail" -ForegroundColor Gray }
  }
  if (-not $Passed) { $script:exitCode++ }
}

function Get-ExitCode { $script:exitCode }

function Check-Mcp {
  Write-Host "`n=== MCP Server ===" -ForegroundColor Cyan
  $mcpJs = Join-Path $root "dist/scripts/mcp/skill-server.js"
  $mcpTs = Join-Path $root "scripts/mcp/skill-server.ts"

  Write-Check "MCP JS exists" (Test-Path $mcpJs) "dist/scripts/mcp/skill-server.js"
  Write-Check "MCP TS exists" (Test-Path $mcpTs) "scripts/mcp/skill-server.ts"

  if (-not (Test-Path $mcpJs)) { return }

  $tsOk = $false
  if (Get-Command "pnpm" -ErrorAction SilentlyContinue) {
    $null = & "pnpm" "tsc" "--noEmit" 2>&1
    $tsOk = $LASTEXITCODE -eq 0
  }
  Write-Check "MCP TS compiles clean" $tsOk

  try {
    $result = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | & "node" $mcpJs 2>&1 | & "node" -e @"
const d=[];process.stdin.on('data',c=>d.push(c));
process.stdin.on('end',()=>{
  try {
    const r=JSON.parse(d.join(''));
    const tools=r.result?.tools||[];
    console.log(tools.length);
  } catch(e) { console.log('ERROR:'+e.message); }
});
"@
    $toolsCount = 0
    if ($result -match '^\d+$') { $toolsCount = [int]$result }
    Write-Check "MCP tools/list responds" ($toolsCount -gt 0) "$toolsCount tools"
    if ($toolsCount -gt 0 -and $result -match 'list_skills') { $toolsCount = 999 }
  } catch {
    Write-Check "MCP tools/list responds" $false $_.Exception.Message
  }
}

function Check-TeamMode {
  Write-Host "`n=== Team Mode ===" -ForegroundColor Cyan
  $scriptPath = Join-Path $root "scripts/team-mode/team-orchestrator.ps1"
  Write-Check "Team Mode script exists" (Test-Path $scriptPath) "scripts/team-mode/team-orchestrator.ps1"
  if (-not (Test-Path $scriptPath)) { return }
  $result = & $scriptPath -Task "health check" -MaxParallel 1 -TimeoutSeconds 5 2>&1
  $exitOk = $LASTEXITCODE -eq 0 -or ($LASTEXITCODE -eq $null)
  Write-Check "Team Mode dry-run passes" $exitOk
}

function Check-SessionRef {
  Write-Host "`n=== Session Reference System ===" -ForegroundColor Cyan
  $scriptPath = Join-Path $root "scripts/utilities/SESSION/session-reference-system.ps1"
  Write-Check "Session Ref script exists" (Test-Path $scriptPath)
}

function Check-SkillFactory {
  Write-Host "`n=== Skill Factory ===" -ForegroundColor Cyan
  $scriptPath = Join-Path $root "scripts/utilities/SKILL-FACTORY/skill-factory.ps1"
  Write-Check "Skill Factory exists" (Test-Path $scriptPath)
  $regPath = Join-Path $root ".atl/skill-registry.md"
  Write-Check "Skill registry exists" (Test-Path $regPath)
  if (Test-Path $regPath) {
    $lines = (Get-Content $regPath).Count
    Write-Check "Registry has entries" ($lines -gt 5) "$lines lines"
  }
}

function Check-Sdd {
  Write-Host "`n=== SDD Pipeline ===" -ForegroundColor Cyan
  $scriptPath = Join-Path $root "scripts/sdd-pipeline/sdd-pipeline.ps1"
  Write-Check "SDD Pipeline exists" (Test-Path $scriptPath)
  if (Test-Path $scriptPath) {
    $result = & $scriptPath -Feature "health-check" -Description "Health check" -DryRun 2>&1
    $exitOk = $LASTEXITCODE -eq 0 -or ($LASTEXITCODE -eq $null)
    Write-Check "SDD Pipeline dry-run passes" $exitOk
  }
}

function Check-Pnpm {
  Write-Host "`n=== pnpm Security ===" -ForegroundColor Cyan
  $lockfile = Join-Path $root "pnpm-lock.yaml"
  $nrmFile = Join-Path $root "rules/NORMATIVA-PNPM-SECURITY.md"
  Write-Check "pnpm-lock.yaml exists" (Test-Path $lockfile)
  Write-Check "pnpm security normativa exists" (Test-Path $nrmFile)
  if (Get-Command "pnpm" -ErrorAction SilentlyContinue) {
    $v = & "pnpm" "--version" 2>&1
    Write-Check "pnpm installed" $true "v$v"
  } else {
    Write-Check "pnpm installed" $false
  }
}

function Check-OptimizationStack {
  Write-Host "`n=== Optimization Stack ===" -ForegroundColor Cyan
  $verifyPath = Join-Path $root "scripts/validation/verify-optimization-stack.ps1"
  if (-not (Test-Path $verifyPath)) { Write-Check "verify-optimization-stack.ps1 exists" $false; return }
  $null = & $verifyPath -Quiet 2>&1
  Write-Check "Optimization stack (8 rules)" ($LASTEXITCODE -eq 0)
}

function Check-Lefthook {
  Write-Host "`n=== Lefthook Hooks ===" -ForegroundColor Cyan
  $hookFiles = @(
    ".lefthook.yml",
    "config/lefthook.yml"
  )
  $found = $false
  foreach ($f in $hookFiles) {
    $p = Join-Path $root $f
    if (Test-Path $p) { $found = $true; Write-Check "lefthook config" $true $f; break }
  }
  if (-not $found) { Write-Check "lefthook config" $false }
}

function Check-GateGuard {
  Write-Host "`n=== GateGuard ===" -ForegroundColor Cyan
  $scriptPath = Join-Path $root "scripts/gateguard/gateguard-mcp.ps1"
  Write-Check "GateGuard script exists" (Test-Path $scriptPath) "scripts/gateguard/gateguard-mcp.ps1"
  if (-not (Test-Path $scriptPath)) { return }
  try {
    $result = & $scriptPath -Server codegraph 2>&1
    $resultJson = ($result | Where-Object { $_ -is [string] }) -join "`n"
    if ([string]::IsNullOrWhiteSpace($resultJson)) { throw "No JSON response from GateGuard" }
    $parsed = $resultJson | ConvertFrom-Json -ErrorAction Stop
    $serverStatus = $parsed.Status
    $detail = "server=$serverStatus latency=$($parsed.LatencyMs)ms"
    Write-Check "GateGuard responds" $true $detail
  } catch {
    Write-Check "GateGuard responds" $false $_.Exception.Message
  }
}

function Check-CostTracking {
  Write-Host "`n=== Cost Tracking ===" -ForegroundColor Cyan
  $routingConfig = Join-Path $root "config/model-routing.json"
  if (-not (Test-Path $routingConfig)) { Write-Check "model-routing.json exists" $false; return }
  Write-Check "model-routing.json exists" $true
  try {
    $config = Get-Content $routingConfig -Raw | ConvertFrom-Json
    $hasCostTracking = $null -ne $config.cost_tracking
    $hasRoutingThresholds = $null -ne $config.routing_thresholds
    Write-Check "cost_tracking section present" $hasCostTracking
    Write-Check "routing_thresholds section present" $hasRoutingThresholds
  } catch {
    Write-Check "cost_tracking section present" $false $_.Exception.Message
    Write-Check "routing_thresholds section present" $false
  }
}

switch ($Component) {
  "mcp" { Check-Mcp }
  "team" { Check-TeamMode }
  "session" { Check-SessionRef }
  "factory" { Check-SkillFactory }
  "sdd" { Check-Sdd }
  "pnpm" { Check-Pnpm }
  "lefthook" { Check-Lefthook }
  "optimization" { Check-OptimizationStack }
  "gateguard" { Check-GateGuard }
  "costtracking" { Check-CostTracking }
  "all" {
    Check-Mcp
    Check-TeamMode
    Check-SessionRef
    Check-SkillFactory
    Check-Sdd
    Check-Pnpm
    Check-Lefthook
    Check-OptimizationStack
    Check-GateGuard
    Check-CostTracking
  }
}

$ec = Get-ExitCode
Write-Host "`n=== Health Check Complete ===" -ForegroundColor Cyan
Write-Host "Status: $(if($ec -eq 0){'ALL PASS'}else{"$ec FAILURES"})" -ForegroundColor $(if($ec -eq 0){'Green'}else{'Red'})
exit $ec
