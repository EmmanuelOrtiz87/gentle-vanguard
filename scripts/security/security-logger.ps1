#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Security Logger - Audit and Security Event Logging
    
.DESCRIPTION
    Logs security events and maintains audit trail
    
.PARAMETER EventType
    Type of event: access, modification, deletion, error, warning
    
.PARAMETER Message
    Event message
    
.PARAMETER Severity
    Severity level: low, medium, high, critical
    
.EXAMPLE
    .\security-logger.ps1 -EventType access -Message "User accessed config" -Severity low
#>

param(
    [ValidateSet('access', 'modification', 'deletion', 'error', 'warning', 'info')]
    [string]$EventType = 'info',
    [string]$Message,
    [ValidateSet('low', 'medium', 'high', 'critical')]
    [string]$Severity = 'low',
    [string]$LogLevel = 'info'
)

$LoggerVersion = "1.0.0"
$logsDir = ".\logs\security"
$auditFile = "$logsDir\audit-trail.log"

function Write-Log {
    param([string]$Message, [string]$Level = "info")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Initialize-LogDirectory {
    Write-Log "Initializing log directory..." "info"
    
    if (-not (Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
        Write-Log "Log directory created: $logsDir" "info"
    }
}

function Log-SecurityEvent {
    param(
        [string]$Type,
        [string]$Message,
        [string]$Severity
    )
    
    Write-Log "Logging security event: $Type" "info"
    
    Initialize-LogDirectory
    
    $event = @{
        timestamp = Get-Date -Format "o"
        type = $Type
        message = $Message
        severity = $Severity
        user = [Environment]::UserName
        computer = [Environment]::MachineName
        processId = $PID
    }
    
    $eventJson = $event | ConvertTo-Json
    Add-Content -Path $auditFile -Value $eventJson
    
    Write-Log "Event logged successfully" "info"
    return $event
}

function Get-AuditTrail {
    param(
        [int]$LastHours = 24,
        [string]$FilterType = $null
    )
    
    Write-Log "Retrieving audit trail (last $LastHours hours)..." "info"
    
    if (-not (Test-Path $auditFile)) {
        Write-Log "Audit file not found" "warn"
        return @()
    }
    
    $cutoffTime = (Get-Date).AddHours(-$LastHours)
    $events = @()
    
    Get-Content -Path $auditFile | ForEach-Object {
        try {
            $event = $_ | ConvertFrom-Json
            $eventTime = [DateTime]::Parse($event.timestamp)
            
            if ($eventTime -gt $cutoffTime) {
                if ([string]::IsNullOrEmpty($FilterType) -or $event.type -eq $FilterType) {
                    $events += $event
                }
            }
        }
        catch {
            Write-Log "Error parsing event: $_" "error"
        }
    }
    
    Write-Log "Retrieved $($events.Count) events" "info"
    return $events
}

function Detect-Anomalies {
    Write-Log "Detecting anomalies..." "info"
    
    $recentEvents = Get-AuditTrail -LastHours 1
    $anomalies = @()
    
    $deletionCount = ($recentEvents | Where-Object { $_.type -eq 'deletion' }).Count
    if ($deletionCount -gt 5) {
        $anomalies += @{
            type = "excessive_deletions"
            count = $deletionCount
            severity = "high"
        }
    }
    
    $errorCount = ($recentEvents | Where-Object { $_.type -eq 'error' }).Count
    if ($errorCount -gt 10) {
        $anomalies += @{
            type = "excessive_errors"
            count = $errorCount
            severity = "medium"
        }
    }
    
    if ($anomalies.Count -gt 0) {
        Write-Log "Detected $($anomalies.Count) anomalies" "warn"
    }
    else {
        Write-Log "No anomalies detected" "info"
    }
    
    return $anomalies
}

function Generate-SecurityReport {
    Write-Log "Generating security report..." "info"
    
    $events = Get-AuditTrail -LastHours 24
    $anomalies = Detect-Anomalies
    
    $report = @{
        timestamp = Get-Date -Format "o"
        version = $LoggerVersion
        period = "24 hours"
        totalEvents = $events.Count
        eventsByType = @{}
        eventsBySeverity = @{}
        anomalies = $anomalies
    }
    
    $events | Group-Object -Property type | ForEach-Object {
        $report.eventsByType[$_.Name] = $_.Count
    }
    
    $events | Group-Object -Property severity | ForEach-Object {
        $report.eventsBySeverity[$_.Name] = $_.Count
    }
    
    $reportPath = "$logsDir\security-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json | Set-Content -Path $reportPath
    
    Write-Log "Security report generated: $reportPath" "info"
    return $report
}

function Cleanup-OldLogs {
    param([int]$RetentionDays = 90)
    
    Write-Log "Cleaning up logs older than $RetentionDays days..." "info"
    
    Initialize-LogDirectory
    
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $deletedCount = 0
    
    Get-ChildItem -Path $logsDir -Filter "*.log" -File | ForEach-Object {
        if ($_.LastWriteTime -lt $cutoffDate) {
            Remove-Item -Path $_.FullName -Force
            $deletedCount++
        }
    }
    
    Write-Log "Deleted $deletedCount old log files" "info"
    return $deletedCount
}

function Main {
    Write-Log "Security Logger v$LoggerVersion" "info"
    Write-Log "Event Type: $EventType" "info"
    
    if ([string]::IsNullOrEmpty($Message)) {
        Write-Log "Message is required" "error"
        return 1
    }
    
    $event = Log-SecurityEvent -Type $EventType -Message $Message -Severity $Severity
    
    if ($event) {
        Write-Log "Security event logged successfully" "info"
        return 0
    }
    else {
        Write-Log "Failed to log security event" "error"
        return 1
    }
}

exit (Main)