param(
    [ValidateSet('full', 'sessions', 'token', 'live', 'git', 'pr', 'cost')]
    [string]$Scope = 'full',
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$outDir = Join-Path $repoRoot '.runtime' 'metrics'
$sessionsDir = Join-Path $repoRoot 'session'
$tokenState = Join-Path $repoRoot '.session' 'token-autopilot-state.json'
$liveObsPath = Join-Path $repoRoot 'reports' 'stack-live-observability-latest.json'

if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$aggDir = Join-Path $outDir 'aggregates'
if (-not (Test-Path $aggDir)) { New-Item -ItemType Directory -Path $aggDir -Force | Out-Null }
$snapDir = Join-Path $outDir 'snapshots'
if (-not (Test-Path $snapDir)) { New-Item -ItemType Directory -Path $snapDir -Force | Out-Null }

function Log { param([string]$M) if (-not $Quiet) { Write-Host "[METRICS] $M" -ForegroundColor Cyan } }

function Collect-GitMetrics {
    Log "Collecting git metrics..."
    $gitDir = $repoRoot
    $totalCommits = 0; $monthCommits = 0; $weekCommits = 0; $todayCommits = 0
    $authors = @{}; $linesAdded = 0; $linesRemoved = 0
    Push-Location $gitDir
    try {
        $totalCommits = [int](git rev-list --count HEAD 2>$null)
        $today = (Get-Date -Format 'yyyy-MM-dd')
        $monthStart = (Get-Date -Year (Get-Date).Year -Month (Get-Date).Month -Day 1 -Hour 0 -Minute 0 -Second 0).ToString('yyyy-MM-dd')
        $weekStart = (Get-Date).AddDays(-(Get-Date).DayOfWeek).ToString('yyyy-MM-dd')
        $monthCommits = [int](git log --oneline --since="$monthStart" 2>$null | Measure-Object -Line | Select-Object -ExpandProperty Lines)
        $weekCommits = [int](git log --oneline --since="$weekStart" 2>$null | Measure-Object -Line | Select-Object -ExpandProperty Lines)
        $todayCommits = [int](git log --oneline --since="$today" 2>$null | Measure-Object -Line | Select-Object -ExpandProperty Lines)
        $shortlog = git shortlog -sn --all 2>$null
        foreach ($line in $shortlog) { if ($line -match '^\s*(\d+)\s+(.+)$') { $authors[$Matches[2]] = [int]$Matches[1] } }
        $diffStat = git diff --stat HEAD~30..HEAD 2>$null
        foreach ($line in $diffStat) {
            if ($line -match '(\d+) insertion') { $linesAdded += [int]$Matches[1] }
            if ($line -match '(\d+) deletion') { $linesRemoved += [int]$Matches[1] }
        }
    } finally { Pop-Location }
    $gitMetrics = [PSCustomObject]@{
        collectedAt   = (Get-Date -Format 'o')
        totalCommits  = $totalCommits
        monthCommits  = $monthCommits
        weekCommits   = $weekCommits
        todayCommits  = $todayCommits
        linesAdded30  = $linesAdded
        linesRemoved30 = $linesRemoved
        authors       = $authors
        authorCount   = $authors.Count
        topAuthor     = ($authors.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
    }
    $gitMetrics | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $outDir 'git.json')
    Log "Git: $totalCommits total, $monthCommits month, $todayCommits today, $linesAdded+/$linesRemoved- lines (30 commits)"
    return $gitMetrics
}

function Collect-PRMetrics {
    Log "Collecting PR metrics..."
    $prMetrics = [PSCustomObject]@{ collectedAt = (Get-Date -Format 'o'); total = 0; open = 0; merged = 0; closed = 0; totalAdditions = 0; totalDeletions = 0; avgReviewTimeHours = 0; recent = @() }
    $gh = Get-Command 'gh' -ErrorAction SilentlyContinue
    if (-not $gh) { $prMetrics | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $outDir 'pr.json'); Log "PR: gh CLI not available"; return $prMetrics }
    try {
        $prs = gh pr list --state all --limit 100 --json number,title,state,createdAt,closedAt,mergedAt,additions,deletions,author 2>$null | ConvertFrom-Json
        $prMetrics.total = $prs.Count
        $prMetrics.merged = @($prs | Where-Object { $_.state -eq 'MERGED' }).Count
        $prMetrics.open = @($prs | Where-Object { $_.state -eq 'OPEN' }).Count
        $prMetrics.closed = @($prs | Where-Object { $_.state -eq 'CLOSED' }).Count
        $prMetrics.totalAdditions = [int]($prs | Measure-Object -Property additions -Sum).Sum
        $prMetrics.totalDeletions = [int]($prs | Measure-Object -Property deletions -Sum).Sum
        $reviewTimes = @()
        foreach ($pr in $prs) {
            if ($pr.createdAt -and ($pr.mergedAt -or $pr.closedAt)) {
                $end = if ($pr.mergedAt) { $pr.mergedAt } else { $pr.closedAt }
                $hours = [int](([DateTime]$end) - ([DateTime]$pr.createdAt)).TotalHours
                if ($hours -ge 0) { $reviewTimes += $hours }
            }
        }
        if ($reviewTimes.Count -gt 0) { $prMetrics.avgReviewTimeHours = [math]::Round(($reviewTimes | Measure-Object -Average).Average, 1) }
        $prMetrics.recent = $prs | Sort-Object createdAt -Descending | Select-Object -First 10
    } catch { Log "PR: collection failed: $_" }
    $prMetrics | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $outDir 'pr.json')
    $mergedCount = $prMetrics.merged; $avgHours = $prMetrics.avgReviewTimeHours
    Log "PR: $($prMetrics.total) total, $mergedCount merged, avg ${avgHours}h lifecycle"
    return $prMetrics
}

function Collect-SessionMetrics {
    Log "Collecting session metrics..."
    $sessions = @(); $today = (Get-Date).Date
    if (Test-Path $sessionsDir) {
        Get-ChildItem -Path $sessionsDir -Filter 'session-*.json' | ForEach-Object {
            try {
                $s = Get-Content $_.FullName -Raw | ConvertFrom-Json
                $start = if ($s.startTime) { [DateTime]$s.startTime } else { $_.LastWriteTime }
                $durSec = [int]($_.LastWriteTime - $start).TotalSeconds
                if ($durSec -lt 0) { $durSec = 0 }
                $sessions += [PSCustomObject]@{
                    sessionId  = $s.sessionId; startTime = $s.startTime
                    status     = $s.status; mode = $s.mode; project = $s.project
                    durationSec = $durSec; isToday = ($start.Date -eq $today); sourceFile = $_.Name
                }
            } catch {}
        }
    }
    $active = @($sessions | Where-Object { $_.status -eq 'active' }).Count
    $total = $sessions.Count; $todaySessions = @($sessions | Where-Object { $_.isToday }).Count
    $durations = $sessions | Where-Object { $_.durationSec -gt 0 } | ForEach-Object { $_.durationSec }
    $avgDurSec = if ($durations.Count -gt 0) { [int](($durations | Measure-Object -Average).Average) } else { 0 }
    $totalDurMin = [int](($durations | Measure-Object -Sum).Sum / 60)
    $latest = $sessions | Sort-Object startTime -Descending | Select-Object -First 1
    $sessionMetrics = [PSCustomObject]@{
        collectedAt = (Get-Date -Format 'o'); total = $total; active = $active
        inactive = $total - $active; today = $todaySessions
        avgDurationSec = $avgDurSec; totalDurationMin = $totalDurMin
        latestId = if ($latest) { $latest.sessionId } else { 'none' }
        latestStart = if ($latest) { $latest.startTime } else { '' }
        latestStatus = if ($latest) { $latest.status } else { '' }
    }
    $sessionMetrics | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $outDir 'sessions.json')
    Log "Sessions: $total total, $active active, ${todaySessions} today, avg ${avgDurSec}s, total ${totalDurMin}min"
    return $sessions
}

function Collect-TokenMetrics {
    Log "Collecting token metrics..."
    $tm = [PSCustomObject]@{ collectedAt = (Get-Date -Format 'o'); status = 'unknown'; usedToday = 0; budget = 120000; pct = 0 }
    if (Test-Path $tokenState) { try { $t = Get-Content $tokenState -Raw | ConvertFrom-Json; $tm.status = $t.lastStatus } catch {} }
    if (Test-Path $liveObsPath) {
        try {
            $obs = Get-Content $liveObsPath -Raw | ConvertFrom-Json
            if ($obs.token) { $tm.usedToday = $obs.token.used_today; $tm.budget = $obs.token.budget; $tm.pct = $obs.token.projected_pct; $tm.status = $obs.token.status }
        } catch {}
    }
    $ratePer1M = 10; $estCost = [math]::Round(($tm.usedToday / 1e6) * $ratePer1M, 4)
    $d = (Get-Date); $dim = [DateTime]::DaysInMonth($d.Year, $d.Month)
    $dom = $d.Day; $forecast = if ($dom -gt 0) { [int](($tm.usedToday / $dom) * $dim) } else { 0 }
    $monthForecastCost = [math]::Round(($forecast / 1e6) * $ratePer1M, 2)
    $baselineTokens = $tm.usedToday * 1.4; $savedTokens = [math]::Max(0, $baselineTokens - $tm.usedToday)
    $modeledSavings = [math]::Round(($savedTokens / 1e6) * $ratePer1M, 4)
    $tm | Add-Member -NotePropertyName 'ratePer1M' -NotePropertyValue $ratePer1M
    $tm | Add-Member -NotePropertyName 'estCost' -NotePropertyValue $estCost
    $tm | Add-Member -NotePropertyName 'monthForecast' -NotePropertyValue $forecast
    $tm | Add-Member -NotePropertyName 'monthForecastCost' -NotePropertyValue $monthForecastCost
    $tm | Add-Member -NotePropertyName 'baselineTokens' -NotePropertyValue ([math]::Round($baselineTokens, 0))
    $tm | Add-Member -NotePropertyName 'savedTokens' -NotePropertyValue ([math]::Round($savedTokens, 0))
    $tm | Add-Member -NotePropertyName 'modeledSavings' -NotePropertyValue $modeledSavings
    $tm | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $outDir 'token.json')
    Log "Tokens: $($tm.usedToday)/$($tm.budget) ($($tm.pct)%) cost=`$$estCost forecast=`$$monthForecastCost saved=`$$modeledSavings"
    return $tm
}

function Collect-LiveMetrics {
    Log "Collecting live observability metrics..."
    $live = [PSCustomObject]@{ collectedAt = (Get-Date -Format 'o'); trafficLight = 'GREEN'; routingTotal = 0; routingAcc = '0%'; benchmarkPass = 0; benchmarkFail = 0; hasData = $false }
    if (Test-Path $liveObsPath) {
        try {
            $obs = Get-Content $liveObsPath -Raw | ConvertFrom-Json
            $live.trafficLight = $obs.executive_traffic_light
            if ($obs.routing) { $live.routingTotal = $obs.routing.total; $live.routingAcc = $obs.routing.accuracy }
            if ($obs.benchmark) { $live.benchmarkPass = $obs.benchmark.pass; $live.benchmarkFail = $obs.benchmark.fail }
            $live.hasData = $true
        } catch {}
    }
    $live | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $outDir 'live.json')
    Log "Live: light=$($live.trafficLight) routing=$($live.routingAcc)"
    return $live
}

function Collect-CostMetrics {
    Log "Collecting cost & savings projections..."
    $token = Collect-TokenMetrics
    $cost = [PSCustomObject]@{
        collectedAt = (Get-Date -Format 'o'); ratePer1M = $token.ratePer1M
        actualCost = $token.estCost; monthForecastCost = $token.monthForecastCost
        baselineTokens = $token.baselineTokens; savedTokens = $token.savedTokens
        modeledSavings = $token.modeledSavings; savingsPct = if ($token.baselineTokens -gt 0) { [math]::Round(($token.savedTokens / $token.baselineTokens) * 100, 1) } else { 0 }
    }
    $cost | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $outDir 'cost.json')
    Log "Cost: actual=`$$($cost.actualCost) forecast=`$$($cost.monthForecastCost) saved=`$$($cost.modeledSavings) ($($cost.savingsPct)% savings)"
    return $cost
}

function Collect-TelemetryMetrics {
    Log "Collecting telemetry metrics..."
    $activityFile = Join-Path $outDir 'live' 'activity.json'
    $eventsFile = Join-Path $outDir 'live' 'events.ndjson'
    $tm = [PSCustomObject]@{ collectedAt = (Get-Date -Format 'o'); hasData = $false; toolCalls = 0; estimatedTokens = 0; filesRead = 0; filesWritten = 0; filesEdited = 0; commandsRun = 0; eventsCount = 0 }
    if (Test-Path $activityFile) {
        try {
            $a = Get-Content $activityFile -Raw | ConvertFrom-Json
            $tm.hasData = $true
            $tm.toolCalls = [int]$a.toolCalls
            $tm.estimatedTokens = [int]$a.estimatedTokens
            $tm.filesRead = [int]$a.filesRead
            $tm.filesWritten = [int]$a.filesWritten
            $tm.filesEdited = [int]$a.filesEdited
            $tm.commandsRun = [int]$a.commandsRun
        } catch {}
    }
    # Read events from ndjson
    $events = @()
    if (Test-Path $eventsFile) {
        try {
            Get-Content $eventsFile | ForEach-Object { if ($_) { $events += $_ | ConvertFrom-Json } }
            $tm | Add-Member -NotePropertyName 'events' -NotePropertyValue @($events) -Force -ErrorAction SilentlyContinue
            $tm.eventsCount = $events.Count
        } catch {}
    }
    if (-not $tm.events) { $tm | Add-Member -NotePropertyName 'events' -NotePropertyValue @() -Force -ErrorAction SilentlyContinue }
    $tm | ConvertTo-Json -Depth 3 | Set-Content (Join-Path $outDir 'telemetry.json')
    $has = $tm.hasData
    Log "Telemetry: hasData=$has calls=$($tm.toolCalls) tokens=$($tm.estimatedTokens) events=$($tm.eventsCount)"
    return $tm
}

function Collect-AllMetrics {
    $s = Collect-SessionMetrics; $t = Collect-TokenMetrics; $l = Collect-LiveMetrics
    $g = Collect-GitMetrics; $p = Collect-PRMetrics; $c = Collect-CostMetrics
    $tel = Collect-TelemetryMetrics
    $all = [PSCustomObject]@{
        collectedAt = (Get-Date -Format 'o')
        sessions = [PSCustomObject]@{ total = $s.Count; active = @($s | Where-Object { $_.status -eq 'active' }).Count; today = @($s | Where-Object { $_.isToday }).Count; avgDurationSec = ($s | Where-Object { $_.durationSec -gt 0 } | Measure-Object -Average durationSec).Average; totalDurationMin = [int](($s | Where-Object { $_.durationSec -gt 0 } | Measure-Object -Sum durationSec).Sum / 60); latest = ($s | Sort-Object startTime -Descending | Select-Object -First 1).sessionId }
        token = $t; live = $l; git = $g; pr = $p; cost = $c; telemetry = $tel
    }
    $all | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $outDir 'consolidated.json')
    $stamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item (Join-Path $outDir 'consolidated.json') (Join-Path $snapDir "snapshot-$stamp.json")
    Log "Consolidated written to .runtime/metrics/consolidated.json"
}

switch ($Scope) {
    'sessions' { Collect-SessionMetrics }
    'token'    { Collect-TokenMetrics }
    'live'     { Collect-LiveMetrics }
    'git'      { Collect-GitMetrics }
    'pr'       { Collect-PRMetrics }
    'cost'     { Collect-CostMetrics }
    'full'     { Collect-AllMetrics }
}
