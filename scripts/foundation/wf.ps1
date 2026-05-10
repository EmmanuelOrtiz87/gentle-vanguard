#!/usr/bin/env pwsh
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wfPath = Join-Path $scriptDir '..\utilities\WORKFLOW-ORCHESTRATION\wf.ps1'
if (-not (Test-Path $wfPath)) {
    Write-Error "Canonical wf entrypoint not found: $wfPath"
    exit 1
}
& $wfPath @args
exit $LASTEXITCODE