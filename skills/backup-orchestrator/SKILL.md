---
name: backup-orchestrator
description: Backup orchestration skill for workspace and project backup management
---

# Skill: backup-orchestrator

**versión**: 1.0.0 **Created**: 2026-04-20 **Status**: ACTIVE **Priority**: HIGH

---

## Overview

The `backup-orchestrator` skill provides advanced backup management with intelligent strategies,
scheduling, retention policies, and integrity validation. It extends the Phase 1 Smart Backup
gentle-vanguard with enterprise-grade capabilities.

### Key Capabilities

- Multiple backup strategies (Full, Incremental, Differential)
- Intelligent scheduling with resource awareness
- Flexible retention policies
- Integrity validation and repair
- Compression and encryption support

---

## When to Use This Skill

### Activation Triggers

- User mentions "backup strategy" or "estrategia de backup"
- User asks to "optimize backups" or "optimizar backups"
- Backup complexity increases (>10 backup scenarios)
- Working with backup scripts in `scripts/`
- Backup performance concerns

### Use Cases

1. **Strategy Design**: "Necesito una estrategia de backup para datos crticos"
2. **Optimization**: "Los backups son demasiado grandes, cmo optimizar?"
3. **Recovery**: "Restaurar estado de ayer a las 15:00"
4. **Validation**: "Verificar integridad de todos los backups"
5. **Scheduling**: "Automatizar backups sin afectar performance"

---

## Core Components

### 1. Backup Strategy Engine

#### Strategy Types

**Full Backup** - Complete snapshot of all data

```powershell
$strategy = @{
    Type = "Full"
    Scope = "All files"
    Compression = "7z"
    Encryption = "AES-256"
    Verification = "SHA256"
    UseCase = "Initial, monthly archive, disaster recovery"
}
```

**Incremental Backup** - Only changes since last backup

```powershell
$strategy = @{
    Type = "Incremental"
    BasedOn = "LastBackup"
    OnlyChanges = $true
    Compression = "7z"
    Encryption = "AES-256"
    UseCase = "Daily backups, frequent snapshots"
}
```

**Differential Backup** - Changes since last full backup

```powershell
$strategy = @{
    Type = "Differential"
    BasedOn = "LastFull"
    OnlyChanges = $true
    Compression = "7z"
    Encryption = "AES-256"
    UseCase = "Weekly backups, balanced approach"
}
```

#### Strategy Selection Logic

```powershell
function Select-BackupStrategy {
    param(
        [int]$DataSizeGB,
        [int]$ChangeRatePercent,
        [int]$ExecutionWindowMinutes,
        [int]$StorageConstraintGB
    )

    if ($IsFirstBackup) { return "Full" }
    if ($ChangeRatePercent -gt 50) { return "Full" }
    if ($ExecutionWindowMinutes -lt 10) { return "Incremental" }
    if ($StorageConstraintGB -lt $DataSizeGB * 2) { return "Incremental" }

    return "Differential"
}
```

---

### 2. Intelligent Scheduling

#### Time-Based Scheduling

```powershell
function New-BackupSchedule {
    param(
        [string]$Name,
        [string]$Pattern,  # Daily, Weekly, Monthly
        [int]$Hour,
        [int]$Minute
    )

    return @{
        Name = $Name
        Pattern = $Pattern
        Time = "$Hour`:$Minute"
        Status = "Active"
    }
}
```

#### Resource-Aware Scheduling

```powershell
function Test-ResourceAvailability {
    param(
        [int]$RequiredCPUPercent = 20,
        [int]$RequiredMemoryMB = 500
    )

    $cpuUsage = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $memoryAvailable = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024

    return @{
        CPUAvailable = ($cpuUsage -lt (100 - $RequiredCPUPercent))
        MemoryAvailable = ($memoryAvailable -gt $RequiredMemoryMB)
        CanProceed = ($cpuUsage -lt (100 - $RequiredCPUPercent))
    }
}
```

---

## References

See `references/patterns.md` for detailed patterns and code examples.
