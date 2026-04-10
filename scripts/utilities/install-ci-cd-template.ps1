param(
    [string]$ProjectPath = '',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $PSScriptRoot
$wfRoot = Split-Path -Parent $scriptDir
$ciCdTemplate = Join-Path $wfRoot 'templates\ci-cd'

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    $ProjectPath = Get-Location
}

Write-Host "Installing CI/CD templates..." -ForegroundColor Cyan

if (-not (Test-Path $ciCdTemplate)) {
    Write-Host "CI/CD template not found at: $ciCdTemplate" -ForegroundColor Red
    return $false
}

$targetGithub = Join-Path $ProjectPath '.github'
$targetWorkflows = Join-Path $targetGithub 'workflows'

if (-not (Test-Path $targetWorkflows)) {
    New-Item -ItemType Directory -Path $targetWorkflows -Force | Out-Null
}

$workflows = @(
    'ci.yml',
    'deploy.yml',
    'release.yml'
)

foreach ($workflow in $workflows) {
    $source = Join-Path $ciCdTemplate ".github\workflows\$workflow"
    $dest = Join-Path $targetWorkflows $workflow

    if ((Test-Path $dest) -and -not $Force) {
        Write-Host "  Skipped: $workflow (already exists)" -ForegroundColor Yellow
        continue
    }

    if (Test-Path $source) {
        Copy-Item -Path $source -Destination $dest -Force
        Write-Host "  Installed: $workflow" -ForegroundColor Green
    }
}

Write-Host "CI/CD templates installation complete!" -ForegroundColor Green
Write-Host "Review and customize the workflows in .github/workflows/" -ForegroundColor Cyan
Write-Host "Configure secrets in GitHub repository settings:" -ForegroundColor Cyan
Write-Host "  - DOCKER_USERNAME" -ForegroundColor White
Write-Host "  - DOCKER_PASSWORD" -ForegroundColor White
Write-Host "  - REGISTRY_HOST" -ForegroundColor White
Write-Host "  - REGISTRY_USER" -ForegroundColor White
Write-Host "  - REGISTRY_TOKEN" -ForegroundColor White
Write-Host "  - SSH_HOST" -ForegroundColor White
Write-Host "  - SSH_USER" -ForegroundColor White
Write-Host "  - SSH_KEY" -ForegroundColor White

return $true
