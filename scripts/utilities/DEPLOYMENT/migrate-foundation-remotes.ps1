param(
    [string[]]$RepoPaths = @(
        (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
        (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path 'foundation-public')
    ),
    [string]$Owner = 'EmmanuelOrtiz87',
    [string]$OldName = 'gentleman-foundation',
    [string]$NewName = 'foundation',
    [switch]$DryRun
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

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

$oldUrl = "https://github.com/$Owner/$OldName.git"
$newUrl = "https://github.com/$Owner/$NewName.git"

Write-Step "Foundation remote migration"
Write-Host "Old URL: $oldUrl"
Write-Host "New URL: $newUrl"

foreach ($repoPath in $RepoPaths) {
    if (-not (Test-Path $repoPath)) {
        Write-Warn "Path not found, skipping: $repoPath"
        continue
    }

    if (-not (Test-Path (Join-Path $repoPath '.git'))) {
        Write-Warn "Not a git repository, skipping: $repoPath"
        continue
    }

    Push-Location $repoPath
    try {
        $originUrl = git remote get-url origin 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($originUrl)) {
            Write-Warn "No origin remote in: $repoPath"
            continue
        }

        Write-Info "Repository: $repoPath"
        Write-Info "Current origin: $originUrl"

        if ($originUrl -eq $oldUrl) {
            if ($DryRun) {
                Write-Info "DryRun: would set origin to $newUrl"
            } else {
                git remote set-url origin $newUrl
                Write-Success "Origin updated to $newUrl"
            }
        } else {
            Write-Info 'Origin does not match old URL. No change applied.'
        }
    }
    finally {
        Pop-Location
    }
}

Write-Step 'Done'
Write-Host 'Remote migration flow complete.'