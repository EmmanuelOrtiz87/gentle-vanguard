<#
.SYNOPSIS
    Judgment Day — Redirect to WORKFLOW-ORCHESTRATION implementation

.DESCRIPTION
    This script has been superseded by the full implementation at:
    scripts/utilities/WORKFLOW-ORCHESTRATION/judgment-day.ps1

    It delegates to the new implementation for backward compatibility.
    All new development should use the WORKFLOW-ORCHESTRATION version.

    The new implementation follows the full adversarial dual-review protocol:
      Phase 1 — Judge A (security + quality) + Judge B (governance + structure)
      Phase 2 — Synthesize findings (Confirmed / Suspect / Contradiction)
      Phase 3 — Fix cycle with Fix Agent
      Phase 4 — Re-judgment after fixes
      Phase 5 — Iteration with escalation

.PARAMETER Target
    Path or scope to review

.PARAMETER MaxPasses
    Maximum judgment passes (default: 3)

.PARAMETER Scope
    Full or Quick

.PARAMETER NoPrompt
    Skip interactive prompts
#>

param(
    [string]$Target = ".",
    [ValidateRange(1, 10)]
    [int]$MaxPasses = 3,
    [ValidateSet('Full', 'Quick')]
    [string]$Scope = 'Full',
    [switch]$NoPrompt
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$newScript = Join-Path $repoRoot 'scripts\utilities\WORKFLOW-ORCHESTRATION\judgment-day.ps1'

if (-not (Test-Path $newScript)) {
    Write-Host "[ERROR] New judgment-day.ps1 not found at WORKFLOW-ORCHESTRATION" -ForegroundColor Red
    Write-Host "[ERROR] Run 'wf verify' to restore the component" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Delegating to WORKFLOW-ORCHESTRATION judgment-day.ps1 (v2.0)" -ForegroundColor DarkGray
& $newScript -Target $Target -MaxPasses $MaxPasses -Scope $Scope -NoPrompt:$NoPrompt
exit $LASTEXITCODE
