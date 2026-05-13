# run-tests-simple.ps1
# Multi-category test runner for Pester
#
# Usage:
#   .\run-tests-simple.ps1                   # run all tests
#   .\run-tests-simple.ps1 -WithCoverage     # run all tests + generate coverage report
#   .\run-tests-simple.ps1 -IncludeE2E       # include e2e tests (slower, needs git)

param(
    [switch]$WithCoverage,
    [switch]$IncludeE2E
)

$script:root = $PSScriptRoot | Split-Path -Parent
$testDir = Join-Path $script:root "tests"
$passed = 0
$failed = 0
$total = 0

$categories = @(
    @{ Name = "Unit Tests";        Path = "unit\*.tests.ps1" }
    @{ Name = "Integration Tests"; Path = "integration\*.tests.ps1" }
    @{ Name = "Security Tests";    Path = "security\*.tests.ps1" }
    @{ Name = "Performance Tests"; Path = "performance\*.tests.ps1" }
)

if ($IncludeE2E) {
    $categories += @{ Name = "E2E Tests"; Path = "e2e\*.e2e.tests.ps1" }
}

foreach ($cat in $categories) {
    $files = Get-ChildItem "$testDir\$($cat.Path)" -ErrorAction SilentlyContinue
    if ($files.Count -eq 0) { continue }

    Write-Host "=== $($cat.Name) ($($files.Count) files) ===" -ForegroundColor Cyan

    foreach ($file in $files) {
        $output = pwsh -NoProfile -Command "Invoke-Pester -Path '$($file.FullName)' -PassThru" 2>&1
        $total++

        if ($output -match "Passed:\s*(\d+)" -and $output -notmatch "Failed:\s*[1-9]") {
            $passed++
            Write-Host "  PASSED: $($file.Name)" -ForegroundColor Green
        } else {
            $failed++
            Write-Host "  FAILED: $($file.Name)" -ForegroundColor Red
            # Show relevant error lines
            $output | Select-String "FAIL|Error|RuntimeException" | Select-Object -First 3 |
                ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
        }
    }
}

Write-Host "`n=== Result ($total total) ===" -ForegroundColor Cyan
Write-Host "Passed: $passed | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

# Code coverage report (optional, requires Pester CodeCoverage support)
if ($WithCoverage) {
    $coverageConfigPath = Join-Path $testDir "coverage-config.json"
    $coverageOutDir = Join-Path $testDir "coverage"
    $coverageReportPath = Join-Path $coverageOutDir "coverage-report.xml"

    if (-not (Test-Path $coverageOutDir)) {
        New-Item -ItemType Directory -Path $coverageOutDir -Force | Out-Null
    }

    $coverageConfig = if (Test-Path $coverageConfigPath) {
        Get-Content $coverageConfigPath | ConvertFrom-Json
    } else {
        [pscustomobject]@{ thresholds = @{ lines = 70; functions = 75; branches = 65 } }
    }

    # Collect all script files to measure
    $scriptsToMeasure = Get-ChildItem "$script:root\scripts\**\*.ps1" -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $rel = $_.FullName.Replace($script:root, '').TrimStart('\')
            $coverageConfig.exclude -notcontains $rel -and
            $_.Name -notmatch '^(run-tests|setup-complete|check-)'
        } |
        Select-Object -ExpandProperty FullName

    if ($scriptsToMeasure.Count -gt 0) {
        Write-Host "`n=== Coverage Report ===" -ForegroundColor Cyan

        # Collect all test files
        $allTestFiles = Get-ChildItem "$testDir\**\*.tests.ps1" -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '\.e2e\.' } |
            Select-Object -ExpandProperty FullName

        $coverageCmd = "
            `$r = Invoke-Pester -Path @('$($allTestFiles -join "','")') -CodeCoverage @('$($scriptsToMeasure -join "','")') -PassThru -Quiet
            `$cov = `$r.CodeCoverage
            if (`$cov) {
                `$hitLines = (`$cov.HitCommands | Measure-Object).Count
                `$missLines = (`$cov.MissedCommands | Measure-Object).Count
                `$totalLines = `$hitLines + `$missLines
                `$pct = if (`$totalLines -gt 0) { [math]::Round((`$hitLines / `$totalLines) * 100, 1) } else { 100 }
                Write-Host \"Lines covered: `$hitLines / `$totalLines (`$pct%)\"
                if (`$pct -lt 70) { Write-Host '[WARNING] Coverage below threshold (70%)' ; exit 1 }
            }
        "
        pwsh -NoProfile -Command $coverageCmd
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARN] Coverage check failed or below threshold" -ForegroundColor Yellow
        }
    }
}

if ($failed -gt 0) { exit 1 }
