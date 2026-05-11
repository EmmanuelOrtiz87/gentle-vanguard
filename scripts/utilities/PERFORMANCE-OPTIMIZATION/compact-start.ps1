param(
    [string]$Objective = '',
    [switch]$NoClipboard
)

$ErrorActionPreference = 'Stop'

function Write-Metric {
    param(
        [string]$Event,
        [string]$Objective,
        [int]$PromptChars,
        [string]$OutputFile
    )

    $repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}
    $metricsDir = Join-Path $repoRoot 'docs/sessions/metrics'
    if (-not (Test-Path $metricsDir)) {
        New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
    }

    $metricsFile = Join-Path $metricsDir 'context-usage.csv'
    if (-not (Test-Path $metricsFile)) {
        'timestamp,event,repository,branch,objective_chars,changed_count,prompt_chars,output_file' | Set-Content -Path $metricsFile -Encoding UTF8
    }

    $branchName = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branchName) { $branchName = '(unknown)' }

    $line = ('{0},{1},{2},{3},{4},{5},{6},{7}' -f
        (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'),
        $Event,
        (Split-Path $repoRoot -Leaf),
        $branchName,
        $Objective.Length,
        0,
        $PromptChars,
        $OutputFile.Replace(',', ';')
    )

    Add-Content -Path $metricsFile -Value $line -Encoding UTF8
}

$contextScript = Join-Path $PSScriptRoot 'context-pack.ps1'
if (-not (Test-Path $contextScript)) {
    Write-Error "Context pack script not found: $contextScript"
    exit 1
}

$contextRaw = & $contextScript -Objective $Objective -PassThru
$contextPath = $null
if ($contextRaw) {
    $candidate = ($contextRaw | Out-String).Trim()
    $matches = [regex]::Matches($candidate, '[A-Za-z]:\\[^\r\n]*\d{4}-\d{2}-\d{2}-\d{6}-context-pack\.md')
    if ($matches.Count -eq 0) {
        $matches = [regex]::Matches($candidate, '[A-Za-z]:\\[^\r\n]*-context-pack\.md')
    }
    if ($matches.Count -gt 0) {
        $contextPath = $matches[$matches.Count - 1].Value
    }
}
if (-not $contextPath) {
    $repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}
    $sessionsDir = Join-Path $repoRoot 'docs/sessions'
    $latest = Get-ChildItem -Path $sessionsDir -Filter '*-context-pack.md' -File -ErrorAction SilentlyContinue |
        Sort-Object @{ Expression = {
            $name = $_.BaseName
            if ($name -match '^(\d{4}-\d{2}-\d{2})-(\d{6})-context-pack$') {
                return "{0}{1}" -f $matches[1], $matches[2]
            }
            if ($name -match '^(\d{4}-\d{2}-\d{2})-(\d{4})-context-pack$') {
                return "{0}{1}" -f $matches[1], $matches[2]
            }
            return $_.LastWriteTime.ToString('yyyyMMddHHmmss')
        }; Descending = $true } |
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
Write-Metric -Event 'compact-start' -Objective $objectiveLine -PromptChars $prompt.Length -OutputFile $contextPath
