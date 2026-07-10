<#
.SYNOPSIS
    Session manager stub — delegates to session-cleanup-start.ps1
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

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $scriptDir "session\session-cleanup-start.ps1"

if (Test-Path $target) {
    $args = @()
    if ($Mode) { $args += "-Mode"; $args += $Mode }
    if ($TimeZone) { $args += "-TimeZone"; $args += $TimeZone }
    if ($Quiet) { $args += "-Quiet" }
    & $target @args
} else {
    Write-Warning "[session-manager] target not found: $target"
}
