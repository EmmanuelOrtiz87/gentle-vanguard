# session-autostart.ps1
# Versión PowerShell pura - Session Autostart with Engram Optimization

param(
    [string]$ProjectName = "workspace_local",
    [string]$WorkspaceRoot = "C:\Workspace_local\workspace-foundation"
)

$ErrorActionPreference = "Continue"

function Write-Step {
    param([int]$Step, [string]$Message)
    Write-Host "[$Step/9] $Message" -ForegroundColor Cyan
}

function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

Write-Host "=== Session Autostart with Engram Optimization ===" -ForegroundColor Cyan
Write-Host ""

# 1. Session Manager
Write-Step 1 "Running session-manager..."
$sessionManager = Join-Path $PSScriptRoot "session-manager.ps1"
if (-not (Test-Path $sessionManager)) {
    Write-Error "session-manager.ps1 not found: $sessionManager"
    $wfScript = ".\scripts\utilities\wf.ps1"
    if (Test-Path $wfScript) {
        & $wfScript start-session
    } else {
        Write-Error "No fallback method found"
        exit 1
    }
} else {
    & $sessionManager -Mode AutoStart
    if ($LASTEXITCODE -ne 0) {
        Write-Error "session-manager.ps1 failed with code: $LASTEXITCODE"
        exit 1
    }
    Write-Success "Session initialized"
}

# 2. Time-based notifications
Write-Step 2 "Checking time-based notifications..."
$notificationScript = Join-Path $PSScriptRoot "session-notification.ps1"
if (Test-Path $notificationScript) {
    & $notificationScript -TimeZone "Argentina Standard Time" -PeakStart 9 -PeakEnd 15 -Region "Argentina"
} else {
    Write-Host "[SKIP] Notification script not found" -ForegroundColor Gray
}

# 3. Get Session ID
Write-Step 3 "Getting Session ID..."
$sessionFiles = Get-ChildItem ".\.session\session-*.json" -File -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending
if ($sessionFiles.Count -gt 0) {
    $SESSION_ID = $sessionFiles[0].BaseName
    Write-Host "Session ID: $SESSION_ID" -ForegroundColor Green
} else {
    Write-Warning "Could not get Session ID"
    $SESSION_ID = $null
}

# 4. Engram Policy Enforcement
Write-Step 4 "Enforcing Engram policy (always installed and active)..."
$engramPolicy = Join-Path $PSScriptRoot "..\foundation\engram-policy.ps1"
if (Test-Path $engramPolicy) {
    & $engramPolicy -Action enforce
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Engram policy enforcement found issues, running orchestrator..."
        $orchScript = Join-Path $PSScriptRoot "engram-orchestrator.ps1"
        if (Test-Path $orchScript) {
            & $orchScript -Action orchestrate
        }
    } else {
        Write-Success "Engram policy enforced - engram active"
    }
} else {
    Write-Host "[SKIP] Engram policy script not found" -ForegroundColor Gray
}

# 5. Engram Optimization
Write-Step 5 "Running Engram optimization..."
$optimizeScript = Join-Path $PSScriptRoot "optimize-engram-usage.ps1"
if (Test-Path $optimizeScript) {
    & $optimizeScript -ProjectName $ProjectName
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Engram optimization completed with warnings"
    } else {
        Write-Success "Engram optimization completed"
    }
} else {
    Write-Host "[SKIP] Engram optimization script not found" -ForegroundColor Gray
}

# 6. Cross-workspace validation
Write-Step 6 "Validating cross-workspace consistency..."
$crossValidator = ".\scripts\monitoring\cross-workspace-validator.ps1"
if (Test-Path $crossValidator) {
    & $crossValidator -Detailed
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Cross-workspace validation found issues"
    } else {
        Write-Success "Cross-workspace validated"
    }
} else {
    Write-Host "[SKIP] Cross-workspace validator not found" -ForegroundColor Gray
}

# 7. Security Orchestrator
Write-Step 7 "Initializing Security Orchestrator..."
$securityScript = ".\scripts\security\security-orchestrator.ps1"
if (Test-Path $securityScript) {
    & $securityScript -Action init -AsJson
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Security Orchestrator initialized with warnings"
    } else {
        Write-Success "Security Orchestrator initialized"
    }
} else {
    Write-Host "[SKIP] Security Orchestrator not found" -ForegroundColor Gray
}

# 8. Skill Router
Write-Step 8 "Initializing Skill Router..."
$skillRouter = Join-Path $PSScriptRoot "skill-router.ps1"
if (Test-Path $skillRouter) {
    & $skillRouter -Query "session-start"
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Skill Router validation issue"
    } else {
        Write-Success "Skill Router active"
    }
} else {
    Write-Host "[SKIP] Skill Router not found" -ForegroundColor Gray
}

# 9. Karpathy Guidelines Enforcement (Next-Level Feature)
Write-Step 9 "Enforcing Karpathy Guidelines (Think, Simplicity, Surgical, Goal-Driven)..."
$karpathyEnforcer = ".\scripts\adaptive\karpathy-enforcer.ps1"
if (Test-Path $karpathyEnforcer) {
    & $karpathyEnforcer -Trigger session-start -VerboseOutput
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Karpathy guidelines violations detected - see above"
    } else {
        Write-Success "Karpathy guidelines enforced - code quality optimal"
    }
} else {
    Write-Host "[SKIP] Karpathy enforcer not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Session Autostart Complete ===" -ForegroundColor Cyan
Write-Host "[READY] Workspace ready for operations" -ForegroundColor Green
exit 0
