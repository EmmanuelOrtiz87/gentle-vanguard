<#
.SYNOPSIS
    Autonomous Norm Learner - Learns and adapts project norms
    
.DESCRIPTION
    Runs at session start/close to learn and adapt project norms.
    
.PARAMETER Trigger
    What triggered this run: session-start, session-close, orchestrator, manual
    
.PARAMETER VerboseOutput
    Show detailed output
    
.EXAMPLE
    .\auto-norm-learner.ps1 -Trigger session-start
    
.NOTES
    Author: gentle-vanguard
    Version: 1.0.0
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("session-start", "session-close", "orchestrator", "manual")]
    [string]$Trigger = "manual",
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Continue'

Write-Host "[NORM-LEARNER] Autonomous Norm Learner started (Trigger: $Trigger)" -ForegroundColor Cyan

exit 0
