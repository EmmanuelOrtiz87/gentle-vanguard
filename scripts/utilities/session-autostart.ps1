# session-autostart.ps1
# Session Autostart - Config-driven pipeline with Engram Optimization

param(
    [string]$ProjectName = "workspace_gentle_vanguard",
    [string]$WorkspaceRoot = ".\gentle-vanguard",
    [string]$ConfigFile = "",
    [switch]$NoExit
)

$ErrorActionPreference = "Continue"

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Message)
    Write-Host "[$Step/$Total] $Message" -ForegroundColor Cyan
}

function Write-Success { param([string]$Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-ErrorMsg { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Complete-Script {
    param([int]$ExitCode = 0)

    if ($NoExit) {
        return $ExitCode
    }

    exit $ExitCode
}

$repoRoot = if ($env:GENTLE_VANGUARD_BASE_DIR) { $env:GENTLE_VANGUARD_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

if (-not $ConfigFile) {
    $ConfigFile = Join-Path $repoRoot "config\session-autostart.config.json"
}

if (-not (Test-Path $ConfigFile)) {
    Write-ErrorMsg "Config file not found: $ConfigFile"
    Complete-Script -ExitCode 1
    return
}

$config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
$steps = @($config.pipeline.steps | Where-Object { $_.enabled -eq $true })
$totalSteps = $steps.Count
$stepNum = 0
$failed = @()
$requiredFailed = @()

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host ""
Write-Host " ██████╗ ███████╗███╗   ██╗████████╗██╗     ███████╗    ██╗   ██╗ █████╗ ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗ " -ForegroundColor Cyan
Write-Host "██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██║     ██╔════╝    ██║   ██║██╔══██╗████╗  ██║██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗" -ForegroundColor Cyan
Write-Host "██║  ███╗█████╗  ██╔██╗ ██║   ██║   ██║     █████╗      ██║   ██║███████║██╔██╗ ██║██║  ███╗██║   ██║███████║██████╔╝██║  ██║" -ForegroundColor Cyan
Write-Host "██║   ██║██╔══╝  ██║╚██╗██║   ██║   ██║     ██╔══╝      ╚██╗ ██╔╝██╔══██║██║╚██╗██║██║   ██║██║   ██║██╔══██║██╔══██╗██║  ██║" -ForegroundColor Cyan
Write-Host "╚██████╔╝███████╗██║  ████║   ██║   ██║███████╗███████╗   ╚████╔╝ ██║  ██║██║  ████║╚██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝" -ForegroundColor Cyan
Write-Host " ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚══════╝╚══════╝    ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ " -ForegroundColor Cyan
Write-Host ""
Write-Host "           -- NATIVE AI COGNITIVE DEVELOPMENT ECOSYSTEM --" -ForegroundColor DarkGray
Write-Host ""
Write-Host "=== Session Autostart (Config-Driven) ===" -ForegroundColor Cyan
Write-Host "[INFO] Loaded config: $ConfigFile" -ForegroundColor Gray
Write-Host "[INFO] Pipeline steps: $totalSteps enabled" -ForegroundColor Gray
Write-Host ""

foreach ($step in $steps) {
    $stepNum++
    $scriptId = $step.id
    $scriptPath = Join-Path $repoRoot $step.script
    $scriptArgs = $step.args
    $isRequired = [bool]$step.required

    Write-Step $stepNum $totalSteps "$scriptId..."

    if (-not (Test-Path $scriptPath)) {
        $msg = "Script not found: $($step.script)"
        Write-Host "[SKIP] $msg" -ForegroundColor Gray
        if ($isRequired) {
            Write-ErrorMsg "REQUIRED step missing: $scriptId ($msg)"
            $requiredFailed += $scriptId
        }
        continue
    }

    try {
        if ($scriptArgs -and $scriptArgs.Trim()) {
            $invokeCmd = "& `"$scriptPath`" $scriptArgs"
            $result = Invoke-Expression $invokeCmd 2>&1
        } else {
            $result = & $scriptPath 2>&1
        }
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            $msg = "$scriptId exited with code $exitCode"
            Write-Warning "$msg"
            $failed += $scriptId
            if ($isRequired) {
                Write-ErrorMsg "REQUIRED step failed: $msg"
                $requiredFailed += $scriptId
            }
        } else {
            Write-Success "$scriptId completed"
        }
    }
    catch {
        $msg = "$scriptId threw exception: $($_.Exception.Message)"
        Write-Warning $msg
        $failed += $scriptId
        if ($isRequired) {
            Write-ErrorMsg "REQUIRED step exception: $msg"
            $requiredFailed += $scriptId
        }
    }
}

Write-Host ""
Write-Host "=== Session Autostart Summary ===" -ForegroundColor Cyan
Write-Host "Steps executed: $stepNum" -ForegroundColor Gray
Write-Host "Steps failed:   $($failed.Count)" -ForegroundColor $(if($failed.Count -gt 0){'Yellow'}else{'Green'})
Write-Host "Required fails: $($requiredFailed.Count)" -ForegroundColor $(if($requiredFailed.Count -gt 0){'Red'}else{'Green'})

if ($requiredFailed.Count -gt 0) {
    Write-Host ""
    Write-ErrorMsg "Required steps failed: $($requiredFailed -join ', ')"
    Write-Host "[ACTION] Fix the issues above and re-run session autostart." -ForegroundColor Yellow
    Complete-Script -ExitCode 1
    return
}

if ($failed.Count -gt 0) {
    Write-Host "[WARNING] Non-required steps with issues: $($failed -join ', ')" -ForegroundColor Yellow
}

Write-Host "[READY] Workspace ready for operations" -ForegroundColor Green
Complete-Script -ExitCode 0
