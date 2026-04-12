# wf.ps1 - Workflow CLI
# Automated development workflow for Gentleman Foundation

param(
    [Parameter(Position=0)]
    [ValidateSet('review', 'audit', 'pr', 'push', 'status', 'health', 'update', 'update-all', 'install-engram', 'orchestrator-status', 'ide-status', 'diagnose', 'verify', 'start-session', 'task-brief', 'migrate-structure', 'context-pack', 'compact-start', 'context-metrics', 'help')]
    [string]$Command = 'help',
    
    [Parameter(Position=1)]
    [string]$Scope = '',
    
    [switch]$SkipTests,
    [switch]$SkipReview,
    [switch]$Force,
    [switch]$JSON
)

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { (Resolve-Path (Join-Path (Join-Path $scriptDir '..') '..')).Path } else { Get-Location }

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Get-GitInfo {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $status = git status --porcelain 2>$null
    $hasChanges = $status -and $status.Trim() -ne ''
    
    @{
        Branch = $branch
        HasChanges = $hasChanges
        Status = $status
        Ahead = 0
        Behind = 0
    }
}

function Get-BranchStatus {
    $gitInfo = Get-GitInfo
    if ($gitInfo.Branch -eq 'main' -or $gitInfo.Branch -eq 'develop') {
        Write-Warning "You are on branch: $($gitInfo.Branch)"
        if (-not $Force) {
            Write-Host "Use -Force to proceed." -ForegroundColor Yellow
            return $false
        }
    }
    return $true
}

function Invoke-Update {
    Write-Step "Updating repository, foundation, skills, and tools"

    $updateScript = Join-Path $scriptDir '..\validation\update-all.ps1'
    if (-not (Test-Path $updateScript)) {
        Write-Error "Update script not found: $updateScript"
        exit 1
    }

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $updateScript -All -Force
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Update failed with exit code $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}

function Invoke-UpdateAll {
    Invoke-Update
}

function Test-Secrets {
    Write-Step "Checking for secrets..."
    
    $patterns = @(
        @{ Name = "AWS Key"; Pattern = 'AKIA[0-9A-Z]{16}' },
        @{ Name = "GitHub Token"; Pattern = 'ghp_[A-Za-z0-9]{36}' },
        @{ Name = "Private Key"; Pattern = '-----BEGIN.*PRIVATE KEY-----' },
        @{ Name = "Stripe Key"; Pattern = 'sk_live_[0-9a-zA-Z]{24,}' }
    )
    
    $staged = git diff --cached --name-only 2>$null
    $found = @()
    
    foreach ($file in $staged) {
        $content = git show ":0:$file" 2>$null
        if ($content) {
            foreach ($pattern in $patterns) {
                if ($content -match $pattern.Pattern) {
                    $found += @{ File = $file; Pattern = $pattern.Name }
                    Write-Error "Secret detected: $($pattern.Name) in $file"
                }
            }
        }
    }
    
    if ($found.Count -eq 0) {
        Write-Success "No secrets detected"
        return $true
    }
    
    return $false
}

function Test-GoTests {
    if (-not (Test-Path (Join-Path $repoRoot 'go.mod'))) {
        Write-Step "Skipping Go tests - no go.mod found"
        return $true
    }
    
    Write-Step "Running Go tests..."
    Set-Location $repoRoot
    $result = go test ./... 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Go tests passed"
        return $true
    } else {
        Write-Error "Go tests failed"
        return $false
    }
}

function Test-AngularTests {
    $webDir = Join-Path $repoRoot 'web'
    if (-not (Test-Path $webDir)) {
        Write-Step "Skipping Angular tests - no web directory found"
        return $true
    }
    
    Write-Step "Running Angular tests..."
    Set-Location $webDir
    npm test 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Angular tests passed"
        return $true
    } else {
        Write-Error "Angular tests failed"
        return $false
    }
}

function Get-CommitHistory {
    param([int]$Count = 5)
    git log --oneline -n $Count 2>$null
}

function Get-ContextMetricsSnapshot {
    param([int]$Days = 7)

    $metricsPath = Join-Path $repoRoot 'docs/sessions/metrics/context-usage.csv'
    if (-not (Test-Path $metricsPath)) {
        return @{
            HealthStatus = 'WARN (no data)'
            Recommendation = 'Adopt compact-start in daily handoffs to start collecting baseline data.'
            Lines = @(
                '| Metric | Value |',
                '|---|---|',
                '| Window | Last 7 days |',
                '| Data | No metrics collected yet |'
            )
            TrendLines = @(
                '| Metric | Current 7d | Previous 7d | Delta |',
                '|---|---:|---:|---:|',
                '| Total events | 0 | 0 | 0 |',
                '| Avg prompt chars | 0 | 0 | 0 |',
                '| compact-start adoption % | 0 | 0 | 0 |'
            )
        }
    }

    $now = Get-Date
    $currentStart = $now.AddDays(-1 * $Days)
    $previousStart = $now.AddDays(-2 * $Days)

    $allRows = Import-Csv -Path $metricsPath
    $rows = $allRows | Where-Object { [datetime]::Parse($_.timestamp) -ge $currentStart }
    $previousRows = $allRows | Where-Object {
        $ts = [datetime]::Parse($_.timestamp)
        $ts -ge $previousStart -and $ts -lt $currentStart
    }

    if (-not $rows -or $rows.Count -eq 0) {
        return @{
            HealthStatus = 'WARN (no events in window)'
            Recommendation = 'Run compact-start before opening new threads to capture usage and enforce concise handoffs.'
            Lines = @(
                '| Metric | Value |',
                '|---|---|',
                '| Window | Last 7 days |',
                '| Events | 0 |'
            )
            TrendLines = @(
                '| Metric | Current 7d | Previous 7d | Delta |',
                '|---|---:|---:|---:|',
                '| Total events | 0 | 0 | 0 |',
                '| Avg prompt chars | 0 | 0 | 0 |',
                '| compact-start adoption % | 0 | 0 | 0 |'
            )
        }
    }

    $total = $rows.Count
    $pack = @($rows | Where-Object event -eq 'context-pack').Count
    $compact = @($rows | Where-Object event -eq 'compact-start').Count
    $avgObjective = [math]::Round((($rows | Measure-Object -Property objective_chars -Average).Average), 1)
    $avgPrompt = [math]::Round((($rows | Measure-Object -Property prompt_chars -Average).Average), 1)
    $adoption = if ($total -gt 0) { [math]::Round(($compact * 100.0) / $total, 1) } else { 0 }

    $prevTotal = @($previousRows).Count
    $prevCompact = @($previousRows | Where-Object event -eq 'compact-start').Count
    $prevAvgPrompt = if ($prevTotal -gt 0) { [math]::Round(((@($previousRows) | Measure-Object -Property prompt_chars -Average).Average), 1) } else { 0 }
    $prevAdoption = if ($prevTotal -gt 0) { [math]::Round(($prevCompact * 100.0) / $prevTotal, 1) } else { 0 }

    $deltaTotal = $total - $prevTotal
    $deltaPrompt = [math]::Round(($avgPrompt - $prevAvgPrompt), 1)
    $deltaAdoption = [math]::Round(($adoption - $prevAdoption), 1)

    $healthStatus = 'GREEN'
    if ($avgPrompt -gt 1800 -or $adoption -lt 40) {
        $healthStatus = 'RED'
    } elseif ($avgPrompt -gt 1200 -or $adoption -lt 70) {
        $healthStatus = 'YELLOW'
    }

    $recommendation = 'Maintain current compact-start adoption and review weekly trend for drift.'
    if ($healthStatus -eq 'RED') {
        $recommendation = 'Enforce compact-start before every handoff and trim objective prompts to one sentence.'
    } elseif ($healthStatus -eq 'YELLOW') {
        $recommendation = 'Increase compact-start adoption and reduce repeated constraints in follow-up prompts.'
    }

    return @{
        HealthStatus = $healthStatus
        Recommendation = $recommendation
        Lines = @(
            '| Metric | Value |',
            '|---|---|',
            "| Window | Last $Days days |",
            "| Total events | $total |",
            "| context-pack | $pack |",
            "| compact-start | $compact |",
            "| compact-start adoption % | $adoption |",
            "| Avg objective chars | $avgObjective |",
            "| Avg prompt chars | $avgPrompt |"
        )
        TrendLines = @(
            '| Metric | Current 7d | Previous 7d | Delta |',
            '|---|---:|---:|---:|',
            "| Total events | $total | $prevTotal | $deltaTotal |",
            "| Avg prompt chars | $avgPrompt | $prevAvgPrompt | $deltaPrompt |",
            "| compact-start adoption % | $adoption | $prevAdoption | $deltaAdoption |"
        )
    }
}

function New-AuditDocument {
    param([string]$OutputPath)
    
    Write-Step "Generating Audit Document..."
    
    $gitInfo = Get-GitInfo
    $date = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    $commits = Get-CommitHistory -Count 10
    $commitLines = if ($commits) {
        (@($commits) | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    } else {
        '- none'
    }
    $metrics = Get-ContextMetricsSnapshot -Days 7
    $metricsSection = ($metrics.Lines -join [Environment]::NewLine)
    $metricsTrendSection = ($metrics.TrendLines -join [Environment]::NewLine)
    
    $auditContent = @"
# Audit Document - $date

**Project:** $(Split-Path $repoRoot -Leaf)
**Branch:** $($gitInfo.Branch)
**Date:** $date

---

## Summary
`[Brief description of changes]`

## Executive Overview

| Area | Status | Notes |
|---|---|---|
| Delivery | `TODO` | Confirm scope completion against task brief |
| Operational Risk | `TODO` | Confirm CI/workflow status and blockers |
| Context Efficiency Health | $($metrics.HealthStatus) | $($metrics.Recommendation) |

## Git Information

| Item | Value |
|------|-------|
| Branch | $($gitInfo.Branch) |
| Has Changes | $($gitInfo.HasChanges) |
| Ahead | $($gitInfo.Ahead) |
| Behind | $($gitInfo.Behind) |

## Recent Commits

$commitLines

## Tests Status

| Suite | Status |
|-------|--------|
| Go | `TODO` |
| Angular | `TODO` |

## Findings

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 0 |
| LOW | 0 |

## Context Efficiency (7d)

$metricsSection

## Technical Context Trend (7d vs previous 7d)

$metricsTrendSection

## Specification

- Status: `TODO`
- Notes: `TODO`

## Next Steps

- [ ] Review changes
- [ ] Create PR if needed

---

**Generated by:** Gentleman Foundation Workflow CLI
**Version:** 1.0
"@
    
    $auditContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Success "Audit document created: $OutputPath"
}

function New-PRDescription {
    param([string]$OutputPath)
    
    $prContent = @"
## Summary
`[Brief description of changes]`

## Changes

- [ ] Feature 1
- [ ] Feature 2
- [ ] Bug fix

## Testing

- [ ] Go tests pass
- [ ] Angular tests pass
- [ ] Manual testing done

## Checklist

- [ ] No secrets committed
- [ ] Code follows conventions
- [ ] Documentation updated
- [ ] Related issues linked

Closes #[ISSUE_NUMBER]
"@
    
    $prContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Success "PR description template created: $OutputPath"
}

function Show-Status {
    $gitInfo = Get-GitInfo
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Project Status" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Branch: $($gitInfo.Branch)"
    Write-Host "Has Changes: $($gitInfo.HasChanges)"
    Write-Host ""
    
    if ($gitInfo.HasChanges) {
        Write-Host "Uncommitted files:" -ForegroundColor Yellow
        $gitInfo.Status | ForEach-Object { Write-Host "  $_" }
    }
    
    Write-Host ""
    Write-Host "Recent commits:" -ForegroundColor Cyan
    Get-CommitHistory -Count 3 | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
}

function Show-Help {
    Write-Host @"
Gentleman Foundation Workflow CLI
================================

USAGE:
    .\wf.ps1 <command> [options]

COMMANDS:
    review [scope]       Run code review (security, quality, all)
    audit                Generate audit document
    pr                   Create PR with template
    push                 Commit and push changes
    status               Show current status
    start-session [task] Create a session brief and optional task brief
    task-brief <task>    Create or refresh a task brief only
    health               Check system health & activate tools
    install-engram       Install or verify Engram CLI availability
    orchestrator-status  Validate orchestrator and Engram integration
    ide-status           Detect IDE session and suggest activation command
    diagnose             Full system diagnostics report
    verify               Quick stack verification & auto-repair
    update               Update repository, foundation, skills, and tools
    update-all           Alias for update
    migrate-structure    Preflight and guided migration of loose scripts
    context-pack [goal]  Generate compact context summary for new chat thread
    compact-start [goal] Generate context pack and copy compact continuation prompt
    context-metrics [days] Show context/token usage metrics from local logs
    help                 Show this help

OPTIONS:
    -SkipTests        Skip test execution
    -SkipReview       Skip code review
    -Force            Proceed without confirmation
    -JSON             Output diagnostics in JSON format (diagnose command)

EXAMPLES:
    .\wf.ps1 review              Run full code review
    .\wf.ps1 review security     Run security scan only
    .\wf.ps1 audit              Generate audit document
    .\wf.ps1 pr                 Create PR
    .\wf.ps1 push               Commit and push
    .\wf.ps1 start-session      Create the session brief for today
    .\wf.ps1 task-brief auth    Create a task brief for auth work
    .\wf.ps1 diagnose            Full diagnostics report (JSON available)
    .\wf.ps1 diagnose -JSON      Full diagnostics report in JSON format
    .\wf.ps1 verify              Quick verify & auto-repair if needed
    .\wf.ps1 health              Check system health & activate tools
    .\wf.ps1 install-engram      Install or verify Engram CLI
    .\wf.ps1 ide-status          Detect IDE and show recommended activation
    .\wf.ps1 update              Refresh repository, foundation, skills, and optional tools
    .\wf.ps1 context-pack "fix ci noise"  Generate compact handoff summary for token-efficient continuation
    .\wf.ps1 compact-start "fix ci noise" Generate handoff summary and copy compact prompt
    .\wf.ps1 context-metrics 14  Show 14-day context usage summary

"@
}

function Show-IdeStatus {
    Write-Step "IDE Session Detection"
    $detectScript = Join-Path $scriptDir 'detect-ide-session.ps1'
    if (-not (Test-Path $detectScript)) {
        Write-Error "IDE detection script not found: $detectScript"
        exit 1
    }

    $ideDataRaw = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $detectScript -AsJson
    $ideData = $ideDataRaw | ConvertFrom-Json

    Write-Host "IDE: $($ideData.ideName)" -ForegroundColor White
    Write-Host "Confidence: $($ideData.confidence)" -ForegroundColor White
    Write-Host "Session detected: $($ideData.isIdeSession)" -ForegroundColor White
    Write-Host "Activation: $($ideData.recommendedActivationCommand)" -ForegroundColor Cyan
    Write-Host "Session start: $($ideData.recommendedSessionCommand)" -ForegroundColor Cyan
}

# Main execution
switch ($Command) {
    'help' {
        Show-Help
    }
    
    'status' {
        Show-Status
    }

    'start-session' {
        Write-Step "Creating session brief"
        $startScript = Join-Path $scriptDir 'start-session.ps1'
        if (Test-Path $startScript) {
            $startSessionArgs = @()
            if (-not [string]::IsNullOrWhiteSpace($Scope)) { $startSessionArgs += @('-TaskName', $Scope) }
            if ($Force) { $startSessionArgs += '-Force' }
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $startScript @startSessionArgs
        } else {
            Write-Error "Start session script not found: $startScript"
            exit 1
        }
    }

    'task-brief' {
        Write-Step "Creating task brief"
        if ([string]::IsNullOrWhiteSpace($Scope)) {
            Write-Error "Task name required. Example: .\wf.ps1 task-brief auth-flow"
            exit 1
        }

        $startScript = Join-Path $scriptDir 'start-session.ps1'
        if (Test-Path $startScript) {
            $taskBriefArgs = @('-TaskName', $Scope, '-Force')
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $startScript @taskBriefArgs
        } else {
            Write-Error "Start session script not found: $startScript"
            exit 1
        }
    }
    
    'update' {
        Invoke-Update
    }

    'update-all' {
        Invoke-UpdateAll
    }
    
    'review' {
        Write-Step "Code Review - $($Scope.ToUpper())"
        
        # Run security check
        if (-not (Test-Secrets)) {
            Write-Error "Secrets detected - review blocked"
            exit 1
        }
        
        # Run tests
        if (-not $SkipTests) {
            $goPass = Test-GoTests
            $ngPass = Test-AngularTests
            
            if (-not ($goPass -and $ngPass)) {
                Write-Error "Tests failed - review blocked"
                exit 1
            }
        }
        
        Write-Success "Code review complete"
    }
    
    'audit' {
        $outputDir = Join-Path $repoRoot 'docs/audits'
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        $dateStr = Get-Date -Format "yyyy-MM-dd"
        $outputPath = Join-Path $outputDir "$dateStr-audit.md"
        
        New-AuditDocument -OutputPath $outputPath
    }
    
    'pr' {
        if (-not (Get-BranchStatus)) { exit 0 }
        
        Write-Step "Creating Pull Request"
        
        # Run review first
        if (-not $SkipReview) {
            & "$PSCommandPath" review -SkipTests
        }
        
        # Generate PR template
        $prPath = Join-Path $repoRoot '.github/PULL_REQUEST_TEMPLATE.md'
        if (-not (Test-Path (Split-Path $prPath))) {
            New-Item -ItemType Directory -Path (Split-Path $prPath) -Force | Out-Null
        }
        
        New-PRDescription -OutputPath $prPath
        Write-Host ""
        Write-Host "PR template created at: $prPath" -ForegroundColor Cyan
        Write-Host "Edit the template and run: gh pr create" -ForegroundColor Cyan
    }
    
    'push' {
        if (-not (Get-BranchStatus)) { exit 0 }
        
        Write-Step "Pushing Changes"
        
        # Check secrets
        if (-not (Test-Secrets)) {
            Write-Error "Secrets detected - push blocked"
            exit 1
        }
        
        # Run tests
        if (-not $SkipTests) {
            Test-GoTests | Out-Null
            Test-AngularTests | Out-Null
        }
        
        # Generate audit
        & "$PSCommandPath" audit
        
        # Commit and push
        Write-Host ""
        Write-Host "Run the following commands:" -ForegroundColor Cyan
        Write-Host "  git add ." -ForegroundColor Yellow
        Write-Host "  git commit -m 'type(scope): description'" -ForegroundColor Yellow
        Write-Host "  git push" -ForegroundColor Yellow
    }
    
    'health' {
        Write-Step "System Health Check & Tool Activation"
        
        $healthScript = Join-Path $scriptDir 'ensure-tools-active.ps1'
        if (Test-Path $healthScript) {
            $healthArgs = @('-AutoStart')
            if ($Force) { $healthArgs += "-Force" }
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $healthScript @healthArgs
        } else {
            Write-Error "Health check script not found: $healthScript"
            exit 1
        }
    }

    'orchestrator-status' {
        Write-Step "Checking Orchestrator and Engram integration"
        $statusScript = Join-Path $scriptDir 'orchestrator-status.ps1'
        if (Test-Path $statusScript) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $statusScript
        } else {
            Write-Error "Orchestrator status script not found: $statusScript"
            exit 1
        }
    }
    'ide-status' {
        Show-IdeStatus
    }
    'install-engram' {
        Write-Step "Installing or verifying Engram CLI"
        $installScript = Join-Path $scriptDir 'install-engram.ps1'
        if (Test-Path $installScript) {
            $installArgs = @()
            if ($Force) { $installArgs += '-Force' }
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installScript @installArgs
        } else {
            Write-Error "Install script not found: $installScript"
            exit 1
        }
    }
    
    'verify' {
        Write-Step "Quick Stack Verification & Auto-Repair"
        $diagScript = $null
        $diagPaths = @(
            (Join-Path $scriptDir '..\..\diagnostics\system-diagnostics.ps1'),
            (Join-Path $repoRoot 'scripts\diagnostics\system-diagnostics.ps1')
        )
        foreach ($path in $diagPaths) {
            if (Test-Path $path) {
                $diagScript = $path
                break
            }
        }
        if ($diagScript) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $diagScript -AutoRepair -Quiet
            Write-Success "Stack verification and repair completed"
        } else {
            Write-Error "Diagnostics script not found"
            exit 1
        }
    }

    'diagnose' {
        Write-Step "Running Full System Diagnostics"
        # Try multiple paths to find diagnostics script
        $diagPaths = @(
            (Join-Path $scriptDir '..\..\diagnostics\system-diagnostics.ps1'),
            (Join-Path $repoRoot 'scripts\diagnostics\system-diagnostics.ps1')
        )
        $found = $false
        foreach ($path in $diagPaths) {
            if (Test-Path $path) {
                $diagnoseArgs = @()
                if ($JSON) { $diagnoseArgs += '-JSON' }
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $path @diagnoseArgs
                $found = $true
                break
            }
        }
        if (-not $found) {
            Write-Error "Diagnostics script not found"
            exit 1
        }
    }
    
    'migrate-structure' {
        Write-Step "Structure Migration"
        $migrateScript = Join-Path $scriptDir 'migrate-structure.ps1'
        if (-not (Test-Path $migrateScript)) {
            Write-Error "Migration script not found: $migrateScript"
            exit 1
        }
        $migrateArgs = @()
        if ($SkipTests) { $migrateArgs += '-DryRun' }
        if ($Force)     { $migrateArgs += '-Force' }
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $migrateScript @migrateArgs
    }

    'context-pack' {
        Write-Step "Generating Compact Context Pack"
        $contextScript = Join-Path $scriptDir 'context-pack.ps1'
        if (-not (Test-Path $contextScript)) {
            Write-Error "Context pack script not found: $contextScript"
            exit 1
        }

        $contextArgs = @()
        if (-not [string]::IsNullOrWhiteSpace($Scope)) {
            $contextArgs += @('-Objective', $Scope)
        }

        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $contextScript @contextArgs
    }

    'compact-start' {
        Write-Step "Preparing Compact Chat Start"
        $compactScript = Join-Path $scriptDir 'compact-start.ps1'
        if (-not (Test-Path $compactScript)) {
            Write-Error "Compact start script not found: $compactScript"
            exit 1
        }

        $compactArgs = @()
        if (-not [string]::IsNullOrWhiteSpace($Scope)) {
            $compactArgs += @('-Objective', $Scope)
        }

        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $compactScript @compactArgs
    }

    'context-metrics' {
        Write-Step "Context Usage Metrics"
        $metricsScript = Join-Path $scriptDir 'context-metrics-report.ps1'
        if (-not (Test-Path $metricsScript)) {
            Write-Error "Context metrics script not found: $metricsScript"
            exit 1
        }

        $days = 7
        if (-not [string]::IsNullOrWhiteSpace($Scope)) {
            $parsedDays = 0
            if ([int]::TryParse($Scope, [ref]$parsedDays) -and $parsedDays -gt 0) {
                $days = $parsedDays
            }
        }

        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $metricsScript -Days $days
    }
}

exit 0
