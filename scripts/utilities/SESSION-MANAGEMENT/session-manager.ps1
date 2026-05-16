param(
    [ValidateSet('AutoStart', 'ManualStart', 'ManualEnd', 'Status')]
    [string]$Mode = 'AutoStart'
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path
$wf = Join-Path $root 'scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1'
$dayEnd = Join-Path $root 'scripts\utilities\UTILITIES\day-end-closure.ps1'
$runEngram = Join-Path $root 'scripts\utilities\UTILITIES\run-engram.ps1'
$agentRouter = Join-Path $root 'scripts\utilities\AI-AGENT-MANAGEMENT\agent-router.ps1'
$enforce = Join-Path $root 'scripts\utilities\UTILITIES\enforce-response-mode.ps1'
$monitor = Join-Path $scriptDir 'session-idle-monitor.ps1'
$stateDir = Join-Path $scriptDir '.session'
$stateFile = Join-Path $stateDir 'state.json'
$counterDir = Join-Path $stateDir 'counters'
$messageFile = Join-Path $stateDir 'last-auto-close-message.txt'
$configPath = Join-Path $scriptDir 'session-autostart.config.json'

function Write-Step { param([string]$Message) Write-Host "`n=== $Message ===" -ForegroundColor Cyan }
function Write-Ok { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }

function Ensure-Dirs {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    New-Item -ItemType Directory -Path $counterDir -Force | Out-Null
}

function Get-Config {
    $defaults = [pscustomobject]@{
        idleTimeoutMinutes = 60
        enableIdleAutoClose = $true
        strictCompatibilityChecks = $true
    }
    if (-not (Test-Path $configPath)) { return $defaults }

    try {
        $cfg = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $cfg.PSObject.Properties['idleTimeoutMinutes']) {
            $cfg | Add-Member -MemberType NoteProperty -Name idleTimeoutMinutes -Value 60
        }
        if (-not $cfg.PSObject.Properties['enableIdleAutoClose']) {
            $cfg | Add-Member -MemberType NoteProperty -Name enableIdleAutoClose -Value $true
        }
        if (-not $cfg.PSObject.Properties['strictCompatibilityChecks']) {
            $cfg | Add-Member -MemberType NoteProperty -Name strictCompatibilityChecks -Value $true
        }
        return $cfg
    }
    catch {
        return $defaults
    }
}

function Load-State {
    if (-not (Test-Path $stateFile)) { return $null }
    try { return (Get-Content -Path $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

function Save-State {
    param([pscustomobject]$State)
    $State | ConvertTo-Json -Depth 8 | Set-Content -Path $stateFile -Encoding UTF8
}

function Get-NewSessionId {
    $date = Get-Date -Format 'yyyy-MM-dd'
    $counterPath = Join-Path $counterDir "$date.txt"
    $n = 0
    if (Test-Path $counterPath) {
        $raw = Get-Content -Path $counterPath -Raw -Encoding UTF8
        if ($raw -match '^\d+$') {
            $n = [int]$raw.Trim()
        }
    }
    $n++
    Set-Content -Path $counterPath -Value $n -Encoding ASCII
    return ('session-{0}-{1:d2}' -f $date, $n)
}

function Show-PendingAutoCloseMessage {
    if (-not (Test-Path $messageFile)) { return }
    Write-Step "Previous auto-close message"
    Get-Content -Path $messageFile -Encoding UTF8 | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    Remove-Item -LiteralPath $messageFile -Force -ErrorAction SilentlyContinue
}

function Start-Monitor {
    param(
        [string]$SessionId,
        [int]$IdleTimeoutMinutes,
        [bool]$Enabled
    )

    if (-not $Enabled) {
        Write-Warn "Idle auto-close disabled by config."
        return $null
    }

    $current = Load-State
    if ($current -and $current.monitorPid) {
        $proc = Get-Process -Id $current.monitorPid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Ok "Idle monitor already active (PID $($current.monitorPid))."
            return [int]$current.monitorPid
        }
    }

    $argLine = "-NoProfile -ExecutionPolicy Bypass -File `"$monitor`" -StateFile `"$stateFile`" -MessageFile `"$messageFile`" -DayEndScript `"$dayEnd`" -SessionId `"$SessionId`" -IdleTimeoutMinutes $IdleTimeoutMinutes"
    $proc = Start-Process -FilePath powershell -ArgumentList $argLine -WindowStyle Hidden -PassThru
    Write-Ok "Idle monitor started (PID $($proc.Id), timeout ${IdleTimeoutMinutes}m)."
    return [int]$proc.Id
}

function Stop-Monitor {
    param([int]$MonitorProcessId)
    if (-not $MonitorProcessId) { return }
    try {
        Stop-Process -Id $MonitorProcessId -Force -ErrorAction SilentlyContinue
    } catch {}
}

function Assert-Prereqs {
    if (-not (Test-Path $wf)) { throw "wf.ps1 not found: $wf" }
    if (-not (Test-Path $dayEnd)) { throw "day-end-closure.ps1 not found: $dayEnd" }
    if (-not (Test-Path $runEngram)) { throw "run-engram.ps1 not found: $runEngram" }
    if (-not (Test-Path $agentRouter)) { throw "agent-router.ps1 not found: $agentRouter" }
}

function Invoke-CompatibilityChecks {
    param(
        [bool]$Strict
    )

    Write-Step "Runtime compatibility checks"
    $failures = @()

    & $wf orchestrator-status
    if ($LASTEXITCODE -ne 0) {
        $failures += "wf orchestrator-status failed with exit $LASTEXITCODE"
    }

    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    if (-not $engramCmd) {
        $failures += "engram command not found in PATH"
    }
    if (-not (Test-Path $runEngram)) {
        $failures += "run-engram.ps1 not found"
    }

    & $agentRouter status
    if ($LASTEXITCODE -ne 0) {
        $failures += "agent-router status failed with exit $LASTEXITCODE"
    }

    if ($failures.Count -eq 0) {
        Write-Ok "Compatibility checks passed (engram + orchestrator + agents)."
        return
    }

    foreach ($f in $failures) {
        Write-Warn $f
    }

    if ($Strict) {
        Write-Host ""
        Write-Warn "Session start blocked by strict compatibility policy."
        Write-Host "How to proceed:" -ForegroundColor Cyan
        Write-Host "  1) Keep strict mode (recommended) and fix missing components." -ForegroundColor White
        Write-Host "     - .\tools\validate-session-stack.ps1 -Quiet" -ForegroundColor Gray
        Write-Host "     - .\foundation\\scripts\utilities\wf.ps1 orchestrator-status" -ForegroundColor Gray
        Write-Host "     - .\foundation\\scripts\utilities\agent-router.ps1 status" -ForegroundColor Gray
        Write-Host "  2) Temporary continuity mode (degraded startup)." -ForegroundColor White
        Write-Host "     - Set strictCompatibilityChecks=false in scripts/utilities/session-autostart.config.json" -ForegroundColor Gray
        Write-Host "     - Re-run: .\tools\session-autostart.cmd" -ForegroundColor Gray
        throw "Compatibility checks failed in strict mode."
    }

    Write-Warn "Continuing because strictCompatibilityChecks=false."
}

function Run-StartFlow {
    param([bool]$Manual)

    Assert-Prereqs
    Ensure-Dirs
    $cfg = Get-Config

    Show-PendingAutoCloseMessage

    Write-Step "Enforcing response mode"
    if (Test-Path $enforce) {
        & $enforce
    } else {
        Write-Warn "enforce-response-mode.ps1 not found, continuing."
    }

    Write-Step "System health and tool activation"
    & $wf health
    if ($LASTEXITCODE -ne 0) { throw "wf health failed with exit $LASTEXITCODE" }

    Invoke-CompatibilityChecks -Strict ([bool]$cfg.strictCompatibilityChecks)

    Write-Step "Session tracking"
    $sessionId = Get-NewSessionId
    & $wf start-session -SessionId $sessionId
    if ($LASTEXITCODE -ne 0) { throw "wf start-session failed with exit $LASTEXITCODE" }

    $monitorPid = Start-Monitor -SessionId $sessionId -IdleTimeoutMinutes ([int]$cfg.idleTimeoutMinutes) -Enabled ([bool]$cfg.enableIdleAutoClose)

    $state = [pscustomobject]@{
        project = 'workspace_local'
        directory = $root
        sessionId = $sessionId
        startedAt = (Get-Date).ToString('s')
        status = 'active'
        mode = if ($Manual) { 'manual' } else { 'auto' }
        monitorPid = $monitorPid
        idleTimeoutMinutes = [int]$cfg.idleTimeoutMinutes
    }
    Save-State -State $state

    Write-Ok "Session started: $sessionId"
    Write-Host "Re-entry commands:" -ForegroundColor Cyan
    Write-Host "  Auto   : .\tools\session-autostart.cmd" -ForegroundColor Gray
    Write-Host "  Manual : .\tools\session-manual-start.cmd" -ForegroundColor Gray
}

function Run-EndFlow {
    param([bool]$Manual)

    Assert-Prereqs
    Ensure-Dirs

    $state = Load-State
    $sessionId = if ($state -and $state.sessionId) { [string]$state.sessionId } else { Get-NewSessionId }

    Write-Step "Day-end closure and Engram save"
    & $dayEnd -SessionId $sessionId -Force
    if ($LASTEXITCODE -ne 0) {
        throw "day-end-closure failed with exit $LASTEXITCODE"
    }

    if ($state -and $state.monitorPid) {
        Stop-Monitor -MonitorProcessId ([int]$state.monitorPid)
    }

    $closed = [pscustomobject]@{
        project = 'workspace_local'
        directory = $root
        sessionId = $sessionId
        closedAt = (Get-Date).ToString('s')
        status = 'closed'
        mode = if ($Manual) { 'manual' } else { 'auto' }
        monitorPid = $null
    }
    Save-State -State $closed
    Write-Ok "Session closed: $sessionId"
}

switch ($Mode) {
    'AutoStart' {
        Run-StartFlow -Manual:$false
    }
    'ManualStart' {
        Run-StartFlow -Manual:$true
    }
    'ManualEnd' {
        Run-EndFlow -Manual:$true
    }
    'Status' {
        Ensure-Dirs
        $state = Load-State
        if (-not $state) {
            Write-Warn "No session state found."
            exit 0
        }
        Write-Host ("Session: {0} | Status: {1} | Started: {2} | Monitor PID: {3}" -f $state.sessionId, $state.status, $state.startedAt, $state.monitorPid) -ForegroundColor White
    }
}


