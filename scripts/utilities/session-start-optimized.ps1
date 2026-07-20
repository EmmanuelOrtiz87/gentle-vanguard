<#
.SYNOPSIS
    Session start optimized stub - delegates to session/session-start-optimized.ps1
.DESCRIPTION
    Thin proxy created during Phase 1 cleanup (2026-07-10).
    Preserves the flat entry point expected by maintenance-watchtower.
#>
param(
    [string]$Mode = "",
    [switch]$Quiet
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $scriptDir "session\session-start-optimized.ps1"

if (Test-Path $target) {
    $invokeArgs = @()
    if ($Mode) { $invokeArgs += "-Mode"; $invokeArgs += $Mode }
    if ($Quiet) { $invokeArgs += "-Quiet" }
    & $target @invokeArgs
} else {
    Write-Warning "[session-start-optimized] target not found: $target"
}
