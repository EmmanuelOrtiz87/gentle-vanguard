#!/usr/bin/env pwsh
# preflight.ps1 - Demo 07 preflight setup
# Ensures the workspace is ready to run the demo on a fresh machine.

param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string]$m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Info { param([string]$m) Write-Host "[INFO] $m" -ForegroundColor Gray }

$demoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Resolve-Path (Join-Path $demoRoot '..\..')

Write-Step "Demo 07 - Mixed Cookbook Preflight"
Write-Info "Workspace: $workspaceRoot"

# 1. Verify Go and Git
Write-Step "Checking prerequisites"
$hasGo = Get-Command go -ErrorAction SilentlyContinue
$hasGit = Get-Command git -ErrorAction SilentlyContinue

if (-not $hasGo) {
    Write-Warn "Go not found. Install from https://go.dev/"
    exit 1
}
Write-Ok "Go available"

if (-not $hasGit) {
    Write-Warn "Git not found. Install from https://git-scm.com/"
    exit 1
}
Write-Ok "Git available"

# 2. Activate orchestrator if not already active
Write-Step "Checking orchestrator status"
$markerFile = Join-Path $workspaceRoot '.orchestrator-active'
if (Test-Path $markerFile) {
    Write-Ok "Orchestrator already active"
} else {
    Write-Info "Activating orchestrator..."
    $stackScript = Join-Path $workspaceRoot 'scripts\utilities\stack-on-demand.ps1'
    if (Test-Path $stackScript) {
        & $stackScript -Action activate -ProjectPath $workspaceRoot -AllowPassive:$Force | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "Orchestrator activated"
        } else {
            Write-Warn "Orchestrator activation completed with warnings (non-critical for demo)"
        }
    } else {
        Write-Warn "stack-on-demand.ps1 not found - skipping auto-activation"
    }
}

# 3. Verify and auto-update Engram (optional for demo base, required for Segment 4)
Write-Step "Checking and updating tools"
$updateScript = Join-Path $workspaceRoot 'scripts\utilities\update-tools.ps1'
if (Test-Path $updateScript) {
    Write-Info "Updating tools to latest versions..."
    & $updateScript -Quiet | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Tools updated successfully"
    } else {
        Write-Warn "Tool update completed with issues (non-critical for demo)"
    }
} else {
    Write-Warn "update-tools.ps1 not found - skipping auto-update"
}

$engramCmd = Get-Command engram -ErrorAction SilentlyContinue
if ($engramCmd) {
    Write-Ok "Engram available: $(& $engramCmd version | Select-Object -First 1)"
} else {
    Write-Warn "Engram not found. If you plan to show Segment 4, run: ./scripts/utilities/gv.ps1 install-engram"
    Write-Info "Demo is runnable without Engram - just skip Segment 4"
}

# 4. Clean task-tracker runtime data if present
Write-Step "Preparing task-tracker demo"
$trackerDb = Join-Path $workspaceRoot 'demos\shared\task-tracker\tasks.json'
if (Test-Path $trackerDb) {
    Remove-Item $trackerDb -Force
    Write-Ok "Cleaned previous task-tracker run"
} else {
    Write-Info "No prior task-tracker data found (fresh start)"
}

# 5. Verify Go can run task-tracker
Write-Step "Verifying task-tracker CLI"
$trackerRoot = Join-Path $workspaceRoot 'demos\shared\task-tracker'
Push-Location $trackerRoot
try {
    $result = & go run . stats 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "task-tracker CLI works: $result"
    } else {
        Write-Warn "task-tracker CLI had issues (may self-correct on first real run)"
    }
} catch {
    Write-Warn "Could not verify task-tracker: $_"
} finally {
    Pop-Location
}

Write-Step "Preflight Complete"
Write-Info "Ready to run the demo. Next steps:"
Write-Info "  1. Run ./scripts/utilities/orchestrator-next-steps.ps1"
Write-Info "  2. Run ./scripts/utilities/orchestrator-status.ps1"
Write-Info "  3. Follow recipe in ./demos/07-mixed-cookbook-real-request/DEMO.md"

