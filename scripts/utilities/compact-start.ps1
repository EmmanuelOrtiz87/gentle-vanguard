param(
    [string]$Objective = '',
    [switch]$NoClipboard
)

$ErrorActionPreference = 'Stop'

$contextScript = Join-Path $PSScriptRoot 'context-pack.ps1'
if (-not (Test-Path $contextScript)) {
    Write-Error "Context pack script not found: $contextScript"
    exit 1
}

$contextRaw = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $contextScript -Objective $Objective -PassThru
$contextPath = $null
if ($contextRaw) {
    $candidate = ($contextRaw | Out-String).Trim()
    $match = [regex]::Match($candidate, '[A-Za-z]:\\[^\r\n]*-context-pack\.md')
    if ($match.Success) {
        $contextPath = $match.Value
    }
}
if (-not $contextPath) {
    $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
    $sessionsDir = Join-Path $repoRoot 'docs/sessions'
    $latest = Get-ChildItem -Path $sessionsDir -Filter '*-context-pack.md' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($latest) {
        $contextPath = $latest.FullName
    }
}

if (-not $contextPath) {
    Write-Error 'Unable to resolve context-pack path.'
    exit 1
}

$objectiveLine = if ([string]::IsNullOrWhiteSpace($Objective)) { 'continue current objective' } else { $Objective }
$prompt = @"
Use this context file as source of truth:
$contextPath

Immediate request:
Continue objective: "$objectiveLine".
Keep only the last 5-10 chat messages active.
Avoid repeating long instructions unless they changed.
Apply minimal required changes and validate outcomes.
"@

if (-not $NoClipboard) {
    $setClipboard = Get-Command Set-Clipboard -ErrorAction SilentlyContinue
    if ($setClipboard) {
        $prompt | Set-Clipboard
        Write-Host '[OK] Compact prompt copied to clipboard.' -ForegroundColor Green
    }
}

Write-Host ''
Write-Host '--- Compact Prompt ---' -ForegroundColor Cyan
Write-Host $prompt
Write-Host '----------------------' -ForegroundColor Cyan
