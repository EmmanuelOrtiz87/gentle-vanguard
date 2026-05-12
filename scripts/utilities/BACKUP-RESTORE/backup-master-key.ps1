#!/usr/bin/env pwsh
# Backup master.key to secure location

$source = "keys/master.key"
$backupDir = "C:\Workspace_local\backups\foundation"

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
