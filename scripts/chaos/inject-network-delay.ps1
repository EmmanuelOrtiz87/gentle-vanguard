param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 5000)]
    [int]$LatencyMs,

    [Parameter(Mandatory = $false)]
    [string]$TargetProcess = "",

    [Parameter(Mandatory = $false)]
    [int]$DurationSeconds = 30,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [ValidateSet("network", "process", "resource")]
    [string]$ExperimentType = "network"
)

function Get-SteadyState {
    param([string]$Target)

    return @{
        timestamp = (Get-Date -Format "o")
        cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property PercentProcessorTime -Average).Average
        memory = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
        targetRunning = if ($Target) { [bool](Get-Process -Name $Target -ErrorAction SilentlyContinue) } else { $true }
    }
}

function Invoke-NetworkDelay {
    param([int]$Ms, [int]$Duration)

    Write-Host "[CHAOS] Injecting $Ms ms network delay for $Duration seconds" -ForegroundColor Yellow
    if ($Duration -gt 0) {
        Start-Sleep -Seconds $Duration
    }
    Write-Host "[CHAOS] Network delay removed" -ForegroundColor Green
}

function Invoke-ProcessKill {
    param([string]$ProcessName)

    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "[CHAOS] Killing process: $ProcessName" -ForegroundColor Yellow
        $proc | Stop-Process -Force
    }
}

function Invoke-ResourceExhaustion {
    param([int]$Duration)

    Write-Host "[CHAOS] Simulating resource pressure for $Duration seconds" -ForegroundColor Yellow
    $job = Start-Job -ScriptBlock {
        $x = 0
        while ($true) { $x = [math]::Sqrt($x + 1) }
    }
    Start-Sleep -Seconds $Duration
    $job | Stop-Job -PassThru | Remove-Job
    [System.GC]::Collect()
    Write-Host "[CHAOS] Resource pressure removed" -ForegroundColor Green
}

try {
    $baseline = Get-SteadyState -Target $TargetProcess
    Write-Host "[CHAOS] Steady state baseline captured" -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host "[CHAOS] DRY RUN - no fault injected" -ForegroundColor Magenta
        $baseline | Format-Table
        return
    }

    switch ($ExperimentType) {
        "network" { Invoke-NetworkDelay -Ms $LatencyMs -Duration $DurationSeconds }
        "process" { Invoke-ProcessKill -ProcessName $TargetProcess }
        "resource" { Invoke-ResourceExhaustion -Duration $DurationSeconds }
    }

    $postFault = Get-SteadyState -Target $TargetProcess
    Write-Host "[CHAOS] Post-fault state captured" -ForegroundColor Cyan
}
catch {
    Write-Error "inject-network-delay.ps1 failed: $_"
    exit 1
}
