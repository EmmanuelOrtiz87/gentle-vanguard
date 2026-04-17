param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'
$legacyScript = Join-Path $PSScriptRoot '..\optional\run-gga.ps1'

if (-not (Test-Path $legacyScript)) {
    Write-Error "Compatibility launcher not found: $legacyScript"
    exit 1
}

& $legacyScript @Args
exit $LASTEXITCODE
