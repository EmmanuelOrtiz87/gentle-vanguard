<#
.SYNOPSIS
    Session manager stub — delegates to session-cleanup-start.ts (or .ps1 fallback)
.DESCRIPTION
    This is a thin proxy created during Phase 1 cleanup (2026-07-10).
    The original session-manager.ps1 was a wrapper; this stub preserves the
    entry point while delegating to the real implementation.
#>
param(
    [string]$Mode = "AutoStart",
    [string]$TimeZone = "",
    [switch]$Quiet
)

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$targetTs = Join-Path $repoRoot "src\session-cleanup-start.ts"
$targetPs1 = Join-Path $MyInvocation.MyCommand.Path "..\session\session-cleanup-start.ps1"

if (Test-Path $targetTs) {
    $args = @()
    if ($Mode) { $args += "-Mode"; $args += $Mode }
    if ($TimeZone) { $args += "-TimeZone"; $args += $TimeZone }
    if ($Quiet) { $args += "-Quiet" }
    & npx tsx $targetTs @args
} elseif (Test-Path $targetPs1) {
    $args = @()
    if ($Mode) { $args += "-Mode"; $args += $Mode }
    if ($TimeZone) { $args += "-TimeZone"; $args += $TimeZone }
    if ($Quiet) { $args += "-Quiet" }
    & $targetPs1 @args
} else {
    Write-Warning "[session-manager] target not found: $targetTs or $targetPs1"
}
