#!/usr/bin/env pwsh
param(
    [ValidateSet('init','record','query','aggregate','export','dashboard')]
    [string]$Action = 'query',
    [string]$SessionId = '',
    [int]$Tokens = 0,
    [double]$Cost = 0.0,
    [int]$Days = 30,
    [ValidateSet('csv','json')]
    [string]$Format = 'json',
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $scriptDir
$runtimeDir = Join-Path $repoRoot '.runtime'
$dbPath = Join-Path $runtimeDir 'metrics.db'

if (-not (Test-Path $runtimeDir)) { 
    New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null 
}

# Use JSON file as fallback database (no external dependencies)
$jsonDbPath = Join-Path $runtimeDir 'metrics.json'

function Get-JsonDb() {
    if (Test-Path $jsonDbPath) {
        return Get-Content $jsonDbPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    return @{ token_usage = @(); version = '1.0' }
}

function Save-JsonDb($Data) {
    $Data | ConvertTo-Json -Depth 10 | Set-Content $jsonDbPath -Encoding UTF8
}

function Initialize-Database() {
    $db = Get-JsonDb
    if (-not $db.token_usage) { $db.token_usage = @() }
    Save-JsonDb $db
    Write-Host "[METRICS-STORE] Database initialized: $jsonDbPath" -ForegroundColor Green
}

function Record-TokenUsage($Sid, $Toks, $Cst) {
    $db = Get-JsonDb
    $record = @{
        id = ($db.token_usage.Count + 1)
        session_id = $Sid
        date = (Get-Date -Format 'yyyy-MM-dd')
        tokens_used = $Toks
        cost_usd = $Cst
        model = $env:AI_MODEL ?? 'unknown'
        provider = $env:AI_PROVIDER ?? 'unknown'
        created_at = (Get-Date -Format 'o')
    }
    $db.token_usage += $record
    Save-JsonDb $db
    Write-Host "[METRICS-STORE] Recorded: $Toks tokens, `$$Cst for session $Sid" -ForegroundColor Green
}

function Query-History($NumDays) {
    $db = Get-JsonDb
    $startDate = (Get-Date).AddDays(-$NumDays).ToString('yyyy-MM-dd')
    $filtered = $db.token_usage | Where-Object { $_.date -ge $startDate }
    
    # Aggregate by date
    $grouped = $filtered | Group-Object -Property date | ForEach-Object {
        [PSCustomObject]@{
            date = $_.Name
            total_tokens = ($_.Group | Measure-Object -Property tokens_used -Sum).Sum
            total_cost = ($_.Group | Measure-Object -Property cost_usd -Sum).Sum
            sessions = $_.Group.session_id | Select-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count
        }
    }
    return $grouped | Sort-Object date
}

function Get-WeeklyData() {
    $db = Get-JsonDb
    $startDate = (Get-Date).AddDays(-84).ToString('yyyy-MM-dd')  # 12 weeks
    $filtered = $db.token_usage | Where-Object { $_.date -ge $startDate }
    
    $grouped = $filtered | Group-Object -Property { ([datetime]$_.date).ToString('yyyy-W', [System.Globalization.CultureInfo]::InvariantCulture) } | ForEach-Object {
        [PSCustomObject]@{
            week = $_.Name
            total_tokens = ($_.Group | Measure-Object -Property tokens_used -Sum).Sum
            total_cost = ($_.Group | Measure-Object -Property cost_usd -Sum).Sum
            sessions = $_.Group.session_id | Select-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count
            avg_daily = [math]::Round(($_.Group | Measure-Object -Property tokens_used -Average).Average, 0)
        }
    }
    return $grouped | Sort-Object week
}

function Get-MonthlyData() {
    $db = Get-JsonDb
    $startDate = (Get-Date).AddMonths(-6).ToString('yyyy-MM-dd')
    $filtered = $db.token_usage | Where-Object { $_.date -ge $startDate }
    
    $grouped = $filtered | Group-Object -Property { $_.date.Substring(0, 7) } | ForEach-Object {
        [PSCustomObject]@{
            month = $_.Name
            total_tokens = ($_.Group | Measure-Object -Property tokens_used -Sum).Sum
            total_cost = ($_.Group | Measure-Object -Property cost_usd -Sum).Sum
            sessions = $_.Group.session_id | Select-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count
            avg_daily = [math]::Round(($_.Group | Measure-Object -Property tokens_used -Average).Average, 0)
        }
    }
    return $grouped | Sort-Object month
}

function Get-DashboardData() {
    $daily = Query-History 30
    $weekly = Get-WeeklyData
    $monthly = Get-MonthlyData
    $today = (Get-Date -Format 'yyyy-MM-dd')
    $todayStats = Get-JsonDb | Select-Object -ExpandProperty token_usage | Where-Object { $_.date -eq $today }
    
    return @{
        daily = $daily
        weekly = $weekly
        monthly = $monthly
        today = @{ 
            tokens = ($todayStats | Measure-Object -Property tokens_used -Sum).Sum
            cost = ($todayStats | Measure-Object -Property cost_usd -Sum).Sum
        }
        generatedAt = (Get-Date -Format 'o')
    }
}

$results = @{ action = $Action; timestamp = (Get-Date -Format 'o') }

switch ($Action) {
    'init' {
        Initialize-Database
        $results.status = 'initialized'
        $results.dbPath = $jsonDbPath
    }
    'record' {
        if ([string]::IsNullOrWhiteSpace($SessionId)) { Write-Error "-SessionId required"; exit 1 }
        if ($Tokens -le 0) { Write-Error "-Tokens must be > 0"; exit 1 }
        Record-TokenUsage $SessionId $Tokens $Cost
        $results.status = 'recorded'
        $results.sessionId = $SessionId
        $results.tokens = $Tokens
        $results.cost = $Cost
    }
    'query' {
        $data = Query-History $Days
        $results.status = 'queried'
        $results.days = $Days
        $results.records = $data
        if (-not $AsJson) {
            Write-Host "`n=== Token History (last $Days days) ===" -ForegroundColor Cyan
            $data | Format-Table -AutoSize
        }
    }
    'aggregate' {
        $weekly = Get-WeeklyData
        $monthly = Get-MonthlyData
        $results.status = 'aggregated'
        $results.weekly = $weekly
        $results.monthly = $monthly
        if (-not $AsJson) {
            Write-Host "`n=== Weekly Aggregates ===" -ForegroundColor Cyan
            $weekly | Format-Table -AutoSize
            Write-Host "`n=== Monthly Aggregates ===" -ForegroundColor Cyan
            $monthly | Format-Table -AutoSize
        }
    }
    'dashboard' {
        $data = Get-DashboardData
        $results.status = 'dashboard'
        $results.data = $data
    }
}

if ($AsJson) { $results | ConvertTo-Json -Depth 10 }
exit 0
