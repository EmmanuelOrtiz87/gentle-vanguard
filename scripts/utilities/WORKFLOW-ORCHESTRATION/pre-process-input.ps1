<#
.SYNOPSIS
    Pre-process user input for trigger detection
.DESCRIPTION
    Analyzes user input to detect skill triggers and automation hooks
.PARAMETER UserInput
    The user input to analyze
.PARAMETER WorkspaceRoot
    Root path of the workspace
#>
param(
    [string]$UserInput,
    [string]$WorkspaceRoot = "."
)

$triggers = @{
    "sdd" = @("sdd init", "sdd propose", "spec", "specs")
    "session" = @("session", "sesion", "start session")
    "validation" = @("validate", "validar", "check")
}

foreach ($key in $triggers.Keys) {
    foreach ($trigger in $triggers[$key]) {
        if ($UserInput -match [regex]::Escape($trigger)) {
            Write-Output "SKILL: $key"
            exit 0
        }
    }
}

Write-Output "No trigger detected"
