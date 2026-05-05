# sdd-process-metrics.ps1
# FF-002: SDD Process KPIs — spec coverage, lead time proxy, rework ratio.
#
# Sources:
#   - docs/backlog/items.json  (authoritative backlog)
#   - docs/sdd/*.md            (spec documents with status field)
#
# Outputs:
#   Human-readable table by default; -AsJson for machine-readable output.
#
# Usage:
#   pwsh -File scripts/utilities/TELEMETRY-METRICS/sdd-process-metrics.ps1
#   wf sdd-metrics [-JSON]

param(
    [switch]$AsJson,
    [switch]$Quiet
)

$ErrorActionPreference = 'Continue'
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot   = (Resolve-Path (Join-Path $scriptDir '..\..\..\..')).Path
$backlogPath = Join-Path $repoRoot 'docs\backlog\items.json'
$sddDir      = Join-Path $repoRoot 'docs\sdd'

# ─── Load backlog ────────────────────────────────────────────────────────────
$items = @()
if (Test-Path $backlogPath) {
    try { $items = Get-Content $backlogPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
}

$totalItems   = $items.Count
$doneItems    = @($items | Where-Object { $_.status -eq 'done' }).Count
$pendingItems = @($items | Where-Object { $_.status -in @('pending', 'scheduled') }).Count
$inProgress   = @($items | Where-Object { $_.status -eq 'in-progress' }).Count
$discarded    = @($items | Where-Object { $_.status -eq 'discarded' }).Count

# Spec coverage = (done / total_actionable) * 100
$actionable = $totalItems - $discarded
$specCoverage = if ($actionable -gt 0) { [math]::Round(($doneItems / $actionable) * 100, 1) } else { 0 }

# ─── Lead time proxy ─────────────────────────────────────────────────────────
# Lead time = days from created_at to last linked_session date for done items.
$leadTimes = @()
foreach ($item in ($items | Where-Object { $_.status -eq 'done' -and $_.created_at })) {
    $sessions = @($item.linked_sessions | Where-Object { $_ })
    if ($sessions.Count -eq 0) { continue }
    try {
        $created   = [datetime]::Parse($item.created_at)
        $lastSession = ($sessions | Sort-Object | Select-Object -Last 1)
        $resolved  = [datetime]::Parse($lastSession)
        $days = ($resolved - $created).TotalDays
        if ($days -ge 0) { $leadTimes += $days }
    } catch {}
}
$avgLeadTimeDays = if ($leadTimes.Count -gt 0) {
    [math]::Round(($leadTimes | Measure-Object -Average).Average, 1)
} else { 0 }

# ─── Rework ratio ─────────────────────────────────────────────────────────────
# Items with more than 1 linked_session indicate rework (reopened/revisited).
$reworkItems = @($items | Where-Object {
    $sessions = @($_.linked_sessions | Where-Object { $_ })
    $sessions.Count -gt 1
}).Count
$reworkRatio = if ($doneItems -gt 0) {
    [math]::Round(($reworkItems / $doneItems) * 100, 1)
} else { 0 }

# ─── SDD document status ─────────────────────────────────────────────────────
$sddDocs = @()
if (Test-Path $sddDir) {
    foreach ($f in (Get-ChildItem -Path $sddDir -Filter '*.md' -File -EA SilentlyContinue)) {
        $content = Get-Content $f.FullName -Raw -Encoding UTF8 -EA SilentlyContinue
        $status = 'unknown'
        if ($content -match '(?im)^\*\*Status\*\*:\s*(.+)$') { $status = $matches[1].Trim().ToLower() }
        elseif ($content -match '(?im)^status:\s*(.+)$') { $status = $matches[1].Trim().ToLower() }
        $sddDocs += [pscustomobject]@{ name = $f.Name; status = $status }
    }
}
$sddValidated = @($sddDocs | Where-Object { $_.status -in @('validated', 'done', 'active') }).Count
$sddDraft     = @($sddDocs | Where-Object { $_.status -notin @('validated', 'done', 'active') }).Count

# ─── Health signals ───────────────────────────────────────────────────────────
$coverageHealth = if ($specCoverage -ge 70) { 'GREEN' } elseif ($specCoverage -ge 40) { 'YELLOW' } else { 'RED' }
$reworkHealth   = if ($reworkRatio -le 20) { 'GREEN' } elseif ($reworkRatio -le 50) { 'YELLOW' } else { 'RED' }
$sddHealth      = if ($sddValidated -ge 1) { 'GREEN' } elseif ($sddDocs.Count -gt 0) { 'YELLOW' } else { 'RED' }

# ─── Result object ───────────────────────────────────────────────────────────
$result = [ordered]@{
    as_of              = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')
    backlog_total      = $totalItems
    backlog_done       = $doneItems
    backlog_pending    = $pendingItems
    backlog_in_progress= $inProgress
    backlog_discarded  = $discarded
    spec_coverage_pct  = $specCoverage
    spec_coverage_health = $coverageHealth
    avg_lead_time_days = $avgLeadTimeDays
    rework_items       = $reworkItems
    rework_ratio_pct   = $reworkRatio
    rework_health      = $reworkHealth
    sdd_docs_total     = $sddDocs.Count
    sdd_validated      = $sddValidated
    sdd_draft          = $sddDraft
    sdd_health         = $sddHealth
}

# ─── Output ──────────────────────────────────────────────────────────────────
if ($AsJson) {
    $result | ConvertTo-Json -Depth 4
    exit 0
}

if (-not $Quiet) {
    $coverageColor = switch ($coverageHealth) { 'GREEN' { 'Green' } 'YELLOW' { 'Yellow' } default { 'Red' } }
    $reworkColor   = switch ($reworkHealth)   { 'GREEN' { 'Green' } 'YELLOW' { 'Yellow' } default { 'Red' } }
    $sddColor      = switch ($sddHealth)      { 'GREEN' { 'Green' } 'YELLOW' { 'Yellow' } default { 'Red' } }

    Write-Host ''
    Write-Host '=== SDD Process Metrics ===' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Backlog'
    Write-Host "    Total: $totalItems  |  Done: $doneItems  |  Pending: $pendingItems  |  In-progress: $inProgress  |  Discarded: $discarded"
    Write-Host ''
    Write-Host "  Spec Coverage: $specCoverage%" -ForegroundColor $coverageColor -NoNewline
    Write-Host " [$coverageHealth]" -ForegroundColor $coverageColor
    Write-Host "  Avg Lead Time (done items): ${avgLeadTimeDays}d"
    Write-Host "  Rework Ratio: $reworkRatio% ($reworkItems items revisited)" -ForegroundColor $reworkColor -NoNewline
    Write-Host " [$reworkHealth]" -ForegroundColor $reworkColor
    Write-Host ''
    Write-Host '  SDD Documents'
    Write-Host "    Total: $($sddDocs.Count)  |  Validated/Done: $sddValidated  |  Draft/Unknown: $sddDraft" -ForegroundColor $sddColor
    if ($sddDocs.Count -gt 0) {
        foreach ($d in $sddDocs) {
            $dc = if ($d.status -in @('validated','done','active')) { 'Green' } elseif ($d.status -eq 'unknown') { 'Gray' } else { 'Yellow' }
            Write-Host "    - $($d.name) [$($d.status)]" -ForegroundColor $dc
        }
    }
    Write-Host ''
}
exit 0
