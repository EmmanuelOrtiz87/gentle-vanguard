<#
.SYNOPSIS
    Token usage notifier — delegates to token-metrics-store.ps1
.DESCRIPTION
    Thin proxy that preserves the entry point for session-autostart config
    while delegating to the canonical token metrics implementation.
#>
param(
    [string]$Action = "init",
    [switch]$Quiet
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $scriptDir "token\token-metrics-store.ps1"

if (Test-Path $target) {
    if ($Quiet) {
        & $target -Action $Action -Quiet
    } else {
        & $target -Action $Action
    }
} else {
    Write-Warning "[token-usage-notifier] target not found: $target"
}
