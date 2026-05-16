function Get-GitInfo {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $status = git status --porcelain 2>$null
    $hasChanges = $status -and $status.Trim() -ne ''
    $ahead = 0; $behind = 0
    $upstream = git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>$null
    if ($upstream) {
        $counts = git rev-list --left-right --count "@{upstream}...HEAD" 2>$null
        if ($counts -and $counts -match '^(\d+)\s+(\d+)$') { $behind = [int]$matches[1]; $ahead = [int]$matches[2] }
    }
    @{ Branch = $branch; HasChanges = $hasChanges; Status = $status; Ahead = $ahead; Behind = $behind }
}

function Assert-GitRepository {
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Error "Current directory is not a git repository."; return $false }
    $true
}

function Get-BranchStatus {
    $gitInfo = Get-GitInfo
    if ($gitInfo.Branch -eq 'main' -or $gitInfo.Branch -eq 'develop') {
        Write-Warning "You are on branch: $($gitInfo.Branch)"
        if (-not $global:Force) { Write-Host "Use -Force to proceed." -ForegroundColor Yellow; return $false }
    }
    $true
}

function Get-GitFlowBaseForBranch {
    param([string]$Branch)
    if ($Branch -match '^(feature|bugfix|chore)/.+') { return 'develop' }
    if ($Branch -match '^(hotfix|release)/.+') { return 'main' }
    if ($Branch -eq 'develop') { return 'develop' }
    'main'
}

function Get-WorkflowCheckpoints {
    $lines = git stash list 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $lines) { return @() }
    @($lines | Where-Object { $_ -match 'gv-checkpoint:' })
}

function Get-WorkflowCheckpointRefs {
    $refs = @()
    foreach ($entry in Get-WorkflowCheckpoints) {
        if ($entry -match '^(stash@\{\d+\})') { $refs += $matches[1] }
    }
    $refs
}

function Get-OldWorkflowCheckpoints {
    param([int]$ThresholdDays = 7)
    $cutoff = (Get-Date).AddDays(-1 * $ThresholdDays)
    $oldRefs = @()
    foreach ($ref in Get-WorkflowCheckpointRefs) {
        $dateRaw = git show -s --format=%cI $ref 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($dateRaw)) { continue }
        try { if ([DateTimeOffset]::Parse([string]$dateRaw).LocalDateTime -lt $cutoff) { $oldRefs += $ref } } catch {}
    }
    $oldRefs
}

function Warn-OldWorkflowCheckpoints {
    param([int]$ThresholdDays = 7)
    if (-not (Assert-GitRepository)) { return }
    $oldRefs = Get-OldWorkflowCheckpoints -ThresholdDays $ThresholdDays
    if ($oldRefs.Count -gt 0) {
        Write-Warning "Found $($oldRefs.Count) checkpoint(s) older than $ThresholdDays days. Use 'gv list-checkpoints'."
        Write-Host "Tip: drop stale checkpoints with 'git stash drop <stash@{n}>'" -ForegroundColor Cyan
    }
}

function Invoke-LiveCheckpoint {
    param([string]$Label)
    if (-not (Assert-GitRepository)) { exit 1 }
    $status = git status --porcelain 2>$null
    if (-not $status -or [string]::IsNullOrWhiteSpace(($status -join ''))) { Write-Warning "No local changes detected."; return }
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $safeLabel = (($Label -replace '\s+', '-') -replace '[^a-zA-Z0-9\-]', '').ToLowerInvariant().Trim('-')
    if ([string]::IsNullOrWhiteSpace($safeLabel)) { $safeLabel = "snapshot" }
    $stashMessage = "gv-checkpoint:$($branch):$($safeLabel):$($timestamp)"
    git stash push -u -m $stashMessage | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Error "Failed to create checkpoint."; exit 1 }
    Write-Success "Checkpoint created: $stashMessage"
    Write-Host "Restore: gv rollback-checkpoint | List: gv list-checkpoints" -ForegroundColor Cyan
}

function Show-LiveCheckpoints {
    if (-not (Assert-GitRepository)) { exit 1 }
    $checkpoints = Get-WorkflowCheckpoints
    if (-not $checkpoints) { Write-Warning "No workflow checkpoints found."; return }
    Write-Step "Available workflow checkpoints"
    foreach ($entry in $checkpoints) { Write-Host "  $entry" }
}

function Resolve-CheckpointReference {
    param([string]$Selector)
    $checkpoints = Get-WorkflowCheckpoints
    if (-not $checkpoints) { return $null }
    if ([string]::IsNullOrWhiteSpace($Selector)) {
        if ($checkpoints[0] -match '^(stash@\{\d+\})') { return $matches[1] }
        return $null
    }
    if ($Selector -match '^stash@\{\d+\}$') { return $Selector }
    $match = $checkpoints | Where-Object { $_ -like "*$Selector*" } | Select-Object -First 1
    if ($match -and $match -match '^(stash@\{\d+\})') { return $matches[1] }
    $null
}

function Invoke-RollbackCheckpoint {
    param([string]$Selector)
    if (-not (Assert-GitRepository)) { exit 1 }
    $stashRef = Resolve-CheckpointReference -Selector $Selector
    if ([string]::IsNullOrWhiteSpace($stashRef)) { Write-Error "No matching checkpoint found."; exit 1 }
    git stash pop $stashRef
    if ($LASTEXITCODE -ne 0) { Write-Warning "Checkpoint apply reported conflicts."; exit 1 }
    Write-Success "Checkpoint restored from $stashRef"
}

function Invoke-CleanBranches {
    param([switch]$ApplyNow)
    if (-not (Assert-GitRepository)) { exit 1 }
    git fetch origin 2>$null | Out-Null
    $currentBranch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
    $mergedDevelop = @(git branch --merged origin/develop 2>$null)
    $mergedMain = @(git branch --merged origin/main 2>$null)
    $allMerged = @($mergedDevelop + $mergedMain) | ForEach-Object { $_.Replace('*', '').Trim() } | Where-Object { $_ } | Sort-Object -Unique
    $candidates = $allMerged | Where-Object { $_ -match '^(feature|bugfix|release|chore)/' } | Where-Object { $_ -ne $currentBranch }
    if (-not $candidates) { Write-Success 'No merged branches to clean.'; return }
    Write-Step 'Merged local branches eligible for cleanup'
    foreach ($b in $candidates) { Write-Host "  $b" }
    if (-not $ApplyNow) { Write-Host "Preview only. Use 'gv clean-branches apply' to delete." -ForegroundColor Cyan; return }
    if (-not $global:Force) { $confirm = Read-Host "Delete these branches? (yes/no)"; if ($confirm -notmatch '^(y|yes|si|s)$') { Write-Warning 'Cancelled.'; return } }
    foreach ($b in $candidates) {
        git branch -d $b 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Success "Deleted: $b"; continue }
        if ($global:Force) { git branch -D $b 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { Write-Success "Force-deleted: $b" } else { Write-Warning "Could not delete: $b" } }
        else { Write-Warning "Could not delete with -d: $b (use -Force)" }
    }
}

function Test-Secrets {
    Write-Step "Checking for secrets..."
    $patterns = @(
        @{ Name = "AWS Key"; Pattern = 'AKIA[0-9A-Z]{16}' }
        @{ Name = "GitHub Token"; Pattern = 'ghp_[A-Za-z0-9]{36}' }
        @{ Name = "Private Key"; Pattern = '-----BEGIN.*PRIVATE KEY-----' }
        @{ Name = "Stripe Key"; Pattern = 'sk_live_[0-9a-zA-Z]{24,}' }
    )
    $staged = git diff --cached --name-only 2>$null
    $found = @()
    foreach ($file in $staged) {
        $content = git show ":0:$file" 2>$null
        if ($content) { foreach ($p in $patterns) { if ($content -match $p.Pattern) { $found += @{ File = $file; Pattern = $p.Name }; Write-Error "Secret: $($p.Name) in $file" } } }
    }
    if ($found.Count -eq 0) { Write-Success "No secrets detected"; return $true }
    $false
}

function Test-GoTests {
    if (-not (Test-Path (Join-Path $global:repoRoot 'go.mod'))) { return $true }
    Write-Step "Running Go tests..."
    Set-Location $global:repoRoot; $result = go test ./... 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Success "Go tests passed"; return $true }
    Write-Error "Go tests failed"; $false
}

function Test-AngularTests {
    $webDir = Join-Path $global:repoRoot 'web'
    if (-not (Test-Path $webDir)) { return $true }
    Write-Step "Running Angular tests..."
    Set-Location $webDir; npm test 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Success "Angular tests passed"; return $true }
    Write-Error "Angular tests failed"; $false
}

function Get-TestSuiteStatus {
    $goStatus = if (Test-Path (Join-Path $global:repoRoot 'go.mod')) { 'AVAILABLE (not run in audit)' } else { 'NOT DETECTED' }
    $webDir = Join-Path $global:repoRoot 'web'
    $angularStatus = if ((Test-Path $webDir) -and (Test-Path (Join-Path $webDir 'package.json'))) { 'AVAILABLE (not run in audit)' } else { 'NOT DETECTED' }
    @{ Go = $goStatus; Angular = $angularStatus }
}

function Get-CommitHistory {
    param([int]$Count = 5)
    git log --oneline -n $Count 2>$null
}

function New-AuditDocument {
    param([string]$OutputPath)
    Write-Step "Generating Audit Document..."
    $gitInfo = Get-GitInfo; $date = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    $commits = Get-CommitHistory -Count 10
    $commitLines = if ($commits) { ($commits | ForEach-Object { "- $_" }) -join [Environment]::NewLine } else { '- none' }
    $summaryText = if ($commits.Count -gt 0) { "Latest: $($commits[0])" } else { 'No recent commits.' }
    $deliveryStatus = if ($gitInfo.HasChanges) { 'IN PROGRESS' } else { 'READY' }
    $deliveryNote = if ($gitInfo.HasChanges) { 'Working tree has pending changes.' } else { 'Working tree clean.' }
    $operationalRisk = if ($gitInfo.Behind -gt 0) { @{Status='HIGH'; Note="Behind upstream by $($gitInfo.Behind) commit(s)"} } elseif ($gitInfo.HasChanges -or $gitInfo.Ahead -gt 0) { @{Status='MEDIUM'; Note="Ahead: $($gitInfo.Ahead), pending: $($gitInfo.HasChanges)"} } else { @{Status='LOW'; Note='No divergence.'} }
    $tests = Get-TestSuiteStatus
    $metrics = Get-ContextMetricsSnapshot -Days 7
    $auditContent = @"
# Audit Document - $date

**Project:** $(Split-Path $global:repoRoot -Leaf)
**Branch:** $($gitInfo.Branch)
**Date:** $date

## Summary
$summaryText

## Executive Overview
| Area | Status | Notes |
|---|---|---|
| Delivery | $deliveryStatus | $deliveryNote |
| Operational Risk | $($operationalRisk.Status) | $($operationalRisk.Note) |
| Context Efficiency | $($metrics.HealthStatus) | $($metrics.Recommendation) |

## Git
| Item | Value |
|---|---|
| Branch | $($gitInfo.Branch) |
| Changes | $($gitInfo.HasChanges) |
| Ahead/Behind | $($gitInfo.Ahead)/$($gitInfo.Behind) |

## Recent Commits
$commitLines

## Tests
| Suite | Status |
|---|---|
| Go | $($tests.Go) |
| Angular | $($tests.Angular) |

## Context Efficiency
$($metrics.Lines -join "`n")
"@
    $auditContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Success "Audit document: $OutputPath"
}

function New-PRDescription {
    param([string]$OutputPath)
    @"
## Summary
`[Brief description]`

## Changes
- Feature / Bug fix / Refactor

## Testing
- [ ] Tests pass
- [ ] Manual testing done

## Checklist
- [ ] No secrets committed
- [ ] Code follows conventions
- [ ] Documentation updated
"@ | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Success "PR template: $OutputPath"
}

function Show-Status {
    $gitInfo = Get-GitInfo
    $checkpointCount = 0; $oldCheckpointCount = 0
    if (Assert-GitRepository) { $checkpointCount = (Get-WorkflowCheckpoints).Count; $oldCheckpointCount = (Get-OldWorkflowCheckpoints -ThresholdDays 7).Count }
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Project Status" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Branch: $($gitInfo.Branch)`nHas Changes: $($gitInfo.HasChanges)`nCheckpoints: $checkpointCount"
    if ($oldCheckpointCount -gt 0) { Write-Warning "$oldCheckpointCount checkpoint(s) older than 7 days" }
    if ($gitInfo.HasChanges) { Write-Host "`nUncommitted:" -ForegroundColor Yellow; $gitInfo.Status | ForEach-Object { Write-Host "  $_" } }
    Write-Host "`nRecent commits:" -ForegroundColor Cyan
    Get-CommitHistory -Count 3 | ForEach-Object { Write-Host "  $_" }
}

function Invoke-GitFlowValidation {
    param([switch]$EnforcePrBase, [string]$PrBase)
    $script = Join-Path $global:scriptDir '..\diagnostics\validate-gitflow.ps1'
    if (-not (Test-Path $script)) { return @{ Passed = $true; Detail = 'validate-gitflow.ps1 not found (skipped)'; Suggestion = ''; Fixable = $false } }
    $args = @(); if ($EnforcePrBase) { $args += '-EnforcePrBase'; if ($PrBase) { $args += @('-PrBase', $PrBase) } }
    Write-Step 'Running GitFlow policy validation...'
    Invoke-LocalPowerShellScript -ScriptPath $script -ScriptArgs $args
    if ($LASTEXITCODE -eq 0) { return @{ Passed = $true; Detail = 'GitFlow validation passed.'; Suggestion = ''; Fixable = $false } }
    @{ Passed = $false; Detail = "GitFlow validation failed (exit $LASTEXITCODE)."; Suggestion = 'Use valid branch type per GitFlow policy.'; Fixable = $false }
}

function Invoke-ScriptGovernanceValidation {
    $script = Join-Path $global:scriptDir '..\diagnostics\validate-script-governance.ps1'
    if (-not (Test-Path $script)) { return @{ Passed = $true; Detail = 'validate-script-governance.ps1 not found (skipped)'; Suggestion = ''; Fixable = $false } }
    Write-Step 'Running script governance validation...'
    Invoke-LocalPowerShellScript -ScriptPath $script
    if ($LASTEXITCODE -eq 0) { return @{ Passed = $true; Detail = 'Script governance passed.'; Suggestion = ''; Fixable = $false } }
    @{ Passed = $false; Detail = "Script governance failed (exit $LASTEXITCODE)."; Suggestion = "Run 'gv homologate apply' and retry."; Fixable = $true }
}

function Resolve-PublishMode {
    param([string]$RequestedMode, [switch]$ForceMode)
    $normalized = if ($RequestedMode) { $RequestedMode.Trim().ToLowerInvariant() } else { '' }
    switch ($normalized) { 'pr' { return 'push+pr' } 'push+pr' { return 'push+pr' } 'with-pr' { return 'push+pr' } 'later' { return 'push-only' } 'push-only' { return 'push-only' } 'only-push' { return 'push-only' } }
    if ($ForceMode) { return 'push-only' }
    Write-Host "`nChoose publish mode:" -ForegroundColor Cyan
    Write-Host "  1) Push + PR now`n  2) Push only (PR later)" -ForegroundColor Yellow
    if ((Read-Host "Enter 1 or 2") -eq '1') { return 'push+pr' }
    'push-only'
}

function Invoke-AutomaticSuggestions {
    param([array]$Findings)
    $actions = @()
    $hasGovernance = $Findings | Where-Object { $_.Code -eq 'governance' -and $_.Fixable }
    if ($hasGovernance) {
        $homologate = Join-Path $global:repoRoot 'scripts\validation\homologate-workspace.ps1'
        if (Test-Path $homologate) { Write-Step 'Applying homologation...'; Invoke-LocalPowerShellScript -ScriptPath $homologate -ScriptArgs @('-Apply'); if ($LASTEXITCODE -eq 0) { $actions += 'Applied homologation fixes.' } else { $actions += "Homologation apply failed (exit $LASTEXITCODE)." } }
    }
    $actions
}

function Write-PublishDecisionLog {
    param([string]$Decision, [array]$Findings, [array]$Actions, [string]$Notes = '')
    $sessionsDir = Join-Path $global:repoRoot 'docs/sessions'
    if (-not (Test-Path $sessionsDir)) { New-Item -ItemType Directory -Path $sessionsDir -Force | Out-Null }
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
    $filePath = Join-Path $sessionsDir "$timestamp-publish-decision.md"
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
    $findingsLines = if ($Findings) { ($Findings | ForEach-Object { "- [$($_.Severity)] $($_.Code): $($_.Detail)" }) -join "`n" } else { '- None' }
    $actionLines = if ($Actions) { ($Actions | ForEach-Object { "- $_" }) -join "`n" } else { '- None' }
    @"
# Publish Decision - $timestamp
**Branch:** $branch | **Decision:** $Decision
## Findings
$findingsLines
## Actions
$actionLines
## Notes
$Notes
"@ | Out-File -FilePath $filePath -Encoding UTF8
    Write-Success "Decision log: $filePath"
}

function Ensure-PublishCommit {
    $gitInfo = Get-GitInfo
    if (-not $gitInfo.HasChanges) { return $true }
    $defaultMessage = 'chore(publish): apply validated release changes'
    $message = Read-Host "Enter commit message or Enter for default [$defaultMessage]"
    if ([string]::IsNullOrWhiteSpace($message)) { $message = $defaultMessage }
    git add .; if ($LASTEXITCODE -ne 0) { Write-Error 'git add failed.'; return $false }
    git commit -m $message; if ($LASTEXITCODE -ne 0) { Write-Error 'git commit failed.'; return $false }
    Write-Success 'Changes committed.'; $true
}

function Ensure-PullRequest {
    param([string]$Branch)
    $targetBase = Get-GitFlowBaseForBranch -Branch $Branch
    $existingJson = gh pr view --head $Branch --json number,url,state,baseRefName 2>$null
    if ($LASTEXITCODE -eq 0 -and $existingJson) { try { $pr = $existingJson | ConvertFrom-Json; if ($pr.baseRefName -ne $targetBase) { Write-Error "PR base '$($pr.baseRefName)' != '$targetBase'."; return $null }; return $pr } catch {} }
    $prPath = Join-Path $global:repoRoot '.github/PULL_REQUEST_TEMPLATE.md'
    $prDir = Split-Path $prPath; if (-not (Test-Path $prDir)) { New-Item -ItemType Directory -Path $prDir -Force | Out-Null }
    if (-not (Test-Path $prPath)) { New-PRDescription -OutputPath $prPath }
    $title = git log -1 --pretty=%s 2>$null; if (-not $title) { $title = 'chore(publish): automated publish flow' }
    gh pr create --base $targetBase --head $Branch --title $title --body-file $prPath | Out-Null
    if ($LASTEXITCODE -ne 0) { return $null }
    $createdJson = gh pr view --head $Branch --json number,url,state,baseRefName 2>$null
    if (-not $createdJson) { return $null }
    try { return ($createdJson | ConvertFrom-Json) } catch { $null }
}

function Invoke-PublishWorkflow {
    param([switch]$SkipReviewGate, [switch]$SkipTestsGate, [switch]$SkipHomologationGate, [switch]$ForceMode)
    if (-not (Get-BranchStatus)) { return }
    Warn-OldWorkflowCheckpoints -ThresholdDays 7
    if (-not $SkipHomologationGate) {
        Write-Step "Homologation Gate"
        $gate = Join-Path $global:repoRoot 'scripts\utilities\DEPLOYMENT\validate-release-homologation.ps1'
        if (Test-Path $gate) { & $gate -PrivateRepo $global:repoRoot; if ($LASTEXITCODE -ne 0) { Write-Host "[BLOCKED]" -ForegroundColor Red; return } }
    }
    Write-Step "Generating SBOM"
    $sbomScript = Join-Path $global:repoRoot 'scripts\utilities\DEPLOYMENT\generate-sbom.ps1'
    if (Test-Path $sbomScript) { & $sbomScript -RepoRoot $global:repoRoot; if ($LASTEXITCODE -ne 0) { Write-Warning "SBOM failed (non-blocking)." } }
    $attempt = 1
    while ($attempt -le 2) {
        Write-Step "Publish validation attempt $attempt/2"
        $findings = @(); $actions = @()
        if (-not $SkipReviewGate -and -not (Test-Secrets)) { $findings += [pscustomobject]@{Code='secrets';Severity='CRITICAL';Detail='Secrets scan failed.';Suggestion='Remove secrets.';Fixable=$false} }
        if (-not $SkipTestsGate) {
            if (-not (Test-GoTests)) { $findings += [pscustomobject]@{Code='go-tests';Severity='HIGH';Detail='Go tests failed.';Suggestion='Fix tests.';Fixable=$false} }
            if (-not (Test-AngularTests)) { $findings += [pscustomobject]@{Code='angular-tests';Severity='HIGH';Detail='Angular tests failed.';Suggestion='Fix tests.';Fixable=$false} }
        }
        $gitInfo = Get-GitInfo; $targetBase = Get-GitFlowBaseForBranch -Branch $gitInfo.Branch
        $gv = Invoke-GitFlowValidation -EnforcePrBase -PrBase $targetBase
        if (-not $gv.Passed) { $findings += [pscustomobject]@{Code='gitflow';Severity='HIGH';Detail=$gv.Detail;Suggestion=$gv.Suggestion;Fixable=$gv.Fixable} }
        $gov = Invoke-ScriptGovernanceValidation
        if (-not $gov.Passed) { $findings += [pscustomobject]@{Code='governance';Severity='HIGH';Detail=$gov.Detail;Suggestion=$gov.Suggestion;Fixable=$gov.Fixable} }
        if ($findings.Count -eq 0) {
            Write-Success 'All validations passed.'
            if (-not (Ensure-PublishCommit)) { Write-PublishDecisionLog -Decision 'blocked-commit' -Findings $findings -Actions $actions; return }
            $branch = (Get-GitInfo).Branch; git push -u origin $branch
            if ($LASTEXITCODE -ne 0) { Write-Error 'Push failed.'; Write-PublishDecisionLog -Decision 'blocked-push' -Findings $findings -Actions $actions; return }
            $actions += "Pushed: $branch"
            $pr = Ensure-PullRequest -Branch $branch
            if (-not $pr) { Write-Error 'PR creation failed.'; Write-PublishDecisionLog -Decision 'blocked-pr' -Findings $findings -Actions $actions; return }
            $actions += "PR: $($pr.url)"
            gh pr merge $($pr.number) --squash --delete-branch
            if ($LASTEXITCODE -eq 0) { $actions += "Merged PR #$($pr.number)."; Write-Success "Merged: $($pr.url)" }
            else { $actions += "Auto-merge failed for PR #$($pr.number)."; Write-Warning 'Auto-merge failed (branch protection?).' }
            Write-PublishDecisionLog -Decision 'completed' -Findings $findings -Actions $actions; return
        }
        Write-Warning 'Validation alerts:'; $findings | ForEach-Object { Write-Host "  [$($_.Severity)] $($_.Code): $($_.Detail)" -ForegroundColor Yellow }
        if ((Read-Host 'Apply suggestions and retry? (yes/no)') -match '^(y|yes|si|s)$') { $applied = Invoke-AutomaticSuggestions -Findings $findings; $actions += $applied; Write-PublishDecisionLog -Decision 'retry-after-fix' -Findings $findings -Actions $actions; $attempt++; continue }
        if ((Read-Host 'Merge with risks? (yes/no)') -match '^(y|yes|si|s)$') {
            if (-not (Ensure-PublishCommit)) { Write-PublishDecisionLog -Decision 'override-commit-failed' -Findings $findings -Actions $actions; return }
            $branch = (Get-GitInfo).Branch; git push -u origin $branch; $pr = Ensure-PullRequest -Branch $branch
            if ($pr) { $actions += "PR: $($pr.url)"; gh pr merge $($pr.number) --squash --delete-branch }
            Write-PublishDecisionLog -Decision 'override-accepted' -Findings $findings -Actions $actions; return
        }
        Write-PublishDecisionLog -Decision 'blocked-declined' -Findings $findings -Actions $actions; return
    }
    Write-Warning 'Publish stopped after retry with remaining alerts.'
}

function Show-Help {
    Write-Host @"
Gentle-Vanguard - Development Stack Workflow CLI

USAGE: gv.ps1 <command> [options]

COMMANDS:
  review, audit, pr, push, publish — Code review & publish
  status, health, verify, diagnose — System status
  start-session, end-session, task-brief — Session management
  agent, dispatch, events, route, skills — Multi-agent
  dashboard, mq, benchmark, version — Monitoring & tools
  checkpoint, clean-branches, homologate — Git workflow
  context-pack, compact-start, token-guard — Context efficiency
  help — This help

Run 'gv.ps1 <command>' for command-specific help.
Full docs: https://github.com/gentleman/gentle-vanguard
"@
}

function Show-IdeStatus {
    Write-Step "IDE Session Detection"
    $detectScript = Join-Path $global:scriptDir '..\UTILITIES\detect-ide-session.ps1'
    if (-not (Test-Path $detectScript)) { Write-Error "detect-ide-session.ps1 not found."; exit 1 }
    $ideDataRaw = & $detectScript -AsJson -Quiet 2>$null
    if ($ideDataRaw -is [array]) { $ideDataRaw = ($ideDataRaw -join "`n") }
    $jsonStart = [string]$ideDataRaw | ForEach-Object { $_.IndexOf('{') } | Select-Object -First 1
    $text = [string]$ideDataRaw; if ($jsonStart -gt 0) { $text = $text.Substring($jsonStart) }
    try { $ideData = $text | ConvertFrom-Json -ErrorAction Stop }
    catch { Write-Error "Invalid JSON from IDE detection."; Write-Host $text -ForegroundColor DarkGray; exit 1 }
    Write-Host "IDE: $($ideData.ideName) | Confidence: $($ideData.confidence) | Session: $($ideData.isIdeSession)"
    Write-Host "Activation: $($ideData.recommendedActivationCommand)" -ForegroundColor Cyan
    Write-Host "Session: $($ideData.recommendedSessionCommand)" -ForegroundColor Cyan
}


