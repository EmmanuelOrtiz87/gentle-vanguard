# create-pull-request.ps1
# Automates Pull Request creation using GitHub CLI (gh).
# Designed to be invoked after a successful push in agnostic environments.

param(
    [string]$BaseBranch = "main"
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# The script operates on the repository where the user is currently located.

Write-Host "`n>> Validating Pull Request automation..." -ForegroundColor Cyan

# 1. Verify gh tool
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "[!] GitHub CLI (gh) not detected in PATH." -ForegroundColor Yellow
    Write-Host "    If you just installed it, please restart your terminal or VS Code." -ForegroundColor Gray
    return
}

# 2. Verify authentication
$oldEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$ghStatus = & gh auth status 2>&1
$ErrorActionPreference = $oldEAP
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] GitHub CLI not authenticated. Please run: gh auth login" -ForegroundColor Red
    return
}

# 3. Verify branches
$currentBranch = git branch --show-current
if ($currentBranch -eq $BaseBranch) {
    Write-Host "[!] You are currently on '$currentBranch', which is the target base branch." -ForegroundColor Yellow
    $BaseBranch = Read-Host "Enter the target base branch for this PR (e.g., main, develop) or press Enter to cancel"
    if ([string]::IsNullOrWhiteSpace($BaseBranch)) {
        Write-Host "[INFO] PR creation cancelled." -ForegroundColor Gray
        return
    }
}

# 4. Verify if the branch exists on remote
$remoteCheck = git ls-remote --heads origin $currentBranch
if (-not $remoteCheck) {
    Write-Host "[!] The branch '$currentBranch' is not on 'origin' remote." -ForegroundColor Yellow
    if ((Read-Host "Do you want to push '$currentBranch' to remote now? (y/n)") -eq 'y') {
        git push -u origin $currentBranch
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to push branch. Cannot create PR."
            return
        }
    } else {
        Write-Host "[INFO] PR creation requires the branch to be on remote. Cancelled." -ForegroundColor Gray
        return
    }
}

# 4.5 Verify if there are commits to merge
$diffCheck = git log "origin/$BaseBranch..$currentBranch" --oneline 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($diffCheck)) {
    Write-Host "[!] No new commits found in '$currentBranch' relative to 'origin/$BaseBranch'." -ForegroundColor Yellow
    return
}

# 5. Verify if a PR already exists for this branch
Write-Host "[INFO] Checking for existing PRs from '$currentBranch' to '$BaseBranch'..." -ForegroundColor Gray
$existingPrsJson = & gh pr list --head $currentBranch --base $BaseBranch --state open --json url 2>$null

$existingPr = $null
if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($existingPrsJson) -and $existingPrsJson -ne "[]") {
    try {
        $prObjects = $existingPrsJson | ConvertFrom-Json
        if ($prObjects.Count -gt 0) {
            $existingPr = $prObjects[0].url
        }
    } catch {
        Write-Warning "Could not parse output from 'gh pr list': $_"
    }
}

if ($existingPr) {
    Write-Host "[OK] A Pull Request already exists for this branch: $existingPr" -ForegroundColor Green
    if ((Read-Host "Do you want to open it in the browser? (y/n)") -eq 'y') {
        Start-Process $existingPr
    }
    return
}
Write-Host "[INFO] No active Pull Requests found for '$currentBranch' to '$BaseBranch'." -ForegroundColor Gray

# 6. Interactive creation process
Write-Host "`n>> Pull Request Configuration" -ForegroundColor Cyan
$titleDefault = "feat: session updates from $currentBranch"
$title = Read-Host "Enter PR Title [$titleDefault]"
if ([string]::IsNullOrWhiteSpace($title)) { $title = $titleDefault }

$bodyDefault = "Automated PR generated after development session.`n`nBase: $BaseBranch`nHead: $currentBranch"
$body = Read-Host "Enter PR Description (Optional)"
if ([string]::IsNullOrWhiteSpace($body)) { $body = $bodyDefault }

$asDraft = (Read-Host "Create as Draft? (y/n) [n]") -eq 'y'

$confirm = Read-Host "Ready to create PR from '$currentBranch' to '$BaseBranch'? (y/n)"
if ($confirm -eq 'y') {
    Write-Host "[INFO] Sending request to GitHub..." -ForegroundColor Cyan
    
    if ($asDraft) {
        & gh pr create --base $BaseBranch --head $currentBranch --title $title --body $body --draft
    } else {
        & gh pr create --base $BaseBranch --head $currentBranch --title $title --body $body
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Pull Request created successfully." -ForegroundColor Green
    } else {
        Write-Host "[!] Error creating the Pull Request. Verify if there are conflicts or branch issues." -ForegroundColor Red
    }
}