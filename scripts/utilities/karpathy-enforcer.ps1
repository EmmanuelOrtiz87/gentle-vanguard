# karpathy-enforcer.ps1
# Enforces Karpathy Guidelines: Think, Simplicity, Goal-Driven

param(
    [Parameter(Mandatory=$true)]
    [string]$Trigger,
    [switch]$VerboseOutput,
    [switch]$AutoFix
)

$ErrorActionPreference = "Continue"

function Write-Log {
    param([string]$Message)
    if ($VerboseOutput) {
        Write-Host "[KARPATHY] $Message" -ForegroundColor Cyan
    }
}

function Test-ThinkGuideline {
    param([string]$Content)
    $thinkPatterns = @('think', 'Think', 'THINK', 'reasoning', 'Reasoning')
    foreach ($pattern in $thinkPatterns) {
        if ($Content -match $pattern) {
            return $true
        }
    }
    return $false
}

function Test-SimplicityGuideline {
    param([string]$Content)
    $simplicityPatterns = @('simple', 'Simple', 'SIMPL', 'KISS', 'clean', 'Clean')
    foreach ($pattern in $simplicityPatterns) {
        if ($Content -match $pattern) {
            return $true
        }
    }
    return $false
}

function Test-GoalDrivenGuideline {
    param([string]$Content)
    $goalPatterns = @('goal', 'Goal', 'GOAL', 'objective', 'Objective', 'purpose', 'Purpose')
    foreach ($pattern in $goalPatterns) {
        if ($Content -match $pattern) {
            return $true
        }
    }
    return $false
}

Write-Log "Enforcing Karpathy Guidelines for trigger: $Trigger"

$allPassed = $true

# Check Think guideline
if (Test-ThinkGuideline -Content $Trigger) {
    Write-Log "[PASS] Think guideline: Present"
} else {
    Write-Log "[FAIL] Think guideline: Missing - encourage reasoning"
    $allPassed = $false
}

# Check Simplicity guideline
if (Test-SimplicityGuideline -Content $Trigger) {
    Write-Log "[PASS] Simplicity guideline: Present"
} else {
    Write-Log "[FAIL] Simplicity guideline: Missing - keep it simple"
    $allPassed = $false
}

# Check Goal-Driven guideline
if (Test-GoalDrivenGuideline -Content $Trigger) {
    Write-Log "[PASS] Goal-Driven guideline: Present"
} else {
    Write-Log "[FAIL] Goal-Driven guideline: Missing - define clear goals"
    $allPassed = $false
}

if ($allPassed) {
    Write-Log "All Karpathy Guidelines enforced - code quality optimal"
    exit 0
} else {
    Write-Log "Karpathy Guidelines violations detected - see above"
    exit 1
}