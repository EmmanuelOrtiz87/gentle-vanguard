# post-autostart-summary.ps1
# Generates compact JSON summary after session-autostart completes
# Agent reads this to present key info to user

param(
    [string]$TimeZone = 'Argentina Standard Time',
    [int]$PeakStart = 9,
    [int]$PeakEnd = 15,
    [string]$Region = 'Argentina'
)

$ErrorActionPreference = 'Continue'

$repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

# Detect peak hour
$peakHour = $false
try {
    $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone)
    $localTime = [System.TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz)
    $hour = $localTime.Hour
    $peakHour = ($hour -ge $PeakStart -and $hour -lt $PeakEnd)
} catch {
    $localTime = [DateTime]::UtcNow.AddHours(-3)
    $hour = $localTime.Hour
    $peakHour = ($hour -ge $PeakStart -and $hour -lt $PeakEnd)
}

# Get session ID (check both session/ and .session/ dirs)
$sessionId = ''
foreach ($sd in @((Join-Path $repoRoot 'session'), (Join-Path $repoRoot '.session'))) {
    if (Test-Path $sd) {
        $sf = Get-ChildItem (Join-Path $sd 'session-*.json') -File -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending |
              Select-Object -First 1
        if ($sf) { $sessionId = $sf.BaseName; break }
    }
}

# Check git status
$workspaceClean = $false
$gitStatus = git -C $repoRoot status --porcelain 2>$null
if ($LASTEXITCODE -eq 0 -and [string]::IsNullOrWhiteSpace($gitStatus)) {
    $workspaceClean = $true
}

# Detect OS
$platform = 'unknown'; $shell = 'unknown'
$osIsWin = [System.OperatingSystem]::IsWindows()
$osIsLinux = [System.OperatingSystem]::IsLinux()
$osIsMacOS = [System.OperatingSystem]::IsMacOS()
if ($osIsWin)     { $platform = 'windows'; $shell = 'powershell' }
elseif ($osIsMacOS) { $platform = 'macos';   $shell = 'zsh' }
elseif ($osIsLinux)  { $platform = 'linux';   $shell = 'bash' }

# Check engram status
$engramOk = $false
try {
    $ep = Get-Process -Name 'engram' -ErrorAction SilentlyContinue
    $engramOk = ($null -ne $ep)
} catch { $engramOk = $false }

$summary = @{
    timestamp       = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    tool            = 'opencode'
    platform        = $platform
    shell           = $shell
    pathSeparator   = [System.IO.Path]::DirectorySeparatorChar.ToString()
    isPeakHour      = $peakHour
    peakHourWindow  = "$PeakStart`:00-$PeakEnd`:00 $Region"
    timezone        = $TimeZone
    sessionId       = $sessionId
    workspaceClean  = $workspaceClean
    engramRunning   = $engramOk
    localTime       = "$($localTime.ToString('HH:mm:ss zzz'))"
}

$summaryDir = Join-Path $repoRoot 'scripts\.session'
if (-not (Test-Path $summaryDir)) { New-Item -ItemType Directory -Path $summaryDir -Force | Out-Null }
$outPath = Join-Path $summaryDir 'startup-summary.json'
$summary | ConvertTo-Json -Depth 3 | Out-File -FilePath $outPath -Encoding UTF8 -Force
Write-Output "[SUMMARY] Startup summary written to $outPath"
