# adaptive-common.ps1
# Shared functions for all adaptive profiles — DRY refactor

function Write-LogInfo { param([string]$m) if (-not $script:Silent) { Write-Host "[INFO] $m" -ForegroundColor Gray } }
function Write-LogOk { param([string]$m) if (-not $script:Silent) { Write-Host "[OK] $m" -ForegroundColor Green } }
function Write-LogWarn { param([string]$m) if (-not $script:Silent) { Write-Host "[WARN] $m" -ForegroundColor Yellow } }

function Get-RepoRoot {
    if ($env:GENTLE_VANGUARD_BASE_DIR -and (Test-Path $env:GENTLE_VANGUARD_BASE_DIR)) { return $env:GENTLE_VANGUARD_BASE_DIR }
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config\orchestrator.json'))) { $root = Split-Path -Parent $root }
    return $root
}

function Get-SessionDir {
    param([string]$RepoRoot)
    $d = Join-Path $RepoRoot 'scripts/.session'
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    return $d
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try { return Get-Content $Path -Raw | ConvertFrom-Json } catch { return $null }
}

function Save-JsonFile {
    param([string]$Path, [object]$Data)
    $Data | ConvertTo-Json -Depth 100 | Out-File -FilePath $Path -Encoding UTF8 -Force
}

function Test-PeakHour {
    param([string]$TimeZone = 'Argentina Standard Time', [int]$PeakStart = 9, [int]$PeakEnd = 15)
    $s = Read-JsonFile -Path $script:summaryPath
    if ($s -and $null -ne $s.isPeakHour) { return [bool]$s.isPeakHour }
    try {
        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone)
        $local = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz)
        return ($local.Hour -ge $PeakStart -and $local.Hour -lt $PeakEnd)
    } catch {
        $fallback = [DateTime]::UtcNow.AddHours(-3)
        return ($fallback.Hour -ge $PeakStart -and $fallback.Hour -lt $PeakEnd)
    }
}

function Test-TokenPressure {
    $m = Read-JsonFile -Path $script:metricsPath
    if (-not $m -or -not $m.metrics) { return $false }
    try { return ([int]$m.metrics.totalTokens -ge 12000) } catch { return $false }
}

function Get-AdaptiveReason {
    param([bool]$Peak, [bool]$Pressure)
    if ($Peak -and $Pressure) { return 'peak-hour + token-pressure' }
    if ($Peak) { return 'peak-hour' }
    if ($Pressure) { return 'token-pressure' }
    return 'normalized'
}

function Get-DefaultState {
    return [pscustomobject]@{
        optimizationActive = $false
        normalStreak = 0
        lastAction = 'none'
        lastReason = ''
        lastChangedAt = ''
    }
}

function Invoke-AdaptiveNotify {
    param([string]$Reason, [string]$Details)
    if (Test-Path $script:notifyPath) {
        try { & $script:notifyPath -Action 'cleanup' -Reason $Reason -Details $Details | Out-Null } catch {}
    }
}
