<#
.SYNOPSIS
Resource Pooling with GPU/CPU Awareness for Parallel Execution

.DESCRIPTION
Provides functions for managing resource pools with GPU/CPU awareness,
dynamic allocation, and resource constraint enforcement.

.VERSION
1.0.0

.AUTHOR
Gentle-Vanguard Team

.LICENSE
MIT
#>

# ============================================================================
# Resource Pool Initialization
# ============================================================================

function Initialize-ResourcePool {
    <#
    .SYNOPSIS
    Initialize resource pool with system detection
    #>
    param(
        [int]$CPUCores = $null,
        [int]$MemoryMB = $null,
        [int]$GPUCount = $null,
        [int]$GPUVRAMPerDevice = $null
    )
    
    # Auto-detect system resources if not provided
    if (-not $CPUCores) {
        $CPUCores = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors
    }
    
    if (-not $MemoryMB) {
        $MemoryMB = [int]((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB)
    }
    
    if (-not $GPUCount) {
        $GPUCount = Get-GPUDeviceCount
    }
    
    if (-not $GPUVRAMPerDevice) {
        $GPUVRAMPerDevice = 24576  # Default 24GB per GPU
    }
    
    $resourcePool = @{
        CPU = @{
            Total = $CPUCores
            Available = $CPUCores
            Allocated = @{}
            Threshold = [int]($CPUCores * 0.8)
            Usage = 0
            History = @()
        }
        Memory = @{
            Total = $MemoryMB
            Available = $MemoryMB
            Allocated = @{}
            Threshold = [int]($MemoryMB * 0.85)
            Usage = 0
            History = @()
        }
        GPU = @{
            Total = $GPUCount
            Available = $GPUCount
            Allocated = @{}
            Threshold = [int]($GPUCount * 0.9)
            Devices = @()
            Usage = 0
            History = @()
        }
        CreatedAt = Get-Date
        LastUpdated = Get-Date
    }
    
    # Initialize GPU devices
    for ($i = 0; $i -lt $GPUCount; $i++) {
        $resourcePool.GPU.Devices += @{
            Id = $i
            VRAM = $GPUVRAMPerDevice
            Available = $GPUVRAMPerDevice
            Allocated = @{}
            Status = "Available"
        }
    }
    
    return $resourcePool
}

function Get-GPUDeviceCount {
    <#
    .SYNOPSIS
    Detect number of GPU devices in the system
    #>
    
    # Try to detect NVIDIA GPUs
    try {
        $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
        if ($nvidiaSmi) {
            $output = & nvidia-smi --list-gpus 2>$null
            if ($output) {
                return ($output | Measure-Object -Line).Lines
            }
        }
    }
    catch { }
    
    # Default to 0 if no GPUs detected
    return 0
}

# ============================================================================
# Resource Allocation
# ============================================================================

function Allocate-Resources {
    <#
    .SYNOPSIS
    Allocate resources for a task
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ResourcePool,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Requirements,
        
        [string]$Strategy = "FirstFit"
    )
    
    # Validate requirements
    $validation = Validate-ResourceRequirements -Requirements $Requirements
    if (-not $validation.IsValid) {
        return @{
            Success = $false
            Reason = "Invalid resource requirements"
            Issues = $validation.Issues
        }
    }
    
    # Check CPU availability
    if ($ResourcePool.CPU.Available -lt $Requirements.CPU) {
        return @{
            Success = $false
            Reason = "Insufficient CPU resources"
            Required = $Requirements.CPU
            Available = $ResourcePool.CPU.Available
            Utilization = [math]::Round(($ResourcePool.CPU.Total - $ResourcePool.CPU.Available) / $ResourcePool.CPU.Total * 100, 2)
        }
    }
    
    # Check Memory availability
    if ($ResourcePool.Memory.Available -lt $Requirements.Memory) {
        return @{
            Success = $false
            Reason = "Insufficient Memory resources"
            Required = $Requirements.Memory
            Available = $ResourcePool.Memory.Available
            Utilization = [math]::Round(($ResourcePool.Memory.Total - $ResourcePool.Memory.Available) / $ResourcePool.Memory.Total * 100, 2)
        }
    }
    
    # Check GPU availability if needed
    $gpuAllocation = $null
    if ($Requirements.GPU -gt 0) {
        $gpuAllocation = Allocate-GPUResources -ResourcePool $ResourcePool -TaskId $TaskId -GPUCount $Requirements.GPU -Strategy $Strategy
        
        if (-not $gpuAllocation.Success) {
            return $gpuAllocation
        }
    }
    
    # Perform allocation
    $ResourcePool.CPU.Available -= $Requirements.CPU
    $ResourcePool.Memory.Available -= $Requirements.Memory
    
    $ResourcePool.CPU.Allocated[$TaskId] = $Requirements.CPU
    $ResourcePool.Memory.Allocated[$TaskId] = $Requirements.Memory
    
    if ($gpuAllocation) {
        $ResourcePool.GPU.Allocated[$TaskId] = $gpuAllocation.Allocation
    }
    
    # Update usage metrics
    $ResourcePool.CPU.Usage = $ResourcePool.Total - $ResourcePool.CPU.Available
    $ResourcePool.Memory.Usage = $ResourcePool.Memory.Total - $ResourcePool.Memory.Available
    $ResourcePool.LastUpdated = Get-Date
    
    return @{
        Success = $true
        TaskId = $TaskId
        Allocation = @{
            CPU = $Requirements.CPU
            Memory = $Requirements.Memory
            GPU = $gpuAllocation.Allocation
        }
        Timestamp = Get-Date
    }
}

function Allocate-GPUResources {
    <#
    .SYNOPSIS
    Allocate GPU resources using specified strategy
    #>
    param(
        [hashtable]$ResourcePool,
        [string]$TaskId,
        [int]$GPUCount,
        [string]$Strategy = "FirstFit"
    )
    
    $allocation = @{
        Success = $false
        Devices = @()
        TotalVRAM = 0
    }
    
    switch ($Strategy) {
        "FirstFit" {
            $allocated = 0
            foreach ($device in $ResourcePool.GPU.Devices) {
                if ($allocated -lt $GPUCount -and $device.Available -gt 0) {
                    $allocation.Devices += $device.Id
                    $allocation.TotalVRAM += $device.Available
                    $allocated++
                }
            }
            
            if ($allocated -eq $GPUCount) {
                $allocation.Success = $true
                
                # Perform allocation
                foreach ($deviceId in $allocation.Devices) {
                    $device = $ResourcePool.GPU.Devices | Where-Object { $_.Id -eq $deviceId }
                    $device.Allocated[$TaskId] = $true
                }
            }
        }
        "BestFit" {
            # Sort devices by available VRAM (ascending)
            $sortedDevices = $ResourcePool.GPU.Devices | Sort-Object -Property Available
            
            $allocated = 0
            foreach ($device in $sortedDevices) {
                if ($allocated -lt $GPUCount -and $device.Available -gt 0) {
                    $allocation.Devices += $device.Id
                    $allocation.TotalVRAM += $device.Available
                    $allocated++
                }
            }
            
            if ($allocated -eq $GPUCount) {
                $allocation.Success = $true
                
                foreach ($deviceId in $allocation.Devices) {
                    $device = $ResourcePool.GPU.Devices | Where-Object { $_.Id -eq $deviceId }
                    $device.Allocated[$TaskId] = $true
                }
            }
        }
        "BalancedLoad" {
            # Distribute load evenly across devices
            $sortedDevices = $ResourcePool.GPU.Devices | Sort-Object -Property { $_.Allocated.Count }
            
            $allocated = 0
            foreach ($device in $sortedDevices) {
                if ($allocated -lt $GPUCount -and $device.Available -gt 0) {
                    $allocation.Devices += $device.Id
                    $allocation.TotalVRAM += $device.Available
                    $allocated++
                }
            }
            
            if ($allocated -eq $GPUCount) {
                $allocation.Success = $true
                
                foreach ($deviceId in $allocation.Devices) {
                    $device = $ResourcePool.GPU.Devices | Where-Object { $_.Id -eq $deviceId }
                    $device.Allocated[$TaskId] = $true
                }
            }
        }
    }
    
    if (-not $allocation.Success) {
        return @{
            Success = $false
            Reason = "Insufficient GPU resources"
            Required = $GPUCount
            Available = ($ResourcePool.GPU.Devices | Where-Object { $_.Available -gt 0 }).Count
        }
    }
    
    return @{
        Success = $true
        Allocation = $allocation
    }
}

# ============================================================================
# Resource Release
# ============================================================================

function Release-Resources {
    <#
    .SYNOPSIS
    Release resources allocated to a task
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ResourcePool,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskId
    )
    
    $released = @{
        CPU = 0
        Memory = 0
        GPU = @()
    }
    
    # Release CPU
    if ($ResourcePool.CPU.Allocated.ContainsKey($TaskId)) {
        $released.CPU = $ResourcePool.CPU.Allocated[$TaskId]
        $ResourcePool.CPU.Available += $released.CPU
        $ResourcePool.CPU.Allocated.Remove($TaskId)
    }
    
    # Release Memory
    if ($ResourcePool.Memory.Allocated.ContainsKey($TaskId)) {
        $released.Memory = $ResourcePool.Memory.Allocated[$TaskId]
        $ResourcePool.Memory.Available += $released.Memory
        $ResourcePool.Memory.Allocated.Remove($TaskId)
    }
    
    # Release GPU
    if ($ResourcePool.GPU.Allocated.ContainsKey($TaskId)) {
        $gpuAllocation = $ResourcePool.GPU.Allocated[$TaskId]
        
        foreach ($deviceId in $gpuAllocation.Devices) {
            $device = $ResourcePool.GPU.Devices | Where-Object { $_.Id -eq $deviceId }
            if ($device.Allocated.ContainsKey($TaskId)) {
                $device.Allocated.Remove($TaskId)
                $released.GPU += $deviceId
            }
        }
        
        $ResourcePool.GPU.Allocated.Remove($TaskId)
    }
    
    # Update usage metrics
    $ResourcePool.CPU.Usage = $ResourcePool.CPU.Total - $ResourcePool.CPU.Available
    $ResourcePool.Memory.Usage = $ResourcePool.Memory.Total - $ResourcePool.Memory.Available
    $ResourcePool.LastUpdated = Get-Date
    
    return @{
        Success = $true
        TaskId = $TaskId
        Released = $released
        Timestamp = Get-Date
    }
}

# ============================================================================
# Resource Monitoring
# ============================================================================

function Get-ResourceUtilization {
    <#
    .SYNOPSIS
    Get current resource utilization
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ResourcePool
    )
    
    $cpuUtilization = [math]::Round(($ResourcePool.CPU.Total - $ResourcePool.CPU.Available) / $ResourcePool.CPU.Total * 100, 2)
    $memoryUtilization = [math]::Round(($ResourcePool.Memory.Total - $ResourcePool.Memory.Available) / $ResourcePool.Memory.Total * 100, 2)
    $gpuUtilization = [math]::Round(($ResourcePool.GPU.Total - $ResourcePool.GPU.Available) / $ResourcePool.GPU.Total * 100, 2)
    
    return @{
        CPU = @{
            Total = $ResourcePool.CPU.Total
            Available = $ResourcePool.CPU.Available
            Allocated = $ResourcePool.CPU.Total - $ResourcePool.CPU.Available
            Utilization = $cpuUtilization
            Threshold = $ResourcePool.CPU.Threshold
            IsThresholdExceeded = $cpuUtilization -gt ($ResourcePool.CPU.Threshold / $ResourcePool.CPU.Total * 100)
        }
        Memory = @{
            Total = $ResourcePool.Memory.Total
            Available = $ResourcePool.Memory.Available
            Allocated = $ResourcePool.Memory.Total - $ResourcePool.Memory.Available
            Utilization = $memoryUtilization
            Threshold = $ResourcePool.Memory.Threshold
            IsThresholdExceeded = $memoryUtilization -gt ($ResourcePool.Memory.Threshold / $ResourcePool.Memory.Total * 100)
        }
        GPU = @{
            Total = $ResourcePool.GPU.Total
            Available = $ResourcePool.GPU.Available
            Allocated = $ResourcePool.GPU.Total - $ResourcePool.GPU.Available
            Utilization = $gpuUtilization
            Threshold = $ResourcePool.GPU.Threshold
            IsThresholdExceeded = $gpuUtilization -gt ($ResourcePool.GPU.Threshold / $ResourcePool.GPU.Total * 100)
        }
        Timestamp = Get-Date
    }
}

function Get-TaskResourceAllocation {
    <#
    .SYNOPSIS
    Get resource allocation for a specific task
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ResourcePool,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskId
    )
    
    $allocation = @{
        TaskId = $TaskId
        CPU = $null
        Memory = $null
        GPU = $null
    }
    
    if ($ResourcePool.CPU.Allocated.ContainsKey($TaskId)) {
        $allocation.CPU = $ResourcePool.CPU.Allocated[$TaskId]
    }
    
    if ($ResourcePool.Memory.Allocated.ContainsKey($TaskId)) {
        $allocation.Memory = $ResourcePool.Memory.Allocated[$TaskId]
    }
    
    if ($ResourcePool.GPU.Allocated.ContainsKey($TaskId)) {
        $allocation.GPU = $ResourcePool.GPU.Allocated[$TaskId]
    }
    
    return $allocation
}

# ============================================================================
# Resource Validation
# ============================================================================

function Validate-ResourceRequirements {
    <#
    .SYNOPSIS
    Validate resource requirements for a task
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Requirements
    )
    
    $issues = @()
    
    if (-not $Requirements.ContainsKey("CPU") -or $Requirements.CPU -lt 0) {
        $issues += "Invalid or missing CPU requirement"
    }
    
    if (-not $Requirements.ContainsKey("Memory") -or $Requirements.Memory -lt 0) {
        $issues += "Invalid or missing Memory requirement"
    }
    
    if (-not $Requirements.ContainsKey("GPU") -or $Requirements.GPU -lt 0) {
        $issues += "Invalid or missing GPU requirement"
    }
    
    return @{
        IsValid = $issues.Count -eq 0
        Issues = $issues
    }
}

function Test-ResourceAvailability {
    <#
    .SYNOPSIS
    Test if resources are available for allocation
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ResourcePool,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Requirements
    )
    
    $available = @{
        CPU = $ResourcePool.CPU.Available -ge $Requirements.CPU
        Memory = $ResourcePool.Memory.Available -ge $Requirements.Memory
        GPU = $ResourcePool.GPU.Available -ge $Requirements.GPU
    }
    
    return @{
        CanAllocate = $available.CPU -and $available.Memory -and $available.GPU
        Available = $available
        Utilization = Get-ResourceUtilization -ResourcePool $ResourcePool
    }
}

# ============================================================================
# Resource Optimization
# ============================================================================

function Optimize-ResourceAllocation {
    <#
    .SYNOPSIS
    Optimize resource allocation for better utilization
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ResourcePool,
        
        [array]$Tasks
    )
    
    $optimization = @{
        CurrentUtilization = Get-ResourceUtilization -ResourcePool $ResourcePool
        Recommendations = @()
        OptimizationScore = 0
    }
    
    # Analyze CPU utilization
    $cpuUtil = $optimization.CurrentUtilization.CPU.Utilization
    if ($cpuUtil -lt 30) {
        $optimization.Recommendations += "CPU utilization is low ($cpuUtil%). Consider increasing parallelism."
    }
    elseif ($cpuUtil -gt 90) {
        $optimization.Recommendations += "CPU utilization is high ($cpuUtil%). Consider reducing parallelism or adding resources."
    }
    
    # Analyze Memory utilization
    $memUtil = $optimization.CurrentUtilization.Memory.Utilization
    if ($memUtil -lt 30) {
        $optimization.Recommendations += "Memory utilization is low ($memUtil%). Consider increasing task batch size."
    }
    elseif ($memUtil -gt 90) {
        $optimization.Recommendations += "Memory utilization is high ($memUtil%). Consider reducing task batch size or adding memory."
    }
    
    # Analyze GPU utilization
    $gpuUtil = $optimization.CurrentUtilization.GPU.Utilization
    if ($gpuUtil -gt 0 -and $gpuUtil -lt 30) {
        $optimization.Recommendations += "GPU utilization is low ($gpuUtil%). Consider increasing GPU task parallelism."
    }
    elseif ($gpuUtil -gt 90) {
        $optimization.Recommendations += "GPU utilization is high ($gpuUtil%). Consider reducing GPU task parallelism."
    }
    
    # Calculate optimization score (0-100)
    $optimization.OptimizationScore = [math]::Min(100, [math]::Abs(50 - $cpuUtil) + [math]::Abs(50 - $memUtil))
    
    return $optimization
}

# ============================================================================
# Export Functions
# ============================================================================

Export-ModuleMember -Function @(
    'Initialize-ResourcePool'
    'Get-GPUDeviceCount'
    'Allocate-Resources'
    'Allocate-GPUResources'
    'Release-Resources'
    'Get-ResourceUtilization'
    'Get-TaskResourceAllocation'
    'Validate-ResourceRequirements'
    'Test-ResourceAvailability'
    'Optimize-ResourceAllocation'
)
