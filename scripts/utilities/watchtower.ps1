<#
.SYNOPSIS
    Watchtower Agent — proactive session monitoring and auto-remediation.

.DESCRIPTION
    Runs health checks during active sessions: git state, token budget, context pressure,
    session age, pending proposals, and error patterns. Reports findings and optionally
    auto-remediates low-severity issues.

.PARAMETER AutoFix
    Auto-remediate low-severity issues (stash old changes, run compact-start, etc.)
.PARAMETER Quiet
    Only output issues (no OK status lines)
#>

param(
    [switch]$AutoFix,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Write-Ok    { if (-not $Quiet) { Write-Host "[OK] $args" -ForegroundColor Green } }
function Write-Warn  { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Crit  { Write-Host "[CRIT] $args" -ForegroundColor Red }
function Write-Info  { if (-not $Quiet) { Write-Host "[INFO] $args" -ForegroundColor Cyan } }
function Write-Step  { if (-not $Quiet) { Write-Host "`n=== $args ===" -ForegroundColor Magenta } }
function Write-Act   { Write-Host "[ACT] $args" -ForegroundColor Blue }

# --- Checks ---

function Check-Git {
    $issues = @()
    $status = & "git" "status" "--porcelain"
    $uncommitted = @($status).Count

    if ($uncommitted -gt 0) {
        $statusDetail = (& "git" "status" "--short" 2>$null) -join "; "
        $stashTs = Get-Date -Format "yyyyMMdd-HHmmss"
        $stashSuggestion = "git stash -u -m 'auto-watchtower-$stashTs'"
        $issues += @{
            check = "git"
            severity = if ($uncommitted -gt 20) { "critical" } elseif ($uncommitted -gt 5) { "warn" } else { "ok" }
            message = "$uncommitted uncommitted file(s)"
            detail = $statusDetail.Substring(0, [Math]::Min(200, $statusDetail.Length))
            autoFixAction = $stashSuggestion
            autoFixDesc = "Stash $uncommitted file(s) for later"
        }
    }

    $branch = & "git" "rev-parse" "--abbrev-ref" "HEAD" 2>$null
    $remote = $null
    $remoteCheck = & "git" "rev-parse" "--abbrev-ref" "@{upstream}" 2>$null
    if ($LASTEXITCODE -eq 0) { $remote = $remoteCheck }
    if ($remote) {
        $ahead = @(& "git" "rev-list" "--count" "$($remote)..HEAD" 2>$null)
        $aheadCount = if ($ahead -is [array]) { $ahead[0] } else { $ahead }
        if ($aheadCount -and [int]$aheadCount -gt 0) {
            $issues += @{
                check = "git"
                severity = "warn"
                message = "Branch '$branch' is $aheadCount commit(s) ahead of remote"
                detail = "Unpushed commits on $branch"
                autoFixAction = "git push origin $($branch)"
                autoFixDesc = "Push $aheadCount commit(s) to origin"
            }
        }
    }

    $lastCommit = & "git" "log" "-1" "--format=%ct" 2>$null
    if ($lastCommit) {
        $epoch = [long]$lastCommit
        $dt = (Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0).AddSeconds($epoch)
        $ageHours = [int]((Get-Date) - $dt).TotalHours
        if ($ageHours -gt 4 -and $uncommitted -gt 0) {
            $issues += @{
                check = "git"
                severity = "warn"
                message = "Last commit was $ageHours hour(s) ago with $uncommitted uncommitted file(s)"
                detail = "Long idle time with changes"
                $ts = Get-Date -Format "yyyyMMdd-HHmmss"
                autoFixAction = "git add -A && git commit -m 'auto: watchtower checkpoint $ts'"
                autoFixDesc = "Auto-commit pending changes"
            }
        }
    }

    return $issues
}

function Check-Tokens {
    $issues = @()
    $tokenFile = Join-Path (Join-Path $repoRoot ".session") "token-autopilot-state.json"
    if (-not (Test-Path $tokenFile)) { return $issues }

    try {
        $state = Get-Content $tokenFile -Raw | ConvertFrom-Json
        $used = [int]$state.consecutiveAboveSoftThreshold
        $pct = [int]$state.budgetUsagePercent
        if ($pct -gt 90) {
            $issues += @{
                check = "tokens"
                severity = "critical"
                message = "Token budget at ${pct}% (exceeds 90% hard threshold)"
                detail = "Consider switching to chat-compact or ending session"
                autoFixAction = ""
                autoFixDesc = ""
            }
        } elseif ($pct -gt 70) {
            $issues += @{
                check = "tokens"
                severity = "warn"
                message = "Token budget at ${pct}% (approaching 90% threshold)"
                detail = "Monitor usage, consider compacting context"
                autoFixAction = ""
                autoFixDesc = ""
            }
        } else {
            $issues += @{
                check = "tokens"
                severity = "ok"
                message = "Token budget healthy at ${pct}%"
                detail = ""
                autoFixAction = ""
                autoFixDesc = ""
            }
        }
    } catch { Write-Info "Token state unreadable: $_" }

    return $issues
}

function Check-Context {
    $issues = @()
    $markerFile = Join-Path (Join-Path $repoRoot ".session") ".compact-marker"
    if (Test-Path $markerFile) {
        $marker = Get-Content $markerFile -Raw
        $lastCompact = if ($marker -match '\d+') { [long]$Matches[0] } else { 0 }
        $epoch2 = [long]$lastCompact
        $dt2 = (Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0).AddSeconds($epoch2)
        $ageMin = [int]((Get-Date) - $dt2).TotalMinutes
        if ($ageMin -gt 60) {
            $issues += @{
                check = "context"
                severity = "warn"
                message = "Last compact-start was $ageMin min(s) ago (recommended < 60 min)"
                detail = "Context may be growing, run compact-start"
                autoFixAction = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot "scripts") "utilities") "WORKFLOW-ORCHESTRATION") "foundation.ps1"
                autoFixDesc = "Run compact-start automatically"
            }
        } else {
            $issues += @{
                check = "context"
                severity = "ok"
                message = "Compact marker fresh ($ageMin min ago)"
                detail = ""
                autoFixAction = ""
                autoFixDesc = ""
            }
        }
    } else {
        $issues += @{
            check = "context"
            severity = "ok"
            message = "No compact marker (fresh session or compact not needed)"
            detail = ""
            autoFixAction = ""
            autoFixDesc = ""
        }
    }
    return $issues
}

function Check-Session {
    $issues = @()
    $sessionDir = Join-Path $repoRoot ".session"
    if (-not (Test-Path $sessionDir)) { return $issues }

    $sessionFiles = @(Get-ChildItem -Path $sessionDir -Filter "session-*.json" -ErrorAction SilentlyContinue)
    $latestFile = $sessionFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latestFile) { return $issues }

    $ageHours = [int]((Get-Date) - $latestFile.LastWriteTime).TotalHours
    if ($ageHours -gt 2) {
        $issues += @{
            check = "session"
            severity = "warn"
            message = "Session '$($latestFile.BaseName)' active for $ageHours hour(s)"
            detail = "Long-running session, consider end-session + fresh start"
            autoFixAction = ""
            autoFixDesc = ""
        }
    } else {
        $issues += @{
            check = "session"
            severity = "ok"
            message = "Session age: $ageHours hour(s)"
            detail = ""
            autoFixAction = ""
            autoFixDesc = ""
        }
    }
    return $issues
}

function Check-Proposals {
    $issues = @()
    $propDir = Join-Path (Join-Path $repoRoot ".local") "improvement-proposals"
    if (-not (Test-Path $propDir)) { return $issues }

    $pending = @(Get-ChildItem -Path $propDir -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object {
        $p = Get-Content $_.FullName -Raw | ConvertFrom-Json
        if (-not $p.applied) { $_ }
    })
    if ($pending.Count -gt 0) {
        $issues += @{
            check = "proposals"
            severity = if ($pending.Count -gt 5) { "critical" } else { "warn" }
            message = "$($pending.Count) pending improvement proposal(s)"
            detail = "Run 'foundation learning apply' to execute"
            autoFixAction = Join-Path (Join-Path (Join-Path (Join-Path $repoRoot "scripts") "utilities") "WORKFLOW-ORCHESTRATION") "foundation.ps1"
            autoFixDesc = "Execute pending proposals"
        }
    } else {
        $issues += @{
            check = "proposals"
            severity = "ok"
            message = "No pending proposals"
            detail = ""
            autoFixAction = ""
            autoFixDesc = ""
        }
    }
    return $issues
}

function Check-Errors {
    $issues = @()
    $errorLog = Join-Path (Join-Path $repoRoot ".session") "session-errors.log"
    if (-not (Test-Path $errorLog)) { return $issues }

    $errors = @(Get-Content $errorLog -ErrorAction SilentlyContinue | Where-Object { $_ -match 'ERROR|FATAL|CRITICAL' })
    $uniqueErrors = $errors | Group-Object | Where-Object { $_.Count -gt 2 }
    if ($uniqueErrors.Count -gt 0) {
        $issues += @{
            check = "errors"
            severity = if ($uniqueErrors.Count -gt 3) { "critical" } else { "warn" }
            message = "$($uniqueErrors.Count) recurring error pattern(s) detected"
            detail = ($uniqueErrors | ForEach-Object { "$($_.Name) ($($_.Count)x)" }) -join "; "
            autoFixAction = ""
            autoFixDesc = ""
        }
    }
    return $issues
}

# --- Aggregator ---

function Invoke-Watchtower {
    $allIssues = @()
    $allIssues += Check-Git
    $allIssues += Check-Tokens
    $allIssues += Check-Context
    $allIssues += Check-Session
    $allIssues += Check-Proposals
    $allIssues += Check-Errors

    $criticalCount = @($allIssues | Where-Object { $_.severity -eq 'critical' }).Count
    $warnCount = @($allIssues | Where-Object { $_.severity -eq 'warn' }).Count

    return @{
        issues = $allIssues
        summary = @{
            total = $allIssues.Count
            critical = $criticalCount
            warn = $warnCount
            ok = @($allIssues | Where-Object { $_.severity -eq 'ok' }).Count
        }
    }
}

function Invoke-AutoFix {
    param($Issues)
    $fixed = 0
    foreach ($issue in $Issues) {
        if ($issue.severity -eq 'ok') { continue }
        if (-not $issue.autoFixAction) { continue }

        Write-Act "$($issue.check): $($issue.autoFixDesc)"
        if ($issue.check -eq 'git' -and $issue.autoFixAction -match '^git ') {
            $cmd = $issue.autoFixAction
            if ($cmd -match '^git stash') {
                & "git" "stash" "-u" "-m" "auto-watchtower-$(Get-Date -Format yyyyMMdd-HHmmss)" 2>$null
                if ($LASTEXITCODE -eq 0) { $fixed++; Write-Ok "Stashed changes" }
                else { Write-Warn "Stash failed" }
            } elseif ($cmd -match '^git add') {
                & "git" "add" "-A" 2>$null
                & "git" "commit" "-m" "auto: watchtower checkpoint $(Get-Date -Format yyyyMMdd-HHmmss)" 2>$null
                if ($LASTEXITCODE -eq 0) { $fixed++; Write-Ok "Auto-committed changes" }
                else { Write-Warn "Auto-commit failed" }
            } elseif ($cmd -match '^git push') {
                & "git" "push" "origin" (git rev-parse --abbrev-ref HEAD) 2>$null
                if ($LASTEXITCODE -eq 0) { $fixed++; Write-Ok "Pushed commits" }
                else { Write-Warn "Push failed" }
            }
        } elseif ($issue.check -eq 'context' -and $issue.autoFixAction) {
            $foundation = $issue.autoFixAction
            & $foundation 2>$null
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) { $fixed++; Write-Ok "Compact-start completed" }
            else { Write-Warn "Compact-start failed" }
        } elseif ($issue.check -eq 'proposals' -and $issue.autoFixAction) {
            $execPath = $issue.autoFixAction
            & $execPath 2>$null
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) { $fixed++; Write-Ok "Proposals executed" }
            else { Write-Warn "Proposal execution had issues" }
        }
    }
    return $fixed
}

# --- Main ---

Write-Step "Watchtower Agent"

$result = Invoke-Watchtower
$summary = $result.summary

foreach ($issue in $result.issues) {
    $icon = switch ($issue.severity) {
        "critical" { "CRIT" }
        "warn"     { "WARN" }
        default    { "OK" }
    }
    $color = switch ($issue.severity) {
        "critical" { "Red" }
        "warn"     { "Yellow" }
        default    { "Green" }
    }
    Write-Host "  [$icon] $($issue.check): $($issue.message)" -ForegroundColor $color
    if ($issue.detail -and -not $Quiet) {
        Write-Host "         $($issue.detail)" -ForegroundColor Gray
    }
}

Write-Step "Watchtower Summary"
Write-Host "  OK: $($summary.ok) | WARN: $($summary.warn) | CRIT: $($summary.critical) | Total: $($summary.total)" -ForegroundColor Cyan

if ($AutoFix) {
    Write-Step "Auto-Remediation"
    $fixed = Invoke-AutoFix -Issues $result.issues
    Write-Ok "Auto-fixed $fixed issue(s)"
}

$exitCode = if ($summary.critical -gt 0) { 1 } elseif ($summary.warn -gt 0) { 0 } else { 0 }
exit $exitCode
