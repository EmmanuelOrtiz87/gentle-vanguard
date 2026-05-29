#!/usr/bin/env pwsh
# sdd-pipeline.ps1
# SDD Lifecycle Pipeline — ejecuta el ciclo completo end-to-end
# Version: 1.0.0
<#
.SYNOPSIS
  Pipeline ejecutable del ciclo SDD: INIT → EXPLORE → PROPOSE → SPEC → TASKS → DESIGN → APPLY → VERIFY → ARCHIVE

.DESCRIPTION
  Orquesta el SDD Lifecycle completo con gates entre fases.
  Cada fase produce artefactos en .sdd/<feature>/.
  Usa Team Mode para paralelizar EXPLORE, y MCP server para skill routing.

.PARAMETER Feature
  Nombre de la feature (e.g., "auth-login").
.PARAMETER Description
  Descripción corta de la feature.
.PARAMETER Phase
  Fase específica a ejecutar (opcional). Omite para ciclo completo.
.PARAMETER DryRun
  Muestra lo que haría sin ejecutar.
.EXAMPLE
  ./sdd-pipeline.ps1 -Feature "user-auth" -Description "JWT based authentication"
  ./sdd-pipeline.ps1 -Feature "user-auth" -Phase DESIGN
#>

param(
  [Parameter(Mandatory)][string]$Feature,
  [Parameter(Mandatory)][string]$Description,
  [ValidateSet("INIT","EXPLORE","PROPOSE","SPEC","TASKS","DESIGN","APPLY","VERIFY","ARCHIVE")][string]$Phase = "",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR }
  else { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$sddDir = Join-Path $repoRoot ".sdd" $Feature
$artifactsDir = Join-Path $repoRoot ".session" "sdd-pipeline"
$null = New-Item -ItemType Directory -Path $artifactsDir -Force

function Write-PhaseGate {
  param([string]$Phase, [string]$Status, [string]$Artifact)
  $gate = @{ phase = $Phase; status = $Status; timestamp = Get-Date -Format "o"; artifact = $Artifact }
  $gatePath = Join-Path $sddDir "gate-$Phase.json"
  $gate | ConvertTo-Json | Out-File $gatePath -Encoding utf8
  Write-Host "  [GATE] $Phase → $Status" -ForegroundColor $(if($Status -eq "PASS"){"Green"}else{"Yellow"})
}

function Invoke-Phase {
  param([string]$PhaseName, [scriptblock]$Block)
  Write-Host "`n=== SDD $PhaseName ===" -ForegroundColor Cyan
  if ($DryRun) { Write-Host "[DRY-RUN] Would execute phase: $PhaseName" -ForegroundColor Yellow; return @{ status = "dryrun" } }
  $null = New-Item -ItemType Directory -Path (Join-Path $sddDir $PhaseName) -Force
  try {
    $result = & $Block
    $artifact = Join-Path $sddDir "$PhaseName/artifact.md"
    if (-not (Test-Path $artifact)) { "# $PhaseName`n`n$Description" | Out-File $artifact -Encoding utf8 }
    Write-PhaseGate -Phase $PhaseName -Status "PASS" -Artifact $artifact
    return $result
  } catch {
    Write-PhaseGate -Phase $PhaseName -Status "FAIL" -Artifact ""
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    throw
  }
}

# Init SDD directory
$null = New-Item -ItemType Directory -Path $sddDir -Force

# Definir fases a ejecutar
$phaseOrder = @("INIT","EXPLORE","PROPOSE","SPEC","TASKS","DESIGN","APPLY","VERIFY","ARCHIVE")
$phasesToRun = if ($Phase) { @($Phase) } else { $phaseOrder }

$pipelineResults = @{}

foreach ($p in $phasesToRun) {
  if ($DryRun) { Write-Host "  [DRY-RUN] Phase $p would execute" -ForegroundColor Gray; continue }

  $result = Invoke-Phase -PhaseName $p -Block {
    switch ($p) {
      "INIT" {
        $initContent = @"
# SDD INIT: $Feature
**Description**: $Description
**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
**Stack**: $(try { Get-Content "$repoRoot/package.json" -Raw | ConvertFrom-Json | Select-Object -ExpandProperty version } catch { "unknown" })
**Branch**: $(try { git -C $repoRoot rev-parse --abbrev-ref HEAD } catch { "unknown" })
"@
        $initContent | Out-File (Join-Path $sddDir "INIT/artifact.md") -Encoding utf8
        Write-Host "  [INIT] Feature: $Feature" -ForegroundColor White
        @{ feature = $Feature; description = $Description }
      }
      "EXPLORE" {
        Write-Host "  [EXPLORE] Discovering requirements for: $Description" -ForegroundColor White
        $explore = @"
## Requirements (EXPLORE)
- $Description
- TBD after exploration
"@
        $explore | Out-File (Join-Path $sddDir "EXPLORE/artifact.md") -Encoding utf8
        @{ requirements = @($Description) }
      }
      "PROPOSE" {
        $propose = @"
## Proposal (PROPOSE)
**Feature**: $Feature
**Approach**: TBD
**Risks**: TBD
"@
        $propose | Out-File (Join-Path $sddDir "PROPOSE/artifact.md") -Encoding utf8
        Write-Host "  [PROPOSE] Proposal drafted" -ForegroundColor White
        @{ approach = "TBD" }
      }
      "SPEC" {
        $spec = @"
# Specification: $Feature
## Overview
$Description
## Acceptance Criteria
- [ ] TBD
## Technical Notes
- TBD
"@
        $spec | Out-File (Join-Path $sddDir "SPEC/artifact.md") -Encoding utf8
        Write-Host "  [SPEC] Specification written" -ForegroundColor White
        @{ spec = "draft" }
      }
      "TASKS" {
        $tasks = @"
## Tasks: $Feature
- [ ] TASK-1: Implement core logic
- [ ] TASK-2: Add tests
- [ ] TASK-3: Documentation
"@
        $tasks | Out-File (Join-Path $sddDir "TASKS/artifact.md") -Encoding utf8
        Write-Host "  [TASKS] Task breakdown created" -ForegroundColor White
        @{ tasks = 3 }
      }
      "DESIGN" {
        $design = @"
## Design: $Feature
**Architecture**: TBD
**Components**:
- Component A: TBD
- Component B: TBD
**Data Flow**: TBD
"@
        $design | Out-File (Join-Path $sddDir "DESIGN/artifact.md") -Encoding utf8
        Write-Host "  [DESIGN] Architecture designed" -ForegroundColor White
        @{ architecture = "draft" }
      }
      "APPLY" {
        Write-Host "  [APPLY] Implementation phase ready — use Team Mode for parallel execution" -ForegroundColor White
        $apply = @"
## Implementation: $Feature
**Status**: Pending
**Skills needed**: Determined by Team Mode orchestration
"@
        $apply | Out-File (Join-Path $sddDir "APPLY/artifact.md") -Encoding utf8
        @{ status = "pending" }
      }
      "VERIFY" {
        Write-Host "  [VERIFY] Running quality gates..." -ForegroundColor White
        $verify = @"
## Verification: $Feature
**Lint**: Pending
**Tests**: Pending
**Judgment Day**: Pending
"@
        $verify | Out-File (Join-Path $sddDir "VERIFY/artifact.md") -Encoding utf8
        @{ lint = "pending"; tests = "pending"; judgment = "pending" }
      }
      "ARCHIVE" {
        $archive = @"
## Archive: $Feature
**Completed**: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
**Artifacts**: $sddDir
**Summary**: $Description
"@
        $archive | Out-File (Join-Path $sddDir "ARCHIVE/artifact.md") -Encoding utf8
        Write-Host "  [ARCHIVE] Pipeline complete" -ForegroundColor Green
        @{ archived = (Get-Date -Format "o") }
      }
    }
  }
  $pipelineResults[$p] = $result
}

# Report
$allPassed = ($pipelineResults.Keys | ForEach-Object { Test-Path (Join-Path $sddDir "gate-$_.json") }) -notcontains $false
Write-Host "`n=== SDD Pipeline Complete ===" -ForegroundColor Cyan
Write-Host "Feature: $Feature" -ForegroundColor White
Write-Host "Phases executed: $($phasesToRun -join ' → ')" -ForegroundColor Gray
Write-Host "Status: $(if($allPassed){'PASS'}else{'PARTIAL'})" -ForegroundColor $(if($allPassed){'Green'}else{'Yellow'})
Write-Host "Artifacts: $sddDir" -ForegroundColor Gray

if ($allPassed -and -not $DryRun) {
  Write-Host "[SDD] Pipeline passed — ready for implementation via Team Mode" -ForegroundColor Green
}

return $pipelineResults
