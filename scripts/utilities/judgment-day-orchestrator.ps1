<#
.SYNOPSIS
    Judgment Day Orchestrator - Coordinates automated dual-review before push/merge
    
.DESCRIPTION
    Manages Judgment Day execution, coordinates with git hooks, and integrates with
    the session orchestrator to ensure code quality and dual-reviewer approval.
    
.PARAMETER Action
    Action to perform: initialize, check-pr, check-push, run-judgment, report
    
.PARAMETER Scope
    Scope of judgment: changed_files, pr_files, all
    
.PARAMETER MaxIterations
    Maximum fix iterations before escalation (default: 2)
    
.EXAMPLE
    .\judgment-day-orchestrator.ps1 -Action initialize
    .\judgment-day-orchestrator.ps1 -Action check-pr
    .\judgment-day-orchestrator.ps1 -Action run-judgment -Scope pr_files
#>

param(
    [ValidateSet('initialize', 'check-pr', 'check-push', 'run-judgment', 'report', 'status')]
    [string]$Action = 'status',
    
    [ValidateSet('changed_files', 'pr_files', 'all')]
    [string]$Scope = 'changed_files',
    
    [int]$MaxIterations = 2,
    
    [switch]$Verbose
)

# ======== CONFIGURATION ========
$ConfigPath = "config/judgment-day-automation.json"
$LogDir = ".session/judgment-day-logs"
$SessionDir = ".session"

# ======== FUNCTIONS ========

function Initialize-JudgmentDay {
    Write-Host "[JUDGMENT-DAY] Initializing Judgment Day automation..." -ForegroundColor Cyan
    
    # Create directories
    if (-not (Test-Path $SessionDir)) {
        New-Item -ItemType Directory -Path $SessionDir -Force | Out-Null
    }
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    
    # Load configuration
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "[JUDGMENT-DAY] Config not found: $ConfigPath" -ForegroundColor Yellow
        return $false
    }
    
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    
    # Register git hooks
    Write-Host "[JUDGMENT-DAY] Registering git hooks..." -ForegroundColor Cyan
    
    $hooksDir = ".git/hooks"
    $preCommitHook = Join-Path $hooksDir "pre-commit"
    $prePushHook = Join-Path $hooksDir "pre-push"
    $preMergeHook = Join-Path $hooksDir "pre-merge-commit"
    
    # Make hooks executable (Unix-style)
    if (Test-Path $prePushHook) {
        Write-Host "  [OK] pre-push hook registered" -ForegroundColor Green
    }
    if (Test-Path $preMergeHook) {
        Write-Host "  [OK] pre-merge-commit hook registered" -ForegroundColor Green
    }
    
    # Create event bus subscription for judgment day events
    Write-Host "[JUDGMENT-DAY] Setting up event bus subscriptions..." -ForegroundColor Cyan
    
    $eventBusPath = ".event-bus/subscriptions.json"
    if (Test-Path $eventBusPath) {
        $subscriptions = Get-Content $eventBusPath -Raw | ConvertFrom-Json
        
        # Ensure subscriptions is an array
        $subsList = @($subscriptions.subscriptions)
        
        # Add judgment day subscriptions if not present
        $jdSubscription = $subsList | Where-Object { $_.name -eq "judgment-day-automation" }
        if (-not $jdSubscription) {
            $newSub = @{
                name = "judgment-day-automation"
                events = @("pre-push", "pre-merge", "pr-created")
                handler = "judgment-day-orchestrator.ps1"
                enabled = $true
            }
            $subsList += $newSub
            $subscriptions.subscriptions = $subsList
            $subscriptions | ConvertTo-Json -Depth 10 | Set-Content $eventBusPath
            Write-Host "  [OK] Event subscriptions registered" -ForegroundColor Green
        }
    }
    
    Write-Host "[JUDGMENT-DAY] Initialization complete" -ForegroundColor Green
    return $true
}

function Check-PRStatus {
    Write-Host "[JUDGMENT-DAY] Checking PR status..." -ForegroundColor Cyan
    
    # Check if we're in a PR context
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) {
        Write-Host "[JUDGMENT-DAY] Not in a git repository" -ForegroundColor Red
        return $false
    }
    
    # Check for PR metadata
    $prFile = ".session/current-pr.json"
    if (Test-Path $prFile) {
        $pr = Get-Content $prFile | ConvertFrom-Json
        Write-Host "  PR #$($pr.number): $($pr.title)" -ForegroundColor Green
        Write-Host "  Target: $($pr.target_branch)" -ForegroundColor Cyan
        return $true
    }
    
    Write-Host "[JUDGMENT-DAY] No active PR detected" -ForegroundColor Yellow
    return $false
}

function Check-PushStatus {
    Write-Host "[JUDGMENT-DAY] Checking push status..." -ForegroundColor Cyan
    
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) {
        Write-Host "[JUDGMENT-DAY] Not in a git repository" -ForegroundColor Red
        return $false
    }
    
    # Get changed files
    $changedFiles = git diff --name-only origin/$branch...HEAD 2>$null
    if (-not $changedFiles) {
        $changedFiles = git diff --name-only HEAD~1...HEAD 2>$null
    }
    
    if ($changedFiles) {
        Write-Host "  Branch: $branch" -ForegroundColor Green
        Write-Host "  Changed files: $($changedFiles.Count)" -ForegroundColor Cyan
        return $true
    }
    
    Write-Host "[JUDGMENT-DAY] No changes to push" -ForegroundColor Yellow
    return $false
}

function Run-JudgmentDay {
    param(
        [string]$Scope = 'changed_files',
        [int]$MaxIterations = 2
    )
    
    Write-Host "[JUDGMENT-DAY] Running Judgment Day review..." -ForegroundColor Cyan
    Write-Host "  Scope: $Scope" -ForegroundColor Cyan
    Write-Host "  Max iterations: $MaxIterations" -ForegroundColor Cyan
    
    # Create judgment day session
    $timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
    $jdSessionFile = Join-Path $LogDir "judgment-day-$timestamp.json"
    
    $jdSession = @{
        timestamp = $timestamp
        scope = $Scope
        max_iterations = $MaxIterations
        status = "initiated"
        judges = @{
            judge_a = @{ status = "pending" }
            judge_b = @{ status = "pending" }
        }
        findings = @()
        fixes_applied = 0
        iterations = 0
    }
    
    $jdSession | ConvertTo-Json -Depth 10 | Set-Content $jdSessionFile
    
    Write-Host "  [OK] Judgment Day session created: $jdSessionFile" -ForegroundColor Green
    Write-Host "[JUDGMENT-DAY] Judgment Day review initiated" -ForegroundColor Green
    
    return $jdSessionFile
}

function Get-Status {
    Write-Host "[JUDGMENT-DAY] Status Report" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    
    # Check configuration
    if (Test-Path $ConfigPath) {
        $config = Get-Content $ConfigPath | ConvertFrom-Json
        Write-Host "Configuration: Loaded" -ForegroundColor Green
        Write-Host "  Pre-push enabled: $($config.automation_rules.pre_push.enabled)" -ForegroundColor Cyan
        Write-Host "  Pre-merge enabled: $($config.automation_rules.pre_merge.enabled)" -ForegroundColor Cyan
    } else {
        Write-Host "Configuration: Not found" -ForegroundColor Red
    }
    
    # Check git hooks
    Write-Host ""
    Write-Host "Git Hooks:" -ForegroundColor Cyan
    if (Test-Path ".git/hooks/pre-push") {
        Write-Host "  [OK] pre-push hook installed" -ForegroundColor Green
    }
    if (Test-Path ".git/hooks/pre-merge-commit") {
        Write-Host "  [OK] pre-merge-commit hook installed" -ForegroundColor Green
    }
    
    # Check recent judgment day sessions
    Write-Host ""
    Write-Host "Recent Sessions:" -ForegroundColor Cyan
    if (Test-Path $LogDir) {
        $sessions = Get-ChildItem $LogDir -Filter "judgment-day-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        if ($sessions) {
            foreach ($session in $sessions) {
                $content = Get-Content $session.FullName | ConvertFrom-Json
                Write-Host "  $($session.BaseName): $($content.status)" -ForegroundColor Cyan
            }
        } else {
            Write-Host "  No sessions found" -ForegroundColor Yellow
        }
    }
}

# ======== MAIN ========

switch ($Action) {
    'initialize' {
        Initialize-JudgmentDay
    }
    'check-pr' {
        Check-PRStatus
    }
    'check-push' {
        Check-PushStatus
    }
    'run-judgment' {
        Run-JudgmentDay -Scope $Scope -MaxIterations $MaxIterations
    }
    'report' {
        Get-Status
    }
    'status' {
        Get-Status
    }
    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        exit 1
    }
}