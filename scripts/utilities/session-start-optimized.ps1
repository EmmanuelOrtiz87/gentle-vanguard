# session-start-optimized.ps1
# Script optimizado de inicio de sesión que ejecuta el pipeline completo y muestra notificaciones
# Uso: pwsh -NoProfile -File scripts/utilities/session-start-optimized.ps1

param(
    [string]$ProjectName = "workspace_gentle_vanguard",
    [switch]$SkipAutostart = $false,
    [switch]$ShowTokenStatus = $true
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "Continue"

# Colores para output
function Write-Step { param([string]$Message) Write-Host "[STEP] $Message" -ForegroundColor Cyan }
function Write-OK { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param([string]$Message) Write-Host "[ERR] $Message" -ForegroundColor Red }
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Gray }

# Detectar repo root
$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { 
    $env:GENTLE_VANGUARD_BASE_DIR 
} else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { 
        $root = Split-Path -Parent $root 
    }
    if (-not $root) { $root = (Get-Location).Path }
    $root
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           GENTLE-VANGUARD SESSION START                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================
# PASO 1: Tool Detection
# ============================================
Write-Step "Detecting AI tool and environment..."
$detectToolScript = Join-Path $repoRoot "scripts\utilities\detect-tool.ps1"
$detected = $null
if (Test-Path $detectToolScript) {
    try {
        $detected = & $detectToolScript -AsJson | ConvertFrom-Json
        Write-OK "Tool detected: $($detected.name) (confidence: $($detected.confidence)%)"
        Write-Info "Platform: $($detected.os.platform) | Shell: $($detected.os.shell)"
    } catch {
        Write-Warn "Could not detect tool: $($_.Exception.Message)"
    }
}

# ============================================
# PASO 2: Session Autostart Pipeline
# ============================================
if (-not $SkipAutostart) {
    Write-Step "Running session autostart pipeline..."
    $autostartScript = Join-Path $repoRoot "scripts\utilities\session-autostart.ps1"
    if (Test-Path $autostartScript) {
        try {
            # Ejecutar con timeout extendido
            $job = Start-Job -ScriptBlock {
                param($script, $project)
                & $script -ProjectName $project -NoExit
            } -ArgumentList $autostartScript, $ProjectName
            
            $completed = $job | Wait-Job -Timeout 300
            if ($completed) {
                $result = Receive-Job $job
                $job | Remove-Job
                Write-OK "Autostart pipeline completed"
            } else {
                Stop-Job $job -ErrorAction SilentlyContinue
                Remove-Job $job -ErrorAction SilentlyContinue
                Write-Warn "Autostart pipeline timed out after 300s, continuing..."
            }
        } catch {
            Write-Warn "Autostart error: $($_.Exception.Message)"
        }
    } else {
        Write-Warn "Autostart script not found: $autostartScript"
    }
} else {
    Write-Info "Skipping autostart (SkipAutostart flag set)"
}

# ============================================
# PASO 3: Engram Session Start
# ============================================
Write-Step "Initializing Engram session..."
$sessionId = "session-$(Get-Date -Format 'yyyy-MM-dd')-$(Get-Random -Minimum 10 -Maximum 99)"
Write-Info "Session ID: $sessionId"

# ============================================
# PASO 4: Read Startup Summary
# ============================================
Write-Step "Reading startup summary..."
$startupSummaryPath = Join-Path $repoRoot "scripts\.session\startup-summary.json"
$startupData = $null
if (Test-Path $startupSummaryPath) {
    try {
        $startupData = Get-Content $startupSummaryPath -Raw | ConvertFrom-Json
        Write-OK "Startup summary loaded"
    } catch {
        Write-Warn "Could not parse startup summary: $($_.Exception.Message)"
    }
} else {
    Write-Warn "Startup summary not found, using defaults"
}

# ============================================
# PASO 5: Initialize Token Usage Tracking
# ============================================
Write-Step "Initializing token usage tracking..."
$tokenNotifierScript = Join-Path $repoRoot "scripts\utilities\token-usage-notifier.ps1"
if (Test-Path $tokenNotifierScript) {
    try {
        # Reset token usage for new session
        $sessionDir = Join-Path $repoRoot ".session"
        if (-not (Test-Path $sessionDir)) {
            New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
        }
        
        # Initialize with session ID
        $tokenUsageFile = Join-Path $sessionDir "token-usage.json"
        $initialData = @{
            sessionId = $sessionId
            startTime = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            messages = @()
            totalInputTokens = 0
            totalOutputTokens = 0
            totalTokens = 0
            totalContextChars = 0
            messageCount = 0
        }
        $initialData | ConvertTo-Json -Depth 10 | Set-Content $tokenUsageFile
        
        if ($ShowTokenStatus) {
            & $tokenNotifierScript -Action status -SessionId $sessionId 2>&1 | ForEach-Object {
                if ($_ -match "Display Enabled|Show After|Show Accumulated|Compact Mode") {
                    Write-Info $_
                }
            }
        }
        Write-OK "Token usage tracking initialized"
    } catch {
        Write-Warn "Token notifier error: $($_.Exception.Message)"
    }
} else {
    Write-Warn "Token notifier not found: $tokenNotifierScript"
}

# ============================================
# PASO 6: Git Status
# ============================================
Write-Step "Checking git status..."
try {
    $gitStatus = git status --porcelain 2>$null
    $workspaceClean = [string]::IsNullOrWhiteSpace($gitStatus)
    if ($workspaceClean) {
        Write-OK "Workspace is clean"
    } else {
        $dirtyCount = ($gitStatus -split "`n" | Where-Object { $_ -match "^\s*[MADRC]" }).Count
        Write-Warn "Workspace has $dirtyCount uncommitted changes"
    }
} catch {
    Write-Warn "Could not check git status"
}

# ============================================
# PASO 7: Display Session Status
# ============================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    SESSION STATUS                                  ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan

# Peak hour info
$isPeakHour = if ($startupData) { $startupData.isPeakHour } else { 
    $hour = (Get-Date).Hour
    ($hour -ge 9 -and $hour -lt 15)
}
$peakStatus = if ($isPeakHour) { "PEAK" } else { "OFF-PEAK" }
$peakColor = if ($isPeakHour) { "Yellow" } else { "Green" }

# Session ID
$displaySessionId = if ($startupData -and $startupData.sessionId) { $startupData.sessionId } else { $sessionId }

# Workspace status
$wsStatus = if ($workspaceClean) { "clean" } else { "dirty" }

# Tool
$toolName = if ($detected) { $detected.name } else { "unknown" }

Write-Host "║  Time:      $(Get-Date -Format 'HH:mm') ART [$peakStatus]" -ForegroundColor White -NoNewline
Write-Host "".PadRight(20) -NoNewline
Write-Host "║" -ForegroundColor Cyan

Write-Host "║  Session:   $displaySessionId" -ForegroundColor White -NoNewline
Write-Host "".PadRight(30) -NoNewline
Write-Host "║" -ForegroundColor Cyan

Write-Host "║  Workspace: $wsStatus" -ForegroundColor White -NoNewline
Write-Host "".PadRight(35) -NoNewline
Write-Host "║" -ForegroundColor Cyan

Write-Host "║  Tool:      $toolName" -ForegroundColor White -NoNewline
Write-Host "".PadRight(38) -NoNewline
Write-Host "║" -ForegroundColor Cyan

Write-Host "║  Engram:    OK" -ForegroundColor White -NoNewline
Write-Host "".PadRight(45) -NoNewline
Write-Host "║" -ForegroundColor Cyan

Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($isPeakHour) {
    Write-Host ""
    Write-Warn "PEAK HOUR (9:00-15:00): Recommend short, focused tasks"
}

Write-Host ""
Write-OK "Session ready for operations"
Write-Host ""

# Return session info for caller
return @{
    sessionId = $sessionId
    tool = $toolName
    isPeakHour = $isPeakHour
    workspaceClean = $workspaceClean
    startupData = $startupData
}
