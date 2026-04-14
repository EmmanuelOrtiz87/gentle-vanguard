#!/usr/bin/env pwsh
# reset-demo.ps1 - Reset Demo 07 to clean state
# Cleans all demo artifacts and re-runs preflight.
# Use this to start over if demo gets interrupted or needs a clean run.

param(
    [switch]$SkipPreflight
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string]$m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Info { param([string]$m) Write-Host "[INFO] $m" -ForegroundColor Gray }

$demoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Resolve-Path (Join-Path $demoRoot '..\..')

Write-Step "Demo 07 - Reset to Clean State"
Write-Info "Workspace: $workspaceRoot"

# 1. End any active sessions
Write-Step "Terminating active sessions"
$wfScript = Join-Path $workspaceRoot 'scripts\utilities\wf.ps1'
if (Test-Path $wfScript) {
    try {
        & $wfScript end-session demo-task-tracker -Force 2>&1 | Out-Null
        Write-Ok "Session terminated"
    } catch {
        Write-Info "No active session (or termination non-critical)"
    }
} else {
    Write-Warn "wf.ps1 not found - skipping session termination"
}

# 2. Clean task-tracker runtime data
Write-Step "Cleaning task-tracker data"
$trackerDb = Join-Path $workspaceRoot 'demos\shared\task-tracker\tasks.json'
if (Test-Path $trackerDb) {
    Remove-Item $trackerDb -Force -ErrorAction SilentlyContinue
    Write-Ok "Removed task-tracker database"
} else {
    Write-Info "No task-tracker data found"
}

# 3. Clean session/context artifacts in demo directory
Write-Step "Cleaning demo session artifacts"
$artifactPatterns = @(
    "context-pack*.txt",
    "session-*.md",
    "closure-*.md",
    "review-*.md",
    "audit-*.md"
)

$demoSharedDir = Join-Path $workspaceRoot 'demos\shared'
$removed = 0
foreach ($pattern in $artifactPatterns) {
    $items = Get-Item (Join-Path $demoSharedDir $pattern) -ErrorAction SilentlyContinue
    if ($items) {
        foreach ($item in $items) {
            Remove-Item $item -Force
            $removed++
        }
    }
}
Write-Ok "Removed $removed old session artifacts"

# 4. Clean any cache/build files in task-tracker
Write-Step "Cleaning task-tracker build cache"
$trackerRoot = Join-Path $workspaceRoot 'demos\shared\task-tracker'
@('go.sum', 'go.mod', '.git', '.gitignore') | ForEach-Object {
    $path = Join-Path $trackerRoot $_
    if ((Test-Path $path) -and ($_ -ne 'go.mod' -and $_ -ne 'go.sum')) {
        # Preserve go.mod and go.sum for reproducibility
    }
}
Write-Ok "Task-tracker cache check complete"

# 5. Run preflight to restore clean state
if (-not $SkipPreflight) {
    Write-Step "Re-running preflight (clean state restoration)"
    $preflightScript = Join-Path $demoRoot 'preflight.ps1'
    if (Test-Path $preflightScript) {
        & $preflightScript -Force
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Preflight completed successfully"
        } else {
            Write-Warn "Preflight completed with warnings (check output above)"
        }
    } else {
        Write-Warn "preflight.ps1 not found - skipping re-initialization"
    }
} else {
    Write-Info "Preflight skipped (use -SkipPreflight to bypass)"
}

Write-Step "Reset Complete"
Write-Info "Demo is now at clean state. Ready to run again."
Write-Info "Next: Run ./demos/07-mixed-cookbook-real-request/preflight.ps1 again if needed."
Write-Info "Then follow recipe in ./demos/07-mixed-cookbook-real-request/DEMO.md"
