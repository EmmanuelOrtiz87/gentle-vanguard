param(
    [switch]$Fix,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$script:ValidationErrors = @()

function Write-Info {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message -ForegroundColor White }
}

function Write-Fix {
    param([string]$Message)
    if (-not $Quiet) { Write-Host "[FIX] $Message" -ForegroundColor Yellow }
}

function Write-Pass {
    param([string]$Message)
    if (-not $Quiet) { Write-Host "[PASS] $Message" -ForegroundColor Green }
}

function Write-Fail {
    param([string]$Message)
    if (-not $Quiet) { Write-Host "[FAIL] $Message" -ForegroundColor Red }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$patterns = @('*.ps1', '*.psm1')

$count = 0
$scanned = 0

Get-ChildItem -Path $repoRoot -Include $patterns -Recurse -File | Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\node_modules\\'
} | ForEach-Object {
    $scanned++
    $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { return }

    if ($content -match '@"[\s\S]*?\[(OK|ERROR|FAIL|PASS|WARN)\][\s\S]*?"@') {
        $count++
        continue
    }

    $lineNum = 0
    $lines = $content -split "`r?`n"
    $totalLines = $lines.Length

    $hasError = $false
    for ($i = 0; $i -lt $totalLines; $i++) {
        $line = $lines[$i]
        $lineNum = $i + 1

        if ($line -match '^\s*\[(OK|ERROR|FAIL|PASS|WARN)\]\s+\w+') {
            $script:ValidationErrors += [ordered]@{
                file = $_.Name
                line = $lineNum
                issue = "Pattern '[$($matches[1])]' at start of line - use Write-Host or here-string"
            }
            Write-Fail "$($_.Name):$lineNum"
            $hasError = $true
        }
    }

    if (-not $hasError) { $count++ }
}

Write-Info "Scanned: $scanned scripts"

if ($script:ValidationErrors.Count -gt 0) {
    $script:ValidationErrors | ForEach-Object { Write-Fail "$($_.file):$($_.line) - $($_.issue)" }
    Write-Fail "Found $($script:ValidationErrors.Count) parser error patterns"
    exit 1
}

Write-Output "[OK] Script governance validation passed"
exit 0