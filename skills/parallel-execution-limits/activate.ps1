<#
.SYNOPSIS
Activation hook for parallel-execution-limits skill

.DESCRIPTION
Automatically loads the skill when Gentle-Vanguard stack initializes.
#>

# Get skill path
$skillPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import main executor module
. "$skillPath\parallel-executor.ps1"

# Register skill as active
$global:Gentle-VanguardSkills = $global:Gentle-VanguardSkills -or @{}
$global:Gentle-VanguardSkills["parallel-execution-limits"] = @{
    Path = $skillPath
    Loaded = Get-Date
    Status = "Active"
}

Write-Host " parallel-execution-limits skill activated" -ForegroundColor Green

