# karpathy-enforcer.ps1
# Canonical entry point — delegates to the real implementation in scripts/adaptive/karpathy-enforcer.ps1
#
# Karpathy Coding Guidelines enforced by this script:
# - Think: Always think step by step before acting. Break down complex problems.
# - Simplicity: Prefer simple solutions. Avoid premature abstraction.
# - Goal-Driven: Every action must serve a clear goal. Define success criteria first.

param(
    [ValidateSet('session-start', 'pre-commit', 'code-review', 'task-complete')]
    [string]$Trigger,
    [switch]$AutoFix,
    [switch]$VerboseOutput
)

$canonical = Join-Path $PSScriptRoot '..' 'adaptive' 'karpathy-enforcer.ps1'
$canonical = Resolve-Path $canonical -ErrorAction Stop

$params = @{}
if ($AutoFix) { $params['AutoFix'] = $true }
if ($VerboseOutput) { $params['VerboseOutput'] = $true }
& $canonical -Trigger $Trigger @params
exit $LASTEXITCODE
