# finalize-session.ps1 (Foundation Core)
# Automates validation, Engram persistence, versioning, and publishing.
# Supports interactive flows for:
# 1. Git identity configuration (user/email).
# 2. Git repository initialization if it doesn't exist.
# 3. Remote repository creation via GitHub CLI (gh).
# 4. Synchronization with intelligent retries and Pull Request creation.

param(
    [string]$GitUser,
    [string]$GitEmail
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Resolve-Path (Join-Path $scriptDir "..")
$projectName = Split-Path $projectRoot -Leaf # Get the current project name from the root directory
Set-Location $projectRoot

$targetBranch = "main" # Default branch defined early for initialization

Write-Host "STARTING: Session finalization for $projectName..." -ForegroundColor Cyan

# 0. Verify and initialize Git repository if missing
if (-not (Test-Path (Join-Path $projectRoot ".git"))) {
    Write-Host "WARN: No Git repository detected in the project root." -ForegroundColor Yellow
    $confirmInit = Read-Host "Do you want to initialize a new Git repository now? (y/n)"
    if ($confirmInit -eq 'y') {
        # Attempt initialization with specified branch (modern Git)
        git init -b $targetBranch 2>$null
        if ($LASTEXITCODE -ne 0) {
            git init
            git checkout -b $targetBranch
        }
        Write-Host "SUCCESS: Git repository initialized on branch '$targetBranch'." -ForegroundColor Green
    } else {
        Write-Error "Cannot proceed with publishing without a Git repository."
        exit 1
    }
}

# 1. Apply identity immediately if parameters are passed
if (-not [string]::IsNullOrWhiteSpace($GitUser)) { git config user.name "$GitUser" }
if (-not [string]::IsNullOrWhiteSpace($GitEmail)) { git config user.email "$GitEmail" }

# 2. Verify/Request configuration if missing (Check global as fallback)
while ([string]::IsNullOrWhiteSpace($(git config --get user.name 2>$null))) {
    Write-Host "WARN: Git user.name not detected." -ForegroundColor Yellow
    $inputUser = Read-Host "Enter your full name for Git (or 'exit' to cancel)"
    if ($inputUser -eq "exit") { exit 1 }
    if (-not [string]::IsNullOrWhiteSpace($inputUser)) {
        git config --global user.name "$inputUser"
        git config user.name "$inputUser" # Set local config too
    }
}

while ([string]::IsNullOrWhiteSpace($(git config --get user.email 2>$null))) {
    Write-Host "WARN: Git user.email not detected." -ForegroundColor Yellow
    $inputEmail = Read-Host "Enter your email for Git (or 'exit' to cancel)"
    if ($inputEmail -eq "exit") { exit 1 }
    if (-not [string]::IsNullOrWhiteSpace($inputEmail)) {
        git config --global user.email "$inputEmail"
        git config user.email "$inputEmail" # Set local config too
    }
}

# 1. Validate and integrate changes into Engram memory
& (Join-Path $scriptDir "validate-project.ps1")

# 3. Git Workflow & Branch Management
Write-Host "`nACTION: Branch Management and Versioning..." -ForegroundColor Cyan

$currentBranch = git branch --show-current
$availableBranches = git branch --format="%(refname:short)" 2>$null

if ([string]::IsNullOrWhiteSpace($currentBranch) -and -not $availableBranches) {
    # Case: Brand new repository with no commits
    $targetBranch = Read-Host "No branches detected. Enter name for initial branch [main]"
    if ([string]::IsNullOrWhiteSpace($targetBranch)) { $targetBranch = "main" }
} else {
    Write-Host "Current branch: $currentBranch" -ForegroundColor Gray
    $branchAction = Read-Host "Use (c)urrent branch, (s)elect existing, or create (n)ew branch? [c]"
    
    switch ($branchAction.ToLower()) {
        "s" {
            Write-Host "Available local branches:" -ForegroundColor Gray
            $availableBranches | ForEach-Object { Write-Host " - $_" -ForegroundColor Gray }
            $targetBranch = Read-Host "Enter branch name to use"
            if ($availableBranches -notcontains $targetBranch) {
                Write-Error "Branch '$targetBranch' does not exist."
                exit 1
            }
            git checkout $targetBranch
        }
        "n" {
            $targetBranch = Read-Host "Enter name for the new branch"
            if ([string]::IsNullOrWhiteSpace($targetBranch)) { Write-Error "Branch name is required."; exit 1 }
            git checkout -b $targetBranch
        }
        default {
            $targetBranch = $currentBranch
            if ([string]::IsNullOrWhiteSpace($targetBranch)) { $targetBranch = "main" }
        }
    }
}

Write-Host "[INFO] Operating on branch: $targetBranch" -ForegroundColor Yellow

# Verify and report on current remote
if (git remote | Select-String -Quiet "^origin$") {
    $currentRemote = git remote get-url origin
    Write-Host "[INFO] Current 'origin' remote: $currentRemote" -ForegroundColor Gray
    $changeRemote = Read-Host "The current remote might be invalid. Do you want to remove it to configure a new one or create it in the cloud? (y/n)"
    if ($changeRemote -eq 'y') {
        git remote remove origin
        Write-Host "Remote removed. A new one will be requested." -ForegroundColor Yellow
    }
}

# Check for origin remote existence
if (-not (git remote | Select-String "origin")) {
    Write-Host "[!] No 'origin' remote found." -ForegroundColor Yellow
    
    $remoteUrl = ""

    # Intelligence: GitHub CLI (gh) integration for automatic creation
    $ghCli = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghCli) {
        $oldEAP = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue' # Avoid breaking script on gh auth status errors
        $ghStatus = & gh auth status 2>&1
        $ErrorActionPreference = $oldEAP
        if ($LASTEXITCODE -eq 0) {
            if ((Read-Host "Do you want to create the repository automatically on GitHub? (y/n)") -eq 'y') {
                $repoDefault = Split-Path -Leaf $projectRoot
                $repoName = Read-Host "Repository name [$repoDefault]"
                if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = $repoDefault }
                $vis = Read-Host "Privacy? (1) Public, (2) Private [Default: Private]"
                $visFlag = if ($vis -eq "1") { "--public" } else { "--private" }
                
                Write-Host "[INFO] Creating repository '$repoName' on GitHub..." -ForegroundColor Cyan
                & gh repo create $repoName $visFlag --source=. --remote=origin -y # -y to accept prompts
                if ($LASTEXITCODE -eq 0) { $remoteUrl = "created_by_cli" }
            }
        } else {
            Write-Host "[!] GitHub CLI detected but not authenticated." -ForegroundColor Yellow
            if ((Read-Host "Do you want to log in to GitHub now to enable automatic creation? (y/n)") -eq 'y') {
                & gh auth login
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Authentication successful. Restart the script to use auto-creation or enter the URL manually." -ForegroundColor Cyan
                }
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        Write-Host "If you haven't created the repository in the cloud, do it now on GitHub or Bitbucket." -ForegroundColor Gray
    }

    while ([string]::IsNullOrWhiteSpace($remoteUrl)) {
        $userInput = Read-Host "Enter the repository URL (e.g., https://github.com/user/repo.git) or just the repo NAME"
        
        if ($userInput -eq "skip") { $remoteUrl = "skip"; break }
        if ([string]::IsNullOrWhiteSpace($userInput)) {
            Write-Warning "Input cannot be empty. Try again or type 'skip'."
            continue
        }

        # Intelligence: If no '/' or ':', assume it's a repo name and suggest URL based on current user
        if ($userInput -notmatch "/" -and $userInput -notmatch ":") {
            $gitUser = git config user.name
            if ([string]::IsNullOrWhiteSpace($gitUser)) { $gitUser = "user" }
            $suggestedUrl = "https://github.com/$gitUser/$userInput.git"
            Write-Host "Generated suggestion: $suggestedUrl" -ForegroundColor Gray
            $confirm = Read-Host "Use this URL? (y/n)"
            if ($confirm -eq 'y') { $remoteUrl = $suggestedUrl; break }
            continue
        } else {
            # Basic validation of Git format (HTTPS or SSH)
            if ($userInput -match "^(https?://|git@|ssh://).+\.git$") {
                $remoteUrl = $userInput
                break
            } else {
                Write-Warning "The URL '$userInput' doesn't seem valid (must start with http/git/ssh and end with .git)."
                $confirm = Read-Host "Do you want to use it anyway? (y/n)"
                if ($confirm -eq 'y') { $remoteUrl = $userInput; break }
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($remoteUrl) -and $remoteUrl -ne "skip") {
        git remote add origin $remoteUrl
        Write-Host "Remote 'origin' configured successfully." -ForegroundColor Green
    }
}

git add .

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$tagName = "$projectName-v$(Get-Date -Format 'yyyy.MM.dd-HHmmss')" # Use dynamic project name
$msg = "feat: $projectName update - session $timestamp" # Use dynamic project name

# Commit only if changes detected
$hasChanges = git status --porcelain
if ($hasChanges) {
    git commit -m $msg 2>$null
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) { # Git commit returns 1 if no changes, but we already checked
        Write-Warning "Could not perform commit. Check Git configuration."
        exit 1
    }

    # Create tag only if user confirms and HEAD is valid
    if (git rev-parse HEAD 2>$null) {
        $createTag = Read-Host "Do you want to create a version tag ($tagName) for this session? (y/n)"
        if ($createTag -eq 'y') {
            git tag -a $tagName -m "Release $tagName - Session $timestamp" 2>$null
            Write-Host "SUCCESS: Commit and Tag ($tagName) created successfully." -ForegroundColor Green
        } else {
            Write-Host "SUCCESS: Commit created without tag." -ForegroundColor Green
        }
    }
} else {
    Write-Host "[INFO] No changes to commit in this session." -ForegroundColor Gray
}

Write-Host "`nACTION: Synchronizing with Remote Repository..." -ForegroundColor Cyan

if (git remote | Select-String "origin") {
    $pushSuccess = $false
    $skippedPush = $false
    while (-not $pushSuccess) {
        # Temporarily allow errors for retry loop to work
        $oldEAP = $ErrorActionPreference # Save old error action
        $ErrorActionPreference = 'SilentlyContinue' # Suppress errors for retry logic

        # Determine if we need --set-upstream for first push
        $upstream = git config "branch.$targetBranch.remote" 2>$null
        if (-not $upstream) {
            Write-Host "[INFO] Upstream branch not configured for '$targetBranch'. Attempting '--set-upstream'." -ForegroundColor Yellow
            git push -u origin $targetBranch --tags
        } else {
            git push origin $targetBranch --tags
        }

        $pushExitCode = $LASTEXITCODE
        $ErrorActionPreference = $oldEAP # Restore old error action

        if ($pushExitCode -eq 0) {
            $pushSuccess = $true
        } else {
            Write-Warning "Error during push. The repo might not exist in the cloud, URL is wrong, or auth failed."
            Write-Host "IMPORTANT: Ensure you have created the repository on the WEB (GitHub/Bitbucket) before uploading." -ForegroundColor Yellow
            Write-Host "Current detected URL: $(git remote get-url origin)" -ForegroundColor Gray
            $action = Read-Host "What do you want to do? (r) Retry URL, (g) Create on GitHub now, (s) Skip, (x) Exit"
            
            if ($action -eq 'r') {
                git remote remove origin
                $newUrl = Read-Host "Enter the correct repository URL (.git)"
                if (-not [string]::IsNullOrWhiteSpace($newUrl)) { git remote add origin $newUrl }
            } elseif ($action -eq 'g') {
                if (Get-Command gh -ErrorAction SilentlyContinue) {
                    git remote remove origin 2>$null
                    $repoDefault = Split-Path -Leaf $projectRoot
                    $repoName = Read-Host "Repository name [$repoDefault]"
                    if ([string]::IsNullOrWhiteSpace($repoName)) { $repoName = $repoDefault }
                    $vis = Read-Host "Privacy? (1) Public, (2) Private [Default: Private]"
                    $visFlag = if ($vis -eq "1") { "--public" } else { "--private" }
                    
                    Write-Host "[INFO] Creating repository '$repoName' on GitHub..." -ForegroundColor Cyan
                    & gh repo create $repoName $visFlag --source=. --remote=origin -y # -y to accept prompts
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Could not create repository. Ensure you are authenticated with 'gh auth login'."
                    }
                } else {
                    Write-Error "GitHub CLI (gh) not installed. Cannot create automatically."
                }
            } elseif ($action -eq 's') {
                Write-Warning "Sync skipped by user."
                $skippedPush = $true
                break
            } elseif ($action -eq 'x') {
                exit 1
            } else {
                Write-Host "Invalid option."
            }
        }
    }

    if ($pushSuccess) {
        Write-Host ""
        Write-Host "SUCCESS: Session finished and uploaded successfully to branch '$targetBranch' on GitHub." -ForegroundColor Green
    } elseif ($skippedPush) {
        Write-Host ""
        Write-Host "SUCCESS: Session finished locally, but upload was skipped." -ForegroundColor Yellow
    }
} else {
    Write-Warning "Sync skipped: No 'origin' remote configured."
    Write-Host ""
    Write-Host "SUCCESS: Session finished locally." -ForegroundColor Yellow
}

# 4. Generate Session Audit
Write-Host "`nACTION: Generating Session Audit..." -ForegroundColor Cyan

$auditScript = Join-Path $scriptDir "generate-session-audit.ps1"
$metricsScript = Join-Path $scriptDir "aggregate-metrics.ps1"
$reportScript = Join-Path $scriptDir "generate-audit-report.ps1"

if (Test-Path $auditScript) {
    try {
        & $auditScript -End
    } catch {
        Write-Warning "Could not generate audit: $_"
    }
}

if (Test-Path $metricsScript) {
    try {
        Write-Host "Aggregating daily metrics..." -ForegroundColor Gray
        & $metricsScript -Period daily -Silent
    } catch {
        Write-Warning "Could not aggregate metrics: $_"
    }
}

$dayOfWeek = (Get-Date).DayOfWeek
if ($dayOfWeek -eq 'Sunday' -or $dayOfWeek -eq 'Monday') {
    if (Test-Path $reportScript) {
        try {
            Write-Host "Generating weekly report..." -ForegroundColor Gray
            & $reportScript -Period weekly -Silent
        } catch {
            Write-Warning "Could not generate weekly report: $_"
        }
    }
}