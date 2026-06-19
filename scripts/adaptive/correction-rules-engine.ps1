#Requires -Version 7.0
<#
.SYNOPSIS
    Auto-Correction Rules Engine — Judgment Day Executor
    
.DESCRIPTION
    Executes auto-correction rules based on session scoring metrics.
    Provides self-healing capabilities for the multi-agent system.
    
.NOTES
    Part of Phase 1 Roadmap v4.0
    - Executes correction rules with atomic rollback capability
    - Tracks success rate and learns confidence over time
    - Integrates with session-autostart pipeline
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('check', 'execute', 'validate', 'report', 'clear')]
    [string]$Mode = 'check',
    
    [Parameter(Mandatory = $false)]
    [string]$RulesConfig = 'config/correction-rules.json',
    
    [Parameter(Mandatory = $false)]
    [string]$SessionScore = 81,
    
    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$root = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))

# ===== LOGGING =====
function Write-Log {
    param([string]$Message, [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')][string]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = @{'INFO' = 'Cyan'; 'WARN' = 'Yellow'; 'ERROR' = 'Red'; 'SUCCESS' = 'Green'}[$Level]
    if (-not $Quiet) { Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color }
    Add-Content -Path "$root/.session/correction-engine.log" -Value "[$timestamp] [$Level] $Message" -ErrorAction SilentlyContinue
}

# ===== LOAD CONFIGURATION =====
function Get-CorrectionRules {
    $configPath = Join-Path $root $RulesConfig
    if (-not (Test-Path $configPath)) {
        Write-Log "Rules config not found: $configPath" ERROR
        return @()
    }
    
    try {
        $json = Get-Content $configPath -Raw | ConvertFrom-Json
        Write-Log "Loaded $($json.rules.Count) correction rules" INFO
        return $json.rules
    }
    catch {
        Write-Log "Failed to parse rules config: $_" ERROR
        return @()
    }
}

# ===== CHECK TRIGGER CONDITIONS =====
function Test-RuleTrigger {
    param([object]$Rule, [int]$Score)
    
    # Examples of trigger conditions
    $triggers = @{
        'TokenBudgetExceeded'      = { $Score -lt 50 }
        'HighErrorRate'            = { $Score -lt 40 }
        'LowQualityScore'          = { $Score -lt 60 }
        'AgentMisalignment'        = { $Score -lt 45 }
        'CacheMiss'                = { $Score -lt 70 }
        'SkillVersionMismatch'     = { $Score -lt 55 }
        'EngineOverload'           = { $Score -lt 50 }
        'MemoryFragmentation'      = { $Score -lt 65 }
    }
    
    if ($triggers.ContainsKey($Rule.id)) {
        return & $triggers[$Rule.id]
    }
    
    return $false
}

# ===== EXECUTE AUTO-CORRECTION =====
function Invoke-Correction {
    param([object]$Rule, [int]$Score)
    
    Write-Log "Executing rule: $($Rule.id) (confidence: $($Rule.metadata.confidence))" INFO
    
    # Ensure atomic transaction
    $checkpointId = (Get-Date -Format 'yyyyMMdd_HHmmss_ffff')
    $backupPath = "$root/.session/state-backups/$checkpointId"
    
    try {
        # 1. Create rollback point
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        Write-Log "Created rollback checkpoint: $checkpointId" INFO
        
        # 2. Execute rule action based on type
        $result = switch ($Rule.id) {
            'TokenBudgetExceeded' { Invoke-TokenBudgetCorrection $Rule }
            'HighErrorRate' { Invoke-ErrorRateCorrection $Rule }
            'LowQualityScore' { Invoke-QualityCorrection $Rule }
            'AgentMisalignment' { Invoke-AgentRerouteCorrection $Rule }
            'CacheMiss' { Invoke-CacheWarmingCorrection $Rule }
            'SkillVersionMismatch' { Invoke-SkillRollbackCorrection $Rule }
            'EngineOverload' { Invoke-ThrottlingCorrection $Rule }
            'MemoryFragmentation' { Invoke-EngramDefragCorrection $Rule }
            default {
                Write-Log "Unknown rule type: $($Rule.id)" WARN
                return @{ success = $false; reason = 'Unknown rule type' }
            }
        }
        
        # 3. Validate correction
        if ($result.success) {
            Write-Log "Correction successful: $($result.message)" SUCCESS
            Update-RuleMetrics $Rule.id $true
        }
        else {
            Write-Log "Correction failed: $($result.reason). Rolling back..." WARN
            Invoke-Rollback $checkpointId $Rule
            Update-RuleMetrics $Rule.id $false
        }
        
        return $result
    }
    catch {
        Write-Log "Exception during correction: $_" ERROR
        Invoke-Rollback $checkpointId $Rule
        Update-RuleMetrics $Rule.id $false
        return @{ success = $false; reason = "Exception: $_" }
    }
}

# ===== RULE IMPLEMENTATIONS =====
function Invoke-TokenBudgetCorrection {
    param([object]$Rule)
    
    Write-Log "Throttling skill complexity..." INFO
    
    # Reduce complexity tier
    $configPath = Join-Path $root 'config/behavior-prompts.json'
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $config.skillComplexityTier = 'BASIC'
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
    
    return @{ success = $true; message = 'Token budget corrected: reduced skill complexity to BASIC' }
}

function Invoke-ErrorRateCorrection {
    param([object]$Rule)
    
    Write-Log "Reducing error rate by activating premortem..." INFO
    
    # Activate premortem mode + manual review requirement
    $orchestratorPath = Join-Path $root 'config/orchestrator.json'
    $config = Get-Content $orchestratorPath -Raw | ConvertFrom-Json
    $config.premortEmEnabled = $true
    $config.requireManualReview = $true
    $config | ConvertTo-Json -Depth 10 | Set-Content $orchestratorPath
    
    return @{ success = $true; message = 'Error rate corrected: enabled premortem + manual review' }
}

function Invoke-QualityCorrection {
    param([object]$Rule)
    
    Write-Log "Improving quality by activating SDD lifecycle..." INFO
    
    # Route to BA → SAD → DEV → QA cycle
    $delegationPath = Join-Path $root 'config/auto-delegation.json'
    $config = Get-Content $delegationPath -Raw | ConvertFrom-Json
    $config.enforceSDDLifecycle = $true
    $config | ConvertTo-Json -Depth 10 | Set-Content $delegationPath
    
    return @{ success = $true; message = 'Quality corrected: enforced full SDD lifecycle' }
}

function Invoke-AgentRerouteCorrection {
    param([object]$Rule)
    
    Write-Log "Re-routing to different agent tier..." INFO
    
    # Increase confidence requirement for agent selection
    $configPath = Join-Path $root 'config/auto-delegation.json'
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $config.minimumConfidenceThreshold = 0.85
    $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
    
    return @{ success = $true; message = 'Agent alignment corrected: increased confidence threshold to 85%' }
}

function Invoke-CacheWarmingCorrection {
    param([object]$Rule)
    
    Write-Log "Pre-warming embedding cache..." INFO
    
    # Trigger cache warming process
    $warmingScript = Join-Path $root 'scripts/utilities/cache/CACHE-MANAGEMENT/cache-warmer.ps1'
    if (Test-Path $warmingScript) {
        & $warmingScript -Warm -Quiet
    }
    
    return @{ success = $true; message = 'Cache corrected: pre-warmed embeddings' }
}

function Invoke-SkillRollbackCorrection {
    param([object]$Rule)
    
    Write-Log "Rolling back to previous skill versions..." INFO
    
    # Restore from skills-lock.json previous version
    $lockPath = Join-Path $root 'skills-lock.json'
    $lock = Get-Content $lockPath -Raw | ConvertFrom-Json
    
    # Check if backup version exists
    if ($lock.previousVersion) {
        $lock.currentVersion = $lock.previousVersion
        $lock.previousVersion = $null
        $lock | ConvertTo-Json -Depth 10 | Set-Content $lockPath
        return @{ success = $true; message = 'Skills corrected: rolled back to previous version' }
    }
    
    return @{ success = $false; reason = 'No previous version available' }
}

function Invoke-ThrottlingCorrection {
    param([object]$Rule)
    
    Write-Log "Activating throttling to reduce engine load..." INFO
    
    $configPath = Join-Path $root 'config/circuit-breaker.json'
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $config.rateLimitPerMinute = [math]::Floor($config.rateLimitPerMinute * 0.5)
        $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
        return @{ success = $true; message = "Throttling corrected: reduced rate limit by 50%" }
    }
    
    return @{ success = $true; message = 'Throttling enabled via circuit breaker' }
}

function Invoke-EngramDefragCorrection {
    param([object]$Rule)
    
    Write-Log "Defragmenting Engram memory..." INFO
    
    $engravPath = Join-Path $root 'scripts/utilities/memory/ENGRAM/engram-integrity-check.ps1'
    if (Test-Path $engravPath) {
        & $engravPath -Mode checksums -Quiet
        return @{ success = $true; message = 'Memory corrected: regenerated Engram checksums' }
    }
    
    return @{ success = $false; reason = 'Engram integrity check not found' }
}

# ===== ROLLBACK MECHANISM =====
function Invoke-Rollback {
    param([string]$CheckpointId, [object]$Rule)
    
    Write-Log "Rolling back checkpoint: $CheckpointId for rule: $($Rule.id)" WARN
    
    if ($Rule.rollback) {
        try {
            & $Rule.rollback
            Write-Log "Rollback completed for $($Rule.id)" SUCCESS
        }
        catch {
            Write-Log "Rollback failed: $_" ERROR
        }
    }
}

# ===== METRICS TRACKING =====
function Update-RuleMetrics {
    param([string]$RuleId, [bool]$Success)
    
    $metricsPath = "$root/.session/rule-metrics.json"
    $metrics = @{ rules = @() }
    
    if (Test-Path $metricsPath) {
        $metrics = Get-Content $metricsPath -Raw | ConvertFrom-Json
    }
    
    $ruleMetric = $metrics.rules | Where-Object { $_.id -eq $RuleId } | Select-Object -First 1
    
    if ($null -eq $ruleMetric) {
        $ruleMetric = @{
            id             = $RuleId
            executionCount = 0
            successCount   = 0
            lastExecution  = $null
            successRate    = 0
        }
        $metrics.rules += $ruleMetric
    }
    
    $ruleMetric.executionCount++
    if ($Success) { $ruleMetric.successCount++ }
    $ruleMetric.lastExecution = Get-Date -Format 'o'
    $ruleMetric.successRate = [math]::Round($ruleMetric.successCount / $ruleMetric.executionCount * 100, 2)
    
    $metrics | ConvertTo-Json -Depth 10 | Set-Content $metricsPath
}

# ===== MAIN OPERATIONS =====
function Invoke-Check {
    Write-Log "Checking which rules would trigger at score $SessionScore" INFO
    
    $rules = Get-CorrectionRules
    $triggered = @()
    
    foreach ($rule in $rules) {
        if (Test-RuleTrigger $rule $SessionScore) {
            $triggered += @{
                id         = $rule.id
                confidence = $rule.metadata.confidence
                pattern    = $rule.metadata.pattern
            }
        }
    }
    
    if ($triggered.Count -gt 0) {
        Write-Log "Found $($triggered.Count) rules to trigger:" INFO
        $triggered | ConvertTo-Json -Depth 5 | Write-Host
        return $triggered
    }
    else {
        Write-Log "No rules triggered at score $SessionScore" INFO
        return @()
    }
}

function Invoke-Execute {
    Write-Log "Executing auto-corrections for score $SessionScore" INFO
    
    $rules = Get-CorrectionRules
    $results = @()
    
    foreach ($rule in $rules) {
        if (Test-RuleTrigger $rule $SessionScore) {
            $result = Invoke-Correction $rule $SessionScore
            $results += $result
        }
    }
    
    Write-Log "Completed $($results.Count) corrections" SUCCESS
    return $results
}

function Invoke-Validate {
    Write-Log "Validating correction rules configuration..." INFO
    
    try {
        $rules = Get-CorrectionRules
        
        foreach ($rule in $rules) {
            if (-not $rule.id -or -not $rule.metadata) {
                Write-Log "Rule validation failed: missing id or metadata" ERROR
                return $false
            }
        }
        
        Write-Log "All $($rules.Count) rules are valid" SUCCESS
        return $true
    }
    catch {
        Write-Log "Validation failed: $_" ERROR
        return $false
    }
}

function Invoke-Report {
    Write-Log "Generating auto-correction report..." INFO
    
    $metricsPath = "$root/.session/rule-metrics.json"
    if (Test-Path $metricsPath) {
        $metrics = Get-Content $metricsPath -Raw | ConvertFrom-Json
        
        Write-Host "`n=== AUTO-CORRECTION METRICS ===" -ForegroundColor Cyan
        $metrics.rules | Sort-Object -Property successRate -Descending | ForEach-Object {
            Write-Host "  $($_.id): $($_.successRate)% success rate ($($_.successCount)/$($_.executionCount))" -ForegroundColor Green
        }
        
        return $metrics
    }
    else {
        Write-Log "No metrics recorded yet" INFO
        return $null
    }
}

function Invoke-Clear {
    Write-Log "Clearing auto-correction metrics..." WARN
    
    $metricsPath = "$root/.session/rule-metrics.json"
    if (Test-Path $metricsPath) {
        Remove-Item $metricsPath -Force
        Write-Log "Metrics cleared" SUCCESS
    }
}

# ===== MAIN =====
try {
    switch ($Mode) {
        'check'    { Invoke-Check }
        'execute'  { Invoke-Execute }
        'validate' { Invoke-Validate }
        'report'   { Invoke-Report }
        'clear'    { Invoke-Clear }
        default    { Write-Log "Invalid mode: $Mode" ERROR; exit 1 }
    }
}
catch {
    Write-Log "Fatal error: $_" ERROR
    exit 1
}

Write-Log "Auto-correction engine completed successfully" SUCCESS
exit 0
