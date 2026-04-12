# sync-docs.ps1
# Sync documentation from Foundation to project

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = if ($scriptDir) { 
    $parent = Split-Path -Parent $scriptDir
    $grandparent = Split-Path -Parent $parent
    if (Test-Path (Join-Path $grandparent 'AGENTS.md')) {
        $grandparent
    } elseif (Test-Path (Join-Path $parent 'AGENTS.md')) {
        $parent
    } else {
        $parent
    }
} else { Get-Location }

$foundationRoot = $env:GENTLEMAN_ROOT
if (-not $foundationRoot) {
    $candidate = "C:\Workspace_local\workspace-foundation"
    if (Test-Path $candidate) {
        $foundationRoot = $candidate
    }
}

if (-not $foundationRoot) {
    Write-Host "[ERROR] Foundation root not found" -ForegroundColor Red
    Write-Host "Set `$env:GENTLEMAN_ROOT or ensure C:\Workspace_local\workspace-foundation exists" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Documentation Sync" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Foundation: $foundationRoot"
Write-Host "Project:    $repoRoot"
Write-Host ""

$syncItems = @(
    @{
        Name = "SESSION-GUIDE.md"
        Source = "docs\guides\SESSION-GUIDE.md"
        Dest = "docs\guides\SESSION-GUIDE.md"
    },
    @{
        Name = "DEVELOPMENT-WORKFLOW.md"
        Source = "docs\guides\DEVELOPMENT-WORKFLOW.md"
        Dest = "docs\guides\DEVELOPMENT-WORKFLOW.md"
    },
    @{
        Name = "wf.ps1"
        Source = "scripts\utilities\wf.ps1"
        Dest = "scripts\utilities\wf.ps1"
    },
    @{
        Name = "PR Template"
        Source = "templates\PULL_REQUEST_TEMPLATE.md"
        Dest = "templates\PULL_REQUEST_TEMPLATE.md"
    }
)

$syncCount = 0
$skipCount = 0

foreach ($item in $syncItems) {
    $sourcePath = Join-Path $foundationRoot $item.Source
    $destPath = Join-Path $repoRoot $item.Dest
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "[SKIP] Source not found: $($item.Name)" -ForegroundColor Yellow
        $skipCount++
        continue
    }
    
    $sourceHash = (Get-FileHash $sourcePath -Algorithm SHA256).Hash
    $destHash = if (Test-Path $destPath) { (Get-FileHash $destPath -Algorithm SHA256).Hash } else { $null }
    
    if ($sourceHash -eq $destHash -and -not $Force) {
        Write-Host "[OK] $($item.Name) (up to date)" -ForegroundColor Green
        $skipCount++
        continue
    }
    
    if ($DryRun) {
        Write-Host "[DRY-RUN] Would sync: $($item.Name)" -ForegroundColor Cyan
        continue
    }
    
    $destDir = Split-Path -Parent $destPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    
    Copy-Item -Path $sourcePath -Destination $destPath -Force
    Write-Host "[SYNC] $($item.Name)" -ForegroundColor Green
    $syncCount++
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Synced: $syncCount"
Write-Host "  Skipped: $skipCount"
Write-Host ""

if (-not $DryRun -and $syncCount -gt 0) {
    Write-Host "Documentation synchronized!" -ForegroundColor Green
}
