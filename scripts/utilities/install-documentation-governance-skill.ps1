param(
    [string]$SourceRoot = $(Join-Path $PSScriptRoot '..'),
    [string]$SkillName = 'documentation-governance'
)

$ErrorActionPreference = 'Stop'

$skillSource = Join-Path $SourceRoot "skills\$SkillName"
if (-not (Test-Path -LiteralPath $skillSource)) {
    throw "Skill source not found: $skillSource"
}

$codeXHome = $env:CODEX_HOME
if ([string]::IsNullOrWhiteSpace($codeXHome)) {
    $codeXHome = Join-Path $HOME '.codex'
}

$destination = Join-Path $codeXHome "skills\$SkillName"
$destinationParent = Split-Path -Parent $destination
if (-not (Test-Path -LiteralPath $destinationParent)) {
    New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
}

if (Test-Path -LiteralPath $destination) {
    Remove-Item -LiteralPath $destination -Recurse -Force
}

Copy-Item -LiteralPath $skillSource -Destination $destination -Recurse -Force
Write-Host "Installed $SkillName to $destination"
Write-Host "Restart Codex to pick up the new skill."
