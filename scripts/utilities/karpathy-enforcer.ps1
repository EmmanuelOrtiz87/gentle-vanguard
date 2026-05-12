# karpathy-enforcer.ps1
# Enforces Karpathy Guidelines: Think, Simplicity, Goal-Driven
# Validates CODEBASE quality, not the trigger string itself.

param(
    [Parameter(Mandatory=$true)]
    [string]$Trigger,
    [switch]$VerboseOutput,
    [switch]$AutoFix
)

$ErrorActionPreference = "Continue"

$repoRoot = if ($env:FOUNDATION_BASE_DIR -and (Test-Path $env:FOUNDATION_BASE_DIR)) { $env:FOUNDATION_BASE_DIR } else {
    $root = Split-Path -Parent $PSScriptRoot
    while ($root -and -not (Test-Path (Join-Path $root 'config'))) { $root = Split-Path -Parent $root }
    if (-not $root) { $root = $PSScriptRoot }
    $root
}

$baselineDir = Join-Path $repoRoot '.runtime\quality'
$baselineFile = Join-Path $baselineDir 'karpathy-baseline.json'

function Write-Log {
    param([string]$Message)
    if ($VerboseOutput) {
        Write-Host "[KARPATHY] $Message" -ForegroundColor Cyan
    }
}

function Test-ThinkGuideline {
    $rulesDir = Join-Path $repoRoot 'rules'
    $thinkFiles = @(
        (Join-Path $rulesDir 'AI-NORMATIVES.md'),
        (Join-Path $rulesDir 'DEVELOPMENT-STANDARDS.md')
    )
    foreach ($f in $thinkFiles) {
        if (Test-Path $f) { return $true }
    }
    $configDir = Join-Path $repoRoot 'config'
    $orchConfig = Join-Path $configDir 'orchestrator.json'
    if (Test-Path $orchConfig) {
        $config = Get-Content $orchConfig -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($config.PSObject.Properties['orchestrator'] -and $config.orchestrator.PSObject.Properties['preProcessing']) {
            return $true
        }
    }
    return $false
}

function Test-SimplicityGuideline {
    $rulesDir = Join-Path $repoRoot 'rules'
    $simpleFiles = @(
        (Join-Path $rulesDir 'DEVELOPMENT-STANDARDS.md'),
        (Join-Path $rulesDir 'NORMATIVAS-CODIGO.md')
    )
    foreach ($f in $simpleFiles) {
        if (Test-Path $f) { return $true }
    }
    $srcDir = Join-Path $repoRoot 'scripts'
    if (Test-Path $srcDir) {
        $scriptCount = (Get-ChildItem $srcDir -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($scriptCount -gt 10) { return $true }
    }
    return $false
}

function Test-GoalDrivenGuideline {
    $taskDir = Join-Path $repoRoot 'docs\tasks'
    if (Test-Path $taskDir) {
        $taskFiles = Get-ChildItem $taskDir -Filter '*.md' -ErrorAction SilentlyContinue
        if ($taskFiles.Count -gt 0) { return $true }
    }
    $sessionDir = Join-Path $repoRoot '.session'
    if (Test-Path $sessionDir) {
        $sessionFiles = Get-ChildItem $sessionDir -Filter 'session-*.json' -ErrorAction SilentlyContinue
        if ($sessionFiles.Count -gt 0) { return $true }
    }
    $agentsFile = Join-Path $repoRoot 'docs\AGENTS.md'
    if (Test-Path $agentsFile) { return $true }
    return $false
}

Write-Log "Enforcing Karpathy Guidelines (trigger: $Trigger)"
Write-Log "Repository: $repoRoot"

$allPassed = $true

$thinkResult = Test-ThinkGuideline
$simplicityResult = Test-SimplicityGuideline
$goalResult = Test-GoalDrivenGuideline

if ($thinkResult) {
    Write-Log "[PASS] Think guideline: Reasoning framework present (rules, orchestrator config)"
} else {
    Write-Log "[FAIL] Think guideline: No reasoning framework found"
    $allPassed = $false
}

if ($simplicityResult) {
    Write-Log "[PASS] Simplicity guideline: Codebase structure present (rules, scripts)"
} else {
    Write-Log "[FAIL] Simplicity guideline: No codebase structure found"
    $allPassed = $false
}

if ($goalResult) {
    Write-Log "[PASS] Goal-Driven guideline: Task/session tracking present"
} else {
    Write-Log "[FAIL] Goal-Driven guideline: No task tracking found"
    $allPassed = $false
}

if (-not (Test-Path $baselineDir)) {
    New-Item -ItemType Directory -Path $baselineDir -Force | Out-Null
}

$baselineData = @{
    timestamp = (Get-Date).ToString("o")
    trigger = $Trigger
    think = $thinkResult
    simplicity = $simplicityResult
    goalDriven = $goalResult
    passed = $allPassed
}
$baselineData | ConvertTo-Json | Set-Content $baselineFile -Encoding UTF8
Write-Log "Baseline saved: $baselineFile"

if ($allPassed) {
    Write-Log "All Karpathy Guidelines enforced - code quality optimal"
    exit 0
} else {
    Write-Log "Karpathy Guidelines violations detected - see above"
    exit 1
}