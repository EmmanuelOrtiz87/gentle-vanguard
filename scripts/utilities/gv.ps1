#!/usr/bin/env pwsh

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wfPath = Join-Path $scriptDir 'WORKFLOW-ORCHESTRATION\gv.ps1'

if (-not (Test-Path $wfPath)) {
	Write-Error "Canonical gv entrypoint not found: $wfPath"
	exit 1
}

& $wfPath @args
exit $LASTEXITCODE
