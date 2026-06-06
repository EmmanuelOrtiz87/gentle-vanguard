#!/usr/bin/env pwsh
# Backup master.key to secure location

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir '..\..\..')
$source = Join-Path $repoRoot "keys/master.key"
$backupDir = if ($env:GV_BACKUP_DIR) { $env:GV_BACKUP_DIR } else { Join-Path (Split-Path $repoRoot -Parent) 'backups\gentle-vanguard' }

if (-not (Test-Path $source)) {
    Write-Error "master.key not found at $source"
    exit 1
}

if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$backupPath = "$backupDir\master.key.$timestamp"
$currentLink = "$backupDir\master.key.current"

Copy-Item $source $backupPath
Copy-Item $source $currentLink -Force

Write-Output "[OK] Backup created: $backupPath"
Write-Output "[OK] Current link updated: $currentLink"
Write-Output ""
Write-Output "[WARN]  Keep backups secure. These files decrypt 185 protected scripts."

