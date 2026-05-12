# run-tests-simple.ps1
# Multi-category test runner for Pester

$script:root = $PSScriptRoot | Split-Path -Parent
$testDir = Join-Path $script:root "tests"
$passed = 0
$failed = 0
$total = 0

$categories = @(
    @{ Name = "Unit Tests";       Path = "unit\*.tests.ps1" }
    @{ Name = "Integration Tests"; Path = "integration\*.tests.ps1" }
    @{ Name = "Security Tests";    Path = "security\*.tests.ps1" }
    @{ Name = "Performance Tests"; Path = "performance\*.tests.ps1" }
)

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
        }
    }
}

Write-Host "`n=== Result ($total total) ===" -ForegroundColor Cyan
Write-Host "Passed: $passed | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
if ($failed -gt 0) { exit 1 }
