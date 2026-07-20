<#
.SYNOPSIS
    Auth session stub — disabled by design in session-autostart.config.json
.DESCRIPTION
    Auth is demand-driven, not session-start. This stub exists solely so the
    config path resolves without error. The step is disabled (enabled: false).
#>
param([switch]$Quiet)

if (-not $Quiet) {
    Write-Host "[auth-session] Stub: auth-session is disabled in pipeline config. Skipping."
}
