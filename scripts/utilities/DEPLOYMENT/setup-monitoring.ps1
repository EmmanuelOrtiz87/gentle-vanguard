param(
    [ValidateSet('telemetry', 'health-checks', 'dashboard', 'all')]
    [string]$Component = 'all',
    [switch]$Enable
)

$ErrorActionPreference = 'Stop'
if ($env:FOUNDATION_BASE_DIR) {
    $repoRoot = $env:FOUNDATION_BASE_DIR
} else {
    $searchDir = $PSScriptRoot
    while ($searchDir -and -not (Test-Path (Join-Path $searchDir 'config\orchestrator.json'))) {
        $searchDir = Split-Path -Parent $searchDir
    }
    $repoRoot = $searchDir
}
Set-Location $repoRoot

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "$Message" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
}

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }

Write-Header "Monitoring Setup"

# Component 1: Enhanced Telemetry
if ($Component -in @('telemetry', 'all')) {
    Write-Info "Setting up enhanced telemetry..."
    
    $telemetryScript = @'
$script:telemetryData = @{
    Sessions = @()
    Errors = @()
    Performance = @()
    TokenUsage = @()
}

function Record-Session {
    param(
        [string]$SessionId,
        [string]$Tool,
        [int]$TokensUsed,
        [double]$Duration
    )
    
    $script:telemetryData.Sessions += @{
        SessionId = $SessionId
        Tool = $Tool
        TokensUsed = $TokensUsed
        Duration = $Duration
        Timestamp = Get-Date
    }
}

function Record-Error {
    param(
        [string]$ErrorMessage,
        [string]$ErrorCode,
        [string]$Component
    )
    
    $script:telemetryData.Errors += @{
        Message = $ErrorMessage
        Code = $ErrorCode
        Component = $Component
        Timestamp = Get-Date
    }
}

function Record-Performance {
    param(
        [string]$Operation,
        [double]$Duration,
        [int]$ItemCount
    )
    
    $script:telemetryData.Performance += @{
        Operation = $Operation
        Duration = $Duration
        ItemCount = $ItemCount
        Timestamp = Get-Date
    }
}

function Get-TelemetrySummary {
    $summary = @{
        TotalSessions = $script:telemetryData.Sessions.Count
        TotalErrors = $script:telemetryData.Errors.Count
        AverageSessionDuration = 0
        TotalTokensUsed = 0
        AverageTokensPerSession = 0
    }
    
    if ($script:telemetryData.Sessions.Count -gt 0) {
        $summary.AverageSessionDuration = ($script:telemetryData.Sessions | Measure-Object -Property Duration -Average).Average
        $summary.TotalTokensUsed = ($script:telemetryData.Sessions | Measure-Object -Property TokensUsed -Sum).Sum
        $summary.AverageTokensPerSession = $summary.TotalTokensUsed / $script:telemetryData.Sessions.Count
    }
    
    return $summary
}

function Export-Telemetry {
    param([string]$Path = ".\telemetry-export.json")
    
    $script:telemetryData | ConvertTo-Json | Out-File $Path -Encoding UTF8
    Write-Host "Telemetry exported to: $Path"
}
'@
    
    $telemetryScript | Out-File ".\scripts\utilities\enhanced-telemetry.ps1" -Encoding UTF8
    Write-Success "Enhanced telemetry module created"
}

# Component 2: Health Checks
if ($Component -in @('health-checks', 'all')) {
    Write-Info "Setting up health checks..."
    
    $healthScript = @'
function Test-SystemHealth {
    $health = @{
        Status = 'Healthy'
        Checks = @()
        Timestamp = Get-Date
    }
    
    # Check disk space
    $diskCheck = @{
        Name = 'Disk Space'
        Status = 'OK'
        Details = ''
    }
    
    $diskSpace = (Get-Volume | Where-Object { $_.DriveLetter -eq 'C' }).SizeRemaining
    if ($diskSpace -lt 1GB) {
        $diskCheck.Status = 'WARNING'
        $diskCheck.Details = "Low disk space: $([math]::Round($diskSpace/1GB, 2))GB"
    }
    $health.Checks += $diskCheck
    
    # Check memory
    $memCheck = @{
        Name = 'Memory'
        Status = 'OK'
        Details = ''
    }
    
    $memUsage = (Get-Process | Measure-Object -Property WorkingSet -Sum).Sum / 1GB
    if ($memUsage -gt 8) {
        $memCheck.Status = 'WARNING'
        $memCheck.Details = "High memory usage: $([math]::Round($memUsage, 2))GB"
    }
    $health.Checks += $memCheck
    
    # Check script integrity
    $scriptCheck = @{
        Name = 'Script Integrity'
        Status = 'OK'
        Details = ''
    }
    
    $invalidScripts = @(Get-ChildItem .\scripts -Filter "*.ps1" -Recurse | Where-Object {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$errors)
        $errors.Count -gt 0
    })
    
    if ($invalidScripts.Count -gt 0) {
        $scriptCheck.Status = 'ERROR'
        $scriptCheck.Details = "$($invalidScripts.Count) scripts have syntax errors"
        $health.Status = 'Unhealthy'
    }
    $health.Checks += $scriptCheck
    
    return $health
}

function Get-HealthReport {
    $health = Test-SystemHealth
    
    Write-Host ""
    Write-Host "System Health Report" -ForegroundColor Cyan
    Write-Host "Status: $($health.Status)" -ForegroundColor $(if ($health.Status -eq 'Healthy') { 'Green' } else { 'Red' })
    Write-Host ""
    
    foreach ($check in $health.Checks) {
        $color = switch ($check.Status) {
            'OK' { 'Green' }
            'WARNING' { 'Yellow' }
            'ERROR' { 'Red' }
        }
        
        Write-Host "[$($check.Status)] $($check.Name)" -ForegroundColor $color
        if ($check.Details) {
            Write-Host "  $($check.Details)" -ForegroundColor Gray
        }
    }
}
'@
    
    $healthScript | Out-File ".\scripts\utilities\health-checks.ps1" -Encoding UTF8
    Write-Success "Health checks module created"
}

# Component 3: Monitoring Dashboard
if ($Component -in @('dashboard', 'all')) {
    Write-Info "Setting up monitoring dashboard..."
    
    $dashboardScript = @'
function Show-MonitoringDashboard {
    Clear-Host
    
    Write-Host ""
    Write-Host "" -ForegroundColor Cyan
    Write-Host "         WORKSPACE FOUNDATION MONITORING DASHBOARD         " -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "System Status" -ForegroundColor Cyan
    Write-Host ""
    
    . .\scripts\utilities\health-checks.ps1
    Get-HealthReport
    
    Write-Host ""
    Write-Host "Performance Metrics" -ForegroundColor Cyan
    Write-Host ""
    
    $cpu = (Get-WmiObject win32_processor).LoadPercentage
    $mem = (Get-WmiObject win32_operatingsystem).TotalVisibleMemorySize - (Get-WmiObject win32_operatingsystem).FreePhysicalMemory
    $memPercent = ($mem / (Get-WmiObject win32_operatingsystem).TotalVisibleMemorySize) * 100
    
    Write-Host "CPU Usage: $cpu%" -ForegroundColor White
    Write-Host "Memory Usage: $([math]::Round($memPercent, 2))%" -ForegroundColor White
    
    Write-Host ""
    Write-Host "Recent Activity" -ForegroundColor Cyan
    Write-Host ""
    
    $recentLogs = Get-ChildItem .\logs -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    if ($recentLogs) {
        $recentLogs | ForEach-Object {
            Write-Host "$($_.Name) - $($_.LastWriteTime)" -ForegroundColor Gray
        }
    } else {
        Write-Host "No recent logs found" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
}

function Start-MonitoringDashboard {
    param([int]$RefreshInterval = 30)
    
    while ($true) {
        Show-MonitoringDashboard
        Start-Sleep -Seconds $RefreshInterval
    }
}
'@
    
    $dashboardScript | Out-File ".\scripts\utilities\monitoring-dashboard.ps1" -Encoding UTF8
    Write-Success "Monitoring dashboard module created"
}

Write-Header "Monitoring Setup Complete"

Write-Host ""
Write-Host "Created Modules:" -ForegroundColor Cyan
Write-Host "  - Enhanced Telemetry: enhanced-telemetry.ps1" -ForegroundColor Green
Write-Host "  - Health Checks: health-checks.ps1" -ForegroundColor Green
Write-Host "  - Monitoring Dashboard: monitoring-dashboard.ps1" -ForegroundColor Green

Write-Host ""
Write-Host "Usage:" -ForegroundColor Cyan
Write-Host "  . .\scripts\utilities\monitoring-dashboard.ps1" -ForegroundColor Yellow
Write-Host "  Show-MonitoringDashboard" -ForegroundColor Yellow
Write-Host "  Start-MonitoringDashboard -RefreshInterval 30" -ForegroundColor Yellow

Write-Host ""
exit 0