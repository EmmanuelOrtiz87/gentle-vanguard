#Requires -Version 5.1
param(
    [ValidateSet('quick', 'standard', 'full', 'deep', 'judgment', 'unified')]
    [string]$Mode = 'standard',
    [ValidateSet('text', 'json', 'markdown')]
    [string]$Output = 'text',
    [switch]$FailOnIssues,
    [switch]$SkipJudgment,
    [string]$StandalonePath = $PWD.Path,
    [string]$BasePath
)

$ErrorActionPreference = 'Continue'
$Script:StartTime = Get-Date
$Script:Issues = @()

$IsStandalone = -not $BasePath
if ($IsStandalone) {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $AuditScript = Join-Path $ScriptRoot 'audit-sweep.ps1'
    $WorkingDir = $StandalonePath
} else {
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $AuditScript = Join-Path $BasePath 'skills\gentle-vanguard-audit-skill\scripts\audit-sweep.ps1'
    $WorkingDir = $BasePath
}

function Write-AuditHeader {
    param([string]$Message, [string]$Color = 'Cyan')
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-Host "  -> $Message" -ForegroundColor White
}

function Add-Issue {
    param([string]$Category, [string]$Message, [string]$Path, [string]$Severity = 'warning')
    $Script:Issues += @{
        Category = $Category
        Message = $Message
        Path = $Path
        Severity = $Severity
        Timestamp = (Get-Date).ToString('o')
    }
    $color = @{ error = 'Red'; warning = 'Yellow'; info = 'DarkGray' }[$Severity]
    Write-Host "    [$Severity] $Message" -ForegroundColor $color
}

function Invoke-BatchAudit {
    param([string]$Scope)
    
    Write-AuditHeader "PHASE 1: Batch Audit" -Color Magenta
    
    if (Test-Path $AuditScript) {
        Write-Step "Running batch validation..."
        
        $scopeMap = @{
            'quick' = 'quick'
            'standard' = 'standard'
            'full' = 'full'
            'deep' = 'deep'
            'judgment' = 'full'
            'unified' = 'full'
        }
        
        $jsonOutput = & $AuditScript -Scope $scopeMap[$Scope] -Output 'json' -BasePath $WorkingDir 2>$null | Out-String
        if (-not [string]::IsNullOrWhiteSpace($jsonOutput)) {
            try {
                $parsed = $jsonOutput | ConvertFrom-Json -ErrorAction Stop
                if ($parsed.Issues) {
                    $Script:Issues = @($parsed.Issues)
                }
            } catch {
                Add-Issue -Category 'audit' -Message 'Could not parse audit output' -Path $AuditScript -Severity 'warning'
            }
        }
        
        Write-Step "Batch audit complete"
    } else {
        Write-Step "Audit script not found"
    }
}

function Invoke-JudgmentReview {
    param([switch]$Skip)
    
    if ($Skip) {
        Write-Step "Judgment review skipped"
        return
    }
    
    Write-AuditHeader "PHASE 2: Judgment Day" -Color Red
    Write-Host "Adversarial review pending" -ForegroundColor DarkGray
}

function Get-AuditReport {
    $elapsed = (Get-Date) - $Script:StartTime
    
    Write-AuditHeader "AUDIT SUMMARY" -Color Cyan
    
    $errors = $Script:Issues | Where-Object { $_.Severity -eq 'error' }
    $warnings = $Script:Issues | Where-Object { $_.Severity -eq 'warning' }
    
    Write-Host ""
    Write-Host "Total Issues: $($Script:Issues.Count)" -ForegroundColor $(if ($Script:Issues.Count -eq 0) { 'Green' } else { 'Yellow' })
    Write-Host "  Errors: $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { 'Red' } else { 'DarkGray' })
    Write-Host "  Warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -gt 0) { 'Yellow' } else { 'DarkGray' })
    Write-Host "Execution Time: $($elapsed.TotalSeconds.ToString('0.0'))s"
    
    if ($Output -eq 'json') {
        @{
            Summary = @{
                TotalIssues = $Script:Issues.Count
                Errors = $errors.Count
                Warnings = $warnings.Count
                ExecutionTimeSeconds = [math]::Round($elapsed.TotalSeconds, 2)
            }
            Issues = $Script:Issues
        } | ConvertTo-Json -Depth 3
    }
    
    if ($FailOnIssues -and $Script:Issues.Count -gt 0) {
        exit 1
    }
}

Write-Host ""
Write-Host "UNIFIED AUDIT WORKFLOW v1.0" -ForegroundColor Magenta
Write-Host "Gentle-Vanguard Audit + Judgment Day Integration" -ForegroundColor Magenta
Write-Host ""

Write-Host "Started: $($Script:StartTime.ToString('HH:mm:ss'))"
Write-Host "Working Dir: $WorkingDir"
Write-Host ""

switch ($Mode) {
    'quick' { Invoke-BatchAudit -Scope 'quick' }
    'standard' { Invoke-BatchAudit -Scope 'standard' }
    'full' { Invoke-BatchAudit -Scope 'full' }
    'deep' { Invoke-BatchAudit -Scope 'deep' }
    'judgment' {
        Invoke-BatchAudit -Scope 'full'
        Invoke-JudgmentReview -Skip:$SkipJudgment
    }
    'unified' {
        Invoke-BatchAudit -Scope 'full'
        Invoke-JudgmentReview -Skip:$SkipJudgment
    }
}

Get-AuditReport

exit 0
