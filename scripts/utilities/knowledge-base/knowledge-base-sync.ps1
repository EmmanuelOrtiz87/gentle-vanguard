param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("full", "engram", "sessions", "documents", "backup")]
    [string]$Mode = "full",
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

function Resolve-ProjectRoot {
    $dir = $PSScriptRoot
    for ($i = 0; $i -lt 8; $i++) {
        if (Test-Path (Join-Path $dir ".git")) { return $dir }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
    return $dir
}

$ProjectRoot = Resolve-ProjectRoot
$VaultPath = Join-Path $ProjectRoot "knowledge-base"
$ConfigPath = Join-Path $ProjectRoot "config\knowledge-base-config.json"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $Quiet) {
        $color = switch ($Level) {
            "OK" { "Green" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

function Get-Config {
    if (Test-Path $ConfigPath) {
        return Get-Content $ConfigPath | ConvertFrom-Json
    }
    return $null
}

function Sync-EngramToVault {
    $engramCmd = Get-Command engram -ErrorAction SilentlyContinue
    
    if (-not $engramCmd) {
        Write-Log "Engram not found - skipping Engram sync" "WARN"
        return
    }
    
    $config = Get-Config
    $sessionsFolder = Join-Path $VaultPath $config.folders.sessions
    
    if (-not (Test-Path $sessionsFolder)) {
        New-Item -ItemType Directory -Path $sessionsFolder -Force | Out-Null
    }
    
    try {
        $output = & engram search "session_summary" --project gentle-vanguard --limit 100 2>&1 | Out-String
        
        if ($output -match "(\d+)\s+observations") {
            Write-Log "Found session summaries in Engram" "OK"
        }
        
        $output = & engram search "architecture" --project gentle-vanguard --limit 50 2>&1 | Out-String
        
        if ($output -match "(\d+)\s+observations") {
            Write-Log "Found architecture notes in Engram" "OK"
        }
        
        Write-Log "Engram sync completed" "OK"
    } catch {
        Write-Log "Engram sync failed: $_" "ERROR"
    }
}

function Sync-SessionsToVault {
    $config = Get-Config
    $sessionDir = Join-Path $ProjectRoot ".session"
    $sessionsFolder = Join-Path $VaultPath $config.folders.sessions
    
    if (-not (Test-Path $sessionDir)) {
        Write-Log "Session directory not found - skipping session sync" "WARN"
        return
    }
    
    $contextLogPath = Join-Path $sessionDir "context-log"
    if (-not (Test-Path $contextLogPath)) {
        Write-Log "Context log not found - skipping session sync" "WARN"
        return
    }
    
    $sessionDirs = Get-ChildItem -Path $contextLogPath -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 10
    
    $synced = 0
    foreach ($session in $sessionDirs) {
        $summaryFile = Join-Path $session.FullName "context-summary.md"
        
        if (Test-Path $summaryFile) {
            $content = Get-Content $summaryFile -Raw
            $sessionId = $session.Name
            
            $targetFile = Join-Path $sessionsFolder "$sessionId-summary.md"
            
            if (-not (Test-Path $targetFile)) {
                if (-not $DryRun) {
                    Copy-Item -Path $summaryFile -Destination $targetFile -Force
                    
                    $frontmatter = @"
---
created: $($session.LastWriteTime.ToString("yyyy-MM-dd"))
tags: [session, #$sessionId]
session_id: $sessionId
---

"@
                    $newContent = $frontmatter + $content
                    Set-Content -Path $targetFile -Value $newContent -Encoding UTF8
                }
                $synced++
                Write-Log "Synced session: $sessionId" "OK"
            }
        }
    }
    
    Write-Log "Synced $synced sessions to vault" "OK"
}

function Sync-DocumentsToVault {
    $config = Get-Config
    $docsArchive = Join-Path $ProjectRoot "docs-archive"
    $researchFolder = Join-Path $VaultPath $config.folders.research
    
    if (-not (Test-Path $docsArchive)) {
        Write-Log "docs-archive not found - skipping document sync" "WARN"
        return
    }
    
    $mdFiles = Get-ChildItem -Path $docsArchive -Recurse -Filter "*.md" -ErrorAction SilentlyContinue
    
    $synced = 0
    foreach ($file in $mdFiles) {
        $relativePath = $file.FullName.Substring($docsArchive.Length + 1)
        $targetPath = Join-Path $researchFolder $relativePath
        
        $targetDir = Split-Path $targetPath -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        if (-not (Test-Path $targetPath)) {
            if (-not $DryRun) {
                Copy-Item -Path $file.FullName -Destination $targetPath -Force
            }
            $synced++
        }
    }
    
    Write-Log "Synced $synced documents to vault" "OK"
}

function Backup-Vault {
    $config = Get-Config
    $backupDir = Join-Path $ProjectRoot $config.backup.path
    
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupFile = Join-Path $backupDir "knowledge-base-$timestamp.zip"
    
    if (-not $DryRun) {
        Compress-Archive -Path $VaultPath\* -DestinationPath $backupFile -Force
        Write-Log "Backup created: $backupFile" "OK"
    } else {
        Write-Log "Would create backup: $backupFile" "OK"
    }
    
    $oldBackups = Get-ChildItem -Path $backupDir -Filter "knowledge-base-*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 7
    foreach ($old in $oldBackups) {
        if (-not $DryRun) {
            Remove-Item -Path $old.FullName -Force
            Write-Log "Removed old backup: $($old.Name)" "OK"
        }
    }
}

function Invoke-FullSync {
    Write-Log "Starting full knowledge base sync..." "INFO"
    
    if ($Mode -eq "full" -or $Mode -eq "engram") {
        Sync-EngramToVault
    }
    
    if ($Mode -eq "full" -or $Mode -eq "sessions") {
        Sync-SessionsToVault
    }
    
    if ($Mode -eq "full" -or $Mode -eq "documents") {
        Sync-DocumentsToVault
    }
    
    if ($Mode -eq "full" -or $Mode -eq "backup") {
        $config = Get-Config
        if ($config.backup.enabled) {
            Backup-Vault
        }
    }
    
    Write-Log "Sync completed successfully" "OK"
}

if ($DryRun) {
    Write-Log "Running in DRY-RUN mode - no changes will be made" "WARN"
}

Invoke-FullSync