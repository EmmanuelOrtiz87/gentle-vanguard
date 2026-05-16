<#
.SYNOPSIS
  Real-time notification for OpenCode optimization rollout.

.DESCRIPTION
  Uses the existing notify-user pipeline to suggest the optimized OpenCode profile
  in active operations without interrupting workflows.

.EXAMPLE
  pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/notify-opencode-optimization.ps1
#>

[CmdletBinding()]
param(
    [switch]$Silent
)

$ErrorActionPreference = 'Stop'

$repoRoot = if ($env:GV_BASE_DIR -and (Test-Path $env:GV_BASE_DIR)) {
    $env:GV_BASE_DIR
} else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) {
        $root = Split-Path -Parent $root
    }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$notifyScript = Join-Path $repoRoot 'scripts\utilities\notify-user.ps1'

$reason = 'OpenCode optimization profile active (compaction + watcher ignore + granular permissions + step caps)'
$details = 'Recomendado para minimizar contexto, reducir latencia y mejorar control de herramientas en tiempo real.'
$recovery = 'pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/agent-verify.ps1 -Domain config -Json'

if (-not (Test-Path $notifyScript)) {
    Write-Host '[WARN] notify-user.ps1 not found. Fallback message:' -ForegroundColor Yellow
    Write-Host "[INFO] $reason"
    Write-Host "[INFO] Verify: $recovery"
    exit 0
}

if ($Silent) {
    & $notifyScript -Action 'cleanup' -Reason $reason -Details $details -RecoveryCommand $recovery | Out-Null
} else {
    & $notifyScript -Action 'cleanup' -Reason $reason -Details $details -RecoveryCommand $recovery
}

Write-Host '[OK] OpenCode optimization notification sent.' -ForegroundColor Green

