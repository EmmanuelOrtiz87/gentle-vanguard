param(
    [switch]$AutoFix,
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

if (-not $repoRoot) {
    $repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $repoRoot = (Resolve-Path (Join-Path $repoRoot '..')).Path
}

$script:Issues = @()
$script:Fixed = @()

function Write-Check {
    param([string]$Message)
    Write-Host "[CHECK] $Message" -ForegroundColor Cyan
}

function Write-Fix {
    param([string]$Message)
    Write-Host "[FIX] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Write-Pass {
    param([string]$Message)
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Test-ParserErrors {
    param([string]$Path)
    $errors = $null
    try {
        [System.Management.Automation.Language.Parser]::ParseFile(
            $Path,
            [ref]$null,
            [ref]$errors
        ) | Out-Null
        return $errors.Count -eq 0
    } catch {
        return $false
    }
}

function Test-PatternErrors {
    param([string]$Path, [string]$Content)

    $lines = $Content -split "`r?`n"
    $totalLines = $lines.Length
    $hasError = $false

    for ($i = 0; $i -lt $totalLines; $i++) {
        $line = $lines[$i]
        $lineNum = $i + 1

        if ($line -match '^\s*\[(OK|ERROR|FAIL|PASS|WARN)\]\s+\w+') {
            $script:Issues += [ordered]@{
                file = Split-Path -Leaf $Path
                line = $lineNum
                issue = "Parser-breaking pattern '[$($matches[1])]' at start of line"
                fullLine = $line.Trim()
            }
            $hasError = $true
        }
    }

    return -not $hasError
}

function Invoke-AutoFix {
    param([string]$Path, [string]$Content)

    $fixed = $Content
    $lines = $fixed -split "`r?`n"
    $newLines = @()

    foreach ($line in $lines) {
        if ($line -match '^\s*\[(OK|ERROR|FAIL|PASS|WARN)\]\s+\w+') {
            $newLine = $line -replace '^(\s*)(\[)(OK|ERROR|FAIL|PASS|WARN)(\])', '$1[# $3]$4'
            $script:Fixed += [ordered]@{
                file = Split-Path -Leaf $Path
                original = $line.Trim()
                fixed = $newLine.Trim()
            }
            $newLines += $newLine
        } else {
            $newLines += $line
        }
    }

    $fixed = $newLines -join "`n"
    Set-Content -Path $Path -Value $fixed -Encoding UTF8 -NoNewline

    return $fixed
}

$patterns = @('*.ps1', '*.psm1')
$scanned = 0
$passed = 0

Set-Location $repoRoot
Write-Check "Scanning PowerShell scripts in $repoRoot..."

Get-ChildItem -Path $repoRoot -Include $patterns -Recurse -File | Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\node_modules\\'
} | ForEach-Object {
    $scanned++
    $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue

    if (-not $content) { return }

    if ($content -match '@"[\s\S]*?\[(OK|ERROR|FAIL|PASS|WARN)\][\s\S]*?"@') {
        $passed++
        return
    }

    $parserOk = Test-ParserErrors -Path $_.FullName
    if (-not $parserOk) {
        Write-Fail "$($_.Name): Parser error detected"
    }

    $patternOk = Test-PatternErrors -Path $_.FullName -Content $content
    if (-not $patternOk) {
        Write-Fail "$($_.Name): Pattern error detected ($(Get-Content $_.FullName -ReadCount 0) lines)"
    }

    if ($patternOk -and $parserOk) { $passed++ }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Pre-Push Validation Summary" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Scanned: $scanned scripts"
Write-Host "Passed:  $passed scripts"
Write-Host "Issues:  $($script:Issues.Count) issues found"

if ($script:Issues.Count -gt 0) {
    Write-Host ""
    Write-Host "DETAILS:" -ForegroundColor Yellow
    $script:Issues | ForEach-Object {
        Write-Host "  $($_.file):$($_.line) - $($_.issue)" -ForegroundColor Yellow
    }

    if ($AutoFix) {
        Write-Host ""
        Write-Host "Attempting auto-fix..." -ForegroundColor Cyan

        $byFile = $script:Issues | Group-Object file
        foreach ($group in $byFile) {
            $file = $group.Name
            $path = Get-ChildItem -Path $repoRoot -Filter $file -Recurse | Select-Object -First 1

            if ($path) {
                $content = Get-Content -path.FullName -Raw -Encoding UTF8
                $fixed = Invoke-AutoFix -Path $path.FullName -Content $content
                Write-Fix "Auto-fixed $file"
            }
        }

        if ($script:Fixed.Count -gt 0) {
            Write-Host ""
            Write-Host "Fixed $($script:Fixed.Count) patterns" -ForegroundColor Green

            if ($Strict) {
                Write-Host ""
                Write-Host "Run git diff to review changes" -ForegroundColor Cyan
                exit 1
            }
        }
    }

    Write-Host ""
    Write-Host "RECOMMENDATION:" -ForegroundColor Red
    Write-Host "  Run: .\scripts\diagnostics\validate-script-governance.ps1 -Fix" -ForegroundColor Cyan
    Write-Host "  Or:  sed -i 's/^\[OK\]/[# OK]/g' scripts/**/*.ps1" -ForegroundColor Cyan

    if ($Strict) {
        Write-Host ""
        Write-Fail "BLOCKED: Fix issues before pushing"
        exit 1
    }
}

if ($passed -eq $scanned) {
    Write-Host ""
    Write-Pass "All scripts validated successfully"
    exit 0
}

exit 0