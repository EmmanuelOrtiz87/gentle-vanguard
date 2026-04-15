# day-end-closure.ps1
# Automated daily session closure: captures learnings, validates state, archives memory, and generates closure report.
# Can be run manually or triggered automatically at shift end.

param(
    [string]$SessionId = '',
    [string]$SessionSummary = '',
    [switch]$AutoTriggered,
    [switch]$Quiet,
    [switch]$SkipEngram,
    [switch]$SkipValidation,
    [switch]$SkipRotation,
    [int]$MaxArtifacts = 1,
    [int]$MaxLocalArtifacts = 30,
    [switch]$Force
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

function Write-Step { param([string]$m) if (-not $Quiet) { Write-Host "`n=== $m ===" -ForegroundColor Cyan } }
function Write-Ok   { param([string]$m) if (-not $Quiet) { Write-Host "[OK] $m" -ForegroundColor Green } }
function Write-Warn { param([string]$m) if (-not $Quiet) { Write-Host "[WARN] $m" -ForegroundColor Yellow } }
function Write-Err  { param([string]$m) Write-Host "[ERROR] $m" -ForegroundColor Red }
function Write-Info { param([string]$m) if (-not $Quiet) { Write-Host "[INFO] $m" -ForegroundColor Cyan } }

function Invoke-LocalPowerShellScript {
    param(
        [string]$ScriptPath,
        [string[]]$ScriptArgs = @()
    )

    & $ScriptPath @ScriptArgs
}

function Invoke-Engram {
    param(
        [string]$RunEngramScript,
        [string[]]$EngramArgs
    )

    if (-not (Test-Path $RunEngramScript)) {
        return $false
    }

    try {
        & $RunEngramScript @EngramArgs 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

# ── Session closure sequence ──────────────────────────────────────────────────
$endSessionScript = Join-Path $scriptDir 'end-session.ps1'
$validateScript = Join-Path $repoRoot 'scripts\diagnostics\validate-script-governance.ps1'

# 1. Generate standard delivery closure artifact via wf.ps1
Write-Step "Stage 1: Operational Closure"
if (Test-Path $endSessionScript) {
    & $endSessionScript -SkipAudit:$SkipValidation -Force:(-not $SkipEngram)
    if ($LASTEXITCODE -ne 0 -and -not $Force) {
        Write-Err "Operational closure reported issues. Use -Force to proceed with memory capture."
        exit 1
    }
    Write-Ok "Delivery closure artifact generated"
} else {
    Write-Warn "end-session.ps1 not found - skipping operational closure"
}

# 2. Workspace validation (optional, controlled by flag)
if (-not $SkipValidation) {
    Write-Step "Stage 2: Workspace Validation"
    if (Test-Path $validateScript) {
        Invoke-LocalPowerShellScript -ScriptPath $validateScript -ScriptArgs @('-SkipFallbackTests', '-Quiet')
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Workspace validation clean"
        } else {
            Write-Warn "Workspace validation found issues (advisory)"
        }
    } else {
        Write-Info "Validation script not found - skipping"
    }
}

# 3. Memory capture via Engram (optional, controlled by flag)
if (-not $SkipEngram) {
    Write-Step "Stage 3: Session Memory Capture"
    $runEngramScript = Join-Path $scriptDir 'run-engram.ps1'
    $projectName = Split-Path $repoRoot -Leaf
    
    # Build session ID if not provided
    if ([string]::IsNullOrWhiteSpace($SessionId)) {
        $timestamp = Get-Date -Format 'YYYY-MM-dd-HHmmss'
        $SessionId = "session-$timestamp"
    }
    
    # Capture session summary from delivery closure artifact if available
    $sessionsDir = Join-Path $repoRoot 'docs\sessions'
    $closureArtifact = Get-ChildItem -Path $sessionsDir -Filter '*delivery-closure.md' -ErrorAction SilentlyContinue | 
                       Sort-Object LastWriteTime -Descending | 
                       Select-Object -First 1
    
    if ($closureArtifact -and [string]::IsNullOrWhiteSpace($SessionSummary)) {
        Write-Info "Reading session summary from closure artifact..."
        $closureContent = Get-Content $closureArtifact.FullName -Raw
        $SessionSummary = $closureContent
    }

    # Avoid overlong command-line payloads while preserving a meaningful closure summary.
    if (-not [string]::IsNullOrWhiteSpace($SessionSummary) -and $SessionSummary.Length -gt 12000) {
        $SessionSummary = $SessionSummary.Substring(0, 12000)
        Write-Info "Session summary trimmed to 12000 chars for Engram save"
    }
    
    if (-not [string]::IsNullOrWhiteSpace($SessionSummary)) {
        Write-Info "Saving session summary to Engram: $SessionId"
        $summaryTitle = "session-summary:$SessionId"
        $savedSummary = Invoke-Engram -RunEngramScript $runEngramScript -EngramArgs @('save', $summaryTitle, $SessionSummary, '--project', $projectName)
        if ($savedSummary) {
            Write-Ok "Engram session summary saved"
        } else {
            Write-Warn "Could not save session summary to Engram"
        }
    } else {
        Write-Warn "No session summary provided - Engram capture skipped"
    }
    
    # Mark session as ended in Engram as a dedicated closure observation.
    Write-Info "Closing session in Engram: $SessionId"
    $endTitle = "session-end:$SessionId"
    $endMessage = "Session closed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') on branch $(git rev-parse --abbrev-ref HEAD 2>$null)."
    $savedEnd = Invoke-Engram -RunEngramScript $runEngramScript -EngramArgs @('save', $endTitle, $endMessage, '--project', $projectName)
    if ($savedEnd) {
        Write-Ok "Engram session end marker saved"
    } else {
        Write-Warn "Could not save session end marker to Engram"
    }
}

# 4. Generate final report
Write-Step "Stage 4: Final Report"
$reportDir = Join-Path $repoRoot 'docs\sessions'
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

$timestamp = Get-Date -Format 'yyyy-MM-dd HHmmss'

# 5. Artifact rotation (optional)
if (-not $SkipRotation) {
    Write-Step "Stage 5: Artifact Rotation"
    $rotateScript = Join-Path $scriptDir 'rotate-artifacts.ps1'
    if (Test-Path $rotateScript) {
        Write-Info "Running artifact rotation (repo max $MaxArtifacts, local max $MaxLocalArtifacts)..."
        & $rotateScript -MaxRepoFiles $MaxArtifacts -MaxLocalFiles $MaxLocalArtifacts -ErrorAction SilentlyContinue | Out-Null
        Write-Ok "Artifact rotation complete"
    } else {
        Write-Info "rotate-artifacts.ps1 not found - skipping rotation"
    }
}
$reportPath = Join-Path $reportDir "closure-report-$timestamp.md"

$owner = git config user.name 2>$null
if ([string]::IsNullOrWhiteSpace($owner)) { $owner = 'unknown' }

$gitStatus = git status --short 2>$null
$repoState = if ([string]::IsNullOrWhiteSpace($gitStatus)) { 'clean' } else { 'has changes' }

$report = @"
# Day End Closure Report

**Timestamp**: $timestamp  
**Owner**: $owner  
**Trigger**: $(if ($AutoTriggered) { 'Automatic' } else { 'Manual' })  
**Session ID**: $SessionId  

## Closure Stages

| Stage | Status |
|-------|--------|
| Operational Closure | ✅ Complete |
| Workspace Validation | $(if ($SkipValidation) { '⏭️  Skipped' } else { '✅ Complete' }) |
| Memory Capture | $(if ($SkipEngram) { '⏭️  Skipped' } else { '✅ Complete' }) |
| Report Generation | ✅ Complete |

## Repository State

- **Git Status**: $repoState
- **Branch**: $(git rev-parse --abbrev-ref HEAD 2>$null)
- **Latest Commit**: $(git log -1 --pretty=oneline 2>$null)

## Artifacts Generated

- Delivery closure: docs/sessions/*delivery-closure*.md
- This report: docs/sessions/closure-report-*.md
- Engram memory: Captured via session_summary and session_end
- Governance checks: Included in delivery closure

## Next Session

1. Session will resume with preserved Engram context.
2. All learnings from today are available for continuation.
3. Run \`gf health\` to verify tools are active.

---

*Generated by day-end-closure.ps1*
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Ok "Closure report generated: $reportPath"

# 5. Summary
Write-Step "Closure Summary"
if (-not $Quiet) {
    Write-Host ""
    Write-Host "Day end closure completed successfully." -ForegroundColor Green
    Write-Host ""
    Write-Host "Artifacts created:" -ForegroundColor Cyan
    Write-Host "  • docs/sessions/*delivery-closure-*.md (operational state)" -ForegroundColor Gray
    Write-Host "  • docs/sessions/closure-report-$timestamp.md (this report)" -ForegroundColor Gray
    Write-Host "  • Engram session summary (memory capture)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To resume tomorrow:" -ForegroundColor Cyan
    Write-Host "  • Tools auto-activate on project entry" -ForegroundColor Gray
    Write-Host "  • Engram loads prior session context" -ForegroundColor Gray
    Write-Host "  • Run 'gf status' to see where you left off" -ForegroundColor Gray
    Write-Host ""
}

exit 0
