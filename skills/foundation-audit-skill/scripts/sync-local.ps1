#Requires -Version 5.1
<#
.SYNOPSIS
    Sync Foundation Audit to Local - Enables standalone usage without repo
.DESCRIPTION
    Copies audit scripts to ~/.foundation-local/ for use in any directory.
    No git repo required - works on any project.
    
    Location: ~/.foundation-local/
    
    Usage after sync:
    ~/.foundation-local/audit-workflow.ps1 -Mode full
    ~/.foundation-local/audit-workflow.ps1 -Mode quick
.PARAMETER Source
    Path to Foundation (default: auto-detect from script location)
.PARAMETER Target
    Target directory (default: ~/.foundation-local/)
.PARAMETER Force
    Overwrite existing files
.PARAMETER ListOnly
    List what would be synced without copying
.EXAMPLE
    # Sync to local
    .\sync-local.ps1
    
    # List what would be synced
    .\sync-local.ps1 -ListOnly
    
    # Force resync
    .\sync-local.ps1 -Force
#>
param(
    [string]$Source,
    [string]$Target = "$env:USERPROFILE\.foundation-local",
    [switch]$Force,
    [switch]$ListOnly
)

$ErrorActionPreference = 'Stop'

# Auto-detect source
if (-not $Source) {
    $Source = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

$AuditSource = Join-Path $Source 'skills\foundation-audit-skill\scripts'
$AuditTarget = $Target

# Files to sync
$FilesToSync = @(
    @{ Source = 'audit-sweep.ps1'; Desc = 'Batch audit (foundation-audit)' },
    @{ Source = 'audit-workflow.ps1'; Desc = 'Unified workflow (audit + judgment)' }
)

function Write-SyncHeader {
    Write-Host @"


           FOUNDATION LOCAL SYNC                               
  Standalone audit scripts for any directory                   


"@ -ForegroundColor Cyan
}

function Test-SyncItem {
    param([string]$SourcePath)
    Test-Path $SourcePath
}

function Copy-SyncItem {
    param([string]$SourcePath, [string]$DestPath, [string]$Description)
    
    $destDir = Split-Path $DestPath -Parent
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    
    if (Test-Path $SourcePath) {
        if ($ListOnly) {
            Write-Host "  [SYNC] $Description" -ForegroundColor Yellow
            Write-Host "         $SourcePath" -ForegroundColor DarkGray
            Write-Host "        $DestPath" -ForegroundColor DarkGray
        } else {
            if ((Test-Path $DestPath) -and -not $Force) {
                Write-Host "  [SKIP] $Description (already exists, use -Force to overwrite)" -ForegroundColor DarkGray
            } else {
                Copy-Item -Path $SourcePath -Destination $DestPath -Force:$Force
                Write-Host "  [OK] $Description" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "  [SKIP] $Description (source not found)" -ForegroundColor DarkGray
    }
}

# Main
Write-SyncHeader

Write-Host "Source: $AuditSource" -ForegroundColor DarkGray
Write-Host "Target: $AuditTarget" -ForegroundColor DarkGray
Write-Host ""

# Check if source exists
if (-not (Test-Path $AuditSource)) {
    Write-Error "Source not found: $AuditSource"
    exit 1
}

# Create target directory
if (-not $ListOnly) {
    if (-not (Test-Path $AuditTarget)) {
        New-Item -ItemType Directory -Path $AuditTarget -Force | Out-Null
        Write-Host "[CREATE] Target directory created`n" -ForegroundColor Green
    }
}

# Sync audit scripts
Write-Host "Syncing audit scripts...`n" -ForegroundColor White

foreach ($item in $FilesToSync) {
    $sourcePath = Join-Path $AuditSource $item.Source
    $destPath = Join-Path $AuditTarget $item.Source
    Copy-SyncItem -SourcePath $sourcePath -DestPath $destPath -Description $item.Desc
}

# Create config directory
$configTarget = Join-Path $AuditTarget 'config'
if (-not (Test-Path $configTarget)) {
    New-Item -ItemType Directory -Path $configTarget -Force | Out-Null
}

# Create default audit rules if not exists
$rulesPath = Join-Path $configTarget 'audit-rules.json'
if (-not (Test-Path $rulesPath)) {
    $defaultRules = @{
        Version = "1.0"
        Description = "Foundation Audit Rules - Standalone"
        DeprecatedSkills = @(
            'sdd-init', 'sdd-explore', 'sdd-propose', 'sdd-spec',
            'sdd-design', 'sdd-tasks', 'sdd-apply', 'sdd-verify',
            'sdd-archive', 'sdd-skill', 'skill-creator'
        )
        RequiredFiles = @('README.md')
        ExcludePaths = @('node_modules', '.git', 'vendor', 'dist', 'build')
        SecurityChecks = @{
            CheckGitignore = $true
            CheckEnvExample = $true
            CheckSecrets = $true
        }
    }
    
    if (-not $ListOnly) {
        $defaultRules | ConvertTo-Json -Depth 3 | Set-Content $rulesPath -Encoding UTF8
        Write-Host "  [CREATE] Default rules: $rulesPath" -ForegroundColor Green
    } else {
        Write-Host "  [CREATE] Default rules" -ForegroundColor Yellow
    }
}

# Create wrapper script for easy access
$wrapperPath = Join-Path $AuditTarget 'audit.ps1'
if (-not (Test-Path $wrapperPath) -or $Force) {
    $wrapperContent = @'
#Requires -Version 5.1
# Foundation Audit Wrapper - Place in project root for quick access
# This script wraps the unified audit workflow

$ErrorActionPreference = 'Continue'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$AuditScript = Join-Path $ScriptRoot 'audit-workflow.ps1'

if (Test-Path $AuditScript) {
    $mode = if ($args.Count -ge 1 -and -not [string]::IsNullOrWhiteSpace($args[0])) { $args[0] } else { 'standard' }
    $out = if ($args.Count -ge 2 -and -not [string]::IsNullOrWhiteSpace($args[1])) { $args[1] } else { 'text' }
    & $AuditScript -Mode $mode -Output $out
} else {
    Write-Error "Audit script not found. Run sync-local.ps1 from Foundation first."
    exit 1
}
'@
    if (-not $ListOnly) {
        $wrapperContent | Set-Content $wrapperPath -Encoding UTF8
        Write-Host "  [CREATE] Wrapper: $wrapperPath" -ForegroundColor Green
    } else {
        Write-Host "  [CREATE] Wrapper script" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "" -ForegroundColor Cyan

if ($ListOnly) {
    Write-Host "[DRY RUN] No files copied. Run without -ListOnly to sync." -ForegroundColor Yellow
} else {
    Write-Host "[SUCCESS] Foundation audit synced to: $AuditTarget" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  cd your-project-directory" -ForegroundColor DarkGray
    Write-Host "  ~\.foundation-local\audit-workflow.ps1 -Mode quick" -ForegroundColor DarkGray
    Write-Host "  ~\.foundation-local\audit-workflow.ps1 -Mode full" -ForegroundColor DarkGray
    Write-Host "  ~\.foundation-local\audit.ps1 full" -ForegroundColor DarkGray
}

Write-Host ""
