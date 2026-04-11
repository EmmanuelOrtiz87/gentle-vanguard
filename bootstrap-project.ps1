# bootstrap-project.ps1
# Workspace Foundation Bootstrap Script
# Implements error handling and performance patterns per SDD

# Error Handling Setup
$ErrorActionPreference = 'Stop'
$scriptStartTime = Get-Date

# Logging Function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path "$PSScriptRoot\bootstrap.log" -Value $logMessage
}

# Error Handler
function Handle-Error {
    param([System.Management.Automation.ErrorRecord]$ErrorRecord, [string]$Context)
    Write-Log "Error in $Context: $($ErrorRecord.Exception.Message)" "ERROR"
    Write-Log "Stack Trace: $($ErrorRecord.ScriptStackTrace)" "ERROR"
    Write-Log "Execution Time: $((Get-Date) - $scriptStartTime)" "INFO"
    throw "Bootstrap failed in $Context. Check logs for details."
}

# Safe Operation Wrapper
function Invoke-SafeOperation {
    param([scriptblock]$Operation, [string]$Context)
    try {
        Write-Log "Starting: $Context"
        $startTime = Get-Date
        & $Operation
        $duration = (Get-Date) - $startTime
        Write-Log "Completed: $Context in $($duration.TotalSeconds) seconds"
    } catch {
        Handle-Error $_ $Context
    }
}

# Main Bootstrap Logic
try {
    Write-Log "Starting Workspace Foundation Bootstrap"

    # Platform Detection (Performance: Cache result)
    $os = if ($IsWindows) { "Windows" } elseif ($IsMacOS) { "macOS" } else { "Linux" }
    $shell = if ($PSVersionTable.PSEdition -eq "Core") { "PowerShell Core" } else { "Windows PowerShell" }
    Write-Log "Platform: $os, Shell: $shell"

    # Project Root Resolution
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    Write-Log "Project Root: $projectRoot"

    # Dependency Synchronization with Error Handling
    Invoke-SafeOperation -Operation {
        Write-Host "`n>> Sincronizando dependencias del proyecto..." -ForegroundColor Cyan
        Set-Location $projectRoot

        # Check if go.mod exists
        if (!(Test-Path "go.mod")) {
            throw "go.mod not found. Ensure you're in a Go project directory."
        }

        # Run go mod tidy with timeout
        $job = Start-Job -ScriptBlock { go mod tidy }
        $result = $job | Wait-Job -Timeout 300  # 5 minute timeout
        if ($job.State -eq "Running") {
            Stop-Job $job
            throw "go mod tidy timed out after 5 minutes"
        }
        $output = Receive-Job $job
        if ($job.State -eq "Failed") {
            throw "go mod tidy failed: $output"
        }

        Write-Host "[OK] Dependencias sincronizadas." -ForegroundColor Green
    } -Context "Dependency Synchronization"

    # Validation Step
    Invoke-SafeOperation -Operation {
        Write-Host "`n>> Validando configuración..." -ForegroundColor Cyan

        # Check required files
        $requiredFiles = @("README.md", "config/orchestrator.json", "docs/README.md")
        foreach ($file in $requiredFiles) {
            if (!(Test-Path (Join-Path $projectRoot $file))) {
                throw "Required file missing: $file"
            }
        }

        # Validate orchestrator config
        $configPath = Join-Path $projectRoot "config/orchestrator.json"
        $config = Get-Content $configPath | ConvertFrom-Json
        if ($config.active -ne $true) {
            throw "Orchestrator is not active in config"
        }

        Write-Host "[OK] Configuración validada." -ForegroundColor Green
    } -Context "Configuration Validation"

    # Success Metrics
    $totalTime = (Get-Date) - $scriptStartTime
    Write-Log "Bootstrap completed successfully in $($totalTime.TotalSeconds) seconds"
    Write-Host "`n✅ Workspace Foundation listo para operar." -ForegroundColor Green
    Write-Host "📊 Tiempo total: $($totalTime.TotalSeconds) segundos" -ForegroundColor Gray

} catch {
    Handle-Error $_ "Main Bootstrap"
    exit 1
}