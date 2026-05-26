<#
.SYNOPSIS
    Judgment Day Integration Bridge
    
.DESCRIPTION
    Connects autonomous systems' logs to Judgment Day:
    1. Collects results from all autonomous systems
    2. Formats for Judgment Day adversarial review
    3. Triggers Judgment Day when issues found
    4. NON-BLOCKING: Only logs for review, doesn't block commits
    
.PARAMETER Action
    What to do: collect, trigger, status
    
.PARAMETER Trigger
    What triggered: session-start, session-close, manual
    
.EXAMPLE
    .\judgment-day-bridge.ps1 -Action collect -Trigger session-close
    
.NOTES
    Non-blocking: Logs are for review, commits proceed normally
    Judgment Day runs separately for deep review
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("collect", "trigger", "status")]
    [string]$Action = "collect",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("session-start", "session-close", "manual")]
    [string]$Trigger = "manual",
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'
$repoRoot = if ($env:GV_BASE_DIR -and (Test-Path $env:GV_BASE_DIR)) { $env:GV_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$judgmentDir = Join-Path $repoRoot "docs\judgment"
$bridgeLog = Join-Path $repoRoot ".session\judgment-bridge-log.json"

# Ensure judgment directory exists
if (-not (Test-Path $judgmentDir)) {
    New-Item -Path $judgmentDir -ItemType Directory -Force | Out-Null
}

function Write-JBridge { param([string]$msg) Write-Host "[J-BRIDGE]" -NoNewline -ForegroundColor Green; Write-Host " $msg" -ForegroundColor White }
function Write-JOk { param([string]$msg) Write-Host "[J-OK]" -NoNewline -ForegroundColor Green; Write-Host " $msg" -ForegroundColor Gray }
function Write-JWarn { param([string]$msg) Write-Host "[J-WARN]" -NoNewline -ForegroundColor Yellow; Write-Host " $msg" -ForegroundColor Gray }
function Write-JFail { param([string]$msg) Write-Host "[J-FAIL]" -NoNewline -ForegroundColor Red; Write-Host " $msg" -ForegroundColor Gray }

# Collect logs from all autonomous systems
function Get-AutonomousLogs {
    $logs = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        trigger = $Trigger
        systems = @()
    }
    
    # 1. Testing results
    $testLog = Join-Path $repoRoot ".session\testing-results.json"
    if (Test-Path $testLog) {
        $testData = Get-Content $testLog -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($testData) {
            $logs.systems += @{
                name = "auto-testing"
                status = $testData.status
                failures = if ($testData.failures) { $testData.failures } else { 0 }
                repaired = if ($testData.repaired) { $testData.repaired } else { 0 }
                details = "Logged for Judgment Day review"
            }
        }
    }
    
    # 2. Doc-drift results
    $driftLog = Join-Path $repoRoot ".session\doc-drift-log.json"
    if (Test-Path $driftLog) {
        $driftData = Get-Content $driftLog -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($driftData) {
            $logs.systems += @{
                name = "auto-doc-drift"
                status = if ($driftData.drifts -gt 0) { "DRIFT_DETECTED" } else { "PASS" }
                drifts = $driftData.drifts
                fixed = if ($driftData.fixed) { $driftData.fixed } else { 0 }
                details = "Documentation drift detection"
            }
        }
    }
    
    # 3. Norm enforcement results
    $normLog = Join-Path $repoRoot ".session\norm-enforcer-log.json"
    if (Test-Path $normLog) {
        $normData = Get-Content $normLog -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($normData) {
            $logs.systems += @{
                name = "auto-norm-enforcer"
                status = $normData.status
                issues = if ($normData.issues) { $normData.issues.Count } else { 0 }
                fixes = if ($normData.fixes) { $normData.fixes.Count } else { 0 }
                details = "Norm enforcement and directory creation"
            }
        }
    }
    
    # 4. Delegation results
    $delegateLog = Join-Path $repoRoot ".session\delegate-log.json"
    if (Test-Path $delegateLog) {
        $delegateData = Get-Content $delegateLog -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($delegateData) {
            $logs.systems += @{
                name = "auto-delegation"
                status = if ($delegateData.failed -and $delegateData.failed.Count -gt 0) { "ISSUES" } else { "PASS" }
                delegated = if ($delegateData.success) { $delegateData.success.Count } else { 0 }
                failed = if ($delegateData.failed) { $delegateData.failed.Count } else { 0 }
                details = "Autonomous delegation and retry"
            }
        }
    }
    
    return $logs
}

# Format for Judgment Day
function Format-ForJudgmentDay {
    param($Logs)
    
    $judgmentInput = @{
        timestamp = $Logs.timestamp
        trigger = $Logs.trigger
        mode = "autonomous-review"
        findings = @()
    }
    
    foreach ($system in $Logs.systems) {
        if ($system.status -ne "PASS" -and $system.status -ne "SKIPPED") {
            $finding = @{
                system = $system.name
                status = $system.status
                details = $system.details
            }
            
            # Add system-specific details
            switch ($system.name) {
                "auto-testing" {
                    $finding.failures = $system.failures
                    $finding.repaired = $system.repaired
                }
                "auto-doc-drift" {
                    $finding.drifts = $system.drifts
                    $finding.fixed = $system.fixed
                }
                "auto-norm-enforcer" {
                    $finding.issues = $system.issues
                    $finding.fixes = $system.fixes
                }
                "auto-delegation" {
                    $finding.delegated = $system.delegated
                    $finding.failed = $system.failed
                }
            }
            
            $judgmentInput.findings += $finding
        }
    }
    
    return $judgmentInput
}

# Main execution: Collect
function Invoke-Collect {
    Write-Host ""
    Write-Host "" -ForegroundColor Green
    Write-Host "  JUDGMENT DAY BRIDGE (Collect Mode)                    " -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host ""
    
    Write-JBridge "Collecting logs from autonomous systems..."
    $logs = Get-AutonomousLogs
    
    if ($logs.systems.Count -eq 0) {
        Write-JWarn "No autonomous system logs found"
        return @{ status = "NO_LOGS"; findings = 0 }
    }
    
    Write-JBridge "Found $($logs.systems.Count) system(s) with logs"
    Write-Host ""
    
    $passCount = 0
    $issueCount = 0
    
    foreach ($system in $logs.systems) {
        $color = if ($system.status -eq "PASS" -or $system.status -eq "SKIPPED") { "Green" } else { "Yellow" }
        Write-Host "  [$($system.name)]" -ForegroundColor White -NoNewline
        Write-Host " Status: $($system.status)" -ForegroundColor $color
        
        if ($system.status -eq "PASS" -or $system.status -eq "SKIPPED") {
            $passCount++
        } else {
            $issueCount++
        }
    }
    
    # Save collected logs
    $logs | ConvertTo-Json -Depth 10 | Out-File -FilePath $bridgeLog -Encoding UTF8
    Write-JOk "Logs saved to: .session\judgment-bridge-log.json"
    
    # Format for Judgment Day if issues found
    if ($issueCount -gt 0) {
        Write-JWarn "Found $issueCount system(s) with issues - formatting for Judgment Day..."
        $judgmentInput = Format-ForJudgmentDay -Logs $logs
        
        $judgmentFile = Join-Path $judgmentDir "autonomous-findings-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').json"
        $judgmentInput | ConvertTo-Json -Depth 10 | Out-File -FilePath $judgmentFile -Encoding UTF8
        
        Write-JWarn "Judgment Day input saved to: $judgmentFile"
        Write-JWarn "Trigger: .\scripts\utilities\judgment-day-orchestrator.ps1 -Action run-judgment"
    }
    
    # Summary
    Write-Host ""
    Write-Host "" -ForegroundColor Cyan
    Write-Host "BRIDGE COLLECTION SUMMARY" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "  Systems checked: $($logs.systems.Count)" -ForegroundColor White
    Write-Host "   Passed: $passCount" -ForegroundColor Green
    Write-Host "    Issues: $issueCount" -ForegroundColor Yellow
    Write-Host ""
    
    return @{ status = "SUCCESS"; systems = $logs.systems.Count; issues = $issueCount }
}

# Main execution
switch ($Action) {
    "collect" { $result = Invoke-Collect }
    "trigger" { 
        Write-JWarn "Triggering Judgment Day..."
        $orchestratorScript = Join-Path $repoRoot "scripts\utilities\judgment-day-orchestrator.ps1"
        if (Test-Path $orchestratorScript) {
            & $orchestratorScript -Action run-judgment -Scope full
        } else {
            Write-JFail "judgment-day-orchestrator.ps1 not found"
            $result = @{ status = "SCRIPT_NOT_FOUND" }
        }
    }
    "status" {
        if (Test-Path $bridgeLog) {
            $logs = Get-Content $bridgeLog -Raw | ConvertFrom-Json
            Write-JOk "Last bridge run: $($logs.timestamp)"
            $result = @{ status = "EXISTS"; last_run = $logs.timestamp }
        } else {
            Write-JWarn "No bridge log found"
            $result = @{ status = "NO_LOGS" }
        }
    }
}

return $result



