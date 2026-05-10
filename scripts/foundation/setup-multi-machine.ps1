param(
    [string]$Owner = 'EmmanuelOrtiz87',
    [string]$FoundationRepo = 'foundation',
    [string]$PublicRepo = 'foundation-public',
    [string]$BasePath = '',
    [switch]$InstallRunner,
    [string]$RunnerConfigPath = 'config/github-runner.local.json'
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Gray
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Ensure-GitRepo {
    param(
        [string]$RepoSlug,
        [string]$TargetPath
    )

    $repoUrl = "https://github.com/$RepoSlug.git"
    if (-not (Test-Path $TargetPath)) {
        Write-Info "Cloning $RepoSlug -> $TargetPath"
        git clone $repoUrl $TargetPath
        if ($LASTEXITCODE -ne 0) {
            throw "Failed cloning $RepoSlug"
        }
        return
    }

    if (-not (Test-Path (Join-Path $TargetPath '.git'))) {
        throw "Path exists but is not a git repository: $TargetPath"
    }

    Write-Info "Updating $RepoSlug at $TargetPath"
    Push-Location $TargetPath
    try {
        git fetch origin --prune
        $remoteHead = git symbolic-ref refs/remotes/origin/HEAD 2>$null
        $defaultBranch = if ($remoteHead) { $remoteHead -replace '^refs/remotes/origin/', '' } else { 'main' }
        git checkout $defaultBranch 2>$null
        git pull --rebase origin $defaultBranch
    }
    finally {
        Pop-Location
    }
}

if ([string]::IsNullOrWhiteSpace($BasePath)) {
    $BasePath = Join-Path $HOME 'source'
}

if (-not (Test-Path $BasePath)) {
    New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
}

$foundationSlug = "$Owner/$FoundationRepo"
$publicSlug = "$Owner/$PublicRepo"
$foundationPath = Join-Path $BasePath $FoundationRepo
$publicPath = Join-Path $BasePath $PublicRepo

Write-Step 'Prepare repositories'
Ensure-GitRepo -RepoSlug $foundationSlug -TargetPath $foundationPath
Ensure-GitRepo -RepoSlug $publicSlug -TargetPath $publicPath
Write-Success 'Repositories are ready'

Write-Step 'Bootstrap foundation workspace'
$bootstrapScript = Join-Path $foundationPath 'scripts/foundation/bootstrap.ps1'
if (-not (Test-Path $bootstrapScript)) {
    throw "Bootstrap script not found: $bootstrapScript"
}

if ($InstallRunner) {
    & $bootstrapScript -InstallGitHubRunner -GitHubRunnerConfigPath $RunnerConfigPath
} else {
    & $bootstrapScript
}

if ($LASTEXITCODE -ne 0) {
    throw 'Bootstrap failed.'
}
Write-Success 'Bootstrap completed'

Write-Step 'Done'
Write-Host "Foundation repo: $foundationPath"
Write-Host "Public repo:     $publicPath"
Write-Host 'Run this same script on any new PC to replicate setup.'