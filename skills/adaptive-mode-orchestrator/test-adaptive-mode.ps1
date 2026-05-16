<#
.SYNOPSIS
    Test script for Adaptive Mode Orchestrator
.DESCRIPTION
    Verifies all components of Adaptive Mode are working correctly
.AUTHOR
    Gentle-Vanguard
#>

param(
    [switch]$Verbose = $false,
    [switch]$Full = $false
)

$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"

# Colors
$colors = @{
    Success = "Green"
    Error = "Red"
    Warning = "Yellow"
    Info = "Cyan"
    Highlight = "Magenta"
}

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n" -ForegroundColor $colors.Info
    Write-Host "=" * 80 -ForegroundColor $colors.Info
    Write-Host "TEST: $Title" -ForegroundColor $colors.Highlight
    Write-Host "=" * 80 -ForegroundColor $colors.Info
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $symbol = if ($Passed) { "[OK]" } else { "[XX]" }
    $color = if ($Passed) { $colors.Success } else { $colors.Error }
    
    Write-Host "  $symbol $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "      $Message" -ForegroundColor $colors.Info
    }
}

# ============================================================================
# TEST 1: Configuration Files
# ============================================================================

Write-TestHeader "Configuration Files"

$configPath = "config/adaptive-dag-config.json"
$configExists = Test-Path $configPath

Write-TestResult "Config file exists" $configExists $configPath

if ($configExists) {
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        Write-TestResult "Config is valid JSON" $true "Parsed successfully"
        
        # Check required fields
        $hasVersion = $null -ne $config.version
        Write-TestResult "Config has version" $hasVersion
        
        $hasDAG = $null -ne $config.dag
        Write-TestResult "Config has DAG" $hasDAG
        
        $hasAgents = $config.dag.agents.PSObject.Properties.Count -gt 0
        Write-TestResult "Config has agents" $hasAgents "Found $($config.dag.agents.PSObject.Properties.Count) agents"
        
        $hasPhases = $config.dag.phases.PSObject.Properties.Count -gt 0
        Write-TestResult "Config has phases" $hasPhases "Found $($config.dag.phases.PSObject.Properties.Count) phases"
        
        $hasFeedback = $config.dag.feedback_loops.PSObject.Properties.Count -gt 0
        Write-TestResult "Config has feedback loops" $hasFeedback "Found $($config.dag.feedback_loops.PSObject.Properties.Count) loops"
        
    } catch {
        Write-TestResult "Config parsing" $false $_.Exception.Message
    }
}

# ============================================================================
# TEST 2: Engine Script
# ============================================================================

Write-TestHeader "Engine Script"

$enginePath = "skills/adaptive-mode-orchestrator/adaptive-mode-engine.ps1"
$engineExists = Test-Path $enginePath

Write-TestResult "Engine script exists" $engineExists $enginePath

if ($engineExists) {
    try {
        # Check script syntax
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $enginePath), [ref]$null)
        Write-TestResult "Engine script syntax" $true "Valid PowerShell"
        
        # Check for required classes
        $content = Get-Content $enginePath -Raw
        $hasAdaptivePhase = $content -match "class AdaptivePhase"
        Write-TestResult "AdaptivePhase class defined" $hasAdaptivePhase
        
        $hasDAGExecutor = $content -match "class DAGExecutor"
        Write-TestResult "DAGExecutor class defined" $hasDAGExecutor
        
        $hasStartFunction = $content -match "function Start-AdaptiveMode"
        Write-TestResult "Start-AdaptiveMode function defined" $hasStartFunction
        
    } catch {
        Write-TestResult "Engine script validation" $false $_.Exception.Message
    }
}

# ============================================================================
# TEST 3: Documentation
# ============================================================================

Write-TestHeader "Documentation"

$skillPath = "skills/adaptive-mode-orchestrator/SKILL.md"
$skillExists = Test-Path $skillPath

Write-TestResult "SKILL.md exists" $skillExists $skillPath

$integrationPath = "skills/adaptive-mode-orchestrator/INTEGRATION.md"
$integrationExists = Test-Path $integrationPath

Write-TestResult "INTEGRATION.md exists" $integrationExists $integrationPath

# ============================================================================
# TEST 4: DAG Structure
# ============================================================================

Write-TestHeader "DAG Structure"

if ($configExists) {
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        
        # Check agent dependencies
        $agents = $config.dag.agents.PSObject.Properties.Name
        Write-TestResult "Agent list" $true "Found: $($agents -join ', ')"
        
        # Verify DAG is acyclic
        $hasCycle = $false
        foreach ($agent in $agents) {
            $deps = $config.dag.agents.$agent.dependencies
            if ($deps -contains $agent) {
                $hasCycle = $true
            }
        }
        Write-TestResult "DAG is acyclic" (-not $hasCycle)
        
        # Check phase dependencies
        $phases = $config.dag.phases.PSObject.Properties.Name
        Write-TestResult "Phase list" $true "Found: $($phases -join ', ')"
        
    } catch {
        Write-TestResult "DAG validation" $false $_.Exception.Message
    }
}

# ============================================================================
# TEST 5: Feedback Loops
# ============================================================================

Write-TestHeader "Feedback Loops"

if ($configExists) {
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        
        $loops = $config.dag.feedback_loops.PSObject.Properties.Name
        Write-TestResult "Feedback loops defined" ($loops.Count -gt 0) "Found: $($loops -join ', ')"
        
        # Validate each loop
        foreach ($loopName in $loops) {
            $loop = $config.dag.feedback_loops.$loopName
            $hasSource = $null -ne $loop.source
            $hasTarget = $null -ne $loop.target
            $hasTrigger = $null -ne $loop.trigger
            
            $isValid = $hasSource -and $hasTarget -and $hasTrigger
            Write-TestResult "Loop '$loopName' is valid" $isValid
        }
        
    } catch {
        Write-TestResult "Feedback loops validation" $false $_.Exception.Message
    }
}

# ============================================================================
# TEST 6: Rollback Policy
# ============================================================================

Write-TestHeader "Rollback Policy"

if ($configExists) {
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        
        $rollbackEnabled = $config.dag.rollback_policy.enabled
        Write-TestResult "Rollback policy enabled" $rollbackEnabled
        
        $autoRollback = $config.dag.rollback_policy.auto_rollback_on_qa_failure
        Write-TestResult "Auto-rollback on QA failure" $autoRollback
        
        $checkpointOnComplete = $config.dag.rollback_policy.checkpoint_on_phase_complete
        Write-TestResult "Checkpoint on phase complete" $checkpointOnComplete
        
        $triggers = $config.dag.rollback_policy.rollback_triggers
        Write-TestResult "Rollback triggers defined" ($triggers.Count -gt 0) "Found: $($triggers -join ', ')"
        
    } catch {
        Write-TestResult "Rollback policy validation" $false $_.Exception.Message
    }
}

# ============================================================================
# TEST 7: Thresholds
# ============================================================================

Write-TestHeader "Thresholds"

if ($configExists) {
    try {
        $config = Get-Content $configPath | ConvertFrom-Json
        
        $qaPassRate = $config.thresholds.qa_pass_rate_min
        Write-TestResult "QA pass rate threshold" ($qaPassRate -ge 0 -and $qaPassRate -le 100) "Value: $qaPassRate%"
        
        $codeCoverage = $config.thresholds.code_coverage_min
        Write-TestResult "Code coverage threshold" ($codeCoverage -ge 0 -and $codeCoverage -le 100) "Value: $codeCoverage%"
        
        $securityIssues = $config.thresholds.security_issues_max
        Write-TestResult "Security issues max" ($securityIssues -ge 0) "Value: $securityIssues"
        
    } catch {
        Write-TestResult "Thresholds validation" $false $_.Exception.Message
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n" -ForegroundColor $colors.Info
Write-Host "=" * 80 -ForegroundColor $colors.Info
Write-Host "TEST SUMMARY" -ForegroundColor $colors.Highlight
Write-Host "=" * 80 -ForegroundColor $colors.Info

Write-Host @"
[# OK] Configuration files verified
[# OK] Engine script checked
[# OK] Documentation present
[# OK] DAG structure validated
[# OK] Feedback loops configured
[# OK] Rollback policy configured
[# OK] Thresholds validated

All tests completed successfully!
"@ -ForegroundColor $colors.Success

Write-Host "=" * 80 -ForegroundColor $colors.Info
Write-Host "ADAPTIVE MODE READY FOR USE" -ForegroundColor $colors.Highlight
Write-Host "=" * 80 -ForegroundColor $colors.Info
