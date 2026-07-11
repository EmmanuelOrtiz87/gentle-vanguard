# adaptive-common.ps1 — Shared helper functions for adaptive profile scripts

function Get-RepoRoot {
    $dir = $PSScriptRoot
    while ($dir -and $dir -ne (Split-Path $dir -Parent)) {
        if (Test-Path (Join-Path $dir '.git')) { return $dir }
        $dir = Split-Path $dir -Parent
    }
    return (Get-Location).Path
}

function Get-SessionDir {
    param([string]$RepoRoot)
    $sessionDir = Join-Path $RepoRoot '.session'
    if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null }
    return $sessionDir
}

function Read-JsonFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try {
        $raw = Get-Content $Path -Raw -ErrorAction SilentlyContinue
        if ($raw) { return ($raw | ConvertFrom-Json) }
    } catch { }
    return $null
}

function Save-JsonFile {
    param([string]$Path, $Data)
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $Data | ConvertTo-Json -Depth 10 | Set-Content $Path -Encoding UTF8
}

function Get-DefaultState {
    return @{
        normalStreak = 0
        peakHoursUsed = 0
        lastProfile = 'balanced'
    }
}

function Test-PeakHour {
    param([string]$TimeZone, [int]$PeakStart = 9, [int]$PeakEnd = 15)
    try {
        $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone)
        $localTime = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz)
        return ($localTime.Hour -ge $PeakStart -and $localTime.Hour -lt $PeakEnd)
    } catch {
        return $false
    }
}

function Test-TokenPressure {
    param([string]$RepoRoot)
    $budgetFile = Join-Path $RepoRoot '.session/token-budget.json'
    $budget = Read-JsonFile -Path $budgetFile
    if (-not $budget) { return $false }
    if ($budget.used -and $budget.limit) {
        return (($budget.used / $budget.limit) -gt 0.8)
    }
    return $false
}

function Get-AdaptiveReason {
    param([bool]$Peak, [bool]$Pressure)
    if ($Peak -and $Pressure) { return 'peak+pressure' }
    if ($Peak) { return 'peak-hours' }
    if ($Pressure) { return 'token-pressure' }
    return 'normal'
}

function Write-LogOk    { param([string]$Msg) Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Write-LogWarn  { param([string]$Msg) Write-Host "  [WARN] $Msg" -ForegroundColor Yellow }
function Write-LogInfo  { param([string]$Msg) Write-Host "  [INFO] $Msg" -ForegroundColor Cyan }
