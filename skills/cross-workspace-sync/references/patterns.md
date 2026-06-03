#### Strategy-Based Resolution

```powershell
function Resolve-Conflict-StrategyBased {
    param(
        [object]$FileA,
        [object]$FileB,
        [hashtable]$Rules
    )

    foreach ($rule in $Rules) {
        if ($FileA.Name -match $rule.Pattern) {
            return @{
                Winner = $rule.Action
                Rule = $rule.Name
                Strategy = "StrategyBased"
            }
        }
    }

    return Resolve-Conflict-NewestWins -FileA $FileA -FileB $FileB
}
```

#### Backup-First Resolution

```powershell
function Resolve-Conflict-BackupFirst {
    param(
        [object]$FileA,
        [object]$FileB,
        [string]$BackupPath
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    $backupA = "$BackupPath\$($FileA.BaseName)_A_$timestamp$($FileA.Extension)"
    $backupB = "$BackupPath\$($FileB.BaseName)_B_$timestamp$($FileB.Extension)"

    Copy-Item -Path $FileA.FullName -Destination $backupA
    Copy-Item -Path $FileB.FullName -Destination $backupB

    return @{
        BackupA = $backupA
        BackupB = $backupB
        Strategy = "BackupFirst"
        Timestamp = $timestamp
    }
}
```

---

### 3. Change Detection

#### File Hash Comparison

```powershell
function Compare-FilesByHash {
    param(
        [string]$Path1,
        [string]$Path2,
        [string]$Algorithm = "SHA256"
    )

    $hash1 = Get-FileHash -Path $Path1 -Algorithm $Algorithm
    $hash2 = Get-FileHash -Path $Path2 -Algorithm $Algorithm

    return @{
        Path1 = $Path1
        Path2 = $Path2
        Identical = ($hash1.Hash -eq $hash2.Hash)
        Algorithm = $Algorithm
    }
}
```

#### Timestamp Comparison

```powershell
function Compare-FilesByTimestamp {
    param([string]$Path1, [string]$Path2)

    $file1 = Get-Item $Path1
    $file2 = Get-Item $Path2

    return @{
        Path1 = $Path1
        Path2 = $Path2
        Newer = if ($file1.LastWriteTime -gt $file2.LastWriteTime) { "Path1" } else { "Path2" }
        TimeDiff = [math]::Abs(($file1.LastWriteTime - $file2.LastWriteTime).TotalSeconds)
    }
}
```

#### Size Comparison

```powershell
function Compare-FilesBySize {
    param([string]$Path1, [string]$Path2)

    $size1 = (Get-Item $Path1).Length
    $size2 = (Get-Item $Path2).Length

    return @{
        Path1 = $Path1
        Path2 = $Path2
        Size1 = $size1
        Size2 = $size2
        Identical = ($size1 -eq $size2)
        SizeDiff = [math]::Abs($size1 - $size2)
    }
}
```

---

### 4. Pre/Post Sync Validation

#### Source Integrity Check

```powershell
function Test-SourceIntegrity {
    param([string]$SourcePath)

    $results = @{
        Valid = $true
        Issues = @()
    }

    # Check 1: Path exists
    if (-not (Test-Path $SourcePath)) {
        $results.Valid = $false
        $results.Issues += "Source path does not exist"
    }

    # Check 2: Readable
    try {
        Get-ChildItem -Path $SourcePath -ErrorAction Stop | Out-Null
    }
    catch {
        $results.Valid = $false
        $results.Issues += "Source path not readable: $($_.Exception.Message)"
    }

    # Check 3: File count
    $fileCount = (Get-ChildItem -Path $SourcePath -Recurse -File).Count
    $results.FileCount = $fileCount

    return $results
}
```

#### Destination Readiness Check

```powershell
function Test-DestinationReadiness {
    param([string]$DestinationPath)

    $results = @{
        Ready = $true
        Issues = @()
    }

    # Check 1: Writable
    try {
        $testFile = "$DestinationPath\.sync_test_$([guid]::NewGuid())"
        New-Item -Path $testFile -ItemType File -Force | Out-Null
        Remove-Item -Path $testFile -Force
    }
    catch {
        $results.Ready = $false
        $results.Issues += "Destination not writable: $($_.Exception.Message)"
    }

    # Check 2: Space available
    $drive = (Get-Item $DestinationPath).PSDrive
    $freeSpace = (Get-Volume -DriveLetter $drive.Name).SizeRemaining
    $results.FreeSpace = $freeSpace

    if ($freeSpace -lt 1GB) {
        $results.Ready = $false
        $results.Issues += "Insufficient disk space (< 1GB)"
    }

    return $results
}
```

#### Permission Verification

```powershell
function Test-SyncPermissions {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )

    $results = @{
        CanSync = $true
        Issues = @()
    }

    # Check source read permissions
    try {
        Get-ChildItem -Path $SourcePath -Recurse -ErrorAction Stop | Out-Null
    }
    catch {
        $results.CanSync = $false
        $results.Issues += "No read permission on source"
    }

    # Check destination write permissions
    try {
        $testFile = "$DestinationPath\.perm_test"
        New-Item -Path $testFile -ItemType File -Force -ErrorAction Stop | Out-Null
        Remove-Item -Path $testFile -Force
    }
    catch {
        $results.CanSync = $false
        $results.Issues += "No write permission on destination"
    }

    return $results
}
```

---

### 5. Consistency Monitoring

#### Drift Detection

```powershell
function Detect-SyncDrift {
    param(
        [string]$Workspace1,
        [string]$Workspace2
    )

    $files1 = Get-ChildItem -Path $Workspace1 -Recurse -File
    $files2 = Get-ChildItem -Path $Workspace2 -Recurse -File

    $drift = @{
        DriftDetected = $false
        OnlyInWorkspace1 = @()
        OnlyInWorkspace2 = @()
        DifferentContent = @()
    }

    # Find files only in workspace 1
    foreach ($file in $files1) {
        $relativePath = $file.FullName.Replace($Workspace1, "")
        $counterpart = Join-Path $Workspace2 $relativePath

        if (-not (Test-Path $counterpart)) {
            $drift.OnlyInWorkspace1 += $relativePath
            $drift.DriftDetected = $true
        }
        else {
            $hash1 = (Get-FileHash $file.FullName).Hash
            $hash2 = (Get-FileHash $counterpart).Hash

            if ($hash1 -ne $hash2) {
                $drift.DifferentContent += $relativePath
                $drift.DriftDetected = $true
            }
        }
    }

    return $drift
}
```

#### Automatic Re-sync

```powershell
function Invoke-AutoResync {
    param(
        [string]$Workspace1,
        [string]$Workspace2,
        [string]$ConflictStrategy = "Newest-Wins"
    )

    $drift = Detect-SyncDrift -Workspace1 $Workspace1 -Workspace2 $Workspace2

    if (-not $drift.DriftDetected) {
        return @{ Success = $true; Message = "Workspaces already synchronized" }
    }

    Write-Host "Detected drift, initiating auto-resync..."

    # Resync files only in workspace 1
    foreach ($file in $drift.OnlyInWorkspace1) {
        $source = Join-Path $Workspace1 $file
        $dest = Join-Path $Workspace2 $file
        Copy-Item -Path $source -Destination $dest -Force
        Write-Host "Synced: $file"
    }

    return @{
        Success = $true
        FilesResynced = $drift.OnlyInWorkspace1.Count + $drift.DifferentContent.Count
    }
}
```

#### Alerting on Inconsistencies

```powershell
function Send-SyncAlert {
    param(
        [string]$AlertType,  # "Drift", "Conflict", "Error"
        [string]$Message,
        [string]$Severity = "Warning"  # Info, Warning, Critical
    )

    $alert = @{
        Type = $AlertType
        Message = $Message
        Severity = $Severity
        Timestamp = Get-Date
    }

    switch ($Severity) {
        "Critical" {
            Write-Host " CRITICAL: $Message" -ForegroundColor Red
        }
        "Warning" {
            Write-Host " WARNING: $Message" -ForegroundColor Yellow
        }
        "Info" {
            Write-Host " INFO: $Message" -ForegroundColor Cyan
        }
    }

    return $alert
}
```

---

## Practical Examples

### Example 1: Two-Way Sync with Conflict Resolution

```powershell
$config = @{
    Mode = "TwoWay"
    Workspace1 = "C:\Dev-A"
    Workspace2 = "C:\Dev-B"
    ConflictStrategy = "Newest-Wins"
}

# Sync and resolve conflicts automatically
$result = Invoke-WorkspaceSync @config

# Monitor for drift
$drift = Detect-SyncDrift -Workspace1 $config.Workspace1 -Workspace2 $config.Workspace2
if ($drift.DriftDetected) {
    Invoke-AutoResync @config
}
```

### Example 2: Selective Configuration Sync

```powershell
$config = @{
    Mode = "Selective"
    Source = "C:\Production"
    Destination = "C:\Staging"
    IncludePatterns = @("*.config", "*.json")
    ExcludePatterns = @("*.log", "*.tmp")
}

# Sync only configuration files
Invoke-WorkspaceSync @config
```

---

## Integration with Phase 1

### Dependencies

- `session-lifecycle` - Track sync operations across sessions
- `backup-orchestrator` - Backup before sync operations

---

## Performance Expectations

| Operation                     | Target Time | Max Memory |
| ----------------------------- | ----------- | ---------- |
| Change Detection (1000 files) | <5 seconds  | <100MB     |
| Conflict Resolution           | <2 seconds  | <50MB      |
| Drift Detection               | <10 seconds | <150MB     |
| Auto-Resync (100 files)       | <15 seconds | <200MB     |

---

## Error Handling

**Issue**: "Destination not writable"

- **Solution**: Check permissions, verify disk space

**Issue**: "Unresolvable conflicts"

- **Solution**: Use Backup-First strategy, manual review

**Issue**: "Sync drift detected"

- **Solution**: Trigger auto-resync, verify source integrity
