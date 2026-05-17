# gentle-vanguard.ps1 - Canonical CLI (v2.11+)
# Replaces 'gv' to avoid conflict with Windows Filtering Platform (gv.exe)
# Delegates to gv.ps1 orchestration engine (internal, do not call directly)

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments = @()
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wfScript = Join-Path $scriptDir 'gv.ps1'

if (-not (Test-Path $wfScript)) {
    Write-Error "Internal error: gv.ps1 not found at $wfScript"
    exit 1
}

# Forward all arguments to internal gv.ps1 engine
& $wfScript @Arguments

