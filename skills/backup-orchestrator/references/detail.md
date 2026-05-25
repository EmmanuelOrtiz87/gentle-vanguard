    if ($ChangeRatePercent -gt 50) { return "Full" }
    if ($ExecutionWindowMinutes -lt 10) { return "Incremental" }
    if ($StorageConstraintGB -lt $DataSizeGB * 2) { return "Incremental" }

    return "Differential"

}

````

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
````

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
