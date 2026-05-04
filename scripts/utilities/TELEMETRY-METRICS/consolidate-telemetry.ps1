# consolidate-telemetry.ps1
# Consolidates runtime/session telemetry into a management master file.
# Usage: .\consolidate-telemetry.ps1 [-UserId <name>]

param(
    [string]$UserId
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path
$runtimeCloudTelemetry = Join-Path $repoRoot '.runtime\telemetry\cloud-agent-telemetry.csv'
$masterFile = Join-Path $repoRoot 'docs\management\telemetry-master.csv'
$sessionsDir = Join-Path $repoRoot 'docs\sessions'
$judgmentDir = Join-Path $repoRoot 'docs\judgment'

function Write-Step { param([string]$m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Info { param([string]$m) Write-Host "[INFO] $m" -ForegroundColor Yellow }

function Sanitize-CsvCell {
    param([string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    $safe = ($Value -replace '[\r\n]+', ' ')
    $trimmedLead = $safe.TrimStart()
    if ($trimmedLead -match '^[=+\-@]') {
        $safe = "'$safe"
    }
    return $safe
}

function Get-LatestFile {
    param(
        [string]$Path,
        [string]$Filter
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    return Get-ChildItem -Path $Path -Filter $Filter -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-LatestCloudTelemetry {
    param([string]$SessionId)

    if (-not (Test-Path $runtimeCloudTelemetry)) {
        return $null
    }

    $rows = Import-Csv $runtimeCloudTelemetry -ErrorAction SilentlyContinue
    if (-not $rows -or $rows.Count -eq 0) {
        return $null
    }

    if ([string]::IsNullOrWhiteSpace($SessionId)) {
        return $null
    }

    $matching = @($rows | Where-Object { $_.Session_ID -eq $SessionId })
    if (-not $matching -or $matching.Count -eq 0) {
        return $null
    }

    return $matching | Select-Object -Last 1
}

# 1. Identify User
if ([string]::IsNullOrWhiteSpace($UserId)) {
    $UserId = git -C $repoRoot config user.name 2>$null
    if ([string]::IsNullOrWhiteSpace($UserId)) { $UserId = 'unknown' }
}
Write-Step "Consolidating telemetry for User: $UserId"

# 2. Ensure Master File Exists
if (-not (Test-Path $masterFile)) {
    New-Item -ItemType Directory -Path (Split-Path $masterFile) -Force | Out-Null
    "Timestamp,User_ID,Session_ID,Task_Scope,Tokens_Estimated,Judgment_Result,Review_Issues,Duration_Min,Efficiency_Score" | Out-File -FilePath $masterFile -Encoding UTF8BOM
}

if (Test-Path $runtimeCloudTelemetry) {
    Write-Ok "Runtime cloud telemetry detected: $runtimeCloudTelemetry"
}

# 3. Consolidate latest available runtime/session signals
$latestSession = Get-LatestFile -Path $sessionsDir -Filter "*-session-start.md"
$latestJudgment = Get-LatestFile -Path $judgmentDir -Filter "dashboard.csv"

if (-not $latestSession) {
    Write-Info "Missing session or runtime telemetry; skipping consolidation append."
    Write-Ok "Telemetry consolidation complete. Check $masterFile"
    exit 0
}

$sessionId = if ($latestSession) { $latestSession.BaseName.Replace('-session-start', '') } else { 'no-session' }
$taskScope = 'General Session'

$latestCloudRow = Get-LatestCloudTelemetry -SessionId $sessionId
if (-not $latestCloudRow) {
    Write-Info "No correlated runtime telemetry for session $sessionId; skipping consolidation append."
    Write-Ok "Telemetry consolidation complete. Check $masterFile"
    exit 0
}

$telemetrySessionId = if ($latestCloudRow -and $latestCloudRow.Session_ID) { [string]$latestCloudRow.Session_ID } else { '' }
if ($latestSession -and $telemetrySessionId -and ($telemetrySessionId -ne $sessionId)) {
    Write-Info "Telemetry/session mismatch (telemetry: $telemetrySessionId, session: $sessionId). Skipping append to avoid mixed records."
    Write-Ok "Telemetry consolidation complete. Check $masterFile"
    exit 0
}

if ([string]::IsNullOrWhiteSpace($telemetrySessionId)) {
    Write-Info "Runtime telemetry row missing Session_ID; skipping append to avoid fabricated aggregation."
    Write-Ok "Telemetry consolidation complete. Check $masterFile"
    exit 0
}

$telemetryUser = if ($latestCloudRow.User_ID) { [string]$latestCloudRow.User_ID } else { '' }
if ([string]::IsNullOrWhiteSpace($telemetryUser)) {
    Write-Info "Runtime telemetry row missing User_ID; skipping append to avoid attribution drift."
    Write-Ok "Telemetry consolidation complete. Check $masterFile"
    exit 0
}

$existingRows = @()
if (Test-Path $masterFile) {
    $existingRows = @(Import-Csv $masterFile -ErrorAction SilentlyContinue)
}
if ($existingRows -and ($existingRows | Where-Object { $_.Session_ID -eq $sessionId })) {
    Write-Info "Session $sessionId already consolidated; skipping duplicate append."
    Write-Ok "Telemetry consolidation complete. Check $masterFile"
    exit 0
}

$tokens = 0
if ($latestCloudRow) {
    $inTokens = 0
    $outTokens = 0
    if ($latestCloudRow.InputTokens -match '^\d+$') {
        $inTokens = [int]$latestCloudRow.InputTokens
    }
    if ($latestCloudRow.OutputTokens -match '^\d+$') {
        $outTokens = [int]$latestCloudRow.OutputTokens
    }
    $tokens = $inTokens + $outTokens
}

$judgmentRes = 'UNKNOWN'
if ($latestJudgment) {
    $judgmentRows = Import-Csv $latestJudgment.FullName -ErrorAction SilentlyContinue
    if ($judgmentRows -and $judgmentRows.Count -gt 0) {
        $matching = $judgmentRows | Where-Object { $_.SessionID -eq $sessionId }
        if ($matching -and $matching.Count -gt 0) {
            $statuses = @($matching | ForEach-Object { [string]$_.Status })
            if ($statuses -contains 'FAIL') {
                $judgmentRes = 'FAIL'
            } elseif ($statuses -contains 'OK') {
                $judgmentRes = 'PASS'
            } else {
                $judgmentRes = 'PARTIAL'
            }
        }
    }
}
$issues = ''
$duration = ''
$efficiency = if ($tokens -gt 0) { 'Measured' } else { 'Unmeasured' }

$row = [pscustomobject]@{
    Timestamp = (Get-Date).ToString('o')
    User_ID = Sanitize-CsvCell -Value $telemetryUser
    Session_ID = Sanitize-CsvCell -Value $sessionId
    Task_Scope = Sanitize-CsvCell -Value $taskScope
    Tokens_Estimated = $tokens
    Judgment_Result = Sanitize-CsvCell -Value $judgmentRes
    Review_Issues = $issues
    Duration_Min = $duration
    Efficiency_Score = Sanitize-CsvCell -Value $efficiency
}

$row | Export-Csv -Path $masterFile -Append -NoTypeInformation -Encoding UTF8
Write-Ok "Telemetry entry added for session $sessionId"

Write-Ok "Telemetry consolidation complete. Check $masterFile"
