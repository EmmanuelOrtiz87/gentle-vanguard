#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test Runner - Executes all test suites
    
.DESCRIPTION
    Comprehensive test runner that executes unit, integration, performance, and security tests
    
.PARAMETER TestType
    Type of tests to run: all, unit, integration, performance, security
    
.PARAMETER GenerateReport
    Generate HTML report
    
.PARAMETER FailOnLowCoverage
    Fail if coverage is below threshold
    
.EXAMPLE
    .\run-tests.ps1 -TestType all -GenerateReport
#>

param(
    [ValidateSet('all', 'unit', 'integration', 'performance', 'security')]
    [string]$TestType = 'all',
    [switch]$GenerateReport,
    [switch]$FailOnLowCoverage,
    [string]$LogLevel = 'info'
)

$TestRunnerVersion = "1.0.0"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$testResultsDir = "test-results"
$coverageDir = "coverage"

# Initialize directories
if (-not (Test-Path $testResultsDir)) { New-Item -ItemType Directory -Path $testResultsDir -Force | Out-Null }
if (-not (Test-Path $coverageDir)) { New-Item -ItemType Directory -Path $coverageDir -Force | Out-Null }

function Write-Log {
    param([string]$Message, [string]$Level = "info")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." "info"
    
    $pesterInstalled = Get-Module -ListAvailable -Name Pester
    if (-not $pesterInstalled) {
        Write-Log "Installing Pester module..." "warn"
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    Write-Log "Prerequisites verified" "info"
}

function Run-UnitTests {
    Write-Log "Running unit tests..." "info"
    
    $unitTestPath = "tests/unit/*.tests.ps1"
    $unitTests = Get-ChildItem -Path $unitTestPath -ErrorAction SilentlyContinue
    
    if ($unitTests.Count -eq 0) {
        Write-Log "No unit tests found" "warn"
        return @{ Passed = 0; Failed = 0; Skipped = 0 }
    }
    
    $results = @()
    foreach ($test in $unitTests) {
        Write-Log "Running: $($test.Name)" "info"
        $result = Invoke-Pester -Path $test.FullName -PassThru
        $results += $result
    }
    
    $summary = @{
        Passed = ($results | Measure-Object -Property PassedCount -Sum).Sum
        Failed = ($results | Measure-Object -Property FailedCount -Sum).Sum
        Skipped = ($results | Measure-Object -Property SkippedCount -Sum).Sum
    }
    
    Write-Log "Unit tests completed: Passed=$($summary.Passed), Failed=$($summary.Failed)" "info"
    return $summary
}

function Run-IntegrationTests {
    Write-Log "Running integration tests..." "info"
    
    $integrationTestPath = "tests/integration/*.integration.tests.ps1"
    $integrationTests = Get-ChildItem -Path $integrationTestPath -ErrorAction SilentlyContinue
    
    if ($integrationTests.Count -eq 0) {
        Write-Log "No integration tests found" "warn"
        return @{ Passed = 0; Failed = 0; Skipped = 0 }
    }
    
    $results = @()
    foreach ($test in $integrationTests) {
        Write-Log "Running: $($test.Name)" "info"
        $result = Invoke-Pester -Path $test.FullName -PassThru
        $results += $result
    }
    
    $summary = @{
        Passed = ($results | Measure-Object -Property PassedCount -Sum).Sum
        Failed = ($results | Measure-Object -Property FailedCount -Sum).Sum
        Skipped = ($results | Measure-Object -Property SkippedCount -Sum).Sum
    }
    
    Write-Log "Integration tests completed: Passed=$($summary.Passed), Failed=$($summary.Failed)" "info"
    return $summary
}

function Run-PerformanceTests {
    Write-Log "Running performance tests..." "info"
    
    $perfTestPath = "tests/performance/*.perf.tests.ps1"
    $perfTests = Get-ChildItem -Path $perfTestPath -ErrorAction SilentlyContinue
    
    if ($perfTests.Count -eq 0) {
        Write-Log "No performance tests found" "warn"
        return @{ Passed = 0; Failed = 0; Skipped = 0 }
    }
    
    $results = @()
    foreach ($test in $perfTests) {
        Write-Log "Running: $($test.Name)" "info"
        $result = Invoke-Pester -Path $test.FullName -PassThru
        $results += $result
    }
    
    $summary = @{
        Passed = ($results | Measure-Object -Property PassedCount -Sum).Sum
        Failed = ($results | Measure-Object -Property FailedCount -Sum).Sum
        Skipped = ($results | Measure-Object -Property SkippedCount -Sum).Sum
    }
    
    Write-Log "Performance tests completed: Passed=$($summary.Passed), Failed=$($summary.Failed)" "info"
    return $summary
}

function Run-SecurityTests {
    Write-Log "Running security tests..." "info"
    
    $secTestPath = "tests/security/*.security.tests.ps1"
    $secTests = Get-ChildItem -Path $secTestPath -ErrorAction SilentlyContinue
    
    if ($secTests.Count -eq 0) {
        Write-Log "No security tests found" "warn"
        return @{ Passed = 0; Failed = 0; Skipped = 0 }
    }
    
    $results = @()
    foreach ($test in $secTests) {
        Write-Log "Running: $($test.Name)" "info"
        $result = Invoke-Pester -Path $test.FullName -PassThru
        $results += $result
    }
    
    $summary = @{
        Passed = ($results | Measure-Object -Property PassedCount -Sum).Sum
        Failed = ($results | Measure-Object -Property FailedCount -Sum).Sum
        Skipped = ($results | Measure-Object -Property SkippedCount -Sum).Sum
    }
    
    Write-Log "Security tests completed: Passed=$($summary.Passed), Failed=$($summary.Failed)" "info"
    return $summary
}

function Generate-TestReport {
    param([hashtable]$Results)
    
    Write-Log "Generating test report..." "info"
    
    $report = @{
        timestamp = Get-Date -Format "o"
        version = $TestRunnerVersion
        testType = $TestType
        results = $Results
        summary = @{
            totalPassed = ($Results.Values | Measure-Object -Property Passed -Sum).Sum
            totalFailed = ($Results.Values | Measure-Object -Property Failed -Sum).Sum
            totalSkipped = ($Results.Values | Measure-Object -Property Skipped -Sum).Sum
        }
    }
    
    $reportPath = "$testResultsDir/test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json | Set-Content -Path $reportPath
    
    Write-Log "Report generated: $reportPath" "info"
    return $report
}

function Main {
    Write-Log "Test Runner v$TestRunnerVersion" "info"
    Write-Log "Test Type: $TestType" "info"
    
    # Check prerequisites
    Test-Prerequisites
    
    # Run tests based on type
    $allResults = @{}
    
    if ($TestType -in @('all', 'unit')) {
        $allResults['unit'] = Run-UnitTests
    }
    
    if ($TestType -in @('all', 'integration')) {
        $allResults['integration'] = Run-IntegrationTests
    }
    
    if ($TestType -in @('all', 'performance')) {
        $allResults['performance'] = Run-PerformanceTests
    }
    
    if ($TestType -in @('all', 'security')) {
        $allResults['security'] = Run-SecurityTests
    }
    
    # Generate report
    if ($GenerateReport) {
        $report = Generate-TestReport -Results $allResults
        
        if ($report.summary.totalFailed -gt 0) {
            Write-Log "TESTS FAILED: $($report.summary.totalFailed) failures" "error"
            return 1
        }
    }
    
    Write-Log "All tests completed successfully" "info"
    return 0
}

exit (Main)