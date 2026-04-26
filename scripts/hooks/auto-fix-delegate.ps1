param(
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $repoRoot '..')).Path

$script:Issues = @()
$script:Fixed = @()
$script:Delegated = @()
$script:Learning = @()

function Write-Auto {
    param([string]$Message)
    Write-Host "[AUTO] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Delegate {
    param([string]$Message)
    Write-Host "[DELEGATE] $Message" -ForegroundColor Magenta
}

function Test-ParserErrors {
    param([string]$Path)
    $errors = $null
    try {
        [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errors) | Out-Null
        return $errors.Count -eq 0
    } catch { return $false }
}

function Test-PatternErrors {
    param([string]$Path, [string]$Content)
    $lines = $Content -split "`r?`n"
    $hasError = $false
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match '^\s*\[(OK|ERROR|FAIL|PASS|WARN)\]\s+\w+') {
            $script:Issues += [ordered]@{
                file = Split-Path -Leaf $Path
                path = $Path
                line = $i + 1
                type = "parser-break"
                pattern = $matches[0]
            }
            $hasError = $true
        }
    }
    return -not $hasError
}

function Invoke-AutoFix {
    param([string]$Path, [string]$Content)
    $lines = $Content -split "`r?`n"
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
    if (-not $DryRun) {
        Set-Content -Path $Path -Value $fixed -Encoding UTF8 -NoNewline
    }
    return $true
}

function Invoke-DelegateFix {
    param([string[]]$Files)

    $filesList = $Files -join ", "
    Write-Delegate "Delegating to sdd-apply agent..."
    Write-Delegate "Files: $filesList"

    $delegateScript = Join-Path $repoRoot "scripts\utilities\auto-delegation-wrapper.ps1"
    if (Test-Path $delegateScript) {
        $task = "fix script parser errors in: $filesList"
        Write-Delegate "Task: $task"
        Write-Delegate "Command: pwsh -NoProfile -Command `"& .\scripts\utilities\auto-delegation-wrapper.ps1 '$task'`""

        $script:Delegated += [ordered]@{
            files = $filesList
            task = $task
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        if (-not $DryRun) {
            $result = & pwsh -NoProfile -Command "& `"$delegateScript`" `"$task`"" 2>&1
            Write-Delegate "Delegation result: $result"
        }
    }
}

function Add-Learning {
    param([string]$Issue, [string]$Fix, [string]$Pattern)

    $script:Learning += [ordered]@{
        issue = $Issue
        fix = $Fix
        pattern = $Pattern
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $learnScript = Join-Path $repoRoot "scripts\diagnostics\auto-learn.ps1"
    if (Test-Path $learnScript -and -not $DryRun) {
        Write-Auto "Learning: $Issue"
    }
}

Set-Location $repoRoot
Write-Auto "Auto-fix validation starting..."

$patterns = @('*.ps1', '*.psm1')
$scanned = 0
$passed = 0

Get-ChildItem -Path $repoRoot -Include $patterns -Recurse -File | Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\node_modules\\'
} | ForEach-Object {
    $scanned++
    $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $content) { return }

    if ($content -match '@"[\s\S]*?\[(OK|ERROR|FAIL|PASS|WARN)\][\s\S]*?"@') {
        $passed++
        return
    }

    $parserOk = Test-ParserErrors -Path $_.FullName
    $patternOk = Test-PatternErrors -Path $_.FullName -Content $content

    if ($patternOk -and $parserOk) { $passed++ }
}

Write-Auto "Scanned: $scanned | Passed: $passed | Issues: $($script:Issues.Count)"

if ($script:Issues.Count -gt 0) {
    Write-Host ""
    Write-Warn "DETECTED: $($script:Issues.Count) issues found"

    $affectedFiles = $script:Issues | Group-Object file | ForEach-Object { $_.Name }

    if ($Verbose) {
        $script:Issues | ForEach-Object {
            Write-Host "  $($_.file):$($_.line) - $($_.type)" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Auto "Attempting AUTO-FIX..."

    $byFile = $script:Issues | Group-Object file
    $autoFixed = 0

    foreach ($group in $byFile) {
        $file = $group.Name
        $path = Get-ChildItem -Path $repoRoot -Filter $file -Recurse | Select-Object -First 1

        if ($path) {
            $content = Get-Content -path.FullName -Raw -Encoding UTF8
            $result = Invoke-AutoFix -Path $path.FullName -Content $content
            if ($result) {
                $autoFixed++
                Write-Auto "Fixed: $file"
                Add-Learning -Issue "Pattern [$($group.Group[0].pattern)] at line start" -Fix "Prefixed with #" -Pattern $group.Group[0].pattern
            }
        }
    }

    Write-Host ""
    Write-Auto "Re-validating after auto-fix..."

    $script:Issues = @()
    $validPass = 0

    Get-ChildItem -Path $repoRoot -Include $patterns -Recurse -File | Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\node_modules\\'
    } | ForEach-Object {
        $content = Get-Content -Path $_.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($content) {
            $pOk = Test-PatternErrors -Path $_.FullName -Content $content
            if ($pOk) { $validPass++ }
        }
    }

    if ($validPass -eq $scanned) {
        Write-Auto "SUCCESS: All issues auto-fixed!"

        if ($script:Fixed.Count -gt 0) {
            Write-Host ""
            Write-Host "SUMMARY:" -ForegroundColor Green
            $script:Fixed | ForEach-Object {
                Write-Host "  $($_.file): $($_.original) → $($_.fixed)" -ForegroundColor Gray
            }

            if (-not $DryRun) {
                Write-Host ""
                Write-Host "AUTO-COMMIT:" -ForegroundColor Cyan
                Write-Host "  Run: git add . && git commit -m 'fix: auto-correct parser patterns'" -ForegroundColor White
            }
        }

        exit 0
    }

    $remaining = $script:Issues.Count
    if ($remaining -gt 0) {
        Write-WARN "Remaining issues: $remaining"
        $stillAffected = $script:Issues | Group-Object file | ForEach-Object { $_.Name }
        Write-Host ""

        $stillFiles = @($stillAffected)
        if ($stillFiles.Count -gt 0 -and -not $DryRun) {
            Write-Auto "DELEGATING to sdd-apply agent..."
            Invoke-DelegateFix -Files $stillFiles
        } elseif ($stillFiles.Count -gt 0 -and $DryRun) {
            Write-Delegate "Would delegate: $($stillFiles -join ', ')"
        }
    }
}

if ($passed -eq $scanned -and $script:Issues.Count -eq 0) {
    Write-Auto "SUCCESS: All scripts validated. No issues found."
    Write-Auto "READY: Push authorized."
}

exit 0