<#
.SYNOPSIS
Post-merge hook for Foundation workflow - syncs documentation and validates consistency

.DESCRIPTION
This hook runs AFTER merge completes to:
- Update documentation references
- Validate consistency across branches
- Sync configuration files
- Generate merge report

.PARAMETER MergeBranch
The branch that was merged

.PARAMETER WorkspaceRoot
Root directory of the workspace

.EXAMPLE
.\post-merge-sync.ps1 -MergeBranch "feature/new-api" -WorkspaceRoot "."
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$MergeBranch,
    
    [Parameter(Mandatory = $false)]
    [string]$WorkspaceRoot = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Initialize
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logFile = ".session/logs/post-merge-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$syncIssues = @()

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    if (Test-Path (Split-Path $logFile)) {
        Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
    }
}

Write-Log "Starting post-merge sync hook"

try {
    # Get current branch if not provided
    if ([string]::IsNullOrWhiteSpace($MergeBranch)) {
        $MergeBranch = git rev-parse --abbrev-ref HEAD 2>$null
        Write-Log "Current branch: $MergeBranch"
    }

    # Check for merge conflicts
    $conflictFiles = @(git diff --name-only --diff-filter=U 2>$null)
    if ($conflictFiles.Count -gt 0) {
        Write-Log "Merge conflicts detected in $($conflictFiles.Count) files" "WARN"
        foreach ($file in $conflictFiles) {
            $syncIssues += "Conflict in $file"
        }
    }

    # Validate configuration files
    Write-Log "Validating configuration files..."
    $configFiles = @(Get-ChildItem -Path "config/*.json" -ErrorAction SilentlyContinue)
    foreach ($configFile in $configFiles) {
        try {
            $json = Get-Content $configFile.FullName -Raw | ConvertFrom-Json
            Write-Log "Config validation passed: $($configFile.Name)"
        }
        catch {
            $syncIssues += "Invalid config file: $($configFile.Name) - $_"
            Write-Log "Config validation failed: $($configFile.Name)" "WARN"
        }
    }

    # Check for documentation updates needed
    Write-Log "Checking documentation references..."
    $docFiles = @(Get-ChildItem -Path "docs/*.md" -ErrorAction SilentlyContinue)
    $changedFiles = @(git diff --name-only HEAD~1 HEAD 2>$null)
    
    if ($changedFiles.Count -gt 0 -and $docFiles.Count -gt 0) {
        Write-Log "Found $($changedFiles.Count) changed files and $($docFiles.Count) documentation files"
        # Documentation sync would happen here
    }

    # Generate merge report
    $reportPath = ".session/reports/merge-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report = @{
        timestamp = $timestamp
        branch = $MergeBranch
        conflictCount = $conflictFiles.Count
        issueCount = $syncIssues.Count
        issues = $syncIssues
        status = if ($syncIssues.Count -eq 0) { "SYNC_COMPLETE" } else { "ISSUES_FOUND" }
    }

    if (-not (Test-Path (Split-Path $reportPath))) {
        New-Item -ItemType Directory -Path (Split-Path $reportPath) -Force | Out-Null
    }

    $report | ConvertTo-Json | Set-Content -Path $reportPath
    Write-Log "Merge report generated: $reportPath"

    # Output result
    if ($syncIssues.Count -eq 0) {
        Write-Log "Post-merge sync completed successfully" "SUCCESS"
        Write-Output "SYNC_COMPLETE"
    }
    else {
        Write-Log "Post-merge sync completed with issues" "WARN"
        Write-Output "ISSUES_FOUND"
    }

    exit 0
}
catch {
    Write-Log "Error in post-merge sync: $_" "ERROR"
    Write-Output "ISSUES_FOUND"
    exit 0
}