param(
    [int]$WindowHours = 24,
    [switch]$Strict,
    [switch]$EmitGitHubAnnotations
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$metricsPath = Join-Path $repoRoot 'docs/sessions/metrics/context-usage.csv'
$sessionsDir = Join-Path $repoRoot 'docs/sessions'
$windowStart = (Get-Date).AddHours(-1 * $WindowHours)

function Emit-Notice {
    param(
        [string]$Level,
        [string]$Message,
        [switch]$Annotate
    )

    if ($Level -eq 'ERROR') {
        Write-Host "[ALERT] $Message" -ForegroundColor Red
    } elseif ($Level -eq 'WARN') {
        Write-Host "[WARN] $Message" -ForegroundColor Yellow
    } else {
        Write-Host "[OK] $Message" -ForegroundColor Green
    }

    if ($Annotate) {
        if ($Level -eq 'ERROR') {
            Write-Host "::error::$Message"
        } elseif ($Level -eq 'WARN') {
            Write-Host "::warning::$Message"
        } else {
            Write-Host "::notice::$Message"
        }
    }
}

function Emit-Remediation {
    param([switch]$Annotate)

    $steps = @(
        "Run: .\\scripts\\utilities\\wf.ps1 health",
        "Run: .\\scripts\\utilities\\wf.ps1 start-session",
        'Run: .\scripts\utilities\wf.ps1 compact-start "current objective"',
        "Optional fix: .\\scripts\\utilities\\wf.ps1 homologate apply"
    )

    foreach ($step in $steps) {
        Write-Host "[SUGGESTION] $step" -ForegroundColor Cyan
        if ($Annotate) {
            Write-Host "::notice::$step"
        }
    }
}

function Get-LatestCommitDate {
    $latestCommitIso = git -C $repoRoot log -1 --format=%cI 2>$null
    if (-not $latestCommitIso) {
        return $null
    }

    try {
        return [datetimeoffset]::Parse($latestCommitIso).LocalDateTime
    } catch {
        return $null
    }
}

$alerts = 0
$warnings = 0

$latestCommitDate = Get-LatestCommitDate
$recentCommit = $false
if ($latestCommitDate -and $latestCommitDate -ge $windowStart) {
    $recentCommit = $true
}

$rows = @()
if (Test-Path $metricsPath) {
    try {
        $rows = Import-Csv -Path $metricsPath | Where-Object {
            try { [datetime]::Parse($_.timestamp) -ge $windowStart } catch { $false }
        }
    } catch {
        Emit-Notice -Level 'WARN' -Message "Could not parse metrics file: $metricsPath" -Annotate:$EmitGitHubAnnotations
        $warnings++
    }
}

$eventCount = @($rows).Count
$compactCount = @($rows | Where-Object event -eq 'compact-start').Count
$packCount = @($rows | Where-Object event -eq 'context-pack').Count

$recentSessionArtifacts = @()
if (Test-Path $sessionsDir) {
    $recentSessionArtifacts = Get-ChildItem -Path $sessionsDir -Filter '*-session-start.md' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -ge $windowStart }
}
$sessionArtifactCount = @($recentSessionArtifacts).Count

Write-Host "=== Agent Process Compliance Snapshot ===" -ForegroundColor Cyan
Write-Host ("Window (hours): {0}" -f $WindowHours)
Write-Host ("Recent commit in window: {0}" -f $recentCommit)
Write-Host ("context-usage events: {0} (compact-start: {1}, context-pack: {2})" -f $eventCount, $compactCount, $packCount)
Write-Host ("session-start artifacts in window: {0}" -f $sessionArtifactCount)

if ($recentCommit -and $eventCount -eq 0) {
    Emit-Notice -Level 'WARN' -Message 'Recent repository activity detected without context-usage telemetry. Possible off-process AI operation.' -Annotate:$EmitGitHubAnnotations
    Emit-Remediation -Annotate:$EmitGitHubAnnotations
    $warnings++
}

if ($recentCommit -and $compactCount -eq 0) {
    Emit-Notice -Level 'WARN' -Message 'Recent repository activity detected without compact-start usage. Handoff process may be bypassed.' -Annotate:$EmitGitHubAnnotations
    Emit-Remediation -Annotate:$EmitGitHubAnnotations
    $warnings++
}

if ($recentCommit -and $sessionArtifactCount -eq 0) {
    Emit-Notice -Level 'WARN' -Message 'Recent repository activity detected without a session-start artifact in the configured window.' -Annotate:$EmitGitHubAnnotations
    Emit-Remediation -Annotate:$EmitGitHubAnnotations
    $warnings++
}

if (-not $recentCommit) {
    Emit-Notice -Level 'OK' -Message 'No recent commits in window; no independent-operation risk detected.' -Annotate:$EmitGitHubAnnotations
} elseif ($warnings -eq 0) {
    Emit-Notice -Level 'OK' -Message 'Process compliance signals look healthy for the selected window.' -Annotate:$EmitGitHubAnnotations
}

if ($Strict -and $warnings -gt 0) {
    $alerts = $warnings
}

if ($alerts -gt 0) {
    exit 3
}

exit 0
