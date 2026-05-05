<#
.SYNOPSIS
    Export persisted metrics to a dedicated analytical store.

.DESCRIPTION
    Reads from:
    - config/metrics-config.json     (runtime_state, agent counters)
    - .event-bus/history.json        (event history)
    - .event-bus/rate-limit-state.json
    - docs/sessions/metrics/token-guard-usage.csv
    - .logs/override-audit.jsonl     (override audit log)

    Exports to (choose via -Format):
    - csv     : reports/metrics-export.csv  (default, always available)
    - jsonl   : reports/metrics-export.jsonl (one JSON object per entry)
    - sqlite  : reports/metrics.db (requires sqlite3 CLI in PATH)
    - all     : all three formats at once

.PARAMETER Format
    Export format: csv | jsonl | sqlite | all. Default: csv

.PARAMETER OutputDir
    Directory for output files. Default: <repo>/reports/

.PARAMETER Since
    Export only entries since this date (ISO 8601). Default: all history.

.EXAMPLE
    .\export-metrics.ps1
    .\export-metrics.ps1 -Format all
    .\export-metrics.ps1 -Format sqlite -Since 2026-05-01
#>
param(
    [ValidateSet('csv', 'jsonl', 'sqlite', 'all')]
    [string]$Format    = 'csv',
    [string]$OutputDir = '',
    [string]$Since     = ''
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = (Resolve-Path (Join-Path $scriptDir '..\..\..') -ErrorAction SilentlyContinue)?.Path
if (-not $repoRoot) { $repoRoot = (Get-Item $scriptDir).Parent.Parent.Parent.FullName }

if (-not $OutputDir) { $OutputDir = Join-Path $repoRoot 'reports' }
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

$sinceDate = $null
if ($Since) { try { $sinceDate = [datetime]::Parse($Since) } catch { Write-Warning "Invalid -Since date: $Since — exporting all." } }

function Read-JsonFile {
    param([string]$Path)
    if (Test-Path $Path) {
        try { return Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json } catch { return $null }
    }
    return $null
}

# ── Load sources ──────────────────────────────────────────────────────────────
$metrics  = Read-JsonFile (Join-Path $repoRoot 'config\metrics-config.json')
$orch     = Read-JsonFile (Join-Path $repoRoot 'config\orchestrator.json')
$evHist   = Read-JsonFile (Join-Path $repoRoot '.event-bus\history.json')
$rlState  = Read-JsonFile (Join-Path $repoRoot '.event-bus\rate-limit-state.json')

# ── Build unified record set ──────────────────────────────────────────────────
$records = [System.Collections.Generic.List[hashtable]]::new()

# 1. Event history entries
if ($evHist -and $evHist.events) {
    foreach ($e in $evHist.events) {
        $ts = $null
        if ($e.timestamp) { try { $ts = [datetime]::Parse($e.timestamp) } catch { } }
        if ($sinceDate -and $ts -and $ts -lt $sinceDate) { continue }
        $records.Add(@{
            source      = 'event_bus'
            timestamp   = if ($ts) { $ts.ToString('o') } else { '' }
            category    = 'event'
            key         = if ($e.event) { $e.event } else { '' }
            value       = 1
            status      = if ($e.status) { $e.status } else { '' }
            extra       = if ($e.payload) { $e.payload } else { '' }
        })
    }
}

# 2. Token guard usage CSV
$tokenCsv = Join-Path $repoRoot 'docs\sessions\metrics\token-guard-usage.csv'
if (Test-Path $tokenCsv) {
    try {
        $csvLines = Get-Content $tokenCsv -Encoding UTF8 | Select-Object -Skip 1
        foreach ($line in $csvLines) {
            $parts = $line -split ','
            if ($parts.Count -lt 2) { continue }
            $ts = $null
            try { $ts = [datetime]::Parse($parts[0].Trim()) } catch { }
            if ($sinceDate -and $ts -and $ts -lt $sinceDate) { continue }
            $records.Add(@{
                source      = 'token_guard'
                timestamp   = if ($ts) { $ts.ToString('o') } else { $parts[0].Trim() }
                category    = 'token_usage'
                key         = 'tokens_used'
                value       = if ($parts.Count -ge 2) { [int]::TryParse($parts[1].Trim(), [ref]$null); $parts[1].Trim() } else { 0 }
                status      = 'recorded'
                extra       = if ($parts.Count -ge 3) { "budget=$($parts[2].Trim())" } else { '' }
            })
        }
    } catch { Write-Warning "Could not read token CSV: $($_.Exception.Message)" }
}

# 3. Override audit log
$overrideLog = Join-Path $repoRoot '.logs\override-audit.jsonl'
if (Test-Path $overrideLog) {
    try {
        $lines = Get-Content $overrideLog -Encoding UTF8
        foreach ($line in $lines) {
            if (-not $line.Trim()) { continue }
            try {
                $entry = $line | ConvertFrom-Json
                $ts = $null
                $tsRaw = if ($entry.timestamp) { $entry.timestamp } elseif ($entry.created_at) { $entry.created_at } else { '' }
                if ($tsRaw) { try { $ts = [datetime]::Parse($tsRaw) } catch { } }
                if ($sinceDate -and $ts -and $ts -lt $sinceDate) { continue }
                $records.Add(@{
                    source      = 'override_audit'
                    timestamp   = if ($ts) { $ts.ToString('o') } else { $tsRaw }
                    category    = 'override'
                    key         = if ($entry.profile) { $entry.profile } else { 'unknown' }
                    value       = 1
                    status      = if ($entry.agent) { $entry.agent } else { '' }
                    extra       = if ($entry.reason) { $entry.reason } else { '' }
                })
            } catch { }
        }
    } catch { }
}

# 4. Runtime state snapshot (single record summarizing current state)
if ($metrics -and $metrics.runtime_state) {
    $rs = $metrics.runtime_state
    $records.Add(@{
        source      = 'metrics_snapshot'
        timestamp   = (Get-Date -Format 'o')
        category    = 'runtime_state'
        key         = 'total_sessions'
        value       = if ($rs.total_sessions) { $rs.total_sessions } else { 0 }
        status      = 'snapshot'
        extra       = "dispatches=$($rs.total_dispatches ?? 0),tokens=$($rs.total_tokens_used ?? 0)"
    })
}

Write-Host "[INFO] Total records to export: $($records.Count)" -ForegroundColor Cyan

# ── Export functions ──────────────────────────────────────────────────────────
function Export-ToCsv {
    $path = Join-Path $OutputDir 'metrics-export.csv'
    $header = 'source,timestamp,category,key,value,status,extra'
    $lines = @($header)
    foreach ($r in $records) {
        $extra = $r.extra -replace '"', '""'
        $lines += "$($r.source),$($r.timestamp),$($r.category),$($r.key),$($r.value),$($r.status),`"$extra`""
    }
    Set-Content -Path $path -Value $lines -Encoding UTF8 -Force
    Write-Host "[OK] CSV exported: $path ($($records.Count) rows)" -ForegroundColor Green
    return $path
}

function Export-ToJsonl {
    $path = Join-Path $OutputDir 'metrics-export.jsonl'
    $lines = $records | ForEach-Object { $_ | ConvertTo-Json -Compress }
    Set-Content -Path $path -Value $lines -Encoding UTF8 -Force
    Write-Host "[OK] JSONL exported: $path ($($records.Count) entries)" -ForegroundColor Green
    return $path
}

function Export-ToSqlite {
    $dbPath = Join-Path $OutputDir 'metrics.db'
    if (-not (Get-Command sqlite3 -ErrorAction SilentlyContinue)) {
        Write-Warning "[SKIP] sqlite3 not in PATH — skipping SQLite export. Install: https://sqlite.org/download.html"
        return $null
    }
    # Create table if not exists
    $ddl = "CREATE TABLE IF NOT EXISTS metrics (id INTEGER PRIMARY KEY AUTOINCREMENT, source TEXT, timestamp TEXT, category TEXT, key TEXT, value TEXT, status TEXT, extra TEXT);"
    & sqlite3 $dbPath $ddl

    foreach ($r in $records) {
        $extra = $r.extra -replace "'", "''"
        $sql = "INSERT INTO metrics (source,timestamp,category,key,value,status,extra) VALUES ('$($r.source)','$($r.timestamp)','$($r.category)','$($r.key)','$($r.value)','$($r.status)','$extra');"
        & sqlite3 $dbPath $sql
    }
    Write-Host "[OK] SQLite exported: $dbPath ($($records.Count) rows in table 'metrics')" -ForegroundColor Green
    return $dbPath
}

# ── Run exports ───────────────────────────────────────────────────────────────
switch ($Format) {
    'csv'    { Export-ToCsv | Out-Null }
    'jsonl'  { Export-ToJsonl | Out-Null }
    'sqlite' { Export-ToSqlite | Out-Null }
    'all'    {
        Export-ToCsv    | Out-Null
        Export-ToJsonl  | Out-Null
        Export-ToSqlite | Out-Null
    }
}

Write-Host "[INFO] Export complete. Output dir: $OutputDir" -ForegroundColor Cyan
