<#
.SYNOPSIS
    Real-Time Executive Dashboard & Governance Reporter
    
.DESCRIPTION
    Unified process that combines:
    1. Real-time status monitoring (continuous-status-monitor.ps1)
    2. Token consumption reporting (token-consumption-report.ps1)
    3. Governance & audit status (wf.ps1 audit, orchestrator-status)
    4. Executive summary for management
    
    Replaces/supplements:
    - continuous-status-monitor.ps1 (legacy - keep for backward compatibility)
    - orchestrator-status.ps1 (integates)
    - token-consumption-report.ps1 (calls internally)
    
.PARAMETER Mode
    Operation mode: dashboard (continuous), report (one-time), monitor (silent)
    
.PARAMETER OutputFormat
    Output format: executive (management), technical (detailed), json (automation)
    
.PARAMETER RefreshInterval
    Refresh interval in seconds for dashboard mode (default: 300 = 5 min)
    
.EXAMPLE
    .\executive-dashboard.ps1 -Mode report -OutputFormat executive
    Generates one-time executive report for management
    
.EXAMPLE
    .\executive-dashboard.ps1 -Mode dashboard -RefreshInterval 300
    Runs continuous dashboard with 5-minute refresh
    
.EXAMPLE
    .\executive-dashboard.ps1 -Mode monitor -OutputFormat json
    Silent monitoring with JSON output for CI/CD integration
#>

param(
    [ValidateSet('dashboard', 'report', 'monitor')]
    [string]$Mode = 'report',
    
    [ValidateSet('executive', 'technical', 'json')]
    [string]$OutputFormat = 'executive',
    
    [int]$RefreshInterval = 300,
    
    [switch]$IncludeTokenDetails,
    [switch]$IncludeAuditStatus,
    [switch]$IncludeGovernance
)

$ErrorActionPreference = 'Continue'
if ($env:FOUNDATION_BASE_DIR) {
    $repoRoot = $env:FOUNDATION_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
$scriptsDir = Join-Path $repoRoot 'scripts\utilities'
$docsDir = Join-Path $repoRoot 'docs'
$reportsDir = Join-Path $repoRoot 'reports'
if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null }

function Write-ExecutiveHeader {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section {
    param([string]$Title)
    Write-Host "`n--- $Title ---" -ForegroundColor Yellow
}

function Get-TokenSummary {
    $tokenScript = Join-Path $scriptsDir 'token-consumption-report.ps1'
    if (-not (Test-Path $tokenScript)) { return $null }
    
    try {
        $jsonOutput = & $tokenScript -OutputFormat json -Scope weekly AsJson 2>$null
        if ($jsonOutput) {
            return $jsonOutput | ConvertFrom-Json -ErrorAction SilentlyContinue
        }
    } catch { }
    
    return $null
}

function Get-AuditStatus {
    $auditScript = Join-Path $scriptsDir 'WORKFLOW-ORCHESTRATION\wf.ps1'
    if (-not (Test-Path $auditScript)) { return $null }
    
    try {
        $output = & $auditScript audit -Mode quick 2>$null
        return @{
            rawOutput = $output
            timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    } catch { }
    
    return $null
}

function Get-GovernanceStatus {
    $orchestratorStatus = Join-Path $scriptsDir 'WORKFLOW-ORCHESTRATION\orchestrator-status.ps1'
    if (-not (Test-Path $orchestratorStatus)) { return $null }
    
    try {
        $output = & $orchestratorStatus 2>$null
        return @{
            rawOutput = $output
            timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    } catch { }
    
    return $null
}

function Get-RealTimeMetrics {
    $metricsDir = Join-Path $repoRoot 'docs\sessions\metrics'
    $usageFile = Join-Path $metricsDir 'token-guard-usage.csv'
    
    if (-not (Test-Path $usageFile)) {
        return @{ totalTokens = 0; tasks = 0; avgPerTask = 0 }
    }
    
    try {
        $rows = Import-Csv -Path $usageFile -ErrorAction SilentlyContinue
        if (-not $rows) { return @{ totalTokens = 0; tasks = 0; avgPerTask = 0 } }
        
        $totalTokens = 0
        foreach ($row in $rows) {
            $tokens = 0
            if ($row.estimated_tokens -match '^\d+$') {
                $tokens = [int]$row.estimated_tokens
                $totalTokens += $tokens
            }
        }
        
        return @{
            totalTokens = $totalTokens
            tasks = $rows.Count
            avgPerTask = if ($rows.Count -gt 0) { [math]::Round($totalTokens / $rows.Count, 0) } else { 0 }
            lastUpdate = (Get-Item $usageFile).LastWriteTime
        }
    } catch { }
    
    return @{ totalTokens = 0; tasks = 0; avgPerTask = 0 }
}

function Generate-ExecutiveReport {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    Write-ExecutiveHeader "EXECUTIVE DASHBOARD - Foundation Workspace"
    Write-Host "Generated: $timestamp" -ForegroundColor Gray
    Write-Host ""
    
    # 1. Real-time Metrics
    Write-Section "REAL-TIME METRICS"
    $metrics = Get-RealTimeMetrics
    Write-Host "  Total Tokens Used: $([string]::Format('{0:N0}', $metrics.totalTokens))" -ForegroundColor White
    Write-Host "  Tasks Executed: $($metrics.tasks)" -ForegroundColor White
    Write-Host "  Avg Tokens/Task: $([string]::Format('{0:N0}', $metrics.avgPerTask))" -ForegroundColor White
    Write-Host "  Last Update: $($metrics.lastUpdate)" -ForegroundColor Gray
    
    # 2. Token Summary (from weekly report)
    if ($IncludeTokenDetails) {
        Write-Section "TOKEN CONSUMPTION SUMMARY"
        $tokenSummary = Get-TokenSummary
        if ($tokenSummary) {
            Write-Host "  Total Tokens: $([string]::Format('{0:N0}', $tokenSummary.summary.totalTokens))" -ForegroundColor White
            Write-Host "  Total Records: $($tokenSummary.summary.totalRecords)" -ForegroundColor White
            Write-Host "  Avg per Task: $([string]::Format('{0:N0}', $tokenSummary.summary.avgPerTask))" -ForegroundColor White
            
            if ($tokenSummary.topTasks) {
                Write-Host "  Top Tasks:" -ForegroundColor Cyan
                $tokenSummary.topTasks | Select-Object -First 5 | ForEach-Object {
                    Write-Host "    - $($_.task): $([string]::Format('{0:N0}', $_.totalTokens)) tokens ($($_.count) execs)" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "  [WARN] Token summary not available" -ForegroundColor Yellow
        }
    }
    
    # 3. Audit Status
    if ($IncludeAuditStatus) {
        Write-Section "AUDIT STATUS"
        $auditStatus = Get-AuditStatus
        if ($auditStatus) {
            Write-Host "  Last Audit: $($auditStatus.timestamp)" -ForegroundColor Gray
            # Parse audit output for key metrics
            $output = $auditStatus.rawOutput -join "`n"
            if ($output -match "PASS|FAIL|WARNING") {
                $status = if ($output -match "PASS") { "HEALTHY" } elseif ($output -match "WARNING") { "ATTENTION" } else { "ISSUES" }
                $color = if ($status -eq "HEALTHY") { "Green" } elseif ($status -eq "ATTENTION") { "Yellow" } else { "Red" }
                Write-Host "  Status: $status" -ForegroundColor $color
            }
        } else {
            Write-Host "  [WARN] Audit status not available" -ForegroundColor Yellow
        }
    }
    
    # 4. Governance Status
    if ($IncludeGovernance) {
        Write-Section "GOVERNANCE STATUS"
        $govStatus = Get-GovernanceStatus
        if ($govStatus) {
            Write-Host "  Last Check: $($govStatus.timestamp)" -ForegroundColor Gray
            $output = $govStatus.rawOutput -join "`n"
            if ($output -match "engram|token_guard|session") {
                Write-Host "  Core Systems: ACTIVE" -ForegroundColor Green
            } else {
                Write-Host "  Core Systems: UNKNOWN" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [WARN] Governance status not available" -ForegroundColor Yellow
        }
    }
    
    # 5. Recommendations
    Write-Section "RECOMMENDATIONS"
    if ($metrics.totalTokens -gt 100000) {
        Write-Host "  [INFO] High token usage detected. Consider optimization." -ForegroundColor Yellow
    } else {
        Write-Host "  [OK] Token usage within normal range." -ForegroundColor Green
    }
    
    if ($metrics.tasks -eq 0) {
        Write-Host "  [WARN] No recent activity detected." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-ExecutiveHeader "END OF REPORT"
}

function Generate-TechnicalReport {
    Write-ExecutiveHeader "TECHNICAL DASHBOARD - Foundation Workspace"
    
    # Call detailed scripts
    $tokenScript = Join-Path $scriptsDir 'token-consumption-report.ps1'
    if (Test-Path $tokenScript) {
        Write-Section "TOKEN CONSUMPTION (DETAILED)"
        & $tokenScript -OutputFormat markdown -Scope all -IncludeContext -IncludeUtility
    }
    
    $auditScript = Join-Path $scriptsDir 'WORKFLOW-ORCHESTRATION\wf.ps1'
    if (Test-Path $auditScript) {
        Write-Section "AUDIT STATUS (DETAILED)"
        & $auditScript audit -Mode full
    }
    
    $govScript = Join-Path $scriptsDir 'WORKFLOW-ORCHESTRATION\orchestrator-status.ps1'
    if (Test-Path $govScript) {
        Write-Section "GOVERNANCE STATUS (DETAILED)"
        & $govScript
    }
}

function Generate-JsonReport {
    $report = @{
        generatedAt = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
        mode = $Mode
        metrics = Get-RealTimeMetrics
        tokenSummary = if ($IncludeTokenDetails) { Get-TokenSummary } else { $null }
        auditStatus = if ($IncludeAuditStatus) { Get-AuditStatus } else { $null }
        governanceStatus = if ($IncludeGovernance) { Get-GovernanceStatus } else { $null }
    }
    
    $report | ConvertTo-Json -Depth 10
}

function Run-Dashboard {
    while ($true) {
        Clear-Host
        Generate-ExecutiveReport
        
        Write-Host "`nNext refresh in $RefreshInterval seconds... (Ctrl+C to stop)" -ForegroundColor DarkGray
        Start-Sleep -Seconds $RefreshInterval
    }
}

# MAIN EXECUTION

switch ($Mode) {
    'dashboard' {
        if ($OutputFormat -eq 'json') {
            Write-Warning "Dashboard mode with JSON output is not supported. Use 'monitor' mode instead."
            exit 1
        }
        Write-Host "Starting continuous dashboard (refresh: $RefreshInterval s)..." -ForegroundColor Cyan
        Run-Dashboard
    }
    'report' {
        switch ($OutputFormat) {
            'executive' {
                Generate-ExecutiveReport
            }
            'technical' {
                Generate-TechnicalReport
            }
            'json' {
                Generate-JsonReport
            }
        }
    }
    'monitor' {
        $report = @{
            timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'
            status = 'running'
            metrics = Get-RealTimeMetrics
        }
        
        if ($OutputFormat -eq 'json') {
            $report | ConvertTo-Json -Depth 5
        } else {
            Generate-ExecutiveReport
        }
    }
}

# Save report to file for management
if ($Mode -eq 'report' -and $OutputFormat -eq 'executive') {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $outputPath = Join-Path $reportsDir "executive-dashboard-$stamp.md"
    
    $content = & $MyInvocation.MyCommand.Path -Mode report -OutputFormat executive -IncludeTokenDetails:$IncludeTokenDetails -IncludeAuditStatus:$IncludeAuditStatus -IncludeGovernance:$IncludeGovernance 2>&1
    $content | Set-Content -Path $outputPath -Encoding UTF8
    
    Write-Host "`n[OK] Executive report saved to: $outputPath" -ForegroundColor Green
}
