# run-tests.ps1
# Simple test runner for Pester 3.4.0

$testDir = "C:\Workspace_local\workspace-foundation\tests"
$passed = 0
$failed = 0

Write-Host "=== Running Unit Tests ===" -ForegroundColor Cyan

Get-ChildItem "$testDir\unit\*.tests.ps1" | ForEach-Object {
    $testFile = $_.FullName
    Write-Host "`nTesting: $($_.Name)" -ForegroundColor Gray
    
    $output = pwsh -NoProfile -Command "Invoke-Pester -Path '$testFile' -PassThru" 2>&1
    
    if ($output -match "Passed:\s*(\d+)" -and $output -notmatch "Failed:\s*[1-9]") {
        $passed++
        Write-Host "  PASSED" -ForegroundColor Green
    } else {
        $failed++
        Write-Host "  FAILED" -ForegroundColor Red
    }
}

Write-Host "`n=== Result ===" -ForegroundColor Cyan
Write-Host "Passed: $passed | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
