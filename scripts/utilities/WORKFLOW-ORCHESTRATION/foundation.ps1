# foundation.ps1 - Main CLI Wrapper (v2.1+)
# Replaces 'wf' command to avoid Windows Defender Firewall conflicts
# Delegates to wf.ps1 orchestration engine

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments = @()
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wfScript = Join-Path $scriptDir 'wf.ps1'

# Forward all arguments to wf.ps1
& $wfScript @Arguments
