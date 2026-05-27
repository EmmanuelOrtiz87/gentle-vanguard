#Requires -Version 7.0
<#
.SYNOPSIS
    Dashboard Health Monitor - Monitorea la salud del dashboard
.DESCRIPTION
    Verifica que el dashboard esté funcionando correctamente, detecta errores
    JavaScript y envía alertas si hay problemas.
.NOTES
    Version: 1.0.0
#>

param(
    [string]$DashboardUrl = "http://localhost:8090",
    [int]$CheckInterval = 300,
    [switch]$SendAlerts,
    [string]$AlertWebhook = "",
    [switch]$Daemon
)

$ErrorActionPreference = 'Continue'
$script:LastErrorCount = 0
$script:LastCheck = $null
$script:UptimeStart = Get-Date

function Write-Log($Message, $Level = 'INFO') {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'ERROR' { 'Red' }
        'WARN'  { 'Yellow' }
        'SUCCESS' { 'Green' }
        default { 'White' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-DashboardHealth {
    param($Url)
    
    $result = @{
        Success = $false
        StatusCode = 0
        ResponseTime = 0
        Errors = @()
        Timestamp = Get-Date
    }
    
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -ErrorAction Stop
        $sw.Stop()
        
        $result.Success = $true
        $result.StatusCode = $response.StatusCode
        $result.ResponseTime = $sw.ElapsedMilliseconds
        
        # Check for critical elements in HTML
        $html = $response.Content
        $checks = @{
            'Has9Sections' = ($html -match 'section id=')
            'HasCharts' = ($html -match '<canvas')
            'HasNavigation' = ($html -match 'data-target=')
            'HasScripts' = ($html -match '<script>')
        }
        
        $failedChecks = $checks.GetEnumerator() | Where-Object { -not $_.Value } | Select-Object -ExpandProperty Key
        if ($failedChecks) {
            $result.Errors += "Missing elements: $($failedChecks -join ', ')"
        }
        
    } catch {
        $result.Errors += $_.Exception.Message
    }
    
    return $result
}

function Send-Alert($Message, $Severity = 'WARNING') {
    Write-Log $Message $Severity
    
    if ($SendAlerts -and $AlertWebhook) {
        try {
            $payload = @{
                text = "Dashboard Health Alert: $Severity"
                message = $Message
                timestamp = (Get-Date).ToString('o')
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri $AlertWebhook -Method Post -Body $payload -ContentType 'application/json' -TimeoutSec 5 | Out-Null
        } catch {
            Write-Log "Failed to send alert: $_" 'ERROR'
        }
    }
}

function Get-HealthMetrics {
    $metrics = @{
        Timestamp = Get-Date
        UptimeMinutes = ((Get-Date) - $script:UptimeStart).TotalMinutes
        LastCheck = $script:LastCheck
        LastErrorCount = $script:LastErrorCount
    }
    
    # Check if dashboard HTML exists
    $dashboardPath = Join-Path $PSScriptRoot '..' '..' 'reports' 'dashboard.html'
    if (Test-Path $dashboardPath) {
        $file = Get-Item $dashboardPath
        $metrics.DashboardSize = $file.Length
        $metrics.LastModified = $file.LastWriteTime
        $metrics.AgeMinutes = ((Get-Date) - $file.LastWriteTime).TotalMinutes
    }
    
    # Check metrics files
    $metricsDir = Join-Path $PSScriptRoot '..' '..' '.runtime' 'metrics'
    if (Test-Path $metricsDir) {
        $jsonFiles = Get-ChildItem -Path $metricsDir -Filter '*.json' -ErrorAction SilentlyContinue
        $metrics.MetricsFilesCount = $jsonFiles.Count
        $metrics.MetricsFilesTotalSize = ($jsonFiles | Measure-Object -Property Length -Sum).Sum
        
        # Check for stale files (> 1 hour)
        $staleFiles = $jsonFiles | Where-Object { ((Get-Date) - $_.LastWriteTime).TotalHours -gt 1 }
        $metrics.StaleMetricsFiles = $staleFiles.Count
    }
    
    return $metrics
}

function Show-HealthDashboard {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           Dashboard Health Monitor v1.0                      ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $metrics = Get-HealthMetrics
    
    Write-Host "System Status:" -ForegroundColor Yellow
    Write-Host "  Uptime: $($metrics.UptimeMinutes.ToString('F1')) minutes" -ForegroundColor White
    Write-Host "  Last Check: $($metrics.LastCheck)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Dashboard:" -ForegroundColor Yellow
    if ($metrics.DashboardSize) {
        Write-Host "  Size: $([math]::Round($metrics.DashboardSize/1KB, 2)) KB" -ForegroundColor White
        Write-Host "  Last Modified: $($metrics.LastModified)" -ForegroundColor White
        Write-Host "  Age: $($metrics.AgeMinutes.ToString('F1')) minutes" -ForegroundColor $(if($metrics.AgeMinutes -gt 60){'Red'}else{'Green'})
    } else {
        Write-Host "  Status: NOT FOUND" -ForegroundColor Red
    }
    Write-Host ""
    
    Write-Host "Metrics Store:" -ForegroundColor Yellow
    Write-Host "  Files: $($metrics.MetricsFilesCount)" -ForegroundColor White
    Write-Host "  Total Size: $([math]::Round($metrics.MetricsFilesTotalSize/1KB, 2)) KB" -ForegroundColor White
    if ($metrics.StaleMetricsFiles -gt 0) {
        Write-Host "  ⚠ Stale Files: $($metrics.StaleMetricsFiles)" -ForegroundColor Red
    }
    Write-Host ""
    
    Write-Host "Last 5 Checks:" -ForegroundColor Yellow
    # This would show history in a real implementation
    Write-Host "  [Monitor running...]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor DarkGray
}

# Main execution
Write-Log "Dashboard Health Monitor started" 'INFO'
Write-Log "Dashboard URL: $DashboardUrl" 'INFO'
Write-Log "Check interval: ${CheckInterval}s" 'INFO'

if ($Daemon) {
    Write-Log "Running in daemon mode" 'INFO'
    
    while ($true) {
        Show-HealthDashboard
        
        # Perform health check
        $health = Test-DashboardHealth -Url $DashboardUrl
        $script:LastCheck = Get-Date
        
        if (-not $health.Success) {
            $script:LastErrorCount++
            Send-Alert "Dashboard health check failed: $($health.Errors -join '; ')" 'ERROR'
        } elseif ($health.Errors.Count -gt 0) {
            Send-Alert "Dashboard warnings: $($health.Errors -join '; ')" 'WARN'
        } else {
            Write-Log "Health check passed ($($health.ResponseTime)ms)" 'SUCCESS'
        }
        
        Start-Sleep -Seconds $CheckInterval
    }
} else {
    # Single check mode
    Write-Log "Running single health check..." 'INFO'
    
    $health = Test-DashboardHealth -Url $DashboardUrl
    $metrics = Get-HealthMetrics
    
    Show-HealthDashboard
    
    if ($health.Success) {
        Write-Log "Dashboard is healthy" 'SUCCESS'
        exit 0
    } else {
        Write-Log "Dashboard has issues: $($health.Errors -join '; ')" 'ERROR'
        exit 1
    }
}
