#Requires -Version 5.1
<#
.SYNOPSIS
    GV Audit Integration - Unified audit interface via gv.ps1
.DESCRIPTION
    Provides unified audit interface combining gentle-vanguard-audit and judgment-day.
    
    Actions:
    - sweep: Batch validation (gentle-vanguard-audit) - zero tokens
    - judgment: Batch + adversarial review (judgment-day) - tokens
    - check: Specific check type
    - report: Generate markdown report
    
    Modes:
    - quick: Basic checks (1s)
    - standard: Standard checks (3s)
    - full: All checks (5s)
    - judgment: Full + adversarial review (15min)
.PARAMETER Action
    sweep | judgment | check | report | sync
.PARAMETER Mode
    quick | standard | full | judgment | unified
.PARAMETER Scope
    quick | standard | full | deep
.PARAMETER Type
    duplicates | links | skills | docs | all
.PARAMETER Output
    text | json | markdown
.PARAMETER SkipJudgment
    Skip adversarial review phase
#>
param(
    [Parameter(Position=0)]
    [ValidateSet('sweep', 'judgment', 'check', 'report', 'sync')]
    [string]$Action = 'sweep',
    
    [ValidateSet('quick', 'standard', 'full', 'judgment', 'unified')]
    [string]$Mode = 'standard',
    
    [ValidateSet('quick', 'standard', 'full', 'deep')]
    [string]$Scope = 'standard',
    
    [ValidateSet('duplicates', 'links', 'skills', 'docs', 'all')]
    [string]$Type = 'all',
    
    [ValidateSet('text', 'json', 'markdown')]
    [string]$Output = 'text',
    
    [switch]$FailOnIssues,
    
    [switch]$SkipJudgment,
    
    [string]$BasePath
)

$ErrorActionPreference = 'Continue'

# Resolve paths
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Gentle-VanguardRoot = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

if (-not $BasePath) {
    $BasePath = $Gentle-VanguardRoot
}

$BatchScript = Join-Path $Gentle-VanguardRoot 'skills\gentle-vanguard-audit-skill\scripts\audit-sweep.ps1'
$WorkflowScript = Join-Path $Gentle-VanguardRoot 'skills\gentle-vanguard-audit-skill\scripts\audit-workflow.ps1'
$SyncScript = Join-Path $Gentle-VanguardRoot 'skills\gentle-vanguard-audit-skill\scripts\sync-local.ps1'

# Execute based on action
switch ($Action) {
    'sweep' {
        Write-Host "Running Gentle-Vanguard Audit Sweep..." -ForegroundColor Magenta
        & $WorkflowScript -Mode $Mode -Output $Output -FailOnIssues:$FailOnIssues -SkipJudgment:$true -BasePath $BasePath
    }
    
    'judgment' {
        Write-Host "Running Unified Audit + Judgment..." -ForegroundColor Magenta
        & $WorkflowScript -Mode 'judgment' -Output $Output -FailOnIssues:$FailOnIssues -SkipJudgment:$SkipJudgment -BasePath $BasePath
    }
    
    'check' {
        Write-Host "Running specific check: $Type..." -ForegroundColor Magenta
        & $BatchScript -Scope 'quick' -Type $Type -Output $Output -FailOnIssues:$FailOnIssues -BasePath $BasePath
    }
    
    'report' {
        Write-Host "Generating audit report..." -ForegroundColor Magenta
        & $BatchScript -Scope 'full' -Type 'all' -Output 'markdown' -BasePath $BasePath
    }
    
    'sync' {
        Write-Host "Syncing to local..." -ForegroundColor Magenta
        & $SyncScript
    }
}

