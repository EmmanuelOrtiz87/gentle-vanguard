param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'
$legacyScript = Join-Path $PSScriptRoot '..\optional\run-gentle-ai.ps1'

if (-not (Test-Path $legacyScript)) {
    Write-Error "Compatibility launcher not found: $legacyScript"
    exit 1
}

& $legacyScript @Args
exit $LASTEXITCODE
