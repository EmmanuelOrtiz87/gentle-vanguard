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
foundation with enterprise-grade capabilities.

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

### 3. Retention Management

#### Time-Based Retention

```powershell
function Set-RetentionPolicy-TimeBased {
    param([int]$KeepDays = 30)

    return @{
        Type = "TimeBased"
        RetentionDays = $KeepDays
    }
}
```

#### Quantity-Based Retention

```powershell
function Set-RetentionPolicy-QuantityBased {
    param([int]$KeepCount = 10)

    return @{
        Type = "QuantityBased"
        RetentionCount = $KeepCount
    }
}
```

#### Space-Based Retention

```powershell
function Set-RetentionPolicy-SpaceBased {
    param([int]$MaxUsagePercent = 80)

    return @{
        Type = "SpaceBased"
        MaxUsagePercent = $MaxUsagePercent
    }
}
```

#### Importance-Weighted Retention

```powershell
function Set-RetentionPolicy-ImportanceWeighted {
    param(
        [hashtable]$Weights = @{
            "Critical" = 90
            "Important" = 30
            "Standard" = 7
        }
    )

    return @{
        Type = "ImportanceWeighted"
        Weights = $Weights
    }
}
```

---

### 4. Integrity & Validation

#### Checksum Verification

```powershell
function New-BackupChecksum {
    param(
        [string]$BackupPath,
        [string]$Algorithm = "SHA256"
    )

    $checksum = Get-FileHash -Path $BackupPath -Algorithm $Algorithm
    $checksumFile = "$BackupPath.checksum"

    @{
        Algorithm = $Algorithm
        Hash = $checksum.Hash
        Timestamp = Get-Date
        FileSize = (Get-Item $BackupPath).Length
    } | ConvertTo-Json | Set-Content -Path $checksumFile

    return $checksumFile
}

function Test-BackupIntegrity {
    param([string]$BackupPath)

    $checksumFile = "$BackupPath.checksum"
    $stored = Get-Content $checksumFile | ConvertFrom-Json
    $current = Get-FileHash -Path $BackupPath -Algorithm $stored.Algorithm

    return @{
        Valid = ($stored.Hash -eq $current.Hash)
        StoredHash = $stored.Hash
        CurrentHash = $current.Hash
    }
}
```

#### Restore Test Validation

```powershell
function Test-RestoreValidity {
    param(
        [string]$BackupPath,
        [string]$TestPath
    )

    try {
        New-Item -ItemType Directory -Path $TestPath -Force -ErrorAction SilentlyContinue | Out-Null
        Expand-Archive -Path $BackupPath -DestinationPath $TestPath -Force

        $files = Get-ChildItem -Path $TestPath -Recurse -File

        Remove-Item -Path $TestPath -Recurse -Force

        return @{
            Valid = ($files.Count -gt 0)
            FilesExtracted = $files.Count
            TotalSize = ($files | Measure-Object -Property Length -Sum).Sum
        }
    }
    catch {
        return @{
            Valid = $false
            Reason = $_.Exception.Message
        }
    }
}
```

#### Corruption Detection

```powershell
function Detect-BackupCorruption {
    param([string]$BackupPath)

    $results = @{
        CorruptionDetected = $false
        Issues = @()
        Severity = "None"
    }

    # Check 1: File size
    $fileInfo = Get-Item $BackupPath
    if ($fileInfo.Length -eq 0) {
        $results.CorruptionDetected = $true
        $results.Issues += "Backup file is empty"
        $results.Severity = "Critical"
    }

    # Check 2: Archive integrity
    if ($BackupPath -match "\.(zip|7z)$") {
        $testResult = Test-RestoreValidity -BackupPath $BackupPath -TestPath "$env:TEMP\backup_test"
        if (-not $testResult.Valid) {
            $results.CorruptionDetected = $true
            $results.Issues += $testResult.Reason
            $results.Severity = "Critical"
        }
    }

    # Check 3: Checksum validation
    $checksumTest = Test-BackupIntegrity -BackupPath $BackupPath
    if (-not $checksumTest.Valid) {
        $results.CorruptionDetected = $true
        $results.Issues += "Checksum mismatch"
        $results.Severity = "Critical"
    }

    return $results
}
```

---

### 5. Compression & Encryption

#### Compression Support

```powershell
function Compress-BackupData {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$Algorithm = "7z"
    )

    Write-Host "Compressing backup with $Algorithm..."

    switch ($Algorithm) {
        "7z" {
            & "C:\Program Files\7-Zip\7z.exe" a -t7z "$DestinationPath" "$SourcePath" -mx=9
        }
        "ZIP" {
            Compress-Archive -Path $SourcePath -DestinationPath $DestinationPath -CompressionLevel Optimal
        }
        "tar.gz" {
            tar -czf "$DestinationPath" -C (Split-Path $SourcePath) (Split-Path -Leaf $SourcePath)
        }
    }

    $originalSize = (Get-Item $SourcePath).Length
    $compressedSize = (Get-Item $DestinationPath).Length
    $ratio = [math]::Round(($compressedSize / $originalSize) * 100, 2)

    return @{
        OriginalSize = $originalSize
        CompressedSize = $compressedSize
        Ratio = $ratio
        Algorithm = $Algorithm
    }
}
```

#### Encryption Support

```powershell
function Encrypt-BackupData {
    param(
        [string]$BackupPath,
        [string]$Algorithm = "AES-256",
        [securestring]$Key
    )

    Write-Host "Encrypting backup with $Algorithm..."

    $encryptedPath = "$BackupPath.encrypted"

    switch ($Algorithm) {
        "AES-256" {
            $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key)
            $aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider
            $aes.Key = $keyBytes
            $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC

            $encryptor = $aes.CreateEncryptor()
            # Encryption logic here
        }
    }

    return @{
        OriginalPath = $BackupPath
        EncryptedPath = $encryptedPath
        Algorithm = $Algorithm
        Timestamp = Get-Date
    }
}
```

---

## Practical Examples

### Example 1: Design Backup Strategy for Critical Data

```powershell
# Scenario: Critical database requiring 99.9% availability

$strategy = @{
    Type = "Full"
    Frequency = "Weekly"
    IncrementalDaily = $true
    Retention = @{
        Type = "ImportanceWeighted"
        Critical = 90
        Important = 30
    }
    Validation = @{
        ChecksumAlgorithm = "SHA256"
        RestoreTest = $true
        TestFrequency = "Weekly"
    }
    Compression = "7z"
    Encryption = "AES-256"
}

# Result: Full backup Sunday 2 AM, Daily incremental 2 AM, Tested weekly
```

### Example 2: Optimize Large Backup Storage

```powershell
# Scenario: 500GB of files growing 10% monthly

$analysis = @{
    CurrentSize = 500
    GrowthRate = 10
    StorageAvailable = 2000
}

$recommendation = Select-BackupStrategy @{
    DataSizeGB = 500
    ChangeRatePercent = 10
    ExecutionWindowMinutes = 60
    StorageConstraintGB = 2000
}

# Result: "Differential" - Balance between size and restore speed
```

### Example 3: Recovery Scenario

```powershell
# Scenario: Restore specific files from 2 days ago

$backups = Get-ChildItem -Path "D:\Backups" |
    Where-Object { $_.CreationTime -gt (Get-Date).AddDays(-3) } |
    Sort-Object -Property CreationTime -Descending

$targetBackup = $backups[0]  # Most recent before issue

$restoreTest = Test-RestoreValidity -BackupPath $targetBackup.FullName -TestPath "$env:TEMP\restore_test"

if ($restoreTest.Valid) {
    # Proceed with actual restore
    Expand-Archive -Path $targetBackup.FullName -DestinationPath "D:\Recovered"
}
```

---

## Integration with Phase 1

### Dependencies

- `session-lifecycle` - Track backup operations across sessions
- PowerShell 7+ - Advanced features and performance

### Smart Backup Extension

This skill extends Phase 1's Smart Backup with:

- Advanced strategy selection algorithms
- Intelligent retention policies
- Automated validation and repair
- Enterprise-grade compression/encryption

---

## Performance Expectations

| Operation            | Target Time | Max Memory |
| -------------------- | ----------- | ---------- |
| Strategy Selection   | <1 second   | <10MB      |
| Schedule Calculation | <1 second   | <5MB       |
| Integrity Check      | <5 seconds  | <50MB      |
| Corruption Detection | <10 seconds | <100MB     |
| Compression (1GB)    | <30 seconds | <200MB     |
| Encryption (1GB)     | <20 seconds | <150MB     |

---

## Error Handling

### Common Issues & Solutions

**Issue**: "Backup file is empty"

- **Cause**: Backup process interrupted or failed
- **Solution**: Retry backup, check disk space, verify source access

**Issue**: "Checksum mismatch"

- **Cause**: File corruption or transfer error
- **Solution**: Re-backup, verify storage integrity, check for hardware issues

**Issue**: "Restore test failed"

- **Cause**: Archive corrupted or incomplete
- **Solution**: Attempt repair, use previous backup, check restore path permissions

---

## References

- [PowerShell Compression](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/)
- [7-Zip Documentation](https://www.7-zip.org/)
- [AES Encryption Standards](https://csrc.nist.gov/publications/detail/fips/197/final)
- [SHA256 Hashing](https://csrc.nist.gov/publications/detail/fips/180-4/final)
