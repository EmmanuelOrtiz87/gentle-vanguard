# sync-agent-instructions.ps1
# Synchronizes master instructions across all AI agent platforms.
# Usage: .\sync-agent-instructions.ps1 [-Target All|OpenCode|Copilot|Claude|Gemini]

param(
    [ValidateSet('All', 'OpenCode', 'Copilot', 'Claude', 'Gemini')]
    [string]$Target = 'All',
    
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

$masterFile = Join-Path $repoRoot 'docs\reference\master-instructions.md'

$homePath = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
$targets = @{
    'OpenCode' = Join-Path $repoRoot 'AGENTS.md'
    'Copilot'  = Join-Path $repoRoot '.github\copilot-instructions.md'
    'Claude'   = Join-Path $homePath '.claude\CLAUDE.md'
    'Gemini'   = Join-Path $homePath '.gemini\instructions.md'
}

function Write-Step { param([string]$m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "[OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[WARN] $m" -ForegroundColor Yellow }

function Sync-Target {
    param([string]$Name, [string]$Path)
    
    if (-not (Test-Path $masterFile)) {
        Write-Warn "Master instructions not found at $masterFile. Skipping."
        return
    }
    
    $targetDir = Split-Path $Path -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Ok "Created directory: $targetDir"
    }
    
    if ($DryRun) {
        Write-Host "[DRY RUN] Would sync $masterFile -> $Path" -ForegroundColor Yellow
        return
    }
    
    Copy-Item $masterFile $Path -Force
    Write-Ok "Synced ${Name}: ${Path}"
}

if (-not (Test-Path $masterFile)) {
    Write-Step "Creating default master instructions..."
    $defaultContent = "# Master Instructions\n\nThese are the global instructions for all AI agents.\n\n## Role\nYou are a senior developer and technical mentor.\n\n## Communication\n- Be concise and direct.\n- Use English for technical terms.\n- Follow the project's coding standards.\n"
    New-Item -ItemType Directory -Path (Split-Path $masterFile -Parent) -Force | Out-Null
    $defaultContent | Out-File -FilePath $masterFile -Encoding UTF8BOM
    Write-Ok "Created master instructions at $masterFile"
}

Write-Step "Synchronizing Agent Instructions ($Target)"

foreach ($key in $targets.Keys) {
    if ($Target -eq 'All' -or $Target -eq $key) {
        Sync-Target -Name $key -Path $targets[$key]
    }
}

Write-Ok "Synchronization complete."
