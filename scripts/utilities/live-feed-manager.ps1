<#
.SYNOPSIS
    Manages background processes for live metrics — starts/stops/monitors live-feed and metrics-server.

.DESCRIPTION
    Orchestrates the metrics pipeline:
    - start   → launches live-feed.ps1 (collector) and metrics-server.ps1 (HTTP)
    - stop    → terminates both processes and cleans state file
    - status  → reports current process health with elapsed time

    State is persisted in .session/live-feed-state.json.
    Use background-watchdog.ps1 for continuous health monitoring with auto-restart.

.PARAMETER Action
    start  → launch background processes (default)
    stop   → terminate all background processes
    status → show process health and dashboard URL

.PARAMETER RefreshSeconds
    Data collection interval. Default: 15

.PARAMETER ServerPort
    HTTP server port. Default: 8090

.PARAMETER OpenDashboard
    Open dashboard in browser after start.

.PARAMETER ProjectRoot
    Project root path. Auto-detected if empty.

.EXAMPLE
    .\live-feed-manager.ps1 -Action start -OpenDashboard
    .\live-feed-manager.ps1 -Action status
    .\live-feed-manager.ps1 -Action stop
#>

param(
    [ValidateSet('start','stop','status')]
    [string]$Action = 'start',
    [int]$RefreshSeconds = 15,
    [int]$ServerPort = 8090,
    [switch]$OpenDashboard,
    [string]$ProjectRoot = ''
)

$ErrorActionPreference = 'Continue'

if (-not $ProjectRoot) {
    $ProjectRoot = if ($env:GV_BASE_DIR -and (Test-Path $env:GV_BASE_DIR)) { 
        $env:GV_BASE_DIR 
    } else {
        $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { 
            Split-Path -Parent $MyInvocation.MyCommand.Path 
        } else { 
            Get-Location 
        }
        $root = Split-Path -Parent $scriptRoot
        while ($root -and -not (Test-Path (Join-Path $root 'config'))) { 
            $root = Split-Path -Parent $root 
        }
        if (-not $root) { $root = $scriptRoot }
        $root
    }
}

$stateFile = Join-Path $ProjectRoot '.session' 'live-feed-state.json'
$healthFile = Join-Path $ProjectRoot '.runtime' 'metrics' 'live' 'daemon-health.json'
$snapDir = Join-Path $ProjectRoot '.runtime' 'metrics' 'snapshots'

function Write-Status { param([string]$m) Write-Host "[LIVE-FEED-MGR] $m" -ForegroundColor Cyan }
function Write-OK     { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn   { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err    { param([string]$m) Write-Host "[ERR] $m" -ForegroundColor Red }

function Register-UrlAcl {
    param([int]$Port)
    $url = "http://localhost:${Port}/"
    try {
        $listener = [System.Net.HttpListener]::new()
        $listener.Prefixes.Add($url)
        $listener.Start()
        $listener.Stop()
        $listener.Close()
        return $true
    } catch {
        Write-Warn "HttpListener needs URL reservation. Registering via netsh..."
        $cmd = "netsh http add urlacl url=http://localhost:${Port}/ user=BUILTIN\Users listen=yes"
        $result = cmd /c "$cmd 2>&1"
        if ($LASTEXITCODE -eq 0) {
            Write-OK "URL reservation added for port $Port"
            return $true
        } else {
            Write-Warn "Could not register URL (may need admin). Server will not start."
            Write-Warn "Run manually: $cmd (as admin)"
            return $false
        }
    }
}

function Ensure-MetricsDirs {
    $liveDir = Join-Path $ProjectRoot '.runtime' 'metrics' 'live'
    if (-not (Test-Path $liveDir)) { New-Item -ItemType Directory -Path $liveDir -Force | Out-Null }
}

function Cleanup-Snapshots {
    if (-not (Test-Path $snapDir)) { return }
    $snaps = Get-ChildItem $snapDir -Filter 'snapshot-*.json' | Sort-Object LastWriteTime -Descending
    $keep = 5
    if ($snaps.Count -gt $keep) {
        $toRemove = $snaps | Select-Object -Skip $keep
        foreach ($s in $toRemove) {
            Remove-Item $s.FullName -Force -ErrorAction SilentlyContinue
        }
        Write-OK "Cleaned $($toRemove.Count) old snapshots (kept $keep)"
    }
}

function Write-HealthFile {
    param([int]$FeedPid, [int]$SrvPid, [int]$Port)
    Ensure-MetricsDirs
    $health = [PSCustomObject]@{
        timestamp     = (Get-Date -Format 'o')
        liveFeedPid   = $FeedPid
        serverPid     = $SrvPid
        serverPort    = $Port
        liveFeedAlive = $null -ne (Get-Process -Id $FeedPid -ErrorAction SilentlyContinue)
        serverAlive   = $null -ne (Get-Process -Id $SrvPid -ErrorAction SilentlyContinue)
    }
    $health | ConvertTo-Json -Depth 3 | Set-Content $healthFile
}

function Start-BackgroundProcess {
    param([string]$ScriptPath, [string]$Args, [string]$Label)
    if (-not (Test-Path $ScriptPath)) { Write-Err "$Label script not found: $ScriptPath"; return $null }
    $si = [System.Diagnostics.ProcessStartInfo]::new()
    $si.FileName = 'pwsh.exe'
    $si.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" $Args"
    $si.UseShellExecute = $false
    $si.CreateNoWindow = $true
    $si.RedirectStandardOutput = $true
    $si.RedirectStandardError = $true
    $si.WorkingDirectory = $ProjectRoot
    try {
        $proc = [System.Diagnostics.Process]::Start($si)
        Start-Sleep -Milliseconds 800
        if ($proc -and -not $proc.HasExited) {
            Write-OK "$Label started (PID $($proc.Id))"
            return $proc.Id
        }
        $stderr = if ($proc) { $proc.StandardError.ReadToEnd() } else { 'process failed to start' }
        Write-Err "$Label failed: $stderr"
    } catch {
        Write-Err "$Label exception: $_"
    }
    return $null
}

function Stop-ProcessByPid {
    param([int]$TargetPid, [string]$Label)
    if ($TargetPid -le 0) { return }
    $proc = Get-Process -Id $TargetPid -ErrorAction SilentlyContinue
    if ($proc) {
        $proc.Kill()
        $proc.WaitForExit(3000) | Out-Null
        Write-OK "$Label (PID $TargetPid) stopped"
    }
}

function Get-State {
    if (Test-Path $stateFile) {
        try { return Get-Content $stateFile -Raw | ConvertFrom-Json } catch {}
    }
    return $null
}

function Save-State {
    param($Data)
    $Data | ConvertTo-Json -Depth 3 | Set-Content $stateFile
}

switch ($Action) {
    'start' {
        $existing = Get-State
        if ($existing) {
            $livePid = if ($existing.liveFeedPid) { $existing.liveFeedPid } else { 0 }
            $srvPid  = if ($existing.serverPid)  { $existing.serverPid }  else { 0 }
            $proc1 = Get-Process -Id $livePid -ErrorAction SilentlyContinue
            $proc2 = Get-Process -Id $srvPid -ErrorAction SilentlyContinue
            if ($proc1 -or $proc2) {
                Write-Warn "Background processes already running. Use 'stop' first."
                exit 0
            }
            Write-Warn "Stale state file found. Removing."
            Remove-Item $stateFile -Force -ErrorAction SilentlyContinue
        }

        $state = @{
            startedAt    = (Get-Date -Format 'o')
            liveFeedPid  = 0
            serverPid    = 0
            refreshSec   = $RefreshSeconds
            serverPort   = $ServerPort
        }

        $feedScript = Join-Path $ProjectRoot 'scripts' 'metrics' 'live-feed.ps1'
        $feedPid = Start-BackgroundProcess -ScriptPath $feedScript -Args "-RefreshSeconds $RefreshSeconds -Daemon" -Label 'Live-feed'
        if (-not $feedPid) { exit 1 }
        $state.liveFeedPid = $feedPid

        $srvScript = Join-Path $ProjectRoot 'scripts' 'metrics' 'metrics-server.ps1'
        $canServe = Register-UrlAcl -Port $ServerPort
        if ($canServe) {
            $srvPid = Start-BackgroundProcess -ScriptPath $srvScript -Args "-Port $ServerPort -Daemon" -Label 'Metrics-server'
            if ($srvPid) { $state.serverPid = $srvPid }
        }

        Cleanup-Snapshots
        Save-State $state
        Write-HealthFile -FeedPid $feedPid -SrvPid $state.serverPid -Port $ServerPort

        Write-Status "Dashboard: http://localhost:${ServerPort}/"
        Write-Status "Live API:   http://localhost:${ServerPort}/api/live"
        Write-Status "Health:     $healthFile"

        if ($OpenDashboard) {
            Start-Process "http://localhost:${ServerPort}/"
            Write-OK "Dashboard opened in default browser"
        }
    }

    'stop' {
        Cleanup-Snapshots

        $state = Get-State
        if ($state) {
            $livePid = if ($state.liveFeedPid) { $state.liveFeedPid } else { 0 }
            $srvPid  = if ($state.serverPid)  { $state.serverPid }  else { 0 }
            Stop-ProcessByPid -TargetPid $livePid -Label 'Live-feed'
            Stop-ProcessByPid -TargetPid $srvPid  -Label 'Metrics-server'
            Remove-Item $stateFile -Force -ErrorAction SilentlyContinue
        }

        # Also clean any orphaned processes (in case state file was lost)
        Get-Process -Name 'pwsh' -ErrorAction SilentlyContinue | Where-Object {
            $cmd = $_.CommandLine
            $cmd -match 'live-feed\.ps1' -or $cmd -match 'metrics-server\.ps1'
        } | ForEach-Object {
            $_.Kill()
            Write-OK "Orphaned process cleaned (PID $($_.Id))"
        }

        if (Test-Path $healthFile) {
            Remove-Item $healthFile -Force -ErrorAction SilentlyContinue
        }

        Write-OK "All background processes stopped"
    }

    'status' {
        $state = Get-State
        if (-not $state) {
            Write-Status "Background processes: NOT RUNNING"
            exit 0
        }
        $livePid = if ($state.liveFeedPid) { $state.liveFeedPid } else { 0 }
        $srvPid  = if ($state.serverPid)  { $state.serverPid }  else { 0 }
        $elapsed = [math]::Round(((Get-Date) - (Get-Date $state.startedAt)).TotalMinutes, 1)
        $proc1 = Get-Process -Id $livePid -ErrorAction SilentlyContinue
        $proc2 = Get-Process -Id $srvPid -ErrorAction SilentlyContinue
        $liveStatus = if ($proc1) { "RUNNING (PID $livePid)" } else { "STOPPED" }
        $srvStatus  = if ($proc2) { "RUNNING (PID $srvPid)" } else { "STOPPED" }
        Write-Status "Live-feed:      $liveStatus"
        Write-Status "Metrics-server: $srvStatus (port $($state.serverPort))"
        Write-Status "Elapsed: ${elapsed}min"
        Write-Status "Dashboard: http://localhost:$($state.serverPort)/"
        if (-not $proc1 -and -not $proc2) {
            Write-Warn "Processes are dead but state file exists. Run 'stop' to clean."
        }
    }
}
