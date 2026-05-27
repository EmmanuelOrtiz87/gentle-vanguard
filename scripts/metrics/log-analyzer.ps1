#Requires -Version 7.0
param(
    [int]$DaysBack = 30,
    [switch]$Quiet,
    [switch]$SaveToMetrics
)

$ErrorActionPreference = 'Continue'
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$logsDir = Join-Path $repoRoot 'logs'
$metricsDir = Join-Path $repoRoot '.runtime' 'metrics'
$outFile = Join-Path $metricsDir 'performance-analytics.json'

function Log { param([string]$M) if (-not $Quiet) { Write-Host "[LOG-ANALYZER] $M" -ForegroundColor Cyan } }

# Initialize analytics object
$analytics = [PSCustomObject]@{
    generatedAt = (Get-Date -Format 'o')
    periodDays = $DaysBack
    sessions = [PSCustomObject]@{}
    hourly = @{}
    daily = @{}
    authors = @{}
    productivity = [PSCustomObject]@{}
    trends = [PSCustomObject]@{}
}

# Initialize hourly activity (24 hours x 7 days)
for ($day = 0; $day -lt 7; $day++) {
    $analytics.hourly[$day.ToString()] = @{}
    for ($hour = 0; $hour -lt 24; $hour++) {
        $analytics.hourly[$day.ToString()][$hour.ToString()] = 0
    }
}

# Initialize daily activity
for ($i = 0; $i -lt $DaysBack; $i++) {
    $date = (Get-Date).AddDays(-$i).ToString('yyyy-MM-dd')
    $analytics.daily[$date] = 0
}

Log "Analyzing logs from last $DaysBack days..."

# Get all log files
$logFiles = Get-ChildItem -Path $logsDir -Filter 'session-*.json' -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-$DaysBack) }

Log "Found $($logFiles.Count) log files"

$totalDuration = 0
$sessionCount = 0
$activeSessions = 0
$autoStartCount = 0
$manualCount = 0

foreach ($logFile in $logFiles) {
    try {
        $log = Get-Content $logFile.FullName -Raw | ConvertFrom-Json
        
        # Parse start time
        if ($log.StartTime) {
            $startTime = [DateTime]$log.StartTime
            $dayOfWeek = [int]$startTime.DayOfWeek
            $hour = $startTime.Hour
            $dateKey = $startTime.ToString('yyyy-MM-dd')
            
            # Count hourly activity
            $dayKey = $dayOfWeek.ToString()
            $hourKey = $hour.ToString()
            if ($analytics.hourly.ContainsKey($dayKey) -and 
                $analytics.hourly[$dayKey].ContainsKey($hourKey)) {
                $analytics.hourly[$dayKey][$hourKey]++
            }
            
            # Count daily activity
            if ($analytics.daily.ContainsKey($dateKey)) {
                $analytics.daily[$dateKey]++
            }
            
            # Calculate duration
            $duration = ($logFile.LastWriteTime - $startTime).TotalMinutes
            if ($duration -gt 0 -and $duration -lt 1440) { # Max 24 hours
                $totalDuration += $duration
                $sessionCount++
            }
            
            # Count by mode
            if ($log.Mode -eq 'AutoStart') { $autoStartCount++ }
            else { $manualCount++ }
            
            # Count active sessions
            if ($log.Status -eq 'ACTIVE') { $activeSessions++ }
        }
    } catch {
        Log "Error parsing $($logFile.Name): $_"
    }
}

# Calculate peak hour
$peakHour = 0
$peakCount = 0
$totalHourly = @{}
for ($hour = 0; $hour -lt 24; $hour++) {
    $hourKey = $hour.ToString()
    $totalHourly[$hourKey] = 0
    for ($day = 0; $day -lt 7; $day++) {
        $dayKey = $day.ToString()
        $totalHourly[$hourKey] += $analytics.hourly[$dayKey][$hourKey]
    }
    if ($totalHourly[$hourKey] -gt $peakCount) {
        $peakCount = $totalHourly[$hourKey]
        $peakHour = $hour
    }
}

# Calculate productivity metrics
$avgDuration = if ($sessionCount -gt 0) { [math]::Round($totalDuration / $sessionCount, 0) } else { 0 }
$sessionsPerDay = if ($DaysBack -gt 0) { [math]::Round($sessionCount / $DaysBack, 1) } else { 0 }

# Calculate velocity trend (last 7 days vs previous 7 days)
$today = Get-Date
$last7Days = 0
$prev7Days = 0
for ($i = 0; $i -lt 7; $i++) {
    $date = $today.AddDays(-$i).ToString('yyyy-MM-dd')
    if ($analytics.daily.ContainsKey($date)) {
        $last7Days += $analytics.daily[$date]
    }
}
for ($i = 7; $i -lt 14; $i++) {
    $date = $today.AddDays(-$i).ToString('yyyy-MM-dd')
    if ($analytics.daily.ContainsKey($date)) {
        $prev7Days += $analytics.daily[$date]
    }
}
$velocityChange = if ($prev7Days -gt 0) { 
    [math]::Round((($last7Days - $prev7Days) / $prev7Days) * 100, 0) 
} else { 0 }

# Build analytics object
$analytics.sessions = [PSCustomObject]@{
    totalAnalyzed = $sessionCount
    activeNow = $activeSessions
    autoStart = $autoStartCount
    manual = $manualCount
    avgDurationMinutes = $avgDuration
    sessionsPerDay = $sessionsPerDay
    peakHour = "$($peakHour.ToString().PadLeft(2,'0')):00"
    peakCount = $peakCount
}

$analytics.productivity = [PSCustomObject]@{
    velocityTrend = $velocityChange
    velocityDirection = if ($velocityChange -ge 0) { 'up' } else { 'down' }
    last7Days = $last7Days
    previous7Days = $prev7Days
}

$analytics.trends = [PSCustomObject]@{
    hourlyActivity = $totalHourly
    dailyActivity = $analytics.daily
    heatmapData = $analytics.hourly
}

# Convert to JSON and save
$json = $analytics | ConvertTo-Json -Depth 10

if ($SaveToMetrics) {
    if (-not (Test-Path $metricsDir)) {
        New-Item -ItemType Directory -Path $metricsDir -Force | Out-Null
    }
    $json | Set-Content $outFile -Encoding UTF8
    Log "Analytics saved to: $outFile"
} else {
    Write-Output $json
}

Log "Analysis complete:"
Log "  Sessions analyzed: $sessionCount"
Log "  Active sessions: $activeSessions"
Log "  Avg duration: $avgDuration min"
Log "  Peak hour: $($peakHour):00 ($peakCount sessions)"
Log "  Velocity trend: $velocityChange% $(if($velocityChange -ge 0){'↑'}else{'↓'})"
