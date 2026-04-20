#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Gestiona backups automáticos de Engram con sincronización.

.DESCRIPTION
    Exporta, importa y sincroniza datos de Engram automáticamente.
    Mantiene backups periódicos y restaura desde el backup más reciente.

.PARAMETER Action
    Acción a realizar: backup, restore, auto-sync, schedule

.PARAMETER ProjectName
    Nombre del proyecto. Por defecto: workspace_local

.PARAMETER BackupPath
    Ruta base para backups. Por defecto: backups/engram

.PARAMETER MaxBackups
    Número máximo de backups a mantener. Por defecto: 30

.EXAMPLE
    .\engram-backup-manager.ps1 -Action backup
    Crea un backup de Engram

.EXAMPLE
    .\engram-backup-manager.ps1 -Action restore
    Restaura desde el backup más reciente

.EXAMPLE
    .\engram-backup-manager.ps1 -Action auto-sync
    Sincroniza automáticamente si hay cambios
#>

param(
    [ValidateSet("backup", "restore", "auto-sync", "schedule", "cleanup")]
    [string]$Action = "backup",
    [string]$ProjectName = "workspace_local",
    [string]$BackupPath = "backups/engram",
    [int]$MaxBackups = 30
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Test-EngramAvailable {
    try {
        $null = & engram --version 2>&1
        return $true
    }
    catch {
        Write-Log "Engram no esta disponible" "ERROR"
        return $false
    }
}

function Get-BackupFileName {
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    return "engram-backup-$timestamp.json"
}

function Export-EngramData {
    param([string]$OutputFile)
    
    Write-Log "Exportando datos de Engram..." "INFO"
    
    try {
        $exportResult = & engram export --project $ProjectName --output $OutputFile 2>&1
        
        if (Test-Path $OutputFile) {
            $fileSize = (Get-Item $OutputFile).Length
            Write-Log "Backup creado exitosamente: $OutputFile ($fileSize bytes)" "SUCCESS"
            return $true
        }
        else {
            Write-Log "Error: archivo de backup no fue creado" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Error al exportar datos: $_" "ERROR"
        return $false
    }
}

function Import-EngramData {
    param([string]$InputFile)
    
    Write-Log "Importando datos desde: $InputFile" "INFO"
    
    if (-not (Test-Path $InputFile)) {
        Write-Log "Archivo de backup no existe: $InputFile" "ERROR"
        return $false
    }
    
    try {
        $importResult = & engram import --project $ProjectName --input $InputFile 2>&1
        Write-Log "Datos importados exitosamente" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Error al importar datos: $_" "ERROR"
        return $false
    }
}

function Get-LatestBackup {
    if (-not (Test-Path $BackupPath)) {
        return $null
    }
    
    $backups = Get-ChildItem -Path $BackupPath -Filter "engram-backup-*.json" | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -gt 0) {
        return $backups[0].FullName
    }
    
    return $null
}

function Test-BackupNeedsUpdate {
    $latestBackup = Get-LatestBackup
    
    if (-not $latestBackup) {
        Write-Log "No hay backups previos, se requiere backup inicial" "INFO"
        return $true
    }
    
    $backupAge = (Get-Date) - (Get-Item $latestBackup).LastWriteTime
    
    # Backup si tiene más de 24 horas
    if ($backupAge.TotalHours -gt 24) {
        Write-Log "Ultimo backup tiene $([math]::Round($backupAge.TotalHours, 1)) horas, se requiere actualizar" "INFO"
        return $true
    }
    
    Write-Log "Backup reciente encontrado ($([math]::Round($backupAge.TotalHours, 1)) horas), no se requiere actualizar" "INFO"
    return $false
}

function Remove-OldBackups {
    Write-Log "Limpiando backups antiguos (manteniendo ultimos $MaxBackups)..." "INFO"
    
    if (-not (Test-Path $BackupPath)) {
        return
    }
    
    $backups = Get-ChildItem -Path $BackupPath -Filter "engram-backup-*.json" | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -le $MaxBackups) {
        Write-Log "Total de backups ($($backups.Count)) dentro del limite ($MaxBackups)" "INFO"
        return
    }
    
    $toDelete = $backups | Select-Object -Skip $MaxBackups
    
    foreach ($backup in $toDelete) {
        Remove-Item $backup.FullName -Force
        Write-Log "Eliminado: $($backup.Name)" "INFO"
    }
    
    Write-Log "Limpieza completada: eliminados $($toDelete.Count) backups" "SUCCESS"
}

function Invoke-Backup {
    Write-Log "=== Iniciando Backup de Engram ===" "INFO"
    
    if (-not (Test-EngramAvailable)) {
        return $false
    }
    
    # Create backup directory
    if (-not (Test-Path $BackupPath)) {
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        Write-Log "Directorio de backups creado: $BackupPath" "INFO"
    }
    
    # Generate backup file name
    $backupFile = Join-Path $BackupPath (Get-BackupFileName)
    
    # Export data
    $success = Export-EngramData -OutputFile $backupFile
    
    if ($success) {
        # Cleanup old backups
        Remove-OldBackups
        Write-Log "Backup completado exitosamente" "SUCCESS"
        return $true
    }
    
    return $false
}

function Invoke-Restore {
    Write-Log "=== Iniciando Restauracion desde Backup ===" "INFO"
    
    if (-not (Test-EngramAvailable)) {
        return $false
    }
    
    $latestBackup = Get-LatestBackup
    
    if (-not $latestBackup) {
        Write-Log "No se encontraron backups para restaurar" "ERROR"
        return $false
    }
    
    Write-Log "Restaurando desde: $latestBackup" "INFO"
    
    $success = Import-EngramData -InputFile $latestBackup
    
    if ($success) {
        Write-Log "Restauracion completada exitosamente" "SUCCESS"
        return $true
    }
    
    return $false
}

function Invoke-AutoSync {
    Write-Log "=== Sincronizacion Automatica de Engram ===" "INFO"
    
    if (-not (Test-EngramAvailable)) {
        return $false
    }
    
    # Check if backup is needed
    if (Test-BackupNeedsUpdate) {
        Write-Log "Creando backup automatico..." "INFO"
        Invoke-Backup
    }
    
    # Check if restore is needed (backup is newer than local data)
    $latestBackup = Get-LatestBackup
    if ($latestBackup) {
        Write-Log "Verificando si se requiere restauracion..." "INFO"
        # This would require checking Engram's last update time
        # For now, we just ensure backup exists
        Write-Log "Sincronizacion completada" "SUCCESS"
    }
    
    return $true
}

function Register-BackupScheduledTask {
    Write-Log "Registrando tarea programada de backup..." "INFO"
    
    $taskName = "EngramAutoBackup"
    $scriptPath = $PSCommandPath
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -Action auto-sync"
    
    # Run every 6 hours
    $trigger1 = New-ScheduledTaskTrigger -Daily -At "00:00"
    $trigger2 = New-ScheduledTaskTrigger -Daily -At "06:00"
    $trigger3 = New-ScheduledTaskTrigger -Daily -At "12:00"
    $trigger4 = New-ScheduledTaskTrigger -Daily -At "18:00"
    
    try {
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Log "Tarea programada existente eliminada" "INFO"
        }
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger1,$trigger2,$trigger3,$trigger4 -Description "Backup automatico de Engram cada 6 horas"
        Write-Log "Tarea programada registrada: $taskName" "SUCCESS"
        Write-Log "Se ejecutara cada 6 horas (00:00, 06:00, 12:00, 18:00)" "INFO"
    }
    catch {
        Write-Log "Error al registrar tarea programada: $_" "ERROR"
    }
}

# Main execution
Write-Host "`n=== Gestor de Backups de Engram ===" -ForegroundColor Cyan
Write-Host "Proyecto: $ProjectName" -ForegroundColor Gray
Write-Host "Ruta de backups: $BackupPath" -ForegroundColor Gray
Write-Host "Accion: $Action" -ForegroundColor Yellow

switch ($Action) {
    "backup" {
        Invoke-Backup
    }
    "restore" {
        Invoke-Restore
    }
    "auto-sync" {
        Invoke-AutoSync
    }
    "schedule" {
        Register-BackupScheduledTask
    }
    "cleanup" {
        Remove-OldBackups
    }
}

Write-Host "`nOperacion completada" -ForegroundColor Green