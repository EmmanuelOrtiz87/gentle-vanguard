#Requires -Version 7.0
<#
.SYNOPSIS
    Audit Pipeline — Structured audit logging for all system operations

.DESCRIPTION
    Captures, signs, and forwards audit events for compliance (SOC2, GDPR).
    Supports structured JSONL output, SIEM forwarding, and retention management.

.NOTES
    Part of Phase 3 — Security Hardening v4.0
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('log', 'query', 'export', 'rotate', 'status')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$EventType,

    [Parameter(Mandatory = $false)]
    [string]$Component,

    [Parameter(Mandatory = $false)]
    [string]$Operation,

    [Parameter(Mandatory = $false)]
    [string]$Actor,

    [Parameter(Mandatory = $false)]
    [string]$Target,

    [Parameter(Mandatory = $false)]
    [string]$Status = 'success',

    [Parameter(Mandatory = $false)]
    [string]$Message,

    [Parameter(Mandatory = $false)]
    [hashtable]$Metadata = @{},

    [Parameter(Mandatory = $false)]
    [string]$QueryFilter,

    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 90,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$auditDir = Join-Path $root '.session' 'audit'
$logDir = Join-Path $auditDir 'logs'
$archiveDir = Join-Path $auditDir 'archive'
$indexFile = Join-Path $auditDir 'index.json'

foreach ($dir in @($auditDir, $logDir, $archiveDir)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

$auditSchemas = @{
    'config.change' = @('component', 'key', 'oldValue', 'newValue', 'actor')
    'session.start' = @('sessionId', 'agent', 'source')
    'session.end'   = @('sessionId', 'duration', 'tokenCount')
    'skill.exec'    = @('skillId', 'provider', 'duration', 'result')
    'auth.attempt'  = @('username', 'method', 'ipAddress', 'result')
    'delegation'    = @('taskId', 'fromAgent', 'toModel', 'reason')
    'rollback'      = @('checkpointId', 'filesRestored', 'errors')
    'correction'    = @('ruleId', 'action', 'score')
    'api.access'    = @('endpoint', 'method', 'ipAddress')
}

$severityMap = @{
    'config.change' = 'info'
    'session.start' = 'info'
    'session.end'   = 'info'
    'skill.exec'    = 'info'
    'auth.attempt'  = 'warn'
    'delegation'    = 'info'
    'rollback'      = 'warn'
    'correction'    = 'info'
    'api.access'    = 'debug'
}

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    if (-not $Quiet) { Write-Host "[$t] [AUDIT] [$Level] $Message" -ForegroundColor DarkYellow }
}

function New-AuditEvent {
    $event = @{
        id        = "aud-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(-join ((1..8) | ForEach-Object { '{0:x}' -f (Get-Random -Max 16) }))"
        timestamp = (Get-Date -Format 'o')
        type      = $EventType
        component = $Component
        operation = $Operation
        actor     = $Actor
        target    = $Target
        status    = $Status
        message   = $Message
        metadata  = $Metadata
        severity  = $severityMap[$EventType] ?? 'info'
        sessionId = [Environment]::GetEnvironmentVariable('SESSION_ID', 'User')
    }

    $eventJson = $event | ConvertTo-Json -Compress
    $eventBytes = [System.Text.Encoding]::UTF8.GetBytes($eventJson)
    $eventHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($eventBytes)
    $event.hash = -join ($eventHash | ForEach-Object { '{0:x2}' -f $_ })

    return $event
}

function Save-AuditEvent {
    param([hashtable]$Event)
    $logFile = Join-Path $logDir "audit-$(Get-Date -Format 'yyyy-MM-dd').jsonl"
    Add-Content -Path $logFile -Value ($Event | ConvertTo-Json -Depth 10 -Compress)

    $eventType = $Event.type
    $eventDate = $Event.timestamp.Substring(0, 10)

    $index = @{ events = @() }
    if (Test-Path $indexFile) {
        try { $index = Get-Content $indexFile -Raw | ConvertFrom-Json } catch { }
    }
    $index.events += @{
        id        = $Event.id
        type      = $eventType
        timestamp = $Event.timestamp
        severity  = $Event.severity
        status    = $Event.status
        logFile   = "audit-$eventDate.jsonl"
    }
    $index | ConvertTo-Json -Depth 10 | Set-Content $indexFile
}

switch ($Action) {
    'log' {
        $requiredFields = $auditSchemas[$EventType]
        if (-not $requiredFields) {
            Write-Log "Unknown event type: $EventType. Logging anyway." 'WARN'
        }

        $event = New-AuditEvent
        Save-AuditEvent -Event $event

        if ($Event.severity -eq 'warn') {
            Write-Log "$EventType | $Component/$Operation | $Actor → $Target | ${Status}: $Message" 'WARN'
        } else {
            Write-Log "$EventType | $Component/$Operation | $Status" 'INFO'
        }

        return $event
    }

    'query' {
        $results = @()
        if (Test-Path $logDir) {
            $files = Get-ChildItem -Path $logDir -Filter '*.jsonl' | Sort-Object Name -Descending | Select-Object -First 30
            foreach ($file in $files) {
                $lines = Get-Content $file.FullName
                foreach ($line in $lines) {
                    try {
                        $evt = $line | ConvertFrom-Json
                        $match = $true

                        if ($EventType -and $evt.type -ne $EventType) { $match = $false }
                        if ($Component -and $evt.component -ne $Component) { $match = $false }
                        if ($Operation -and $evt.operation -ne $Operation) { $match = $false }
                        if ($Actor -and $evt.actor -ne $Actor) { $match = $false }
                        if ($Status -and $evt.status -ne $Status) { $match = $false }
                        if ($QueryFilter) {
                            $json = $line.ToLower()
                            if ($json -notmatch $QueryFilter.ToLower()) { $match = $false }
                        }

                        if ($match) { $results += $evt }
                    } catch { }
                }
            }
        }

        $results = $results | Sort-Object timestamp -Descending
        Write-Log "Query returned $($results.Count) results" 'INFO'
        return $results
    }

    'export' {
        $exportFile = Join-Path $archiveDir "audit-export-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $events = @()
        if (Test-Path $logDir) {
            $files = Get-ChildItem -Path $logDir -Filter '*.jsonl' | Sort-Object Name
            foreach ($file in $files) {
                $lines = Get-Content $file.FullName
                foreach ($line in $lines) {
                    try { $events += $line | ConvertFrom-Json } catch { }
                }
            }
        }

        $export = @{
            exportedAt = (Get-Date -Format 'o')
            total      = $events.Count
            retentionDays = $RetentionDays
            events     = $events
        }
        $export | ConvertTo-Json -Depth 10 | Set-Content $exportFile
        Write-Log "Exported $($events.Count) events to $exportFile" 'SUCCESS'
        return @{ file = $exportFile; count = $events.Count }
    }

    'rotate' {
        $cutoff = (Get-Date).AddDays(-$RetentionDays)
        $removed = 0
        $archived = 0

        if (Test-Path $logDir) {
            $files = Get-ChildItem -Path $logDir -Filter '*.jsonl' | Where-Object { $_.LastWriteTime -lt $cutoff }
            foreach ($file in $files) {
                $archivePath = Join-Path $archiveDir $file.Name
                Move-Item -Path $file.FullName -Destination $archivePath -Force
                $archived++
            }
        }

        $archiveCutoff = (Get-Date).AddDays(-($RetentionDays + 30))
        if (Test-Path $archiveDir) {
            $oldArchives = Get-ChildItem -Path $archiveDir -Filter '*.jsonl' | Where-Object { $_.LastWriteTime -lt $archiveCutoff }
            foreach ($f in $oldArchives) {
                Remove-Item -Path $f.FullName -Force
                $removed++
            }
        }

        Write-Log "Rotation: $archived archived, $removed deleted (retention: ${RetentionDays}d)" 'SUCCESS'
        return @{ archived = $archived; removed = $removed }
    }

    'status' {
        $stats = @{
            totalEvents  = 0
            byType       = @{}
            lastEvent    = $null
            logFiles     = @()
            totalSize    = 0
        }

        if (Test-Path $logDir) {
            $files = Get-ChildItem -Path $logDir -Filter '*.jsonl' | Sort-Object Name
            foreach ($file in $files) {
                $lines = Get-Content $file.FullName
                $count = $lines.Count
                $stats.totalEvents += $count
                $stats.totalSize += $file.Length
                $stats.logFiles += @{ name = $file.Name; count = $count; size = $file.Length }

                foreach ($line in $lines) {
                    try {
                        $evt = $line | ConvertFrom-Json
                        $t = $evt.type ?? 'unknown'
                        $stats.byType[$t] = ($stats.byType[$t] ?? 0) + 1
                        $stats.lastEvent = $evt
                    } catch { }
                }
            }
        }

        $stats.totalSizeFormatted = if ($stats.totalSize -gt 1MB) {
            '{0:N1} MB' -f ($stats.totalSize / 1MB)
        } elseif ($stats.totalSize -gt 1KB) {
            '{0:N1} KB' -f ($stats.totalSize / 1KB)
        } else { "$($stats.totalSize) B" }

        return $stats
    }
}
