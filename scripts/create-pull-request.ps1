# create-pull-request.ps1
# Automates Pull Request creation using GitHub CLI (gh).
# Designed to be invoked after a successful push in agnostic environments.

param(
    [string]$BaseBranch = "main"
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# The script operates on the repository where the user is currently located.

Write-Host "`nACTION: Validating Pull Request automation..." -ForegroundColor Cyan

# 1. Check for gh tool
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "WARN: GitHub CLI (gh) not detected in PATH." -ForegroundColor Yellow
    Write-Host "    If you just installed it, please restart your terminal or VS Code." -ForegroundColor Gray
    return
}

# 2. Verify authentication
$oldEAP = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$ghStatus = & gh auth status 2>&1
$ErrorActionPreference = $oldEAP
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: GitHub CLI not authenticated. Please run: gh auth login" -ForegroundColor Red
    return
}

# 3. Verify branches
$currentBranch = git branch --show-current
if ($currentBranch -eq $BaseBranch) {
    Write-Host "INFO: You are on the '$BaseBranch' branch. Cannot create a PR to itself." -ForegroundColor Gray
    Write-Host "       To create a PR, you must work on a feature branch." -ForegroundColor Gray
    return
}

# 4. Verify if the branch exists on remote
$remoteCheck = git ls-remote --heads origin $currentBranch
if (-not $remoteCheck) {
    Write-Host "WARN: Branch '$currentBranch' does not exist on remote 'origin'." -ForegroundColor Yellow
    Write-Host "    Perform a 'git push' before attempting to create the Pull Request." -ForegroundColor Gray
    return
}

# 5. Check if a PR already exists for this branch
Write-Host "INFO: Checking for existing active PR..." -ForegroundColor Gray
$existingPr = & gh pr view $currentBranch --json url --template "{{.url}}" 2>$null
if ($LASTEXITCODE -eq 0 -and $existingPr) {
    Write-Host "SUCCESS: A Pull Request already exists for this branch: $existingPr" -ForegroundColor Green
    if ((Read-Host "Open in browser? (y/n)") -eq 'y') {
        Start-Process $existingPr
    }
    return
}

# 6. Interactive creation process
$confirmation = Read-Host "Do you want to create a new Pull Request to merge '$currentBranch' into '$BaseBranch'? (y/n)"
if ($confirmation -eq 'y') {
    $title = "Session Update: $currentBranch -> $BaseBranch"
    $body = "Automated Pull Request generated after finishing the development session.`n`nBase Branch: $BaseBranch`nHead Branch: $currentBranch"
    
    Write-Host "INFO: Sending request to GitHub..." -ForegroundColor Cyan
    & gh pr create --base $BaseBranch --head $currentBranch --title "$title" --body "$body"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Pull Request created and available on the platform." -ForegroundColor Green
    } else {
        Write-Host "ERROR: Error creating the Pull Request. Please check the messages above." -ForegroundColor Red
    }
}