<#
.SYNOPSIS
    Token usage notifier stub — delegates to token-metrics-store.ps1
.DESCRIPTION
    Thin proxy created during Phase 1 cleanup (2026-07-10).
    Preserves the entry point for session-autostart config while delegating
    to the canonical token metrics implementation.
#>
param(
    [string]$Action = "init",
    [switch]$Quiet
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $scriptDir "token\token-metrics-store.ps1"

if (Test-Path $target) {
    $invokeArgs = @()
    if ($Action) { $invokeArgs += "-Action"; $invokeArgs += $Action }
    if ($Quiet) { $invokeArgs += "-Quiet" }
    & $target @invokeArgs
} else {
    Write-Warning "[token-usage-notifier] target not found: $target"
}
