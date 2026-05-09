# wf.ps1 - Workflow CLI
# Automated development workflow for Gentleman Foundation

param(
    [Parameter(Position=0)]
    [ValidateSet('review', 'audit', 'pr', 'push', 'publish', 'status', 'health', 'update', 'update-all', 'update-tools', 'install', 'install-engram', 'orchestrator-status', 'stack-dashboard', 'runtime-route', 'runtime-gate', 'custom-rules-status', 'response-mode', 'ide-status', 'diagnose', 'verify', 'start-session', 'end-session', 'day-end-closure', 'task-brief', 'migrate-structure', 'context-pack', 'compact-start', 'context-metrics', 'token-guard', 'checkpoint', 'list-checkpoints', 'rollback-checkpoint', 'clean-branches', 'homologate', 'foundation-sync', 'agent-alert', 'agent', 'skills', 'dispatch', 'events', 'reset-demo', 'judgment-day', 'simplify-text', 'context-dashboard', 'dashboard', 'mq', 'export-metrics', 'monthly-report', 'platform-info', 'sdd-gate', 'sdd-metrics', 'sync-drift', 'benchmark', 'version', 'route', 'help')]
    [string]$Command = 'help',
    
    [Parameter(Position=1)]
    [string]$Scope = '',

    [Parameter(Position=2, ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs = @(),
    
    [switch]$SkipTests,
    [switch]$SkipReview,
    [switch]$StrictCleanup,
    [switch]$Force,
    [switch]$JSON
)

$ErrorActionPreference = 'Continue'
# Prefer FOUNDATION_BASE_DIR when running cached from AppData (launcher v2.1+)
# Falls back to $MyInvocation for development mode
if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) {
    $scriptDir = "$env:FOUNDATION_APPDATA_DIR\scripts\utilities\WORKFLOW-ORCHESTRATION"
    $repoRoot = $env:FOUNDATION_BASE_DIR
} else {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    # repoRoot: go up 3 levels from wf.ps1 (WORKFLOW-ORCHESTRATION -> utilities -> scripts -> repo)
    $repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..\..')).Path
}

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

    if ($ScriptArgs.Count -gt 0) {
        & $ScriptPath @ScriptArgs
    } else {
        & $ScriptPath
    }
}

function Invoke-TokenBudgetGuard {
    param(
        [string]$Task,
        [ValidateSet('low', 'medium', 'high')]
        [string]$Risk = 'medium',
        [int]$EstimatedChars = 0,
        [int]$ActualPromptTokens = 0,
        [int]$ActualCompletionTokens = 0
    )

    $guardScript = Join-Path $scriptDir '..\TELEMETRY-METRICS\token-budget-guard.ps1'
    if (-not (Test-Path $guardScript)) {
        return
    }

    $guardArgs = @{
        Mode = 'check'
        Task = $Task
        Risk = $Risk
        Record = $true
        AsJson = $true
        Quiet = $true
    }
    if ($EstimatedChars -gt 0) {
        $guardArgs['EstimatedChars'] = $EstimatedChars
    }
    if ($ActualPromptTokens -gt 0) {
        $guardArgs['ActualPromptTokens'] = $ActualPromptTokens
    }
    if ($ActualCompletionTokens -gt 0) {
        $guardArgs['ActualCompletionTokens'] = $ActualCompletionTokens
    }

    $guardResult = $null
    try {
        $guardRaw = & $guardScript @guardArgs
        if ($guardRaw) {
            $guardText = [string]$guardRaw
            $guardResult = $guardText | ConvertFrom-Json -ErrorAction Stop
        }
    }
    catch {
        # Fallback to legacy output mode if JSON parsing fails.
        $fallbackArgs = @('-Mode', 'check', '-Task', $Task, '-Risk', $Risk, '-Record')
        if ($EstimatedChars -gt 0) { $fallbackArgs += @('-EstimatedChars', $EstimatedChars) }
        if ($ActualPromptTokens -gt 0) { $fallbackArgs += @('-ActualPromptTokens', $ActualPromptTokens) }
        if ($ActualCompletionTokens -gt 0) { $fallbackArgs += @('-ActualCompletionTokens', $ActualCompletionTokens) }
        & $guardScript @fallbackArgs
        return
    }

    if ($guardResult -and $guardResult.status -ne 'PASS') {
        Write-Warning ("Token guard status={0} projected={1}% for task={2}" -f $guardResult.status, $guardResult.projected_pct, $Task)
    }

    Invoke-TokenAutopilot -Task $Task -GuardResult $guardResult
}

function Get-TokenAutopilotPolicy {
    $defaults = [ordered]@{
        enabled = $true
        triggerStatuses = @('SOFT_LIMIT', 'HARD_LIMIT')
        minConsecutiveAlerts = 2
        autoApplyOnCommands = @('context-pack', 'compact-start', 'audit', 'publish', 'end-session', 'dispatch')
        applyChatLevel = 'chat-compact'
        stateFile = '.session/token-autopilot-state.json'
    }

    $configPath = Join-Path $repoRoot 'config\context-efficiency.json'
    if (-not (Test-Path $configPath)) {
        return [pscustomobject]$defaults
    }

    try {
        $cfg = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cfg -and $cfg.PSObject.Properties['tokenAutopilot']) {
            $custom = $cfg.tokenAutopilot
            foreach ($k in @($defaults.Keys)) {
                if ($custom.PSObject.Properties[$k]) {
                    $defaults[$k] = $custom.$k
                }
            }
        }
    }
    catch {
        return [pscustomobject]$defaults
    }

    return [pscustomobject]$defaults
}

function Get-TokenAutopilotState {
    param([string]$StatePath)

    if (Test-Path $StatePath) {
        try {
            return Get-Content -Path $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        }
        catch {
            # Fall through to defaults.
        }
    }

    return [pscustomobject]@{
        consecutiveAlerts = 0
        lastStatus = 'PASS'
        lastTask = ''
        lastAppliedChatLevel = ''
        lastAppliedAt = ''
    }
}

function Save-TokenAutopilotState {
    param(
        [string]$StatePath,
        [pscustomobject]$State
    )

    $stateDir = Split-Path -Parent $StatePath
    if (-not (Test-Path $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }

    $State | ConvertTo-Json -Depth 10 | Set-Content -Path $StatePath -Encoding UTF8
}

function Set-TokenAutopilotProfile {
    param(
        [ValidateSet('hard', 'balanced')]
        [string]$Profile
    )

    $configPath = Join-Path $repoRoot 'config\context-efficiency.json'
    if (-not (Test-Path $configPath)) {
        throw "Context efficiency config not found: $configPath"
    }

    $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $config.PSObject.Properties['tokenAutopilot']) {
        $config | Add-Member -MemberType NoteProperty -Name 'tokenAutopilot' -Value ([pscustomobject]@{})
    }

    if ($Profile -eq 'hard') {
        $config.tokenAutopilot.profile = 'hard'
        $config.tokenAutopilot.triggerStatuses = @('HARD_LIMIT')
        $config.tokenAutopilot.minConsecutiveAlerts = 1
        $config.tokenAutopilot.applyChatLevel = 'chat-compact'
    }
    else {
        $config.tokenAutopilot.profile = 'balanced'
        $config.tokenAutopilot.triggerStatuses = @('SOFT_LIMIT', 'HARD_LIMIT')
        $config.tokenAutopilot.minConsecutiveAlerts = 2
        $config.tokenAutopilot.applyChatLevel = 'chat-compact'
    }

    $json = $config | ConvertTo-Json -Depth 30
    Set-Content -Path $configPath -Value $json -Encoding UTF8
}

function Invoke-TokenAutopilot {
    param(
        [string]$Task,
        [pscustomobject]$GuardResult
    )

    if (-not $GuardResult) {
        return
    }

    $policy = Get-TokenAutopilotPolicy
    if (-not $policy.enabled) {
        return
    }

    $normalizedTask = if ($Task) { $Task.Trim().ToLowerInvariant() } else { 'general' }
    $taskAllowList = @($policy.autoApplyOnCommands | ForEach-Object { [string]$_ })
    if ($taskAllowList.Count -gt 0 -and ($taskAllowList -notcontains $normalizedTask)) {
        return
    }

    $status = [string]$GuardResult.status
    $triggerStatuses = @($policy.triggerStatuses | ForEach-Object { [string]$_ })
    $statePath = Join-Path $repoRoot ([string]$policy.stateFile)
    $state = Get-TokenAutopilotState -StatePath $statePath

    if ($triggerStatuses -contains $status) {
        $state.consecutiveAlerts = [int]$state.consecutiveAlerts + 1
    }
    else {
        $state.consecutiveAlerts = 0
    }

    $state.lastStatus = $status
    $state.lastTask = $normalizedTask

    $requiredAlerts = [int]$policy.minConsecutiveAlerts
    if ($requiredAlerts -lt 1) {
        $requiredAlerts = 1
    }

    if (($triggerStatuses -contains $status) -and ([int]$state.consecutiveAlerts -ge $requiredAlerts)) {
        $modeScript = Join-Path $scriptDir '..\UTILITIES\response-mode.ps1'
        if (Test-Path $modeScript) {
            $chatLevel = [string]$policy.applyChatLevel
            & $modeScript -Mode set-chat-level -ChatLevel $chatLevel -SkipEngramLog 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $state.lastAppliedChatLevel = $chatLevel
                $state.lastAppliedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')
                Write-Warning ("Token autopilot applied chat-level={0} after {1} consecutive alerts (status={2})." -f $chatLevel, $state.consecutiveAlerts, $status)
            }
        }
    }

    Save-TokenAutopilotState -StatePath $statePath -State $state
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
        $homologateScript = Join-Path $scriptDir '..\..\validation\homologate-workspace.ps1'
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

**Generated by:** Foundation - Development Stack Workflow CLI
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
        try {
            $parsedDate = [DateTimeOffset]::Parse([string]$dateRaw)
            if ($parsedDate.LocalDateTime -lt $cutoff) {
                $oldRefs += $ref
            }
        } catch { }
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
Foundation - Development Stack Workflow CLI
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
    runtime-gate [type]  Gate check: is task type allowed? type=ai|heavy-ai|network|local|metrics|any
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
    compact-start [goal]  Generate context pack and copy compact continuation prompt
    simplify-text [text]   Simplify input text (remove emojis, normalize, abbreviate)
    context-metrics [days] Show context/token usage metrics from local logs
    token-guard [task]   Check token budget thresholds and continuity alternatives (Engram-aware/autopilot-aware)
    checkpoint [label]   Save a live rollback point (git stash -u) before risky edits
    list-checkpoints     List workflow-created checkpoints
    rollback-checkpoint [selector] Restore latest checkpoint or one matching selector
    clean-branches [apply] Preview or clean merged local feature/release branches
    homologate [apply]  Normalize docs/artifacts and update references (dry-run default)
    foundation-sync [apply] [optional -CreatePr]  Sync managed assets declared in foundation manifest
    agent-alert [strict] Check process-compliance signals for off-process AI activity
    agent <AGENT> [TASK] Route task to specialized sub-agent (BA|SAD|DEV|QA|OPS|GOV|DOC)
    dashboard [open]     Generate static HTML dashboard from telemetry JSON (open = auto-open browser)
    mq [action]          Message queue adapter: status|publish|consume|test (file/redis/webhook)
    export-metrics [fmt] Export metrics to analytical store: csv|jsonl|sqlite|all (default: csv)
    monthly-report [fmt] Run export-metrics + generate-management-report (fmt: csv|jsonl|sqlite|all)
    platform-info        Show current platform and PowerShell version
    sdd-gate             FF-001: Validate SDD spec status before merging to protected branches
    sdd-metrics          FF-002: SDD process KPIs: spec coverage, lead time, rework ratio
    sync-drift           FF-004: Detect drift between declared config and actual skills/files
    benchmark [cmds]     FF-006: Profile wf commands vs SLO thresholds (default: status,health)
    version              Show current stack version (from VERSION file + orchestrator.json)
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
    .\scripts\utilities\wf.ps1 response-mode ahorro         On-demand token saving mode (chat-compact)
    .\scripts\utilities\wf.ps1 response-mode normal         On-demand balanced mode (chat-balanced, override)
    .\scripts\utilities\wf.ps1 response-mode detallado      On-demand detailed mode (chat-detailed, override)
    .\scripts\utilities\wf.ps1 ide-status          Detect IDE and show recommended activation
    .\scripts\utilities\wf.ps1 update              Refresh repository, foundation, skills, and optional tools
    .\scripts\utilities\wf.ps1 update-tools         Update required tools and optional integrations
    .\scripts\utilities\wf.ps1 context-pack "fix ci noise"  Generate compact handoff summary for token-efficient continuation
    .\scripts\utilities\wf.ps1 compact-start "fix ci noise" Generate handoff summary and copy compact prompt
    .\scripts\utilities\wf.ps1 context-metrics 14  Show 14-day context usage summary
    .\scripts\utilities\wf.ps1 token-guard         Show token budget status for current session
    .\scripts\utilities\wf.ps1 token-guard publish Check token budget for publish-level workflow
    .\scripts\utilities\wf.ps1 token-guard auto    Run token check and execute autopilot if thresholds persist
    .\scripts\utilities\wf.ps1 token-guard profile:hard      Set autopilot default to hard mode
    .\scripts\utilities\wf.ps1 token-guard profile:balanced  Set autopilot default to balanced mode
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
    .\scripts\utilities\wf.ps1 monthly-report all      Export metrics and build monthly management report
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
    $detectScript = Join-Path $scriptDir '..\UTILITIES\detect-ide-session.ps1'
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
        $endScript = Join-Path $scriptDir '..\SESSION-MANAGEMENT\end-session.ps1'
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
        $dayEndScript = Join-Path $scriptDir '..\UTILITIES\day-end-closure.ps1'
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
        
        $healthScript = Join-Path $scriptDir '..\SKILLS-TOOLS\ensure-tools-active.ps1'
        if (Test-Path $healthScript) {
            $healthArgs = @('-AutoStart')
            if ($Force) { $healthArgs += "-Force" }
            Invoke-LocalPowerShellScript -ScriptPath $healthScript -ScriptArgs $healthArgs
        } else {
            Write-Error "Health check script not found: $healthScript"
            exit 1
        }

        $homologateScript = Join-Path $scriptDir '..\..\validation\homologate-workspace.ps1'
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
        $dashboardScript = Join-Path $scriptDir '..\UTILITIES\stack-dashboard.ps1'
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

    'runtime-gate' {
        $routeScript = Join-Path $scriptDir 'runtime-router.ps1'
        if (-not (Test-Path $routeScript)) {
            Write-Error "Runtime router script not found: $routeScript"
            exit 1
        }
        $taskType = if ($Scope) { $Scope } else { 'any' }
        if ($JSON) {
            & $routeScript -Mode gate -TaskType $taskType -AsJson
        } else {
            Write-Step "Runtime Gate — task: $taskType"
            & $routeScript -Mode gate -TaskType $taskType
        }
    }

    'custom-rules-status' {
        Write-Step "Custom Rules Status"
        $rulesScript = Join-Path $scriptDir '..\UTILITIES\custom-rules.ps1'
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
        $modeScript = Join-Path $scriptDir '..\UTILITIES\response-mode.ps1'
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
            elseif ($scopeText -in @('ahorro', 'modo-ahorro', 'ahorro-on', 'economy', 'token-save')) {
                $modeParams = @{ Mode = 'set-chat-level'; ChatLevel = 'chat-compact' }
            }
            elseif ($scopeText -in @('normal', 'balanceado', 'modo-normal', 'ahorro-off')) {
                $modeParams = @{ Mode = 'set-chat-level'; ChatLevel = 'chat-balanced'; AllowPolicyOverride = $true; OverrideReason = 'manual-demand:balanced-chat' }
            }
            elseif ($scopeText -in @('detallado', 'detalle', 'full', 'verbose')) {
                $modeParams = @{ Mode = 'set-chat-level'; ChatLevel = 'chat-detailed'; AllowPolicyOverride = $true; OverrideReason = 'manual-demand:detailed-chat' }
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
        $installScript = Join-Path $scriptDir '..\SKILLS-TOOLS\install-engram.ps1'
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

    'context-dashboard' {
        $dashScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\context-dashboard.ps1'
        if (-not (Test-Path $dashScript)) {
            Write-Error "context-dashboard.ps1 not found at: $dashScript"
            exit 1
        }
        $promptCharsArg = if ($Scope -match '^\d+$') { [int]$Scope } else { 0 }
        & $dashScript -PromptChars $promptCharsArg
    }

    'dashboard' {
        $genScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\generate-dashboard.ps1'
        if (-not (Test-Path $genScript)) {
            Write-Error "generate-dashboard.ps1 not found at: $genScript"; exit 1
        }
        $openFlag = if ($Scope -eq 'open') { $true } else { $false }
        if ($openFlag) { & $genScript -Open }
        else           { & $genScript }
    }

    'mq' {
        $mqScript = Join-Path $repoRoot 'scripts\utilities\WORKFLOW-ORCHESTRATION\mq-adapter.ps1'
        if (-not (Test-Path $mqScript)) {
            Write-Error "mq-adapter.ps1 not found at: $mqScript"; exit 1
        }
        $mqAction = if ($Scope) { $Scope } else { 'status' }
        & $mqScript -Action $mqAction
    }

    'export-metrics' {
        $exportScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\export-metrics.ps1'
        if (-not (Test-Path $exportScript)) {
            Write-Error "export-metrics.ps1 not found at: $exportScript"; exit 1
        }
        $fmt = if ($Scope -in @('csv','jsonl','sqlite','all')) { $Scope } else { 'csv' }
        & $exportScript -Format $fmt
    }

    'monthly-report' {
        Write-Step "Monthly management report pipeline"

        $fmt = if ($Scope -in @('csv','jsonl','sqlite','all')) { $Scope } else { 'csv' }
        $exportScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\export-metrics.ps1'
        $reportScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\generate-management-report.ps1'

        if (-not (Test-Path $exportScript)) {
            Write-Error "export-metrics.ps1 not found at: $exportScript"
            exit 1
        }

        if (-not (Test-Path $reportScript)) {
            Write-Error "generate-management-report.ps1 not found at: $reportScript"
            exit 1
        }

        & $exportScript -Format $fmt
        if (-not $?) {
            Write-Error "export-metrics failed."
            exit 1
        }

        & $reportScript -OnDemand
        if (-not $?) {
            Write-Error "generate-management-report failed."
            exit 1
        }

        Write-Success "Monthly report pipeline finished."
    }

    'platform-info' {
        $compat = Join-Path $repoRoot 'scripts\utilities\platform-compat.ps1'
        if (Test-Path $compat) {
            . $compat
            Write-Host (Get-PlatformInfo) -ForegroundColor Cyan
        } else {
            $platform = if ($IsWindows) { 'windows' } elseif ($IsMacOS) { 'macos' } else { 'linux' }
            Write-Host "[platform: $platform | pwsh: $($PSVersionTable.PSVersion)]" -ForegroundColor Cyan
        }
    }

    'sdd-gate' {
        # FF-001: Run SDD gate check (local validation)
        $sddGateScript = Join-Path $repoRoot 'scripts\hooks\check-sdd-gate.ps1'
        if (-not (Test-Path $sddGateScript)) {
            Write-Error "check-sdd-gate.ps1 not found: $sddGateScript"
            exit 1
        }
        & $sddGateScript
        exit $LASTEXITCODE
    }

    'sdd-metrics' {
        # FF-002: SDD process KPIs — spec coverage, lead time, rework ratio
        $metricsScript = Join-Path $repoRoot 'scripts\utilities\TELEMETRY-METRICS\sdd-process-metrics.ps1'
        if (-not (Test-Path $metricsScript)) {
            Write-Error "sdd-process-metrics.ps1 not found: $metricsScript"
            exit 1
        }
        $asJson = $Scope -eq '-JSON' -or $Scope -eq 'json'
        if ($asJson) { & $metricsScript -AsJson } else { & $metricsScript }
        exit $LASTEXITCODE
    }

    'sync-drift' {
        # FF-004: Sync drift report — declared config vs actual filesystem
        $driftScript = Join-Path $repoRoot 'scripts\utilities\sync-drift-report.ps1'
        if (-not (Test-Path $driftScript)) {
            Write-Error "sync-drift-report.ps1 not found: $driftScript"
            exit 1
        }
        $asJson = $Scope -eq '-JSON' -or $Scope -eq 'json'
        if ($asJson) { & $driftScript -AsJson } else { & $driftScript }
        exit $LASTEXITCODE
    }

    'foundation-sync' {
        $syncScript = Join-Path $repoRoot 'scripts\utilities\UTILITIES\foundation-sync.ps1'
        if (-not (Test-Path $syncScript)) {
            Write-Error "foundation-sync.ps1 not found: $syncScript"
            exit 1
        }

        $createPr = $RemainingArgs -contains '-CreatePr' -or $RemainingArgs -contains '-CreatePR'

        if ($Scope -eq 'apply') {
            & $syncScript -Mode apply -Force:$Force -CreatePR:$createPr
        } else {
            & $syncScript -Mode check -Force:$Force
        }
        exit $LASTEXITCODE
    }

    'benchmark' {
        # FF-006: Profile key wf commands against SLO thresholds
        $benchScript = Join-Path $repoRoot 'scripts\utilities\wf-benchmark.ps1'
        if (-not (Test-Path $benchScript)) {
            Write-Error "wf-benchmark.ps1 not found: $benchScript"
            exit 1
        }
        $cmds = @()
        if ($Scope) {
            $cmds += $Scope -split ','
        }
        if ($RemainingArgs) {
            $cmds += $RemainingArgs
        }
        $cmds = @($cmds | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        if ($cmds.Count -eq 0) {
            $cmds = @('status', 'health')
        }
        & $benchScript -Commands $cmds
        exit $LASTEXITCODE
    }

    'version' {
        # Show current stack version from VERSION file
        $versionFile = Join-Path $repoRoot 'VERSION'
        $ver = if (Test-Path $versionFile) {
            (Get-Content $versionFile -Raw -Encoding UTF8).Trim()
        } else {
            'unknown'
        }
        $orchConfig = Join-Path $repoRoot 'config\orchestrator.json'
        $orchVer = ''
        if (Test-Path $orchConfig) {
            try {
                $oc = Get-Content $orchConfig -Raw -Encoding UTF8 | ConvertFrom-Json
                $orchVer = if ($oc.version) { " | orchestrator: $($oc.version)" } else { '' }
            } catch {}
        }
        Write-Host "Gentleman Foundation v${ver}${orchVer}" -ForegroundColor Cyan
        Write-Host "  Stack: $($PSVersionTable.PSVersion) on $(if($IsWindows){'windows'}elseif($IsMacOS){'macos'}else{'linux'})" -ForegroundColor Gray
        Write-Host "  Skills: $(if(Test-Path (Join-Path $repoRoot 'skills')){(Get-ChildItem (Join-Path $repoRoot 'skills') -Dir -EA SilentlyContinue).Count}else{'n/a'})" -ForegroundColor Gray
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

    'simplify-text' {
        Write-Step "Simplifying Text for Token Efficiency"
        $simplifyScript = Join-Path $scriptDir 'simplify-text.ps1'
        if (-not (Test-Path $simplifyScript)) {
            Write-Error "Simplify text script not found: $simplifyScript"
            exit 1
        }

        if ([string]::IsNullOrWhiteSpace($Scope)) {
            Write-Host "Usage: wf.ps1 simplify-text '<text>'" -ForegroundColor Yellow
            Write-Host "       wf.ps1 simplify-text -Interactive" -ForegroundColor Yellow
            Write-Host "       wf.ps1 simplify-text -InputFile '<path>'" -ForegroundColor Yellow
        } else {
            & $simplifyScript -InputText $Scope -SaveMetrics
        }
    }

    'context-metrics' {
        Write-Step "Context Usage Metrics"
        $metricsScript = Join-Path $scriptDir '..\AUDIT-REPORTING\context-metrics-report.ps1'
        if (-not (Test-Path $metricsScript)) {
            Write-Error "Context metrics script not found: $metricsScript"
            exit 1
        }

        $days = 7
        if (-not [string]::IsNullOrWhiteSpace($Scope)) {
            if ($Scope -match '^\d+$') {
                $parsedDays = [int]$Scope
                if ($parsedDays -gt 0) {
                    $days = $parsedDays
                }
            }
        }

        & $metricsScript -Days $days
    }

    'token-guard' {
        Write-Step "Token Budget Guard"
        $guardScript = Join-Path $scriptDir '..\TELEMETRY-METRICS\token-budget-guard.ps1'
        if (-not (Test-Path $guardScript)) {
            Write-Error "Token budget guard script not found: $guardScript"
            exit 1
        }

        if ($Scope -match '^profile:(hard|balanced)$') {
            $selectedProfile = [string]$matches[1]
            Set-TokenAutopilotProfile -Profile $selectedProfile
            Write-Success "Token autopilot profile updated to: $selectedProfile"
            break
        }

        if ($Scope -eq 'auto') {
            Invoke-TokenBudgetGuard -Task 'general' -Risk 'medium' -EstimatedChars 4500
            Write-Success 'Token autopilot check completed.'
            break
        }

        $taskName = if ([string]::IsNullOrWhiteSpace($Scope)) { 'general' } else { $Scope }
        & $guardScript -Mode status -Task $taskName
    }

    'homologate' {
        Write-Step "Workspace Homologation"
        $homologateScript = Join-Path $scriptDir '..\..\validation\homologate-workspace.ps1'
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
        Write-Step "Parallel Agent Dispatch with Memory Persistence"
        $dispatchScript = Join-Path $scriptDir 'dispatch-agent.ps1'
        $memoryScript = Join-Path $scriptDir 'dispatch-memory-manager.ps1'
        
        if (-not (Test-Path $dispatchScript)) {
            Write-Error "Dispatch script not found: $dispatchScript"
            exit 1
        }
        
        if (-not (Test-Path $memoryScript)) {
            Write-Error "Dispatch memory manager not found: $memoryScript"
            exit 1
        }

        # Parse dispatch command: dispatch [agents|memory] [action] [params...]
        $dispatchParts = $Scope -split ' ', 3
        $dispatchAction = if ($dispatchParts[0]) { $dispatchParts[0].ToLower() } else { 'execute' }
        
        switch ($dispatchAction) {
            'memory' {
                # Memory management: dispatch memory [list|load|save|clear|sync]
                $memAction = if ($dispatchParts[1]) { $dispatchParts[1].ToLower() } else { 'list' }
                Write-Host "Memory action: $memAction" -ForegroundColor Gray
                
                $memArgs = @('-Action', $memAction)
                if ($JSON) { $memArgs += '-AsJson' }
                
                & $memoryScript @memArgs
            }
            'list' {
                # List dispatch memory for current session
                Write-Host "Listing dispatch memory for current session..." -ForegroundColor Gray
                & $memoryScript -Action 'list' -AsJson | ConvertFrom-Json | Format-Table -AutoSize
            }
            'sync' {
                # Synchronize dispatch memory
                Write-Host "Synchronizing dispatch memory..." -ForegroundColor Gray
                & $memoryScript -Action 'sync' -AsJson | ConvertFrom-Json | Format-Table -AutoSize
            }
            default {
                # Execute dispatch with agents
                $agents = if ($dispatchAction -ne 'execute') { $dispatchAction } else { $dispatchParts[1] }
                $task = if ($dispatchParts.Count -gt 2) { $dispatchParts[2] } else { '' }
                
                $dispatchArgs = @()
                if ($agents) { $dispatchArgs += @('-Agents', $agents) }
                if ($task) { $dispatchArgs += @('-Task', $task) }
                if ($JSON) { $dispatchArgs += '-AsJson' }
                
                Invoke-TokenBudgetGuard -Task 'dispatch' -Risk 'medium' -EstimatedChars 5000
                & $dispatchScript @dispatchArgs
            }
        }
    }

    'install' {
        Write-Step "Foundation TUI Installer (FF-018)"
        $installScript = Join-Path $scriptDir '..\foundation-installer-tui.ps1'
        if (-not (Test-Path $installScript)) {
            Write-Error "Installer script not found: $installScript"
            exit 1
        }
        & $installScript @RemainingArgs
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

    'route' {
        $routerScript = Join-Path $scriptDir '..\MODEL-ROUTER\model-router.ps1'
        if (-not (Test-Path $routerScript)) {
            Write-Error "Model router script not found: $routerScript"
            exit 1
        }

        $scopeParts = $Scope -split ' ', 2
        $routeAction = if ($scopeParts[0]) { $scopeParts[0] } else { '' }

        $routeParams = @{
            Action       = $routeAction
            Agent        = ''
            Model        = ''
            Provider     = ''
            Temperature  = ''
            AdminPassword = ''
            AdminKeyFile = ''
        }

        $allRawArgs = @($RemainingArgs)
        if ($scopeParts.Count -gt 1) {
            $allRawArgs = @($scopeParts[1]) + $allRawArgs
        }

        $i = 0
        while ($i -lt $allRawArgs.Count) {
            $arg = $allRawArgs[$i]
            if ($arg.StartsWith('-')) {
                $key = $arg.TrimStart('-').ToLower()
                $i++
                $val = if ($i -lt $allRawArgs.Count) { $allRawArgs[$i] } else { '' }
                switch ($key) {
                    'agent'       { $routeParams.Agent = $val }
                    'model'       { $routeParams.Model = $val }
                    'provider'    { $routeParams.Provider = $val }
                    'temperature' { $routeParams.Temperature = $val }
                    'adminpassword' { $routeParams.AdminPassword = $val }
                    'adminkeyfile'  { $routeParams.AdminKeyFile = $val }
                    'json'        { $routeParams.JSON = $true; $i-- }
                }
            } else {
                if ([string]::IsNullOrWhiteSpace($routeParams.Agent)) {
                    $routeParams.Agent = $arg
                } elseif ([string]::IsNullOrWhiteSpace($routeParams.Model)) {
                    $routeParams.Model = $arg
                } elseif ([string]::IsNullOrWhiteSpace($routeParams.Provider)) {
                    $routeParams.Provider = $arg
                }
            }
            $i++
        }

        & $routerScript @routeParams
    }
}

exit 0
