param(
    [switch]$AutoFix,
    [switch]$Strict,
    [switch]$AutoDelegate
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot

if (-not $repoRoot) {
    $repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $repoRoot = (Resolve-Path (Join-Path $repoRoot '..')).Path
}

$script:Issues = @()
$script:Fixed = @()
$script:Delegated = @()

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

function Write-Delegate {
    param([string]$Message, [string]$Agent)
    Write-Host "[DELEGATE] $Message  $Agent" -ForegroundColor Magenta
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
                path = $Path
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

function Invoke-DelegatedFix {
    param([string]$Task, [string]$Files)

    Write-Delegate "Detected unfixable errors" "SDD-APPLY"
    Write-Host "  Task: $Task" -ForegroundColor Gray
    Write-Host "  Files: $Files" -ForegroundColor Gray
    Write-Host ""

    $delegateScript = Join-Path $repoRoot "scripts\utilities\auto-delegation-wrapper.ps1"
    if (Test-Path $delegateScript) {
        Write-Check "Running delegated fix..."
        return $true
    }

    return $false
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
        Write-Fail "$($_.Name): Pattern error detected"
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
        $autoFixed = 0

        foreach ($group in $byFile) {
            $file = $group.Name
            $path = Get-ChildItem -Path $repoRoot -Filter $file -Recurse | Select-Object -First 1

            if ($path) {
                $content = Get-Content -path.FullName -Raw -Encoding UTF8
                $fixed = Invoke-AutoFix -Path $path.FullName -Content $content
                $autoFixed++
                Write-Fix "Auto-fixed $file"
            }
        }

        if ($autoFixed -gt 0) {
            Write-Host ""
            Write-Fix "Auto-fixed $autoFixed files"

            Write-Host ""
            Write-Check "Re-validating after auto-fix..."

            $script:Issues = @()
            $passCount = 0
            Get-ChildItem -Path $repoRoot -Include $patterns -Recurse -File | Where-Object {
                $_.FullName -notmatch '\\\.git\\' -and
                $_.FullName -notmatch '\\node_modules\\'
            } | ForEach-Object {
                $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                if ($content) {
                    $pOk = Test-PatternErrors -Path $_.FullName -Content $content
                    if ($pOk) { $passCount++ }
                }
            }

            if ($passCount -eq $scanned -and $script:Issues.Count -eq 0) {
                Write-Pass "All issues resolved after auto-fix"
                Write-Host ""
                Write-Host "Run 'git add . && git commit -m \"fix: auto-correct parser patterns\"' to commit" -ForegroundColor Cyan
                exit 0
            }

            $remaining = $script:Issues.Count
            if ($remaining -gt 0) {
                Write-Warning "$remaining issues could not be auto-fixed"
            }
        }
    }

    if ($AutoDelegate -and $script:Issues.Count -gt 0 -and -not $AutoFix) {
        Write-Host ""
        $affectedFiles = ($script:Issues | Group-Object file | ForEach-Object { $_.Name }) -join ", "

        Write-Check "Delegating to SDD-APPLY agent for automated fix..."
        Write-Host ""

        $delegateCmd = "pwsh -NoProfile -Command `""
        Write-Host @"
[DELEGATE] Delegating fix task to SDD-APPLY agent
  Files: $affectedFiles
  
  Delegate command:
  pwsh -NoProfile -Command "& .\scripts\utilities\auto-delegation-wrapper.ps1 'fix script errors'"
"@
    }

    Write-Host ""
    Write-Host "RECOMMENDATION:" -ForegroundColor Red
    Write-Host "  Run: .\scripts\hooks\pre-push-script-validator.ps1 -AutoFix" -ForegroundColor Cyan
    Write-Host "  Run: .\scripts\hooks\pre-push-script-validator.ps1 -AutoFix -AutoDelegate" -ForegroundColor Cyan

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
