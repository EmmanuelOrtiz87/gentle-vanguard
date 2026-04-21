# engram-backup-manager.ps1
# Script para gestionar backups automáticos de Engram y sincronización

param(
    [ValidateSet('auto-sync', 'backup', 'restore', 'status')]
    [string]$Action = 'status',
    [string]$ProjectName = 'workspace_local',
    [string]$BackupPath = '.\.session\engram-backups'
)

$ErrorActionPreference = 'Continue'

function Write-Status {
    param([string]$Message)
    Write-Host "[BACKUP] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Asegurar que existe el directorio de backup
if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
    Write-Info "Created backup directory: $BackupPath"
}

switch ($Action) {
    'auto-sync' {
        Write-Status "Starting auto-sync backup for project: $ProjectName"
        
        # Crear timestamp para el backup
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $backupFile = Join-Path $BackupPath "engram-backup-$timestamp.json"
        
        # Simular backup (en producción, esto sincronizaría con Engram real)
        $backupData = @{
            timestamp = Get-Date -Format "o"
            project = $ProjectName
            status = "auto-synced"
            version = "1.0"
        }
        
        $backupData | ConvertTo-Json | Out-File -FilePath $backupFile -Encoding UTF8
        Write-Status "Auto-sync backup created: $backupFile"
        
        # Limpiar backups antiguos (mantener últimos 10)
        $backups = Get-ChildItem -Path $BackupPath -Filter "engram-backup-*.json" -ErrorAction SilentlyContinue | 
                   Sort-Object -Property LastWriteTime -Descending
        
        if ($backups.Count -gt 10) {
            $backups | Select-Object -Skip 10 | Remove-Item -Force
            Write-Info "Cleaned up old backups. Kept latest 10."
        }
    }
    
    'backup' {
        Write-Status "Creating manual backup for project: $ProjectName"
        
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $backupFile = Join-Path $BackupPath "engram-manual-backup-$timestamp.json"
        
        $backupData = @{
            timestamp = Get-Date -Format "o"
            project = $ProjectName
            status = "manual-backup"
            version = "1.0"
        }
        
        $backupData | ConvertTo-Json | Out-File -FilePath $backupFile -Encoding UTF8
        Write-Status "Manual backup created: $backupFile"
    }
    
    'restore' {
        Write-Status "Restore functionality - checking available backups"
        
        $backups = Get-ChildItem -Path $BackupPath -Filter "engram-*.json" -ErrorAction SilentlyContinue | 
                   Sort-Object -Property LastWriteTime -Descending
        
        if ($backups.Count -eq 0) {
            Write-Warning "No backups found in $BackupPath"
        } else {
            Write-Info "Available backups:"
            $backups | ForEach-Object { Write-Host "  - $($_.Name) ($(Get-Date $_.LastWriteTime -Format 'yyyy-MM-dd HH:mm:ss'))" }
        }
    }
    
    'status' {
        Write-Status "Engram Backup Manager Status"
        Write-Info "Project: $ProjectName"
        Write-Info "Backup Path: $BackupPath"
        
        $backups = Get-ChildItem -Path $BackupPath -Filter "engram-*.json" -ErrorAction SilentlyContinue
        
        if ($backups.Count -eq 0) {
            Write-Warning "No backups found"
        } else {
            Write-Info "Total backups: $($backups.Count)"
            $latestBackup = $backups | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
            Write-Info "Latest backup: $($latestBackup.Name) ($(Get-Date $latestBackup.LastWriteTime -Format 'yyyy-MM-dd HH:mm:ss'))"
        }
    }
    
    default {
        Write-Error "Unknown action: $Action"
        exit 1
    }
}

Write-Status "Engram backup manager operation completed"
exit 0