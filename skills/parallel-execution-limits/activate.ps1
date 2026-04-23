<#
.SYNOPSIS
Activation hook for parallel-execution-limits skill

.DESCRIPTION
Automatically loads the skill when Foundation stack initializes.
#>

# Get skill path
$skillPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import main executor module
. "$skillPath\parallel-executor.ps1"

# Register skill as active
$global:FoundationSkills = $global:FoundationSkills -or @{}
$global:FoundationSkills["parallel-execution-limits"] = @{
    Path = $skillPath
    Loaded = Get-Date
    Status = "Active"
}

Write-Host "âœ… parallel-execution-limits skill activated" -ForegroundColor Green
