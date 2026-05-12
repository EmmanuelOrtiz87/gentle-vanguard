<#
.SYNOPSIS
    Judgment Day Orchestrator - Coordinates dual-review before push/merge/session

.DESCRIPTION
    Manages Judgment Day execution, coordinates with git hooks, and integrates
    with the session orchestrator. Calls the real judgment-day.ps1 from
    WORKFLOW-ORCHESTRATION for all review operations.

.PARAMETER Action
    Action to perform: initialize, check-pr, check-push, run-judgment, report, status

.PARAMETER Scope
    Scope of judgment: changed_files, pr_files, all, full, quick

.PARAMETER MaxIterations
    Maximum fix iterations before escalation (default: 2)

.EXAMPLE
    .\judgment-day-orchestrator.ps1 -Action initialize
    .\judgment-day-orchestrator.ps1 -Action check-pr
    .\judgment-day-orchestrator.ps1 -Action run-judgment -Scope full
#>

param(
    [ValidateSet('initialize', 'check-pr', 'check-push', 'run-judgment', 'report', 'status')]
    [string]$Action = 'status',

    [ValidateSet('changed_files', 'pr_files', 'all', 'full', 'quick')]
    [string]$Scope = 'changed_files',

    [int]$MaxIterations = 2,

    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Get-Item (Join-Path $scriptDir '..\..')).FullName
$automationConfig = Join-Path $repoRoot 'config\judgment-day-automation.json'
$orchestratorConfig = Join-Path $repoRoot 'config\judgment-day-orchestrator-config.json'
$jdScript = Join-Path $repoRoot 'scripts\utilities\WORKFLOW-ORCHESTRATION\judgment-day.ps1'
$logDir = Join-Path $repoRoot '.session\judgment-day-logs'
$sessionDir = Join-Path $repoRoot '.session'

function Write-OK   { param([string]$m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "  [WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param([string]$m) Write-Host "  [FAIL] $m" -ForegroundColor Red }
function Write-Step { param([string]$m) Write-Host "[JUDGMENT-DAY] $m" -ForegroundColor Cyan }

# ======== INITIALIZE ========
function Initialize-JudgmentDay {
    Write-Step "Initializing Judgment Day automation..."

    # Create directories
    foreach ($dir in @($sessionDir, $logDir)) {
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    }

    # Validate config exists
    if (-not (Test-Path $automationConfig)) {
        Write-Warn "Automation config not found: $automationConfig"
    }

    # Validate main script exists
    if (-not (Test-Path $jdScript)) {
        Write-Fail "judgment-day.ps1 not found at WORKFLOW-ORCHESTRATION"
        return $false
    }
    Write-OK "judgment-day.ps1 found"

    # Install git hooks
    Install-GitHooks

    # Register event bus subscription
    Register-EventBusSubscription

    Write-Step "Initialization complete"
    return $true
}

function Install-GitHooks {
    $hooksDir = Join-Path $repoRoot '.git\hooks'
    if (-not (Test-Path $hooksDir)) {
        Write-Warn "No .git/hooks directory - not a git repository?"
        return
    }

    $hooks = @{
        'pre-push' = @"
#!/usr/bin/env pwsh
# Judgment Day pre-push hook - auto-triggers dual-review before push
`$repoRoot = Split-Path -Parent (Split-Path -Parent `$MyInvocation.MyCommand.Path)
`$jdScript = Join-Path `$repoRoot 'scripts\utilities\judgment-day-orchestrator.ps1'
if (Test-Path `$jdScript) {
    & `$jdScript -Action check-push
}
"@
        'pre-merge-commit' = @"
#!/usr/bin/env pwsh
# Judgment Day pre-merge-commit hook - auto-triggers review before merge
`$repoRoot = Split-Path -Parent (Split-Path -Parent `$MyInvocation.MyCommand.Path)
`$jdScript = Join-Path `$repoRoot 'scripts\utilities\judgment-day-orchestrator.ps1'
if (Test-Path `$jdScript) {
    & `$jdScript -Action check-pr
}
"@
    }

    foreach ($hook in $hooks.Keys) {
        $hookPath = Join-Path $hooksDir $hook
        if (-not (Test-Path $hookPath)) {
            try {
                $hooks[$hook] | Set-Content -Path $hookPath -Encoding UTF8 -NoNewline
                Write-OK "Git hook installed: $hook"
            } catch {
                Write-Warn "Could not install hook $hook : $_"
            }
        } else {
            Write-OK "Git hook already installed: $hook"
        }
    }
}

function Register-EventBusSubscription {
    $eventBusPath = Join-Path $repoRoot '.event-bus\subscriptions.json'
    if (-not (Test-Path $eventBusPath)) {
        $busDir = Split-Path $eventBusPath -Parent
        if (-not (Test-Path $busDir)) { New-Item -ItemType Directory -Path $busDir -Force | Out-Null }
        $base = @{ subscriptions = @() }
        $base | ConvertTo-Json -Depth 5 | Set-Content -Path $eventBusPath -Encoding UTF8
    }

    $subscriptions = Get-Content $eventBusPath -Raw | ConvertFrom-Json
    $subsList = @($subscriptions.subscriptions)
    $existing = $subsList | Where-Object { $_.name -eq 'judgment-day-automation' }

    if (-not $existing) {
        $newSub = @{
            name = 'judgment-day-automation'
            events = @('pre-push', 'pre-merge', 'pr-created', 'session-start')
            handler = 'judgment-day-orchestrator.ps1'
            enabled = $true
        }
        $subsList += $newSub
        $subscriptions.subscriptions = $subsList
        $subscriptions | ConvertTo-Json -Depth 10 | Set-Content $eventBusPath -Encoding UTF8
        Write-OK "Event bus subscription registered"
    } else {
        Write-OK "Event bus subscription already exists"
    }
}

# ======== CHECK PR ========
function Check-PRStatus {
    Write-Step "Checking PR status..."

    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) {
        Write-Fail "Not in a git repository"
        return $false
    }

    $prFile = Join-Path $sessionDir 'current-pr.json'
    if (Test-Path $prFile) {
        $pr = Get-Content $prFile | ConvertFrom-Json
        Write-OK "PR #$($pr.number): $($pr.title) -> $($pr.target_branch)"
        return $true
    }

    Write-Warn "No active PR detected (branch: $branch)"
    return $false
}

# ======== CHECK PUSH ========
function Check-PushStatus {
    Write-Step "Checking push status..."

    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    if (-not $branch) {
        Write-Fail "Not in a git repository"
        return $false
    }

    $protected = @('main', 'develop', 'master')
    if ($protected -contains $branch) {
        Write-Warn "Protected branch: $branch - skipping auto-judgment"
        return $true
    }

    # Get changed files relative to upstream or last commit
    $changedFiles = git diff --name-only 'origin/main...HEAD' 2>$null
    if (-not $changedFiles) {
        $changedFiles = git diff --name-only 'HEAD~1...HEAD' 2>$null
    }

    if ($changedFiles) {
        Write-OK "Branch: $branch | Changed files: $($changedFiles.Count)"
        # Run judgment on changed files
        $target = ($changedFiles | Select-Object -First 20) -join ','
        Write-Step "Auto-triggering judgment on $($changedFiles.Count) changed file(s)..."
        & $jdScript -Target $target -Scope Full -NoPrompt
        return ($LASTEXITCODE -eq 0)
    }

    Write-Warn "No changes detected"
    return $true
}

# ======== RUN JUDGMENT ========
function Run-JudgmentDay {
    param([string]$ScopeName = 'full', [int]$MaxIter = 2)

    Write-Step "Running Judgment Day review..."

    $scopeArg = if ($ScopeName -in @('full', 'all')) { 'Full' } else { 'Quick' }

    # Resolve scope to file path
    $target = '.'
    switch ($ScopeName) {
        'changed_files' {
            $changed = git diff --name-only 'HEAD~1...HEAD' 2>$null
            if (-not $changed) { $changed = git diff --name-only --cached 2>$null }
            if ($changed) { $target = $changed -join ' ' }
        }
        'pr_files' {
            $prFile = Join-Path $sessionDir 'current-pr.json'
            if (Test-Path $prFile) {
                $pr = Get-Content $prFile | ConvertFrom-Json
                Write-OK "PR context: $($pr.number)"
            }
        }
    }

    Write-OK "Target: $target | Scope: $scopeArg | MaxIterations: $MaxIter"

    if (-not (Test-Path $jdScript)) {
        Write-Fail "judgment-day.ps1 not found at $jdScript"
        return $null
    }

    $result = & $jdScript -Target $target -Scope $scopeArg -MaxPasses $MaxIter -NoPrompt
    $exitCode = $LASTEXITCODE

    Write-Step "Judgment Day completed. Exit: $exitCode"
    return @{ exitCode = $exitCode; approved = ($exitCode -eq 0) }
}

# ======== STATUS ========
function Get-Status {
    Write-Step "Status Report"
    Write-Host "================================" -ForegroundColor Cyan

    # Config
    if (Test-Path $automationConfig) {
        $config = Get-Content $automationConfig | ConvertFrom-Json
        Write-OK "Configuration loaded"
        Write-Host "  Pre-push enabled: $($config.automation_rules.pre_push.enabled)" -ForegroundColor Cyan
        Write-Host "  Pre-merge enabled: $($config.automation_rules.pre_merge.enabled)" -ForegroundColor Cyan
    } else {
        Write-Warn "Configuration not found"
    }

    # Script
    if (Test-Path $jdScript) {
        Write-OK "judgment-day.ps1 available"
    } else {
        Write-Fail "judgment-day.ps1 missing"
    }

    # Git hooks
    Write-Host "`nGit Hooks:" -ForegroundColor Cyan
    $hooksToCheck = @('pre-push', 'pre-merge-commit')
    foreach ($hook in $hooksToCheck) {
        $hookPath = Join-Path $repoRoot ".git\hooks\$hook"
        if (Test-Path $hookPath) { Write-OK "Git hook: $hook" } else { Write-Warn "Git hook: $hook (not installed)" }
    }

    # Recent sessions
    Write-Host "`nRecent Sessions:" -ForegroundColor Cyan
    if (Test-Path $logDir) {
        $sessions = Get-ChildItem $logDir -Filter 'judgment-day-*.json' | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        if ($sessions) {
            foreach ($session in $sessions) {
                $content = Get-Content $session.FullName | ConvertFrom-Json
                Write-Host "  $($session.BaseName): $($content.status) (rounds: $(@($content.rounds).Count))" -ForegroundColor $(if ($content.status -eq 'APPROVED') { 'Green' } else { 'Yellow' })
            }
        } else {
            Write-Host "  No sessions found" -ForegroundColor Yellow
        }
    }
}

# ======== MAIN ========
switch ($Action) {
    'initialize' { Initialize-JudgmentDay }
    'check-pr' { Check-PRStatus }
    'check-push' { Check-PushStatus }
    'run-judgment' {
        $result = Run-JudgmentDay -ScopeName $Scope -MaxIter $MaxIterations
        if ($result -and -not $result.approved) {
            exit 1
        }
    }
    'report' { Get-Status }
    'status' { Get-Status }
    default {
        Write-Fail "Unknown action: $Action"
        exit 1
    }
}
