<#
.SYNOPSIS
  Notify team that Codex/Windsurf optimized profile is active.
#>

[CmdletBinding()]
param(
    [string]$Reason = "Codex/Windsurf optimization profile active",
    [string]$Details = "Temporary optimization enabled: strict local-first context, safer approvals, reduced indexing noise.",
    [switch]$Silent
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$notifyScript = Join-Path $repoRoot 'scripts\utilities\notify-user.ps1'
$recovery = 'pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-codex-windsurf-profile.ps1 -Mode Status'

if (-not (Test-Path $notifyScript)) {
    if (-not $Silent) {
        Write-Host "[INFO] $Reason"
        Write-Host "[INFO] $Details"
        Write-Host "[INFO] Verify: $recovery"
    }
    exit 0
}

try {
    if ($Silent) {
        & $notifyScript -Action 'cleanup' -Reason $Reason -Details $Details -RecoveryCommand $recovery | Out-Null
    } else {
        & $notifyScript -Action 'cleanup' -Reason $Reason -Details $Details -RecoveryCommand $recovery
    }
} catch {
    if (-not $Silent) {
        Write-Host "[WARN] Notification fallback: $Reason" -ForegroundColor Yellow
    }
}

if (-not $Silent) {
    Write-Host '[OK] Codex/Windsurf optimization notification sent.' -ForegroundColor Green
}
