param(
    [switch]$Record,
    [switch]$Report,
    [string]$Agent = '',
    [string]$Skill = '',
    [string]$Task = '',
    [int]$DurationMs = 0,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$eventBusPath = Join-Path $repoRoot '.event-bus'
$csvDir = Join-Path $repoRoot 'docs\sessions\metrics'
$csvPath = Join-Path $csvDir 'agent-usage.csv'
$csvHeader = 'timestamp,agent,skill,task,duration_ms'

function Get-EventBusRows {
    $historyFile = Join-Path $eventBusPath 'history.json'
    if (-not (Test-Path $historyFile)) { return @() }
    $history = Get-Content -Path $historyFile -Raw | ConvertFrom-Json
    if (-not $history.events) { return @() }
    $rows = @()
    foreach ($evt in $history.events) {
        if ($evt.event -notmatch 'agent\.(dispatched|completed)') { continue }
        $p = if ($evt.payload) { try { $evt.payload | ConvertFrom-Json } catch { $null } } else { $null }
        $rows += [PSCustomObject]@{
            timestamp   = $evt.timestamp
            agent       = if ($p -and $p.agent) { $p.agent } else { 'unknown' }
            skill       = if ($p -and $p.PSObject.Properties['skill']) { $p.skill } else { '' }
            task        = if ($p -and $p.task) { $p.task } else { $evt.event }
            duration_ms = if ($p -and $p.PSObject.Properties['token_estimate']) { $p.token_estimate } else { 0 }
        }
    }
    return $rows
}

function Ensure-Csv {
    if (-not (Test-Path $csvPath)) {
        if (-not (Test-Path $csvDir)) { New-Item -ItemType Directory -Path $csvDir -Force | Out-Null }
        $csvHeader | Out-File -FilePath $csvPath -Encoding UTF8
    }
}
function Get-AllRows {
    $eventRows = Get-EventBusRows
    if ($eventRows.Count -gt 0) { return $eventRows }
    Ensure-Csv; return (Import-Csv -Path $csvPath)
}

if ($Record) {
    if ([string]::IsNullOrWhiteSpace($Agent)) {
        Write-Host '[ERROR] -Agent required with -Record' -ForegroundColor Red; exit 1
    }
    Ensure-Csv
    $ts = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
    $row = "$ts,$Agent,$Skill,$Task,$DurationMs"
    $row | Out-File -FilePath $csvPath -Encoding UTF8 -Append
    if (-not $Quiet) { Write-Host "[OK] Recorded: $Agent / $Skill" -ForegroundColor Green }
    exit 0
}

if ($Report) {
    $rows = Get-AllRows
    if ($rows.Count -eq 0) {
        Write-Host '[INFO] No usage data found' -ForegroundColor Yellow; exit 0
    }
    Write-Host "`n=== AGENT USAGE METRICS ===" -ForegroundColor Cyan
    Write-Host "Total events: $($rows.Count)`n" -ForegroundColor Gray
    Write-Host 'By Agent:' -ForegroundColor Yellow
    $rows | Group-Object agent | Sort-Object Count -Descending |
        Format-Table @{L='Agent';E={$_.Name}}, Count -AutoSize | Out-String | Write-Host
    Write-Host 'By Skill:' -ForegroundColor Yellow
    $rows | Where-Object { $_.skill -ne '' } | Group-Object skill | Sort-Object Count -Descending |
        Format-Table @{L='Skill';E={$_.Name}}, Count -AutoSize | Out-String | Write-Host
    exit 0
}

Write-Host 'Usage: agent-usage-metrics.ps1 -Record -Agent <NAME> [-Skill <S>] | -Report' -ForegroundColor Yellow
