# wf.ps1 - Workflow CLI
# Automated development workflow for Gentleman Foundation

param(
    [Parameter(Position=0)]
    [ValidateSet('review', 'audit', 'pr', 'push', 'publish', 'status', 'health', 'update', 'update-all', 'update-tools', 'install-engram', 'orchestrator-status', 'stack-dashboard', 'runtime-route', 'custom-rules-status', 'response-mode', 'ide-status', 'diagnose', 'verify', 'start-session', 'end-session', 'day-end-closure', 'task-brief', 'migrate-structure', 'context-pack', 'compact-start', 'context-metrics', 'token-guard', 'checkpoint', 'list-checkpoints', 'rollback-checkpoint', 'clean-branches', 'homologate', 'agent-alert', 'agent', 'skills', 'dispatch', 'events', 'reset-demo', 'judgment-day', 'help')]
    [string]$Command = 'help',
    
    [Parameter(Position=1)]
    [string]$Scope = '',
    
    [switch]$SkipTests,
    [switch]$SkipReview,
    [switch]$StrictCleanup,
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

function Invoke-LocalPowerShellScript {
    param(
        [string]$ScriptPath,
        [string[]]$ScriptArgs = @()
    )

    & $ScriptPath @ScriptArgs
}

function Invoke-TokenBudgetGuard {
    param(
        [string]$Task,
        [ValidateSet('low', 'medium', 'high')]
        [string]$Risk = 'medium',
        [int]$EstimatedChars = 0
    )

    $guardScript = Join-Path $scriptDir 'token-budget-guard.ps1'
    if (-not (Test-Path $guardScript)) {
        return
    }

    # Guard alerts are non-blocking by default to avoid blocking session completion.
    if ($EstimatedChars -gt 0) {
        & $guardScript -Mode check -Task $Task -Risk $Risk -EstimatedChars $EstimatedChars -Record
    } else {
        & $guardScript -Mode check -Task $Task -Risk $Risk -Record
    }
}

function Get-GitInfo {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $status = git status --porcelain 2>$null
    $hasChanges = $status -and $status.Trim() -ne ''

    $ahead = 0
    $behind = 0
    $upstream = git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>$null
    if ($upstream) {
        $counts = git rev-list --left-right --count "@{upstream}...HEAD" 2>$null
        if ($counts -and $counts -match '^(\d+)\s+(\d+)$') {
            $behind = [int]$matches[1]
            $ahead = [int]$matches[2]
        }
    }
    
    @{
        Branch = $branch
        HasChanges = $hasChanges
        Status = $status
        Ahead = $ahead
        Behind = $behind
    }
}

function Get-TestSuiteStatus {
    $goStatus = if (Test-Path (Join-Path $repoRoot 'go.mod')) { 'AVAILABLE (not run in audit)' } else { 'NOT DETECTED' }

    $webDir = Join-Path $repoRoot 'web'
    $angularStatus = if ((Test-Path $webDir) -and (Test-Path (Join-Path $webDir 'package.json'))) {
        'AVAILABLE (not run in audit)'
    } else {
        'NOT DETECTED'
    }

    return @{
        Go = $goStatus
        Angular = $angularStatus
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

function Resolve-PublishMode {
    param(
        [string]$RequestedMode,
        [switch]$ForceMode
    )

    $normalized = if ($RequestedMode) { $RequestedMode.Trim().ToLowerInvariant() } else { '' }
    switch ($normalized) {
        'pr' { return 'push+pr' }
        'push+pr' { return 'push+pr' }
        'with-pr' { return 'push+pr' }
        'later' { return 'push-only' }
        'push-only' { return 'push-only' }
        'only-push' { return 'push-only' }
    }

    if ($ForceMode) {
        return 'push-only'
    }

    Write-Host "" 
    Write-Host "Choose publish mode:" -ForegroundColor Cyan
    Write-Host "  1) Push changes and open PR now" -ForegroundColor Yellow
    Write-Host "  2) Push changes only (create PR later)" -ForegroundColor Yellow
    $choice = Read-Host "Enter 1 or 2"

    if ($choice -eq '1') {
        return 'push+pr'
    }

    return 'push-only'
}

function Invoke-ScriptGovernanceValidation {
    $validationScript = Join-Path $scriptDir '..\diagnostics\validate-script-governance.ps1'
    if (-not (Test-Path $validationScript)) {
        return @{
            Passed = $true
            Detail = 'validate-script-governance.ps1 not found (skipped)'
            Suggestion = 'Add scripts/diagnostics/validate-script-governance.ps1 to enable governance gate.'
            Fixable = $false
        }
    }

    Write-Step 'Running script governance validation...'
    Invoke-LocalPowerShellScript -ScriptPath $validationScript
    if ($LASTEXITCODE -eq 0) {
        return @{
            Passed = $true
            Detail = 'Script governance validation passed.'
            Suggestion = ''
            Fixable = $false
        }
    }

    return @{
        Passed = $false
        Detail = "Script governance validation failed with exit code $LASTEXITCODE."
        Suggestion = "Run '.\\wf.ps1 homologate apply' and rerun publish."
        Fixable = $true
    }
}

function Get-GitFlowBaseForBranch {
    param([string]$Branch)

    if ($Branch -match '^(feature|bugfix|chore)/.+') {
        return 'develop'
    }

    if ($Branch -match '^(hotfix|release)/.+') {
        return 'main'
    }

    if ($Branch -eq 'develop') {
        return 'develop'
    }

    return 'main'
}

function Invoke-GitFlowValidation {
    param(
        [switch]$EnforcePrBase,
        [string]$PrBase
    )

    $gitflowScript = Join-Path $scriptDir '..\diagnostics\validate-gitflow.ps1'
    if (-not (Test-Path $gitflowScript)) {
        return @{
            Passed = $true
            Detail = 'validate-gitflow.ps1 not found (skipped)'
            Suggestion = 'Add scripts/diagnostics/validate-gitflow.ps1 to enforce GitFlow gates.'
            Fixable = $false
        }
    }

    $gitflowArgs = @()
    if ($EnforcePrBase) {
        $gitflowArgs += '-EnforcePrBase'
        if (-not [string]::IsNullOrWhiteSpace($PrBase)) {
            $gitflowArgs += @('-PrBase', $PrBase)
        }
    }

    Write-Step 'Running GitFlow policy validation...'
    Invoke-LocalPowerShellScript -ScriptPath $gitflowScript -ScriptArgs $gitflowArgs
    if ($LASTEXITCODE -eq 0) {
        return @{
            Passed = $true
            Detail = 'GitFlow policy validation passed.'
            Suggestion = ''
            Fixable = $false
        }
    }

    return @{
        Passed = $false
        Detail = "GitFlow policy validation failed with exit code $LASTEXITCODE."
        Suggestion = 'Use a valid branch type and PR base per GitFlow policy.'
        Fixable = $false
    }
}

function Ensure-PublishCommit {
    $gitInfo = Get-GitInfo
    if (-not $gitInfo.HasChanges) {
        return $true
    }

    $defaultMessage = 'chore(publish): apply validated release changes'
    $message = Read-Host "Detected uncommitted changes. Enter commit message or press Enter for default [$defaultMessage]"
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = $defaultMessage
    }

    git add .
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'git add failed.'
        return $false
    }

    git commit -m $message
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'git commit failed.'
        return $false
    }

    Write-Success 'Pending changes committed.'
    return $true
}

function Ensure-PullRequest {
    param([string]$Branch)

    $targetBase = Get-GitFlowBaseForBranch -Branch $Branch

    $existingJson = gh pr view --head $Branch --json number,url,state,baseRefName 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($existingJson)) {
        try {
            $existingPr = ($existingJson | ConvertFrom-Json)
            if ($existingPr.baseRefName -ne $targetBase) {
                Write-Error "Existing PR base '$($existingPr.baseRefName)' does not match GitFlow target '$targetBase'."
                return $null
            }
            return $existingPr
        } catch {
        }
    }

    $prPath = Join-Path $repoRoot '.github/PULL_REQUEST_TEMPLATE.md'
    if (-not (Test-Path (Split-Path $prPath))) {
        New-Item -ItemType Directory -Path (Split-Path $prPath) -Force | Out-Null
    }
    if (-not (Test-Path $prPath)) {
        New-PRDescription -OutputPath $prPath
    }

    $title = (git log -1 --pretty=%s 2>$null)
    if ([string]::IsNullOrWhiteSpace($title)) {
        $title = 'chore(publish): automated publish flow'
    }

    gh pr create --base $targetBase --head $Branch --title $title --body-file $prPath | Out-Null
    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    $createdJson = gh pr view --head $Branch --json number,url,state,baseRefName 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($createdJson)) {
        return $null
    }

    try {
        return ($createdJson | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Write-PublishDecisionLog {
    param(
        [string]$Decision,
        [array]$Findings,
        [array]$Actions,
        [string]$Notes = ''
    )

    $sessionsDir = Join-Path $repoRoot 'docs/sessions'
    if (-not (Test-Path $sessionsDir)) {
        New-Item -ItemType Directory -Path $sessionsDir -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
    $filePath = Join-Path $sessionsDir "$timestamp-publish-decision.md"
    $branch = git rev-parse --abbrev-ref HEAD 2>$null

    $findingsLines = if ($Findings -and $Findings.Count -gt 0) {
        ($Findings | ForEach-Object { "- [$($_.Severity)] $($_.Code): $($_.Detail) | Suggestion: $($_.Suggestion)" }) -join [Environment]::NewLine
    } else {
        '- None'
    }

    $actionLines = if ($Actions -and $Actions.Count -gt 0) {
        ($Actions | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    } else {
        '- None'
    }

    $content = @"
# Publish Decision Log

- Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")
- Repository: $(Split-Path $repoRoot -Leaf)
- Branch: $branch
- Decision: $Decision

## Findings
$findingsLines

## Actions Taken
$actionLines

## Notes
$Notes
"@

    $content | Out-File -FilePath $filePath -Encoding UTF8
    Write-Success "Publish decision documented: $filePath"
}

function Invoke-AutomaticSuggestions {
    param([array]$Findings)

    $actions = @()
    $hasGovernanceFinding = $Findings | Where-Object { $_.Code -eq 'governance' -and $_.Fixable }
    if ($hasGovernanceFinding) {
        $homologateScript = Join-Path $scriptDir '..\validation\homologate-workspace.ps1'
        if (Test-Path $homologateScript) {
            Write-Step 'Applying homologation suggestions...'
            Invoke-LocalPowerShellScript -ScriptPath $homologateScript -ScriptArgs @('-Apply')
            if ($LASTEXITCODE -eq 0) {
                $actions += 'Applied homologation fixes via homologate-workspace.ps1 -Apply.'
            } else {
                $actions += "Homologation apply failed with exit code $LASTEXITCODE."
            }
        }
    }

    return $actions
}

function Invoke-PublishWorkflow {
    param(
        [switch]$SkipReviewGate,
        [switch]$SkipTestsGate,
        [switch]$ForceMode
    )

    if (-not (Get-BranchStatus)) {
        return
    }

    Warn-OldWorkflowCheckpoints -ThresholdDays 7

    $attempt = 1
    while ($attempt -le 2) {
        Write-Step "Publish validation attempt $attempt/2"
        $findings = @()
        $actions = @()

        if (-not $SkipReviewGate) {
            if (-not (Test-Secrets)) {
                $findings += [pscustomobject]@{
                    Code = 'secrets'
                    Severity = 'CRITICAL'
                    Detail = 'Secrets scan failed.'
                    Suggestion = 'Remove secrets from staged changes and rotate compromised credentials.'
                    Fixable = $false
                }
            }
        }

        if (-not $SkipTestsGate) {
            if (-not (Test-GoTests)) {
                $findings += [pscustomobject]@{
                    Code = 'go-tests'
                    Severity = 'HIGH'
                    Detail = 'Go test suite failed.'
                    Suggestion = 'Fix failing tests before merging.'
                    Fixable = $false
                }
            }

            if (-not (Test-AngularTests)) {
                $findings += [pscustomobject]@{
                    Code = 'angular-tests'
                    Severity = 'HIGH'
                    Detail = 'Angular test suite failed.'
                    Suggestion = 'Fix failing frontend tests before merging.'
                    Fixable = $false
                }
            }
        }

        $gitInfo = Get-GitInfo
        $targetBase = Get-GitFlowBaseForBranch -Branch $gitInfo.Branch
        $gitflow = Invoke-GitFlowValidation -EnforcePrBase -PrBase $targetBase
        if (-not $gitflow.Passed) {
            $findings += [pscustomobject]@{
                Code = 'gitflow'
                Severity = 'HIGH'
                Detail = $gitflow.Detail
                Suggestion = $gitflow.Suggestion
                Fixable = $gitflow.Fixable
            }
        }

        $governance = Invoke-ScriptGovernanceValidation
        if (-not $governance.Passed) {
            $findings += [pscustomobject]@{
                Code = 'governance'
                Severity = 'HIGH'
                Detail = $governance.Detail
                Suggestion = $governance.Suggestion
                Fixable = $governance.Fixable
            }
        }

        & "$PSCommandPath" audit
        if ($LASTEXITCODE -eq 0) {
            $actions += 'Generated audit document via wf.ps1 audit.'
        }

        if ($findings.Count -eq 0) {
            Write-Success 'All validations passed. Proceeding with automatic PR creation and merge authorization.'

            if (-not (Ensure-PublishCommit)) {
                Write-PublishDecisionLog -Decision 'blocked-commit-failed' -Findings $findings -Actions $actions -Notes 'Commit step failed.'
                return
            }

            $gitInfo = Get-GitInfo
            $branch = $gitInfo.Branch
            git push -u origin $branch
            if ($LASTEXITCODE -ne 0) {
                Write-Error 'Branch push failed.'
                Write-PublishDecisionLog -Decision 'blocked-push-failed' -Findings $findings -Actions $actions -Notes 'Could not push branch to origin.'
                return
            }
            $actions += "Pushed branch to origin: $branch"

            $pr = Ensure-PullRequest -Branch $branch
            if (-not $pr) {
                Write-Error 'PR creation or retrieval failed.'
                Write-PublishDecisionLog -Decision 'blocked-pr-failed' -Findings $findings -Actions $actions -Notes 'Unable to create or retrieve PR.'
                return
            }
            $actions += "PR ready: $($pr.url)"

            gh pr merge $($pr.number) --squash --delete-branch
            if ($LASTEXITCODE -eq 0) {
                $actions += "Merged PR #$($pr.number) with squash merge."
                Write-Success "PR merged successfully: $($pr.url)"
                Write-PublishDecisionLog -Decision 'auto-merged-after-clean-validation' -Findings $findings -Actions $actions -Notes 'Merge authorized automatically because no alerts were detected.'
            } else {
                $actions += "Automatic merge failed for PR #$($pr.number)."
                Write-Warning 'Automatic merge failed (likely branch protection or required checks).'
                Write-PublishDecisionLog -Decision 'merge-blocked-after-clean-validation' -Findings $findings -Actions $actions -Notes 'Validations passed but merge command did not complete.'
            }

            return
        }

        Write-Warning 'Validation alerts detected. Summary:'
        $findings | ForEach-Object {
            Write-Host " - [$($_.Severity)] $($_.Code): $($_.Detail)" -ForegroundColor Yellow
            Write-Host "   Suggestion: $($_.Suggestion)" -ForegroundColor Yellow
        }

        $apply = Read-Host 'Apply automatic suggestions and retry publish? (yes/no)'
        if ($apply -match '^(y|yes|si|s)$') {
            $applied = Invoke-AutomaticSuggestions -Findings $findings
            $actions += $applied
            Write-PublishDecisionLog -Decision 'alerts-detected-auto-fix-requested' -Findings $findings -Actions $actions -Notes 'Developer accepted auto-suggestions and rerun.'
            $attempt++
            continue
        }

        $confirm = Read-Host 'Do you confirm merge with detected gaps and developer responsibility? (yes/no)'
        if ($confirm -match '^(y|yes|si|s)$') {
            if (-not (Ensure-PublishCommit)) {
                Write-PublishDecisionLog -Decision 'override-requested-but-commit-failed' -Findings $findings -Actions $actions -Notes 'Developer accepted risks but commit failed.'
                return
            }

            $gitInfo = Get-GitInfo
            $branch = $gitInfo.Branch
            git push -u origin $branch
            if ($LASTEXITCODE -eq 0) {
                $actions += "Pushed branch to origin: $branch"
            }

            $pr = Ensure-PullRequest -Branch $branch
            if ($pr) {
                $actions += "PR ready: $($pr.url)"
                gh pr merge $($pr.number) --squash --delete-branch
                if ($LASTEXITCODE -eq 0) {
                    $actions += "Merged PR #$($pr.number) by developer override."
                } else {
                    $actions += "Developer override merge attempt failed for PR #$($pr.number)."
                }
            }

            Write-PublishDecisionLog -Decision 'developer-override-accepted-risks' -Findings $findings -Actions $actions -Notes 'Developer accepted full responsibility for detected gaps before merge attempt.'
            return
        }

        Write-PublishDecisionLog -Decision 'blocked-awaiting-remediation' -Findings $findings -Actions $actions -Notes 'Developer declined auto-fixes and merge override.'
        return
    }

    Write-Warning 'Publish stopped after automatic suggestion retry with remaining alerts.'
}

function Invoke-Update {
    Write-Step "Updating repository, foundation, skills, and tools"

    $updateScript = Join-Path $scriptDir '..\validation\update-all.ps1'
    if (Test-Path $updateScript) {
        Invoke-LocalPowerShellScript -ScriptPath $updateScript -ScriptArgs @('-All', '-Force')
        if ($LASTEXITCODE -ne 0) { Write-Warning "Foundation update returned exit $LASTEXITCODE" }
    } else {
        Write-Warning "update-all.ps1 not found - skipping foundation update"
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

function Get-ContextEfficiencyPolicy {
    $defaults = @{
        ProfileName = 'default'
        WindowDays = 7
        PromptYellowMax = 1200
        PromptRedMax = 1800
        AdoptionYellowMin = 70
        AdoptionRedMin = 40
    }

    $policyPath = Join-Path $repoRoot 'config/context-efficiency.json'
    if (-not (Test-Path $policyPath)) {
        return $defaults
    }

    try {
        $policy = Get-Content -Path $policyPath -Raw | ConvertFrom-Json
        $source = $policy

        if ($policy.profiles) {
            $requestedProfile = if ($policy.activeProfile) { [string]$policy.activeProfile } else { 'default' }
            $availableProfiles = @($policy.profiles.PSObject.Properties.Name)
            if ($availableProfiles -contains $requestedProfile) {
                $source = $policy.profiles.$requestedProfile
                $defaults.ProfileName = $requestedProfile
            } elseif ($availableProfiles -contains 'default') {
                $source = $policy.profiles.default
                $defaults.ProfileName = 'default'
            }
        }

        if ($null -ne $source.windowDays) { $defaults.WindowDays = [int]$source.windowDays }
        if ($source.promptChars -and $null -ne $source.promptChars.yellowMax) { $defaults.PromptYellowMax = [int]$source.promptChars.yellowMax }
        if ($source.promptChars -and $null -ne $source.promptChars.redMax) { $defaults.PromptRedMax = [int]$source.promptChars.redMax }
        if ($source.adoptionPercent -and $null -ne $source.adoptionPercent.yellowMin) { $defaults.AdoptionYellowMin = [int]$source.adoptionPercent.yellowMin }
        if ($source.adoptionPercent -and $null -ne $source.adoptionPercent.redMin) { $defaults.AdoptionRedMin = [int]$source.adoptionPercent.redMin }
    } catch {
        Write-Warning "Invalid context efficiency policy; using defaults."
    }

    return $defaults
}

function Get-ContextLiveAssistPolicy {
    $defaults = @{
        Enabled = $true
        ShowOnCommands = @('status', 'health', 'start-session', 'end-session', 'day-end-closure', 'review', 'audit', 'publish')
        AutoRunOnStartSessionWhenRed = $false
    }

    $policyPath = Join-Path $repoRoot 'config/context-efficiency.json'
    if (-not (Test-Path $policyPath)) {
        return $defaults
    }

    try {
        $policy = Get-Content -Path $policyPath -Raw | ConvertFrom-Json
        if ($policy.liveAssist) {
            if ($null -ne $policy.liveAssist.enabled) {
                $defaults.Enabled = [bool]$policy.liveAssist.enabled
            }
            if ($policy.liveAssist.showOnCommands) {
                $defaults.ShowOnCommands = @($policy.liveAssist.showOnCommands | ForEach-Object { [string]$_ })
            }
            if ($null -ne $policy.liveAssist.autoRunOnStartSessionWhenRed) {
                $defaults.AutoRunOnStartSessionWhenRed = [bool]$policy.liveAssist.autoRunOnStartSessionWhenRed
            }
        }
    } catch {
        Write-Warning 'Invalid context live-assist policy; using defaults.'
    }

    return $defaults
}

function Get-ContextMetricsSnapshot {
    param([int]$Days = 7)

    $policy = Get-ContextEfficiencyPolicy
    if (-not $Days -or $Days -le 0) {
        $Days = $policy.WindowDays
    }

    $metricsPath = Join-Path $repoRoot 'docs/sessions/metrics/context-usage.csv'
    if (-not (Test-Path $metricsPath)) {
        return @{
            HealthStatus = 'WARN (no data)'
            Recommendation = 'Adopt compact-start in daily handoffs to start collecting baseline data.'
            WindowDays = $Days
            TotalEvents = 0
            ContextPackCount = 0
            CompactStartCount = 0
            AdoptionPercent = 0
            AvgObjectiveChars = 0
            AvgPromptChars = 0
            HasData = $false
            Lines = @(
                '| Metric | Value |',
                '|---|---|',
                "| Policy profile | $($policy.ProfileName) |",
                "| Thresholds (prompt/adoption) | Y: <=$($policy.PromptYellowMax) & >=$($policy.AdoptionYellowMin)% ; R: <=$($policy.PromptRedMax) & >=$($policy.AdoptionRedMin)% |",
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
            WindowDays = $Days
            TotalEvents = 0
            ContextPackCount = 0
            CompactStartCount = 0
            AdoptionPercent = 0
            AvgObjectiveChars = 0
            AvgPromptChars = 0
            HasData = $false
            Lines = @(
                '| Metric | Value |',
                '|---|---|',
                "| Policy profile | $($policy.ProfileName) |",
                "| Thresholds (prompt/adoption) | Y: <=$($policy.PromptYellowMax) & >=$($policy.AdoptionYellowMin)% ; R: <=$($policy.PromptRedMax) & >=$($policy.AdoptionRedMin)% |",
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
    if ($avgPrompt -gt $policy.PromptRedMax -or $adoption -lt $policy.AdoptionRedMin) {
        $healthStatus = 'RED'
    } elseif ($avgPrompt -gt $policy.PromptYellowMax -or $adoption -lt $policy.AdoptionYellowMin) {
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
        WindowDays = $Days
        TotalEvents = $total
        ContextPackCount = $pack
        CompactStartCount = $compact
        AdoptionPercent = $adoption
        AvgObjectiveChars = $avgObjective
        AvgPromptChars = $avgPrompt
        HasData = $true
        Lines = @(
            '| Metric | Value |',
            '|---|---|',
            "| Policy profile | $($policy.ProfileName) |",
            "| Thresholds (prompt/adoption) | Y: <=$($policy.PromptYellowMax) & >=$($policy.AdoptionYellowMin)% ; R: <=$($policy.PromptRedMax) & >=$($policy.AdoptionRedMin)% |",
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

function Invoke-ContextEfficiencyLiveAssist {
    param(
        [string]$CommandName,
        [string]$Objective = ''
    )

    $livePolicy = Get-ContextLiveAssistPolicy
    if (-not $livePolicy.Enabled) {
        return
    }

    $normalized = if ($CommandName) { $CommandName.Trim().ToLowerInvariant() } else { '' }
    if (-not $normalized) {
        return
    }

    if (@('help', 'context-pack', 'compact-start', 'context-metrics') -contains $normalized) {
        return
    }

    $allowedCommands = @($livePolicy.ShowOnCommands | ForEach-Object { [string]$_ })
    if ($allowedCommands.Count -gt 0 -and ($allowedCommands -notcontains $normalized)) {
        return
    }

    $metrics = Get-ContextMetricsSnapshot -Days 7
    $needsNudge = ($metrics.HealthStatus -like 'RED*') -or ($metrics.HealthStatus -like 'YELLOW*') -or ($metrics.HealthStatus -like 'WARN*')
    if (-not $needsNudge) {
        return
    }

    Write-Host ''
    Write-Host '[Context Efficiency]' -ForegroundColor Yellow
    Write-Host "  Status: $($metrics.HealthStatus)" -ForegroundColor Yellow
    Write-Host "  Window: last $($metrics.WindowDays) days | adoption: $($metrics.AdoptionPercent)% | avg prompt chars: $($metrics.AvgPromptChars)" -ForegroundColor Yellow
    Write-Host "  Recommendation: $($metrics.Recommendation)" -ForegroundColor Yellow
    Write-Host '  Suggested action now:' -ForegroundColor Cyan
    Write-Host '    .\scripts\utilities\wf.ps1 compact-start "one-sentence objective"' -ForegroundColor Cyan

    if ($livePolicy.AutoRunOnStartSessionWhenRed -and $normalized -eq 'start-session' -and ($metrics.HealthStatus -like 'RED*')) {
        $compactScript = Join-Path $scriptDir 'compact-start.ps1'
        if (Test-Path $compactScript) {
            $autoObjective = if ([string]::IsNullOrWhiteSpace($Objective)) {
                "resume $((Get-GitInfo).Branch) work"
            } else {
                $Objective
            }

            Write-Host '  Auto action: running compact-start before session brief...' -ForegroundColor Cyan
            & $compactScript -Objective $autoObjective | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success 'Auto compact-start completed.'
            } else {
                Write-Warning 'Auto compact-start failed; continue manually with wf.ps1 compact-start.'
            }
        }
    }
}

function New-AuditDocument {
    param([string]$OutputPath)
    
    Write-Step "Generating Audit Document..."
    
    $gitInfo = Get-GitInfo
    $date = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    $commits = Get-CommitHistory -Count 10
    $commitArray = @($commits)
    $commitLines = if ($commits) {
        ($commitArray | ForEach-Object { "- $_" }) -join [Environment]::NewLine
    } else {
        '- none'
    }

    $summaryText = if ($commitArray.Count -gt 0) {
        "Latest change: $($commitArray[0])"
    } else {
        'No recent commits detected in this branch.'
    }

    $deliveryStatus = if ($gitInfo.HasChanges) { 'IN PROGRESS' } else { 'READY' }
    $deliveryNote = if ($gitInfo.HasChanges) {
        'Working tree has pending changes; finalize commit before PR cut.'
    } else {
        'Working tree clean; branch is ready for review handoff.'
    }

    $operationalRiskStatus = 'LOW'
    $operationalRiskNote = 'No divergence from upstream and no local pending changes.'
    if ($gitInfo.Behind -gt 0) {
        $operationalRiskStatus = 'HIGH'
        $operationalRiskNote = "Branch is behind upstream by $($gitInfo.Behind) commit(s); rebase or merge before release."
    } elseif ($gitInfo.HasChanges -or $gitInfo.Ahead -gt 0) {
        $operationalRiskStatus = 'MEDIUM'
        $operationalRiskNote = "Ahead: $($gitInfo.Ahead), pending changes: $($gitInfo.HasChanges). Validate and publish intentionally."
    }

    $tests = Get-TestSuiteStatus
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
$summaryText

## Executive Overview

| Area | Status | Notes |
|---|---|---|
| Delivery | $deliveryStatus | $deliveryNote |
| Operational Risk | $operationalRiskStatus | $operationalRiskNote |
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
| Go | $($tests.Go) |
| Angular | $($tests.Angular) |

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

- Status: Baseline governance and context-efficiency controls are active.
- Notes: Use task-brief + audit output as implementation contract for next slice.

## Next Steps

- [ ] Run `wf.ps1 review` before release cut
- [ ] Confirm audit + governance outputs in PR description

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
    $checkpointCount = 0
    $oldCheckpointCount = 0

    if (Assert-GitRepository) {
        $checkpointCount = (Get-WorkflowCheckpoints).Count
        $oldCheckpointCount = (Get-OldWorkflowCheckpoints -ThresholdDays 7).Count
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Project Status" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Branch: $($gitInfo.Branch)"
    Write-Host "Has Changes: $($gitInfo.HasChanges)"
    Write-Host "Workflow checkpoints: $checkpointCount"
    if ($oldCheckpointCount -gt 0) {
        Write-Warning "$oldCheckpointCount checkpoint(s) older than 7 days"
    }
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

function Assert-GitRepository {
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Current directory is not a git repository."
        return $false
    }

    return $true
}

function Get-WorkflowCheckpoints {
    $lines = git stash list 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $lines) {
        return @()
    }

    return @($lines | Where-Object { $_ -match 'wf-checkpoint:' })
}

function Get-WorkflowCheckpointRefs {
    $checkpoints = Get-WorkflowCheckpoints
    if (-not $checkpoints -or $checkpoints.Count -eq 0) {
        return @()
    }

    $refs = @()
    foreach ($entry in $checkpoints) {
        if ($entry -match '^(stash@\{\d+\})') {
            $refs += $matches[1]
        }
    }

    return $refs
}

function Get-OldWorkflowCheckpoints {
    param([int]$ThresholdDays = 7)

    $refs = Get-WorkflowCheckpointRefs
    if (-not $refs -or $refs.Count -eq 0) {
        return @()
    }

    $cutoff = (Get-Date).AddDays(-1 * $ThresholdDays)
    $oldRefs = @()
    foreach ($ref in $refs) {
        $dateRaw = git show -s --format=%cI $ref 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($dateRaw)) {
            continue
        }

        [DateTimeOffset]$parsedDate = [DateTimeOffset]::MinValue
        if ([DateTimeOffset]::TryParse([string]$dateRaw, [ref]$parsedDate)) {
            if ($parsedDate.LocalDateTime -lt $cutoff) {
                $oldRefs += $ref
            }
        }
    }

    return $oldRefs
}

function Warn-OldWorkflowCheckpoints {
    param([int]$ThresholdDays = 7)

    if (-not (Assert-GitRepository)) {
        return
    }

    $oldRefs = Get-OldWorkflowCheckpoints -ThresholdDays $ThresholdDays
    if ($oldRefs.Count -gt 0) {
        Write-Warning "Found $($oldRefs.Count) workflow checkpoint(s) older than $ThresholdDays days. Review with '.\scripts\utilities\wf.ps1 list-checkpoints'."
        Write-Host "Tip: drop stale checkpoints with 'git stash drop <stash@{n}>'" -ForegroundColor Cyan
    }
}

function Invoke-LiveCheckpoint {
    param([string]$Label)

    if (-not (Assert-GitRepository)) {
        exit 1
    }

    $status = git status --porcelain 2>$null
    if (-not $status -or [string]::IsNullOrWhiteSpace(($status -join ''))) {
        Write-Warning "No local changes detected. Nothing to checkpoint."
        return
    }

    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $branchTag = (($branch -replace '[^a-zA-Z0-9\-/_]', '') -replace '[/_]+', '-').ToLowerInvariant()
    $rawLabel = if ([string]::IsNullOrWhiteSpace($Label)) {
        Write-Warning "No checkpoint label provided. Convention is '<scope>-<objective>' (example: feature-mcp-cleanup)."
        "$branchTag-snapshot"
    } else {
        $Label
    }

    $safeLabel = (($rawLabel -replace '\s+', '-') -replace '[^a-zA-Z0-9\-]', '').ToLowerInvariant().Trim('-')
    if ([string]::IsNullOrWhiteSpace($safeLabel)) {
        $safeLabel = "$branchTag-snapshot"
    }
    if ($safeLabel -notmatch '^[a-z0-9]+-[a-z0-9][a-z0-9-]*$') {
        $safeLabel = "$branchTag-$safeLabel".Trim('-')
        Write-Warning "Normalized checkpoint label to '$safeLabel' (expected '<scope>-<objective>')."
    }

    $stashMessage = "wf-checkpoint:{0}:{1}:{2}" -f $branch, $safeLabel, $timestamp
    git stash push -u -m $stashMessage | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create checkpoint stash."
        exit 1
    }

    Write-Success "Checkpoint created: $stashMessage"
    Write-Host "Restore latest checkpoint with: .\scripts\utilities\wf.ps1 rollback-checkpoint" -ForegroundColor Cyan
    Write-Host "List checkpoints with: .\scripts\utilities\wf.ps1 list-checkpoints" -ForegroundColor Cyan
}

function Show-LiveCheckpoints {
    if (-not (Assert-GitRepository)) {
        exit 1
    }

    $checkpoints = Get-WorkflowCheckpoints
    if (-not $checkpoints -or $checkpoints.Count -eq 0) {
        Write-Warning "No workflow checkpoints found."
        return
    }

    Write-Step "Available workflow checkpoints"
    foreach ($entry in $checkpoints) {
        Write-Host "  $entry"
    }
}

function Resolve-CheckpointReference {
    param([string]$Selector)

    $checkpoints = Get-WorkflowCheckpoints
    if (-not $checkpoints -or $checkpoints.Count -eq 0) {
        return $null
    }

    if ([string]::IsNullOrWhiteSpace($Selector)) {
        if ($checkpoints[0] -match '^(stash@\{\d+\})') {
            return $matches[1]
        }
        return $null
    }

    if ($Selector -match '^stash@\{\d+\}$') {
        return $Selector
    }

    $match = $checkpoints | Where-Object { $_ -like "*$Selector*" } | Select-Object -First 1
    if ($match -and $match -match '^(stash@\{\d+\})') {
        return $matches[1]
    }

    return $null
}

function Invoke-RollbackCheckpoint {
    param([string]$Selector)

    if (-not (Assert-GitRepository)) {
        exit 1
    }

    $stashRef = Resolve-CheckpointReference -Selector $Selector
    if ([string]::IsNullOrWhiteSpace($stashRef)) {
        Write-Error "No matching workflow checkpoint found. Use '.\scripts\utilities\wf.ps1 list-checkpoints'."
        exit 1
    }

    git stash pop $stashRef
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Checkpoint apply reported conflicts. Resolve them and continue."
        exit 1
    }

    Write-Success "Checkpoint restored from $stashRef"
}

function Invoke-CleanBranches {
    param([switch]$ApplyNow)

    if (-not (Assert-GitRepository)) {
        exit 1
    }

    git fetch origin 2>$null | Out-Null

    $currentBranch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
    $mergedDevelop = @(git branch --merged origin/develop 2>$null)
    $mergedMain = @(git branch --merged origin/main 2>$null)

    $allMerged = @($mergedDevelop + $mergedMain) |
        ForEach-Object { $_.Replace('*', '').Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique

    $candidates = $allMerged |
        Where-Object { $_ -match '^(feature|bugfix|release|chore)/' } |
        Where-Object { $_ -ne $currentBranch }

    if (-not $candidates -or $candidates.Count -eq 0) {
        Write-Success 'No merged feature/bugfix/release/chore branches to clean.'
        return
    }

    Write-Step 'Merged local branches eligible for cleanup'
    foreach ($branch in $candidates) {
        Write-Host "  $branch"
    }

    if (-not $ApplyNow) {
        Write-Host "Preview mode only. Use '.\scripts\utilities\wf.ps1 clean-branches apply' to delete listed local branches." -ForegroundColor Cyan
        return
    }

    if (-not $Force) {
        $confirm = Read-Host "Delete these local branches now? (yes/no)"
        if ($confirm -notmatch '^(y|yes|si|s)$') {
            Write-Warning 'Branch cleanup cancelled.'
            return
        }
    }

    foreach ($branch in $candidates) {
        git branch -d $branch 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Deleted local branch: $branch"
            continue
        }

        if ($Force) {
            git branch -D $branch 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Force-deleted local branch: $branch"
            } else {
                Write-Warning "Could not delete branch: $branch"
            }
        } else {
            Write-Warning "Could not delete branch with -d: $branch (use -Force to allow -D)"
        }
    }
}

function Show-Help {
    Write-Host @"
Gentleman Foundation Workflow CLI
================================

USAGE:
    .\scripts\utilities\wf.ps1 <command> [options]

COMMANDS:
    review [scope]       Run code review (security, quality, all, judgment-day)
    audit                Generate audit document
    pr                   Create PR with template
    push [pr|later]      Prepare publish flow; choose push+PR now or push-only
    publish              Full PR workflow: validate, document, decide, and merge
    status               Show current status
    start-session [task]   Create a session brief and optional task brief
    end-session [task]     Run session closure checks and create delivery closure artifact
    day-end-closure        Automated daily closure: delivery closure + workspace validation + Engram memory capture
    task-brief <task>      Create or refresh a task brief only
    judgment-day          Run dual-review adversarial protocol (pre-merge validation)
    health               Check system health & activate tools
    install-engram       Install or verify Engram CLI availability
    orchestrator-status  Validate orchestrator and Engram integration
    stack-dashboard      Show one-shot stack health, token risk, and next action recommendation
    runtime-route        Resolve runtime mode (AI/Hybrid/Offline) and delegation strategy
    custom-rules-status  Show custom technical/business/review rule loading status
    response-mode [arg]  Show/set language, detail, profile, chat level, presets, and recommendation
    ide-status           Detect IDE session and suggest activation command
    diagnose             Full system diagnostics report
    verify               Quick stack verification & auto-repair
    update               Update repository, foundation, skills, and tools
    update-all           Alias for update
    update-tools         Update toolchain (required + optional integrations)
    migrate-structure    Preflight and guided migration of loose scripts
    context-pack [goal]  Generate compact context summary for new chat thread
    compact-start [goal] Generate context pack and copy compact continuation prompt
    context-metrics [days] Show context/token usage metrics from local logs
    token-guard [task]   Check token budget thresholds and continuity alternatives (Engram-aware)
    checkpoint [label]   Save a live rollback point (git stash -u) before risky edits
    list-checkpoints     List workflow-created checkpoints
    rollback-checkpoint [selector] Restore latest checkpoint or one matching selector
    clean-branches [apply] Preview or clean merged local feature/release branches
    homologate [apply]  Normalize docs/artifacts and update references (dry-run default)
    agent-alert [strict] Check process-compliance signals for off-process AI activity
    agent <AGENT> [TASK] Route task to specialized sub-agent (BA|SAD|DEV|QA|OPS|GOV|DOC)
    help                 Show this help

OPTIONS:
    -SkipTests        Skip test execution
    -SkipReview       Skip code review
    -StrictCleanup    Fail if homologation drift is detected (CI-oriented)
    -Force            Proceed without confirmation
    -JSON             Output diagnostics in JSON format (diagnose command)

EXAMPLES:
    .\scripts\utilities\wf.ps1 review              Run full code review
    .\scripts\utilities\wf.ps1 review security     Run security scan only
    .\scripts\utilities\wf.ps1 review judgment-day Run dual-review adversarial protocol
    .\scripts\utilities\wf.ps1 judgment-day       Run judgment day directly
    .\scripts\utilities\wf.ps1 audit              Generate audit document
    .\scripts\utilities\wf.ps1 pr                 Create PR
    .\scripts\utilities\wf.ps1 push               Commit and push
    .\scripts\utilities\wf.ps1 push pr            Push and open PR now
    .\scripts\utilities\wf.ps1 push later         Push only and create PR later
    .\scripts\utilities\wf.ps1 publish            Run end-to-end PR flow with auto-merge on clean validation
    .\scripts\utilities\wf.ps1 start-session      Create the session brief for today
    .\scripts\utilities\wf.ps1 end-session        Run end-of-session checks and create closure artifact
    .\scripts\utilities\wf.ps1 task-brief auth    Create a task brief for auth work
    .\scripts\utilities\wf.ps1 diagnose            Full diagnostics report (JSON available)
    .\scripts\utilities\wf.ps1 diagnose -JSON      Full diagnostics report in JSON format
    .\scripts\utilities\wf.ps1 verify              Quick verify & auto-repair if needed
    .\scripts\utilities\wf.ps1 health              Check system health & activate tools
    .\scripts\utilities\wf.ps1 install-engram      Install or verify Engram CLI
    .\scripts\utilities\wf.ps1 stack-dashboard     One-shot operational dashboard (health + token risk + action)
    .\scripts\utilities\wf.ps1 stack-dashboard strict  Fail with non-zero exit when executive traffic light is RED
    .\scripts\utilities\wf.ps1 runtime-route        Resolve runtime mode and recommended fallback actions
    .\scripts\utilities\wf.ps1 runtime-route -JSON  Emit machine-readable runtime mode data
    .\scripts\utilities\wf.ps1 custom-rules-status Show loaded custom rule scopes and files
    .\scripts\utilities\wf.ps1 response-mode                Show active communication settings
    .\scripts\utilities\wf.ps1 response-mode list           List language/detail/profile options
    .\scripts\utilities\wf.ps1 response-mode profile:ultra  Set compression profile
    .\scripts\utilities\wf.ps1 response-mode chat:chat-compact Set chat level bundle
    .\scripts\utilities\wf.ps1 response-mode language:pt-BR Set communication language
    .\scripts\utilities\wf.ps1 response-mode detail:expanded Set detail level
    .\scripts\utilities\wf.ps1 response-mode preset:bugfix Apply preset for task type
    .\scripts\utilities\wf.ps1 response-mode recommend:docs:high Recommend mode for preset+risk
    .\scripts\utilities\wf.ps1 ide-status          Detect IDE and show recommended activation
    .\scripts\utilities\wf.ps1 update              Refresh repository, foundation, skills, and optional tools
    .\scripts\utilities\wf.ps1 update-tools         Update required tools and optional integrations
    .\scripts\utilities\wf.ps1 context-pack "fix ci noise"  Generate compact handoff summary for token-efficient continuation
    .\scripts\utilities\wf.ps1 compact-start "fix ci noise" Generate handoff summary and copy compact prompt
    .\scripts\utilities\wf.ps1 context-metrics 14  Show 14-day context usage summary
    .\scripts\utilities\wf.ps1 token-guard         Show token budget status for current session
    .\scripts\utilities\wf.ps1 token-guard publish Check token budget for publish-level workflow
    .\scripts\utilities\wf.ps1 checkpoint feature-doc-cleanup  Save rollback point including untracked files
    .\scripts\utilities\wf.ps1 list-checkpoints        Show available rollback points
    .\scripts\utilities\wf.ps1 rollback-checkpoint     Restore latest checkpoint
    .\scripts\utilities\wf.ps1 rollback-checkpoint feature-doc-cleanup Restore matching checkpoint
    .\scripts\utilities\wf.ps1 clean-branches          Preview merged local branches for cleanup
    .\scripts\utilities\wf.ps1 clean-branches apply    Delete merged local branches (asks confirmation)
    .\scripts\utilities\wf.ps1 clean-branches apply -Force  Delete merged branches without prompt, fallback to -D when needed
    .\scripts\utilities\wf.ps1 homologate          Preview normalization actions
    .\scripts\utilities\wf.ps1 homologate apply    Execute normalization and reference updates
    .\scripts\utilities\wf.ps1 health -StrictCleanup  Run health and fail if cleanup drift exists
    .\scripts\utilities\wf.ps1 agent-alert           Show process-compliance warnings (non-blocking)
    .\scripts\utilities\wf.ps1 agent-alert strict    Fail if process-compliance warnings are detected
    .\scripts\utilities\wf.ps1 agent list            List all available specialized agents
    .\scripts\utilities\wf.ps1 agent status          Check agent readiness and skill availability
    .\scripts\utilities\wf.ps1 agent DEV "implement login"  Delegate implementation to DEV agent
    .\scripts\utilities\wf.ps1 agent QA "validate checkout"  Delegate testing to QA agent

CHECKPOINT LABEL CONVENTION:
    Use '<scope>-<objective>' in lowercase kebab-case.
    Examples: feature-doc-cleanup, bugfix-hook-timeout, release-prep-check.

"@
}

function Show-IdeStatus {
    Write-Step "IDE Session Detection"
    $detectScript = Join-Path $scriptDir 'detect-ide-session.ps1'
    if (-not (Test-Path $detectScript)) {
        Write-Error "IDE detection script not found: $detectScript"
        exit 1
    }

    # Request machine-readable output and suppress human-readable noise from the child script.
    $ideDataRaw = & $detectScript -AsJson -Quiet 2>$null
    if ($ideDataRaw -is [array]) {
        $ideDataRaw = ($ideDataRaw -join [Environment]::NewLine)
    }

    $ideDataText = [string]$ideDataRaw
    $jsonStart = $ideDataText.IndexOf('{')
    if ($jsonStart -gt 0) {
        $ideDataText = $ideDataText.Substring($jsonStart)
    }

    try {
        $ideData = $ideDataText | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Error "IDE detection returned invalid JSON."
        Write-Host "Raw output:" -ForegroundColor Yellow
        Write-Host $ideDataText -ForegroundColor DarkGray
        exit 1
    }

    Write-Host "IDE: $($ideData.ideName)" -ForegroundColor White
    Write-Host "Confidence: $($ideData.confidence)" -ForegroundColor White
    Write-Host "Session detected: $($ideData.isIdeSession)" -ForegroundColor White
    Write-Host "Activation: $($ideData.recommendedActivationCommand)" -ForegroundColor Cyan
    Write-Host "Session start: $($ideData.recommendedSessionCommand)" -ForegroundColor Cyan
}

# Main execution
Invoke-ContextEfficiencyLiveAssist -CommandName $Command -Objective $Scope

switch ($Command) {
    'help' {
        Show-Help
    }
    
    'status' {
        Show-Status
    }

    'checkpoint' {
        Invoke-LiveCheckpoint -Label $Scope
    }

    'list-checkpoints' {
        Show-LiveCheckpoints
    }

    'rollback-checkpoint' {
        Invoke-RollbackCheckpoint -Selector $Scope
    }

    'clean-branches' {
        Invoke-CleanBranches -ApplyNow:($Scope -eq 'apply')
    }

    'start-session' {
        Write-Step "Creating session brief"
        $startScript = Join-Path $scriptDir 'start-session.ps1'
        if (Test-Path $startScript) {
            $startSessionArgs = @()
            if (-not [string]::IsNullOrWhiteSpace($Scope)) { $startSessionArgs += @('-TaskName', $Scope) }
            if ($Force) { $startSessionArgs += '-Force' }
            Invoke-LocalPowerShellScript -ScriptPath $startScript -ScriptArgs $startSessionArgs
        } else {
            Write-Error "Start session script not found: $startScript"
            exit 1
        }
    }

    'task-brief' {
        Write-Step "Creating task brief"
        if ([string]::IsNullOrWhiteSpace($Scope)) {
            Write-Error "Task name required. Example: .\scripts\utilities\wf.ps1 task-brief auth-flow"
            exit 1
        }

        $startScript = Join-Path $scriptDir 'start-session.ps1'
        if (Test-Path $startScript) {
            $taskBriefArgs = @('-TaskName', $Scope, '-Force')
            Invoke-LocalPowerShellScript -ScriptPath $startScript -ScriptArgs $taskBriefArgs
        } else {
            Write-Error "Start session script not found: $startScript"
            exit 1
        }
    }

    'end-session' {
        Write-Step "Running session closure"
        Invoke-TokenBudgetGuard -Task 'end-session' -Risk 'medium' -EstimatedChars 7200
        $endScript = Join-Path $scriptDir 'end-session.ps1'
        if (Test-Path $endScript) {
            $endArgs = @()
            if (-not [string]::IsNullOrWhiteSpace($Scope)) { $endArgs += @('-TaskName', $Scope) }
            if ($SkipReview) { $endArgs += '-SkipReview' }
            if ($SkipTests) { $endArgs += '-SkipTests' }
            if ($Force) { $endArgs += '-Force' }
            Invoke-LocalPowerShellScript -ScriptPath $endScript -ScriptArgs $endArgs
        } else {
            Write-Error "End session script not found: $endScript"
            exit 1
        }
    }

    'reset-demo' {
        Write-Step "Resetting Demo 07"
        $demoRoot = Join-Path $repoRoot 'demos\07-mixed-cookbook-real-request'
        $resetScript = Join-Path $demoRoot 'reset-demo.ps1'
        if (Test-Path $resetScript) {
            $resetArgs = @()
            if ($Force) { $resetArgs += '-SkipPreflight' }
            Invoke-LocalPowerShellScript -ScriptPath $resetScript -ScriptArgs $resetArgs
        } else {
            Write-Error "Reset script not found: $resetScript"
            exit 1
        }
    }

    'day-end-closure' {
        Write-Step "Running automated day-end closure"
        Invoke-TokenBudgetGuard -Task 'end-session' -Risk 'high' -EstimatedChars 14000
        $dayEndScript = Join-Path $scriptDir 'day-end-closure.ps1'
        if (Test-Path $dayEndScript) {
            if (-not [string]::IsNullOrWhiteSpace($Scope)) {
                & $dayEndScript -SessionId $Scope -SkipValidation:$SkipTests -Force:$Force
            } else {
                & $dayEndScript -SkipValidation:$SkipTests -Force:$Force
            }
        } else {
            Write-Error "Day-end closure script not found: $dayEndScript"
            exit 1
        }
    }
    
    'update' {
        Invoke-Update
    }

    'update-all' {
        Invoke-UpdateAll
    }

    'update-tools' {
        Write-Step "Updating tools (required + optional integrations)"
        $toolsScript = Join-Path $scriptDir 'update-tools.ps1'
        if (-not (Test-Path $toolsScript)) {
            Write-Error "update-tools.ps1 not found: $toolsScript"
            exit 1
        }
        $toolsArgs = @()
        if ($Force) { $toolsArgs += '-Force' }
        Invoke-LocalPowerShellScript -ScriptPath $toolsScript -ScriptArgs $toolsArgs
    }

    'review' {
        Write-Step "Code Review - $($Scope.ToUpper())"

        if ($Scope -eq 'judgment-day') {
            $jdScript = Join-Path $scriptDir 'judgment-day.ps1'
            if (-not (Test-Path $jdScript)) {
                Write-Error "judgment-day.ps1 not found"
                exit 1
            }

            Write-Host " Running: judgment-day.ps1" -ForegroundColor Cyan
            & $jdScript
            $exitCode = $LASTEXITCODE
        } else {
            $reviewScript = Join-Path $repoRoot 'skills\code-review-orchestrator-skill\code-review.ps1'
            if (-not (Test-Path $reviewScript)) {
                Write-Error "Code review script not found: $reviewScript"
                exit 1
            }

            $reviewArgs = @()
            if ($Scope) {
                $reviewArgs += $Scope
            } else {
                $reviewArgs += 'all'
            }

            Write-Host " Running: code-review.ps1 --scope $($reviewArgs -join ' ')" -ForegroundColor Cyan
            & $reviewScript @reviewArgs
            $exitCode = $LASTEXITCODE
        }

        if ($exitCode -ne 0) {
            Write-Error "Code review found issues"
            exit $exitCode
        }

        Write-Success "Code review complete"
    }

    'judgment-day' {
        Write-Step "Judgment Day - Dual Review Protocol"

        $jdScript = Join-Path $scriptDir 'judgment-day.ps1'
        if (-not (Test-Path $jdScript)) {
            Write-Error "judgment-day.ps1 not found"
            exit 1
        }

        Write-Host " Running: judgment-day.ps1 (max 3 passes default)" -ForegroundColor Cyan
        & $jdScript -MaxPasses 3
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            Write-Error "Judgment Day found issues"
            exit $exitCode
        }

        Write-Success "Judgment Day complete"
    }
    
    'audit' {
        Write-Step "Generating Audit"
        Invoke-TokenBudgetGuard -Task 'audit' -Risk 'medium' -EstimatedChars 8800

        $auditWorkflow = Join-Path $repoRoot 'skills\foundation-audit-skill\scripts\audit-workflow.ps1'
        $auditModes = @('quick', 'standard', 'full', 'deep', 'judgment', 'unified')
        $normalizedScope = if ($Scope) { $Scope.ToLowerInvariant() } else { $null }

        if ($normalizedScope) {
            if (-not ($auditModes -contains $normalizedScope)) {
                Write-Error "Invalid audit scope '$Scope'. Valid scopes: $($auditModes -join ', ')"
                exit 1
            }

            # Structured audit via audit-workflow.ps1
            if (-not (Test-Path $auditWorkflow)) {
                Write-Error "audit-workflow.ps1 not found: $auditWorkflow"
                exit 1
            }
            Write-Host " Mode: $normalizedScope" -ForegroundColor Gray
            & $auditWorkflow -Mode $normalizedScope -BasePath $repoRoot
            if ($LASTEXITCODE -ne 0) {
                Write-Error "audit-workflow failed with exit code $LASTEXITCODE"
                exit $LASTEXITCODE
            }
        } else {
            # Default: generate audit markdown document
            $outputDir = Join-Path $repoRoot 'docs/audits'
            if (-not (Test-Path $outputDir)) {
                New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            }

            $dateStr = Get-Date -Format "yyyy-MM-dd-HHmmss"
            $outputPath = Join-Path $outputDir "$dateStr-audit.md"

            New-AuditDocument -OutputPath $outputPath

            Write-Host ""
            Write-Host "Tip: Use scoped audit modes for structural validation:" -ForegroundColor DarkGray
            Write-Host "  wf.ps1 audit quick     -- fast structure check (0 tokens)" -ForegroundColor DarkGray
            Write-Host "  wf.ps1 audit standard  -- + links and skill validation" -ForegroundColor DarkGray
            Write-Host "  wf.ps1 audit full      -- complete batch sweep" -ForegroundColor DarkGray
            Write-Host "  wf.ps1 audit deep      -- + orphaned docs sweep" -ForegroundColor DarkGray
            Write-Host "  wf.ps1 audit judgment  -- full sweep + adversarial AI review" -ForegroundColor DarkGray
        }
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
        Warn-OldWorkflowCheckpoints -ThresholdDays 7
        
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

        $publishMode = Resolve-PublishMode -RequestedMode $Scope -ForceMode:$Force
        $gitInfo = Get-GitInfo
        $branchName = if ([string]::IsNullOrWhiteSpace($gitInfo.Branch)) { '<current-branch>' } else { $gitInfo.Branch }
        
        # Commit and push
        Write-Host ""
        if ($publishMode -eq 'push+pr') {
            Write-Host "Run the following commands (push + PR):" -ForegroundColor Cyan
            Write-Host "  git add ." -ForegroundColor Yellow
            Write-Host "  git commit -m 'type(scope): description'" -ForegroundColor Yellow
            Write-Host "  git push -u origin $branchName" -ForegroundColor Yellow
            Write-Host "  gh pr create --fill" -ForegroundColor Yellow
        } else {
            Write-Host "Run the following commands (push only):" -ForegroundColor Cyan
            Write-Host "  git add ." -ForegroundColor Yellow
            Write-Host "  git commit -m 'type(scope): description'" -ForegroundColor Yellow
            Write-Host "  git push" -ForegroundColor Yellow
            Write-Host "" 
            Write-Host "Later, create PR with:" -ForegroundColor Cyan
            Write-Host "  .\scripts\utilities\wf.ps1 pr" -ForegroundColor Yellow
        }
    }

    'publish' {
        Invoke-TokenBudgetGuard -Task 'publish' -Risk 'high' -EstimatedChars 18000
        Invoke-PublishWorkflow -SkipReviewGate:$SkipReview -SkipTestsGate:$SkipTests -ForceMode:$Force
    }
    
    'health' {
        Write-Step "System Health Check & Tool Activation"
        
        $healthScript = Join-Path $scriptDir 'ensure-tools-active.ps1'
        if (Test-Path $healthScript) {
            $healthArgs = @('-AutoStart')
            if ($Force) { $healthArgs += "-Force" }
            Invoke-LocalPowerShellScript -ScriptPath $healthScript -ScriptArgs $healthArgs
        } else {
            Write-Error "Health check script not found: $healthScript"
            exit 1
        }

        $homologateScript = Join-Path $scriptDir '..\validation\homologate-workspace.ps1'
        if (Test-Path $homologateScript) {
            Write-Step "Homologation Drift Preview"
            $homologateArgs = @('-OrganizeRootDocs')
            if ($StrictCleanup) {
                $homologateArgs += '-FailOnChanges'
            }

            Invoke-LocalPowerShellScript -ScriptPath $homologateScript -ScriptArgs $homologateArgs

            if ($StrictCleanup -and $LASTEXITCODE -ne 0) {
                Write-Error "Strict cleanup mode failed: run '.\scripts\utilities\wf.ps1 homologate apply' to remediate drift."
                exit $LASTEXITCODE
            }
        }
    }

    'orchestrator-status' {
        Write-Step "Checking Orchestrator and Engram integration"
        $statusScript = Join-Path $scriptDir 'orchestrator-status.ps1'
        if (Test-Path $statusScript) {
            Invoke-LocalPowerShellScript -ScriptPath $statusScript
        } else {
            Write-Error "Orchestrator status script not found: $statusScript"
            exit 1
        }
    }

    'stack-dashboard' {
        $dashboardScript = Join-Path $scriptDir 'stack-dashboard.ps1'
        if (-not (Test-Path $dashboardScript)) {
            Write-Error "Stack dashboard script not found: $dashboardScript"
            exit 1
        }

        $isStrict = $StrictCleanup -or ($Scope -eq 'strict')

        if ($JSON) {
            if ($isStrict) {
                & $dashboardScript -AsJson -Strict
            } else {
                & $dashboardScript -AsJson
            }
        } else {
            if ($isStrict) {
                & $dashboardScript -Strict
            } else {
                Invoke-LocalPowerShellScript -ScriptPath $dashboardScript
            }
        }
    }

    'runtime-route' {
        if (-not $JSON) {
            Write-Step "Runtime Route"
        }
        $routeScript = Join-Path $scriptDir 'runtime-router.ps1'
        if (-not (Test-Path $routeScript)) {
            Write-Error "Runtime router script not found: $routeScript"
            exit 1
        }

        $isStrict = $StrictCleanup -or ($Scope -eq 'strict')
        if ($JSON) {
            if ($isStrict) {
                & $routeScript -Mode route -AsJson -Strict
            } else {
                & $routeScript -Mode route -AsJson
            }
        } else {
            if ($isStrict) {
                & $routeScript -Mode route -Strict
            } else {
                & $routeScript -Mode route
            }
        }
    }

    'custom-rules-status' {
        Write-Step "Custom Rules Status"
        $rulesScript = Join-Path $scriptDir 'custom-rules.ps1'
        if (-not (Test-Path $rulesScript)) {
            Write-Error "Custom rules script not found: $rulesScript"
            exit 1
        }

        $rulesArgs = @('status')
        if ($JSON) { $rulesArgs += '-AsJson' }
        Invoke-LocalPowerShellScript -ScriptPath $rulesScript -ScriptArgs $rulesArgs
    }
    'response-mode' {
        Write-Step 'Response Profile'
        $modeScript = Join-Path $scriptDir 'response-mode.ps1'
        if (-not (Test-Path $modeScript)) {
            Write-Error "Response mode script not found: $modeScript"
            exit 1
        }

        $modeParams = @{
            Mode = 'status'
        }

        $scopeText = [string]$Scope
        if (-not [string]::IsNullOrWhiteSpace($scopeText)) {
            if ($scopeText -eq 'list') {
                $modeParams = @{ Mode = 'list' }
            }
            elseif ($scopeText -match '^profile:(.+)$') {
                $modeParams = @{ Mode = 'set'; Profile = $matches[1] }
            }
            elseif ($scopeText -match '^language:(.+)$') {
                $modeParams = @{ Mode = 'set-language'; Language = $matches[1] }
            }
            elseif ($scopeText -match '^detail:(.+)$') {
                $modeParams = @{ Mode = 'set-detail'; Detail = $matches[1] }
            }
            elseif ($scopeText -match '^chat:(.+)$') {
                $modeParams = @{ Mode = 'set-chat-level'; ChatLevel = $matches[1] }
            }
            elseif ($scopeText -match '^preset:(.+)$') {
                $modeParams = @{ Mode = 'set-preset'; Preset = $matches[1] }
            }
            elseif ($scopeText -match '^recommend:([^:]+):([^:]+)$') {
                $modeParams = @{ Mode = 'recommend'; Preset = $matches[1]; Risk = $matches[2] }
            }
            elseif ($scopeText -match '^recommend:([^:]+)$') {
                $modeParams = @{ Mode = 'recommend'; Preset = $matches[1] }
            }
            elseif ($scopeText -in @('lite', 'lleno', 'ultra')) {
                $modeParams = @{ Mode = 'set'; Profile = $scopeText }
            }
            elseif ($scopeText -in @('es', 'pt-BR', 'en')) {
                $modeParams = @{ Mode = 'set-language'; Language = $scopeText }
            }
            elseif ($scopeText -in @('simple', 'executive', 'expanded')) {
                $modeParams = @{ Mode = 'set-detail'; Detail = $scopeText }
            }
            elseif ($scopeText -in @('chat-compact', 'chat-balanced', 'chat-detailed')) {
                $modeParams = @{ Mode = 'set-chat-level'; ChatLevel = $scopeText }
            }
            elseif ($scopeText -in @('bugfix', 'refactor', 'docs', 'audit-review', 'executive-demo')) {
                $modeParams = @{ Mode = 'set-preset'; Preset = $scopeText }
            }
        }

        if ($JSON) { $modeParams['AsJson'] = $true }
        & $modeScript @modeParams
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
            Invoke-LocalPowerShellScript -ScriptPath $installScript -ScriptArgs $installArgs
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
            Invoke-LocalPowerShellScript -ScriptPath $diagScript -ScriptArgs @('-AutoRepair', '-Quiet')
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
                Invoke-LocalPowerShellScript -ScriptPath $path -ScriptArgs $diagnoseArgs
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
        Invoke-LocalPowerShellScript -ScriptPath $migrateScript -ScriptArgs $migrateArgs
    }

    'context-pack' {
        Write-Step "Generating Compact Context Pack"
        $scopeChars = if ([string]::IsNullOrWhiteSpace($Scope)) { 0 } else { $Scope.Length }
        Invoke-TokenBudgetGuard -Task 'context-pack' -Risk 'medium' -EstimatedChars (4800 + $scopeChars)
        $contextScript = Join-Path $scriptDir 'context-pack.ps1'
        if (-not (Test-Path $contextScript)) {
            Write-Error "Context pack script not found: $contextScript"
            exit 1
        }

        if ([string]::IsNullOrWhiteSpace($Scope)) {
            & $contextScript
        } else {
            & $contextScript -Objective $Scope
        }
    }

    'compact-start' {
        Write-Step "Preparing Compact Chat Start"
        $scopeChars = if ([string]::IsNullOrWhiteSpace($Scope)) { 0 } else { $Scope.Length }
        Invoke-TokenBudgetGuard -Task 'compact-start' -Risk 'medium' -EstimatedChars (6200 + $scopeChars)
        $compactScript = Join-Path $scriptDir 'compact-start.ps1'
        if (-not (Test-Path $compactScript)) {
            Write-Error "Compact start script not found: $compactScript"
            exit 1
        }

        if ([string]::IsNullOrWhiteSpace($Scope)) {
            & $compactScript
        } else {
            & $compactScript -Objective $Scope
        }
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

        Invoke-LocalPowerShellScript -ScriptPath $metricsScript -ScriptArgs @('-Days', [string]$days)
    }

    'token-guard' {
        Write-Step "Token Budget Guard"
        $guardScript = Join-Path $scriptDir 'token-budget-guard.ps1'
        if (-not (Test-Path $guardScript)) {
            Write-Error "Token budget guard script not found: $guardScript"
            exit 1
        }

        $taskName = if ([string]::IsNullOrWhiteSpace($Scope)) { 'general' } else { $Scope }
        & $guardScript -Mode status -Task $taskName
    }

    'homologate' {
        Write-Step "Workspace Homologation"
        $homologateScript = Join-Path $scriptDir '..\validation\homologate-workspace.ps1'
        if (-not (Test-Path $homologateScript)) {
            Write-Error "Homologation script not found: $homologateScript"
            exit 1
        }

        $homologateArgs = @('-OrganizeRootDocs')
        if ($Force -or $Scope -eq 'apply') {
            $homologateArgs += '-Apply'
        }

        Invoke-LocalPowerShellScript -ScriptPath $homologateScript -ScriptArgs $homologateArgs
    }

    'agent-alert' {
        Write-Step "Agent Process Compliance Alert"
        $alertScript = Join-Path $scriptDir '..\diagnostics\agent-process-alert.ps1'
        if (-not (Test-Path $alertScript)) {
            Write-Error "Agent alert script not found: $alertScript"
            exit 1
        }

        $alertArgs = @('-WindowHours', '24')
        if ($StrictCleanup -or $Scope -eq 'strict') {
            $alertArgs += '-Strict'
        }

        Invoke-LocalPowerShellScript -ScriptPath $alertScript -ScriptArgs $alertArgs
    }

    'agent' {
        Write-Step "Multi-Agent Router"
        $agentScript = Join-Path $scriptDir 'agent-router.ps1'
        if (-not (Test-Path $agentScript)) {
            Write-Error "Agent router script not found: $agentScript"
            exit 1
        }

        if ([string]::IsNullOrWhiteSpace($Scope)) {
            Write-Host "Usage: .\wf.ps1 agent <AGENT> [TASK]" -ForegroundColor Yellow
            Write-Host "Agents: BA, SAD, DEV, QA, OPS, GOV, DOC, status, list" -ForegroundColor White
            exit 1
        }

        $agentParams = $Scope.Trim() -split ' ', 2
        $agentName = if ($agentParams.Count -ge 1) { $agentParams[0].Trim() } else { '' }
        $taskText = if ($agentParams.Count -ge 2) { $agentParams[1].Trim() -replace "^'", "" -replace "'$", "" } else { '' }

        if (-not [string]::IsNullOrWhiteSpace($agentName)) {
            & $agentScript -Agent $agentName -Task $taskText
        } else {
            & $agentScript
        }
    }

    'skills' {
        Write-Step "Skills Auto-Discovery"
        $skillsScript = Join-Path $scriptDir 'skills-discovery.ps1'
        if (-not (Test-Path $skillsScript)) {
            Write-Error "Skills discovery script not found: $skillsScript"
            exit 1
        }

        $validActions = @('discover', 'map', 'agents', 'validate')
        $action = if ($validActions -contains $Scope) { $Scope } else { 'discover' }

        & $skillsScript -Action $action
    }

    'dispatch' {
        Write-Step "Parallel Agent Dispatch"
        $dispatchScript = Join-Path $scriptDir 'dispatch-agent.ps1'
        if (-not (Test-Path $dispatchScript)) {
            Write-Error "Dispatch script not found: $dispatchScript"
            exit 1
        }

        if ([string]::IsNullOrWhiteSpace($Scope)) {
            & $dispatchScript
        } else {
            & $dispatchScript -Agents $Scope
        }
    }

    'events' {
        Write-Step "Event Bus"
        $eventScript = Join-Path $scriptDir 'event-bus.ps1'
        if (-not (Test-Path $eventScript)) {
            Write-Error "Event bus script not found: $eventScript"
            exit 1
        }

        $scopeParts = $Scope -split ' ', 2
        $action = if ($scopeParts[0]) { $scopeParts[0] } else { 'list' }
        $eventName = if ($scopeParts.Count -gt 1) { $scopeParts[1] } else { '' }

        $eventArgs = @('-Action', $action)
        if ($eventName) {
            $eventArgs += @('-Event', $eventName)
        }

        & $eventScript @eventArgs
    }
}

exit 0
