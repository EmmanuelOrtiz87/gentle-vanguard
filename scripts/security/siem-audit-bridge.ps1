#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Gentle-Vanguard SIEM Audit Bridge — Routes audit events to SIEM endpoints
    
.DESCRIPTION
    Reads JSONL audit logs and forwards to configured SIEM (Splunk, ELK, Datadog,
    or local structured file). Implements SOC2 CC7.2 (monitoring of security events)
    and GDPR Art.33 (breach notification pipeline).
    
    Design: Local-first (always writes to structured JSONL). Cloud SIEM forwarding
    is optional and configured via config/observability-config.json.
    Runs on schedule (cron/Task Scheduler) or on-demand.
    
.PARAMETER Mode
    tail    — Process new entries since last checkpoint (default, for scheduled runs)
    full    — Reprocess all audit log entries
    status  — Show SIEM bridge status and last checkpoint
    test    — Send a test event to configured SIEM endpoint
    
.PARAMETER LogFile
    Override default audit log path (default: logs/secret-audit.jsonl)
    
.EXAMPLE
    .\siem-audit-bridge.ps1 -Mode tail
    .\siem-audit-bridge.ps1 -Mode status
    .\siem-audit-bridge.ps1 -Mode test
#>

param(
    [ValidateSet('tail', 'full', 'status', 'test')]
    [string]$Mode = 'tail',
    [string]$LogFile = ''
)

$ErrorActionPreference = 'Stop'
$BRIDGE_VERSION = '1.0.0'

# ── Paths ──────────────────────────────────────────────────────────────────────
$ScriptDir     = $PSScriptRoot
$SecurityDir   = Split-Path -Parent $ScriptDir   # scripts/security → scripts/
$ScriptsDir    = Split-Path -Parent $SecurityDir  # If needed
# Resolve workspace root
$WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not (Test-Path (Join-Path $WorkspaceRoot 'config'))) {
    # Fallback: try one level up
    $WorkspaceRoot = Split-Path -Parent $WorkspaceRoot
}
$LogDir        = Join-Path $WorkspaceRoot 'logs'
$ConfigPath    = Join-Path $WorkspaceRoot 'config' 'observability-config.json'
$CheckpointFile = Join-Path $LogDir 'siem-checkpoint.json'
$SiemOutputLog  = Join-Path $LogDir 'siem-forwarded.jsonl'
$AlertLog       = Join-Path $LogDir 'siem-alerts.jsonl'

$DefaultAuditLog = Join-Path $LogDir 'secret-audit.jsonl'
$AuditLog = if ($LogFile) { $LogFile } else { $DefaultAuditLog }

# ── Alert thresholds (from SOC2/Secrets governance) ───────────────────────────
$ALERT_MASS_ACCESS_THRESHOLD = 10    # >10 access ops in 5 minutes
$ALERT_MASS_ACCESS_WINDOW    = 5     # minutes
$ALERT_FAILURE_THRESHOLD     = 3     # >3 failures in 10 minutes

# ── Load SIEM config ───────────────────────────────────────────────────────────
function Get-SiemConfig {
    if (-not (Test-Path $ConfigPath)) { return $null }
    try {
        $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        return $cfg.siem ?? $cfg.PSObject.Properties['siem']?.Value
    } catch { return $null }
}

# ── Checkpoint management ──────────────────────────────────────────────────────
function Get-Checkpoint {
    if (Test-Path $CheckpointFile) {
        try { return Get-Content $CheckpointFile -Raw | ConvertFrom-Json }
        catch {}
    }
    return [PSCustomObject]@{ lastLine = 0; lastTimestamp = ''; lastRun = '' }
}

function Save-Checkpoint {
    param([int]$lineNum, [string]$lastTs)
    @{
        lastLine      = $lineNum
        lastTimestamp = $lastTs
        lastRun       = (Get-Date -Format 'o')
        bridgeVersion = $BRIDGE_VERSION
    } | ConvertTo-Json | Set-Content $CheckpointFile -Encoding UTF8
}

# ── Normalize audit entry to SIEM event ───────────────────────────────────────
function ConvertTo-SiemEvent {
    param($entry, [string]$source = 'gentle-vanguard-secret-vault')
    return [ordered]@{
        timestamp   = $entry.timestamp
        source      = $source
        version     = $BRIDGE_VERSION
        event = [ordered]@{
            operation = $entry.operation
            secret    = $entry.secret
            outcome   = $entry.outcome
            details   = $entry.details
            actor     = $entry.actor
            machine   = $entry.machine
            pid       = $entry.pid
        }
        severity = switch ($entry.outcome) {
            'FAILURE' { 'ERROR' }
            'WARNING' { 'WARN' }
            default   { 'INFO' }
        }
        tags = @('gentle-vanguard', 'secrets', 'compliance', 'audit')
    }
}

# ── Forward event (local structured + optional cloud SIEM) ────────────────────
function Send-ToSiem {
    param($siemEvent, $siemConfig)
    
    # Always write to local structured SIEM log (ECS-compatible format)
    $jsonLine = $siemEvent | ConvertTo-Json -Compress -Depth 6
    Add-Content -Path $SiemOutputLog -Value $jsonLine -Encoding UTF8
    
    # Optional: Forward to cloud SIEM (requires explicit config)
    if ($siemConfig -and $siemConfig.enabled -eq $true) {
        $endpoint = $siemConfig.endpoint
        $provider = $siemConfig.provider  # splunk | elk | datadog | custom
        
        try {
            switch ($provider) {
                'splunk' {
                    $headers = @{ 
                        'Authorization' = "Splunk $($siemConfig.token)"
                        'Content-Type'  = 'application/json'
                    }
                    $body = @{ event = $siemEvent; sourcetype = 'gentle-vanguard:audit' } | ConvertTo-Json -Depth 8
                    Invoke-RestMethod -Uri "$endpoint/services/collector/event" `
                        -Method POST -Headers $headers -Body $body -TimeoutSec 10 | Out-Null
                }
                'datadog' {
                    $headers = @{
                        'DD-API-KEY'  = $siemConfig.apiKey
                        'Content-Type' = 'application/json'
                    }
                    $body = @{
                        ddsource  = 'gentle-vanguard'
                        ddtags    = 'env:production,service:gentle-vanguard-vault'
                        hostname  = $siemEvent.event.machine
                        message   = $siemEvent | ConvertTo-Json -Compress -Depth 6
                    } | ConvertTo-Json -Depth 8
                    Invoke-RestMethod -Uri "$endpoint/v1/input" `
                        -Method POST -Headers $headers -Body $body -TimeoutSec 10 | Out-Null
                }
                'elk' {
                    $headers = @{ 'Content-Type' = 'application/json' }
                    if ($siemConfig.apiKey) { $headers['Authorization'] = "ApiKey $($siemConfig.apiKey)" }
                    $body = $siemEvent | ConvertTo-Json -Depth 8
                    Invoke-RestMethod -Uri "$endpoint/_doc" `
                        -Method POST -Headers $headers -Body $body -TimeoutSec 10 | Out-Null
                }
                default {
                    # Generic webhook
                    $body = $siemEvent | ConvertTo-Json -Depth 8
                    Invoke-RestMethod -Uri $endpoint `
                        -Method POST -Headers @{ 'Content-Type' = 'application/json' } `
                        -Body $body -TimeoutSec 10 | Out-Null
                }
            }
            return $true
        } catch {
            # Non-blocking: cloud SIEM failure doesn't break local logging
            Write-Host "  [WARN] Cloud SIEM forward failed: $($_.Exception.Message)" -ForegroundColor Yellow
            return $false
        }
    }
    
    return $true
}

# ── Anomaly detection ──────────────────────────────────────────────────────────
function Invoke-AnomalyDetection {
    param([array]$entries)
    
    $alerts = @()
    $now = Get-Date
    
    # Rule 1: Mass access (>10 get operations in 5 minutes)
    $recentAccess = $entries | Where-Object {
        $_.operation -eq 'get' -and 
        $_.timestamp -and
        (try { ($now - [datetime]$_.timestamp).TotalMinutes -le $ALERT_MASS_ACCESS_WINDOW } catch { $false })
    }
    if ($recentAccess.Count -ge $ALERT_MASS_ACCESS_THRESHOLD) {
        $alerts += @{
            type      = 'MASS_SECRET_ACCESS'
            severity  = 'HIGH'
            message   = "Mass secret access detected: $($recentAccess.Count) operations in ${ALERT_MASS_ACCESS_WINDOW} minutes"
            timestamp = (Get-Date -Format 'o')
        }
    }
    
    # Rule 2: Multiple failures (>3 failures in 10 minutes)
    $recentFailures = $entries | Where-Object {
        $_.outcome -eq 'FAILURE' -and 
        $_.timestamp -and
        (try { ($now - [datetime]$_.timestamp).TotalMinutes -le 10 } catch { $false })
    }
    if ($recentFailures.Count -ge $ALERT_FAILURE_THRESHOLD) {
        $alerts += @{
            type      = 'REPEATED_FAILURES'
            severity  = 'MEDIUM'
            message   = "Repeated authentication failures: $($recentFailures.Count) in 10 minutes"
            timestamp = (Get-Date -Format 'o')
        }
    }
    
    # Rule 3: Breach response events (always alert)
    $breachEvents = $entries | Where-Object { $_.operation -eq 'breach-response' }
    foreach ($b in $breachEvents) {
        $alerts += @{
            type      = 'SECRET_BREACH'
            severity  = 'CRITICAL'
            message   = "Secret breach response activated for: $($b.secret) — $($b.details)"
            timestamp = $b.timestamp
        }
    }
    
    return $alerts
}

# ── Write alert ────────────────────────────────────────────────────────────────
function Write-Alert {
    param([hashtable]$alert)
    $alert | ConvertTo-Json -Compress | Add-Content -Path $AlertLog -Encoding UTF8
    
    $color = switch ($alert.severity) {
        'CRITICAL' { 'Red' }
        'HIGH'     { 'Red' }
        'MEDIUM'   { 'Yellow' }
        default    { 'White' }
    }
    Write-Host "  [ALERT][$($alert.severity)] $($alert.message)" -ForegroundColor $color
}

# ══ MODES ══════════════════════════════════════════════════════════════════════

function Invoke-Tail {
    if (-not (Test-Path $AuditLog)) {
        Write-Host "[INFO] No audit log found at: $AuditLog" -ForegroundColor Yellow
        Write-Host "[INFO] No events to process." -ForegroundColor Gray
        return
    }
    
    $checkpoint  = Get-Checkpoint
    $allLines    = @(Get-Content $AuditLog -Encoding UTF8)
    $newLines    = $allLines | Select-Object -Skip $checkpoint.lastLine
    
    if ($newLines.Count -eq 0) {
        Write-Host "[INFO] No new audit events since last run (checkpoint: line $($checkpoint.lastLine))." -ForegroundColor Gray
        return
    }
    
    $siemConfig  = Get-SiemConfig
    $processed   = 0
    $forwarded   = 0
    $lastTs      = ''
    $entries     = @()
    
    foreach ($line in $newLines) {
        try {
            $entry = $line | ConvertFrom-Json
            $entries += $entry
            $siemEvent = ConvertTo-SiemEvent $entry
            $ok = Send-ToSiem $siemEvent $siemConfig
            if ($ok) { $forwarded++ }
            $processed++
            $lastTs = $entry.timestamp
        } catch {
            Write-Host "  [WARN] Skipping malformed log line: $line" -ForegroundColor Yellow
        }
    }
    
    # Anomaly detection on new entries
    $alerts = Invoke-AnomalyDetection $entries
    foreach ($alert in $alerts) { Write-Alert $alert }
    
    Save-Checkpoint ($checkpoint.lastLine + $processed) $lastTs
    
    Write-Host "[OK] SIEM bridge processed $processed event(s), $forwarded forwarded." -ForegroundColor Green
    if ($alerts.Count -gt 0) {
        Write-Host "[!] $($alerts.Count) alert(s) generated — see: $AlertLog" -ForegroundColor Yellow
    }
}

function Invoke-Full {
    if (-not (Test-Path $AuditLog)) {
        Write-Host "[INFO] No audit log found." -ForegroundColor Yellow
        return
    }
    
    $allLines   = @(Get-Content $AuditLog -Encoding UTF8)
    $siemConfig = Get-SiemConfig
    $processed  = 0
    $forwarded  = 0
    $lastTs     = ''
    $entries    = @()
    
    foreach ($line in $allLines) {
        try {
            $entry = $line | ConvertFrom-Json
            $entries += $entry
            $siemEvent = ConvertTo-SiemEvent $entry
            $ok = Send-ToSiem $siemEvent $siemConfig
            if ($ok) { $forwarded++ }
            $processed++
            $lastTs = $entry.timestamp
        } catch {
            Write-Host "  [WARN] Skipping malformed log line." -ForegroundColor Yellow
        }
    }
    
    $alerts = Invoke-AnomalyDetection $entries
    foreach ($alert in $alerts) { Write-Alert $alert }
    
    Save-Checkpoint $processed $lastTs
    Write-Host "[OK] Full reprocess: $processed event(s), $forwarded forwarded." -ForegroundColor Green
}

function Invoke-Status {
    Write-Host ""
    Write-Host "  Gentle-Vanguard SIEM Audit Bridge v$BRIDGE_VERSION" -ForegroundColor Cyan
    Write-Host "  ──────────────────────────────────────────" -ForegroundColor Gray
    
    $checkpoint = Get-Checkpoint
    Write-Host "  Audit log:      $AuditLog" -ForegroundColor White
    Write-Host "  SIEM output:    $SiemOutputLog" -ForegroundColor White
    Write-Host "  Alert log:      $AlertLog" -ForegroundColor White
    Write-Host "  Last run:       $(if ($checkpoint.lastRun) { $checkpoint.lastRun } else { 'Never' })" -ForegroundColor White
    Write-Host "  Last checkpoint: line $($checkpoint.lastLine)" -ForegroundColor White
    
    if (Test-Path $AuditLog) {
        $totalLines = (Get-Content $AuditLog | Measure-Object -Line).Lines
        Write-Host "  Total events:   $totalLines ($(${totalLines} - $checkpoint.lastLine) unprocessed)" -ForegroundColor White
    }
    
    $siemConfig = Get-SiemConfig
    if ($siemConfig -and $siemConfig.enabled) {
        Write-Host "  Cloud SIEM:     $($siemConfig.provider) — $($siemConfig.endpoint)" -ForegroundColor Green
    } else {
        Write-Host "  Cloud SIEM:     Not configured (local-only mode)" -ForegroundColor Yellow
        Write-Host "                  Configure via config/observability-config.json#siem" -ForegroundColor Gray
    }
    
    if (Test-Path $AlertLog) {
        $alertCount = (Get-Content $AlertLog | Measure-Object -Line).Lines
        $color = if ($alertCount -gt 0) { 'Yellow' } else { 'Green' }
        Write-Host "  Active alerts:  $alertCount" -ForegroundColor $color
    } else {
        Write-Host "  Active alerts:  0" -ForegroundColor Green
    }
    Write-Host ""
}

function Invoke-Test {
    Write-Host "[INFO] Sending test event to SIEM..." -ForegroundColor Cyan
    
    $testEvent = ConvertTo-SiemEvent ([PSCustomObject]@{
        timestamp = (Get-Date -Format 'o')
        operation = 'test'
        secret    = 'SIEM_TEST'
        outcome   = 'SUCCESS'
        details   = 'SIEM bridge connectivity test'
        actor     = $env:USERNAME
        machine   = $env:COMPUTERNAME
        pid       = $PID
    }) 'gentle-vanguard-siem-test'
    
    $siemConfig = Get-SiemConfig
    $ok = Send-ToSiem $testEvent $siemConfig
    
    if ($ok) {
        Write-Host "[OK] Test event written to: $SiemOutputLog" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Local write OK but cloud SIEM forward failed." -ForegroundColor Yellow
    }
    Write-Host "      Check config/observability-config.json#siem for cloud config." -ForegroundColor Gray
}

# ══ MAIN ═══════════════════════════════════════════════════════════════════════
foreach ($dir in @($LogDir)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

switch ($Mode) {
    'tail'   { Invoke-Tail }
    'full'   { Invoke-Full }
    'status' { Invoke-Status }
    'test'   { Invoke-Test }
}

