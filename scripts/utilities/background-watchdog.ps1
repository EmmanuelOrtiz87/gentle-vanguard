<#
.SYNOPSIS
    Watchdog daemon for background processes — monitors live-feed and metrics-server PIDs.

.DESCRIPTION
    Reads .session/live-feed-state.json and .runtime/metrics/live/daemon-health.json,
    checks if PIDs are alive, logs status, and optionally auto-restarts dead processes.
    Can run as a persistent daemon loop or one-shot check.

.PARAMETER Action
    check   → one-shot health check (default, exit code 0=all alive)
    start   → run as daemon loop with interval
    stop    → clean watchdog state
    status  → detailed report with restart count and log path

.PARAMETER IntervalSeconds
    Polling interval in daemon mode. Default: 30

.PARAMETER MaxRestarts
    Max automatic restarts before giving up. Default: 3

.PARAMETER AutoRestart
    Enable automatic restart of dead processes.

.PARAMETER Quiet
    Suppress console output (still writes to watchdog.log).

.EXAMPLE
    .\background-watchdog.ps1 -Action status
    .\background-watchdog.ps1 -Action start -AutoRestart -IntervalSeconds 15
#>

param(
    [ValidateSet('start','stop','status','check')]
    [string]$Action = 'check',
    [int]$IntervalSeconds = 30,
    [int]$MaxRestarts = 3,
    [switch]$AutoRestart,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

$stateFile     = Join-Path $repoRoot '.session' 'live-feed-state.json'
$healthFile    = Join-Path $repoRoot '.runtime' 'metrics' 'live' 'daemon-health.json'
$watchdogState = Join-Path $repoRoot '.session' 'watchdog-state.json'
$watchdogLog   = Join-Path $repoRoot '.runtime' 'logs' 'watchdog.log'

if (-not (Test-Path (Split-Path $watchdogLog -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $watchdogLog -Parent) -Force | Out-Null
}

function Write-Log {
    param([string]$Level, [string]$Message)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $watchdogLog -Value $line -Encoding UTF8
    if (-not $Quiet) {
        $color = switch ($Level) { 'OK' { 'Green' } 'WARN' { 'Yellow' } 'ERR' { 'Red' } default { 'Cyan' } }
        Write-Host "[WATCHDOG] $Message" -ForegroundColor $color
    }
}

function Get-State {
    if (Test-Path $stateFile) {
        try { return Get-Content $stateFile -Raw | ConvertFrom-Json } catch {}
    }
    return $null
}

function Get-Health {
    if (Test-Path $healthFile) {
        try { return Get-Content $healthFile -Raw | ConvertFrom-Json } catch {}
    }
    return $null
}

function Test-ProcessAlive {
    param([int]$TargetPid)
    if ($TargetPid -le 0) { return $false }
    $proc = Get-Process -Id $TargetPid -ErrorAction SilentlyContinue
    return ($null -ne $proc -and -not $proc.HasExited)
}

function Write-HealthFile {
    param([int]$FeedPid, [int]$SrvPid, [int]$Port, [bool]$FeedAlive, [bool]$SrvAlive)
    $health = [PSCustomObject]@{
        timestamp     = (Get-Date -Format 'o')
        liveFeedPid   = $FeedPid
        serverPid     = $SrvPid
        serverPort    = $Port
        liveFeedAlive = $FeedAlive
        serverAlive   = $SrvAlive
    } | ConvertTo-Json -Depth 3
    $health | Set-Content $healthFile
}

function Save-WatchdogState {
    param($Data)
    $Data | ConvertTo-Json -Depth 3 | Set-Content $watchdogState
}

function Get-WatchdogState {
    if (Test-Path $watchdogState) {
        try { return Get-Content $watchdogState -Raw | ConvertFrom-Json } catch {}
    }
    return [PSCustomObject]@{ restartCount = 0; lastRestart = $null; startedAt = (Get-Date -Format 'o') }
}

function Start-ProcessByScript {
    param([string]$ScriptPath, [string]$Args, [string]$Label)
    if (-not (Test-Path $ScriptPath)) { Write-Log 'ERR' "$Label script not found: $ScriptPath"; return $null }
    $si = [System.Diagnostics.ProcessStartInfo]::new()
    $si.FileName = 'pwsh.exe'
    $si.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $Args"
    $si.UseShellExecute = $false
    $si.CreateNoWindow = $true
    $si.RedirectStandardOutput = $true
    $si.RedirectStandardError = $true
    $si.WorkingDirectory = $repoRoot
    try {
        $proc = [System.Diagnostics.Process]::Start($si)
        Start-Sleep -Milliseconds 800
        if ($proc -and -not $proc.HasExited) {
            Write-Log 'OK' "$Label restarted (PID $($proc.Id))"
            return $proc.Id
        }
        Write-Log 'ERR' "$Label restart failed: $($proc.StandardError.ReadToEnd())"
    } catch {
        Write-Log 'ERR' "$Label restart exception: $_"
    }
    return $null
}

function Invoke-WatchdogCheck {
    $state = Get-State
    $health = Get-Health
    if (-not $state -and -not $health) {
        Write-Log 'WARN' 'No state or health file found — background processes not managed'
        return @{ feedAlive = $false; srvAlive = $false; feedPid = 0; srvPid = 0; port = 0 }
    }

    $feedPid = 0; $srvPid = 0; $port = 8090
    if ($state) {
        $feedPid = if ($state.liveFeedPid) { $state.liveFeedPid } else { 0 }
        $srvPid  = if ($state.serverPid)  { $state.serverPid }  else { 0 }
        $port    = if ($state.serverPort) { $state.serverPort }  else { 8090 }
    } elseif ($health) {
        $feedPid = if ($health.liveFeedPid) { $health.liveFeedPid } else { 0 }
        $srvPid  = if ($health.serverPid)  { $health.serverPid }  else { 0 }
        $port    = if ($health.serverPort) { $health.serverPort }  else { 8090 }
    }

    $feedAlive = Test-ProcessAlive -Pid $feedPid
    $srvAlive  = Test-ProcessAlive -Pid $srvPid

    if (-not $feedAlive -or -not $srvAlive) {
        Write-Log 'WARN' "Process health: feed=$(if ($feedAlive) {'OK'} else {'DEAD'}) PID=$feedPid | server=$(if ($srvAlive) {'OK'} else {'DEAD'}) PID=$srvPid"
    } else {
        Write-Log 'OK' "All processes healthy — feed PID $feedPid, server PID $srvPid"
    }

    if ($AutoRestart) {
        $wdState = Get-WatchdogState
        if ($wdState.restartCount -ge $MaxRestarts) {
            Write-Log 'ERR' "Max restarts ($MaxRestarts) reached — not attempting further restarts"
        } else {
            if (-not $feedAlive) {
                $feedScript = Join-Path $repoRoot 'scripts' 'metrics' 'live-feed.ps1'
                $newPid = Start-ProcessByScript -ScriptPath $feedScript -Args "-Daemon" -Label 'Live-feed'
                if ($newPid) { $feedPid = $newPid; $feedAlive = $true; $wdState.restartCount += 1; $wdState.lastRestart = (Get-Date -Format 'o') }
            }
            if (-not $srvAlive) {
                $srvScript = Join-Path $repoRoot 'scripts' 'metrics' 'metrics-server.ps1'
                $newPid = Start-ProcessByScript -ScriptPath $srvScript -Args "-Daemon -Port $port" -Label 'Metrics-server'
                if ($newPid) { $srvPid = $newPid; $srvAlive = $true; $wdState.restartCount += 1; $wdState.lastRestart = (Get-Date -Format 'o') }
            }
            Save-WatchdogState $wdState
        }
    }

    Write-HealthFile -FeedPid $feedPid -SrvPid $srvPid -Port $port -FeedAlive $feedAlive -SrvAlive $srvAlive

    return @{ feedAlive = $feedAlive; srvAlive = $srvAlive; feedPid = $feedPid; srvPid = $srvPid; port = $port }
}

switch ($Action) {
    'check' {
        $result = Invoke-WatchdogCheck
        if (-not $Quiet) {
            Write-Host "[WATCHDOG] Live-feed:  $(if ($result.feedAlive) { 'RUNNING' } else { 'STOPPED' }) (PID $($result.feedPid))" -ForegroundColor $(if ($result.feedAlive) { 'Green' } else { 'Red' })
            Write-Host "[WATCHDOG] Server:     $(if ($result.srvAlive) { 'RUNNING' } else { 'STOPPED' }) (PID $($result.srvPid))" -ForegroundColor $(if ($result.srvAlive) { 'Green' } else { 'Red' })
            Write-Host "[WATCHDOG] Port:       $($result.port)" -ForegroundColor Cyan
        }
        exit $(if ($result.feedAlive -and $result.srvAlive) { 0 } else { 1 })
    }

    'start' {
        Write-Log 'OK' 'Watchdog daemon started'
        $wdState = Get-WatchdogState
        $wdState.startedAt = (Get-Date -Format 'o')
        Save-WatchdogState $wdState
        while ($true) {
            Invoke-WatchdogCheck
            Start-Sleep -Seconds $IntervalSeconds
        }
    }

    'stop' {
        if (Test-Path $watchdogState) {
            Remove-Item $watchdogState -Force -ErrorAction SilentlyContinue
            Write-Log 'OK' 'Watchdog daemon stopped'
        }
        if (-not $Quiet) {
            Write-Host "[WATCHDOG] Stopped" -ForegroundColor Cyan
        }
    }

    'status' {
        $result = Invoke-WatchdogCheck
        $wdState = Get-WatchdogState
        Write-Host "[WATCHDOG] Live-feed:    $(if ($result.feedAlive) { 'RUNNING' } else { 'STOPPED' }) (PID $($result.feedPid))" -ForegroundColor $(if ($result.feedAlive) { 'Green' } else { 'Red' })
        Write-Host "[WATCHDOG] Server:       $(if ($result.srvAlive) { 'RUNNING' } else { 'STOPPED' }) (PID $($result.srvPid))" -ForegroundColor $(if ($result.srvAlive) { 'Green' } else { 'Red' })
        Write-Host "[WATCHDOG] Port:         $($result.port)" -ForegroundColor Cyan
        Write-Host "[WATCHDOG] Restarts:     $($wdState.restartCount) / $MaxRestarts" -ForegroundColor Yellow
        Write-Host "[WATCHDOG] Last restart: $(if ($wdState.lastRestart) { $wdState.lastRestart } else { 'never' })" -ForegroundColor Gray
        Write-Host "[WATCHDOG] Log:          $watchdogLog" -ForegroundColor Gray
        exit $(if ($result.feedAlive -and $result.srvAlive) { 0 } else { 1 })
    }
}
