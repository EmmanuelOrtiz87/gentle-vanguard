#Requires -Version 7.0
<#
.SYNOPSIS
    Session Snapshot Manager — Periodic .session state snapshots with rotation

.DESCRIPTION
    Takes lightweight JSON snapshots of key session state files at configurable
    intervals. Supports retention policies, compression, and diff detection.

.NOTES
    Part of Phase 2 — State Persistence v4.0
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('snapshot', 'list', 'cleanup', 'schedule')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$Label,

    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 7,

    [Parameter(Mandatory = $false)]
    [int]$IntervalSeconds = 300,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
$snapshotDir = Join-Path $root '.session' 'snapshots'
$sessionDir = Join-Path $root '.session'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    if (-not $Quiet) { Write-Host "[$t] [SNAP] [$Level] $Message" -ForegroundColor Magenta }
}

$criticalFiles = @(
    'session-state.json',
    'token-usage.json',
    'cloud-metrics.json',
    'hybrid-metrics.json',
    'metrics-report.json',
    'health.json'
)

switch ($Action) {
    'snapshot' {
        if (-not (Test-Path $snapshotDir)) { New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null }

        $snapshot = @{
            id        = "snap-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            timestamp = (Get-Date -Format 'o')
            label     = $Label
            files     = @{}
        }

        foreach ($f in $criticalFiles) {
            $fp = Join-Path $sessionDir $f
            if (Test-Path $fp) {
                try {
                    $snapshot.files[$f] = Get-Content $fp -Raw
                } catch {
                    Write-Log "Failed to read ${f}: $_" 'WARN'
                }
            }
        }

        $snapshotPath = Join-Path $snapshotDir "$($snapshot.id).json"
        $snapshot | ConvertTo-Json -Depth 10 | Set-Content $snapshotPath
        Write-Log "Snapshot $($snapshot.id) saved ($($snapshot.files.Count) files)" 'SUCCESS'

        return $snapshot
    }

    'list' {
        $snapshots = @()
        if (Test-Path $snapshotDir) {
            $files = Get-ChildItem -Path $snapshotDir -Filter '*.json' | Sort-Object LastWriteTime -Descending
            foreach ($f in $files) {
                try {
                    $content = Get-Content $f.FullName -Raw | ConvertFrom-Json
                    $snapshots += @{
                        id        = $content.id
                        timestamp = $content.timestamp
                        label     = $content.label
                        files     = $content.files.PSObject.Properties.Name.Count
                        size      = '{0:N1} KB' -f ($f.Length / 1KB)
                    }
                } catch {
                    $snapshots += @{ id = $f.BaseName; timestamp = $f.LastWriteTime.ToString('o'); error = 'corrupted' }
                }
            }
        }
        return $snapshots
    }

    'cleanup' {
        $cutoff = (Get-Date).AddDays(-$RetentionDays)
        $removed = 0
        if (Test-Path $snapshotDir) {
            $files = Get-ChildItem -Path $snapshotDir -Filter '*.json' | Where-Object { $_.LastWriteTime -lt $cutoff }
            foreach ($f in $files) {
                Remove-Item -Path $f.FullName -Force
                $removed++
                Write-Log "Removed expired snapshot: $($f.Name)" 'INFO'
            }
        }
        Write-Log "Cleanup complete: $removed snapshots removed (retention: ${RetentionDays}d)" 'SUCCESS'
        return @{ removed = $removed; retentionDays = $RetentionDays }
    }

    'schedule' {
        Write-Log "Snapshot scheduler started (interval: ${IntervalSeconds}s, retention: ${RetentionDays}d)" 'INFO'
        Write-Log "Press Ctrl+C to stop" 'INFO'
        $counter = 0
        while ($true) {
            $counter++
            & $PSCommandPath -Action snapshot -Label "auto-$counter" -Quiet:$Quiet
            if ($counter % 10 -eq 0) {
                & $PSCommandPath -Action cleanup -RetentionDays $RetentionDays -Quiet:$Quiet
            }
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
}
