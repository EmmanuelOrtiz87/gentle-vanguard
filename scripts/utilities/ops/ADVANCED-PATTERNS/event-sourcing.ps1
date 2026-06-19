#Requires -Version 7.0
<#
.SYNOPSIS
    Event Sourcing Engine — Append-only event store with replay and projection

.DESCRIPTION
    Implements event sourcing pattern for session events with:
    - Append-only event store (JSONL)
    - Event replay by aggregate ID
    - Projection building for current state
    - Snapshot creation for performance

.NOTES
    Part of Phase 5 — Advanced Patterns v4.0
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('append', 'replay', 'project', 'snapshot', 'list')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$AggregateId,

    [Parameter(Mandatory = $false)]
    [string]$EventType,

    [Parameter(Mandatory = $false)]
    [string]$EventData,

    [Parameter(Mandatory = $false)]
    [int]$FromVersion = 0,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))))
$eventStoreDir = Join-Path $root '.session' 'event-store'
$snapshotDir = Join-Path $root '.session' 'event-snapshots'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $t = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    if (-not $Quiet) { Write-Host "[$t] [EVT] [$Level] $Message" -ForegroundColor DarkCyan }
}

function Ensure-Dirs {
    foreach ($d in @($eventStoreDir, $snapshotDir)) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
}

function Get-StorePath {
    param([string]$Id)
    return Join-Path $eventStoreDir "$Id.jsonl"
}

function Get-SnapshotPath {
    param([string]$Id)
    return Join-Path $snapshotDir "$Id-snapshot.json"
}

function New-EventId {
    return "evt-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(-join ((1..8) | ForEach-Object { '{0:x}' -f (Get-Random -Max 16) }))"
}

function New-Event {
    param([string]$AggregateId, [string]$Type, [hashtable]$Data, [int]$Version)
    return @{
        eventId     = New-EventId
        aggregateId = $AggregateId
        type        = $Type
        data        = $Data
        version     = $Version
        timestamp   = (Get-Date -Format 'o')
        sessionId   = [Environment]::GetEnvironmentVariable('SESSION_ID', 'User')
    }
}

function Save-Event {
    param([hashtable]$Event)
    $path = Get-StorePath -Id $Event.aggregateId
    Add-Content -Path $path -Value ($Event | ConvertTo-Json -Depth 10 -Compress)
}

function Load-Events {
    param([string]$Id)
    $path = Get-StorePath -Id $Id
    if (-not (Test-Path $path)) { return @() }
    return Get-Content $path | ForEach-Object { $_ | ConvertFrom-Json }
}

function Get-NextVersion {
    param([string]$Id)
    $events = Load-Events -Id $Id
    if ($events.Count -eq 0) { return 1 }
    return ($events[-1].version) + 1
}

# Projection handlers
$projections = @{
    'session.started' = { param($state, $evt) $state.status = 'active'; $state.startedAt = $evt.timestamp }
    'session.ended' = { param($state, $evt) $state.status = 'completed'; $state.endedAt = $evt.timestamp; $state.duration = $evt.data.duration }
    'session.scored' = { param($state, $evt) $state.score = $evt.data.score; $state.quality = $evt.data.quality }
    'skill.executed' = { param($state, $evt) $state.skillsExecuted = ($state.skillsExecuted ?? 0) + 1; $state.lastSkill = $evt.data.skillId }
    'config.changed' = { param($state, $evt) $state.configChanges = ($state.configChanges ?? 0) + 1; $state.lastConfigChange = $evt.data.key }
    'correction.applied' = { param($state, $evt) $state.corrections = ($state.corrections ?? 0) + 1; $state.lastCorrection = $evt.data.ruleId }
    'checkpoint.created' = { param($state, $evt) $state.checkpoints = ($state.checkpoints ?? 0) + 1; $state.lastCheckpoint = $evt.data.checkpointId }
    'rollback.executed' = { param($state, $evt) $state.rollbacks = ($state.rollbacks ?? 0) + 1; $state.lastRollback = $evt.data.checkpointId }
    'cloud.invocation' = { param($state, $evt) $state.cloudCalls = ($state.cloudCalls ?? 0) + 1; $state.cloudCost = ($state.cloudCost ?? 0) + ($evt.data.cost ?? 0) }
}

switch ($Action) {
    'append' {
        Ensure-Dirs
        if (-not $AggregateId) { throw 'AggregateId required' }
        if (-not $EventType) { throw 'EventType required' }
        $data = if ($EventData) { $EventData | ConvertFrom-Json -AsHashtable } else { @{} }
        $version = Get-NextVersion -Id $AggregateId
        $event = New-Event -AggregateId $AggregateId -Type $EventType -Data $data -Version $version
        Save-Event -Event $event
        Write-Log "Event #${version}: $EventType → $AggregateId" 'SUCCESS'
        return $event
    }

    'replay' {
        if (-not $AggregateId) { throw 'AggregateId required' }
        $events = Load-Events -Id $AggregateId
        $filtered = $events | Where-Object { $_.version -gt $FromVersion }
        Write-Log "Replaying $($filtered.Count) events from $AggregateId (v$FromVersion+)" 'INFO'
        return $filtered
    }

    'project' {
        if (-not $AggregateId) { throw 'AggregateId required' }
        $events = Load-Events -Id $AggregateId

        $snapshot = Get-SnapshotPath -Id $AggregateId
        $startVersion = 0
        $state = @{
            aggregateId = $AggregateId
            status      = 'unknown'
            eventsCount = 0
        }

        if (Test-Path $snapshot) {
            $snap = Get-Content $snapshot -Raw | ConvertFrom-Json
            $state = $snap.state
            $startVersion = $snap.version
            Write-Log "Loaded snapshot at v$startVersion" 'INFO'
        }

        $eventsToApply = $events | Where-Object { $_.version -gt $startVersion }
        foreach ($evt in $eventsToApply) {
            $handler = $projections[$evt.type]
            if ($handler) { & $handler $state $evt }
            $state.eventsCount++
        }

        Write-Log "Projection built for ${AggregateId}: v$($state.eventsCount)" 'SUCCESS'
        return $state
    }

    'snapshot' {
        if (-not $AggregateId) { throw 'AggregateId required' }
        $state = & $PSCommandPath -Action project -AggregateId $AggregateId -Quiet:$Quiet
        $events = Load-Events -Id $AggregateId
        $snapshot = @{
            aggregateId = $AggregateId
            version     = $events.Count
            state       = $state
            createdAt   = (Get-Date -Format 'o')
        }
        $snapshot | ConvertTo-Json -Depth 10 | Set-Content (Get-SnapshotPath -Id $AggregateId)
        Write-Log "Snapshot saved at v$($events.Count) for $AggregateId" 'SUCCESS'
        return $snapshot
    }

    'list' {
        $aggregates = @{}
        if (Test-Path $eventStoreDir) {
            Get-ChildItem -Path $eventStoreDir -Filter '*.jsonl' | ForEach-Object {
                $id = $_.BaseName
                $events = Get-Content $_.FullName
                $aggregates[$id] = @{
                    aggregateId = $id
                    eventCount  = $events.Count
                    lastEvent   = if ($events.Count -gt 0) { ($events[-1] | ConvertFrom-Json).type } else { $null }
                    size        = '{0:N1} KB' -f ($_.Length / 1KB)
                }
            }
        }
        return $aggregates.Values | Sort-Object eventCount -Descending
    }
}
