param(
    [string]$SourceRoot = $(Join-Path $PSScriptRoot '..')
)

$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
$docsScript = Join-Path $scriptDir 'install-documentation-governance-skill.ps1'
$archScript = Join-Path $scriptDir 'install-architecture-governance-skill.ps1'

if (-not (Test-Path -LiteralPath $docsScript)) {
    throw "Missing installer: $docsScript"
}
if (-not (Test-Path -LiteralPath $archScript)) {
    throw "Missing installer: $archScript"
}

& $docsScript -SourceRoot $SourceRoot
& $archScript -SourceRoot $SourceRoot

Write-Host "Installed workspace skills. Restart Codex to pick up the new skills."
