# foundation.ps1 - Canonical CLI (v2.11+)
# Replaces 'wf' to avoid conflict with Windows Filtering Platform (wf.exe)
# Delegates to wf.ps1 orchestration engine (internal, do not call directly)

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments = @()
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wfScript = Join-Path $scriptDir 'wf.ps1'

if (-not (Test-Path $wfScript)) {
    Write-Error "Internal error: wf.ps1 not found at $wfScript"
    exit 1
}

# Forward all arguments to internal wf.ps1 engine
& $wfScript @Arguments
