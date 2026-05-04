# auto-delegate-orchestrator.ps1
# Nivel 4 (AI-Native) - Orchestrator with Resilience, Dependencies, Continuity, Metrics
# Version: 2.0.0 - Clean rewrite with full integration

param(
    [string]$TaskDescription,
    [string]$AgentType,
    [string]$Behavior = "balanced",
    [string]$SessionId = "manual-save-workspace_local",
    [string]$Project = "workspace_local",
    [int]$TimeoutSeconds = 300,
    [switch]$UseTieredRouting,
    [switch]$EnableConcurrency,
    [switch]$EnableCircuitBreaker,
    [switch]$EnableMetrics,
    [switch]$EnableContinuity,
    [switch]$DryRun,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

#region Configuration Loading
$ConfigPath = Join-Path $PSScriptRoot "..\..\config"
$SubagentMapping = Get-Content (Join-Path $ConfigPath "subagent-mapping.json") | ConvertFrom-Json
$AutoDelegation = Get-Content (Join-Path $ConfigPath "auto-delegation.json") | ConvertFrom-Json
$SkillDeps = Get-Content (Join-Path $ConfigPath "skill-dependencies.json") | ConvertFrom-Json
$MetricsConfig = Get-Content (Join-Path $ConfigPath "metrics-config.json") | ConvertFrom-Json
$BehaviorPrompts = Get-Content (Join-Path $ConfigPath "behavior-prompts.json") | ConvertFrom-Json
$OrchestratorConfig = Get-Content (Join-Path $ConfigPath "orchestrator.json") | ConvertFrom-Json
$AutoDelegationWrapper = Join-Path $PSScriptRoot "..\utilities\auto-delegation-wrapper.ps1"
#endregion

#region Global State
$script:OrchestratorState = @{
    ActiveDelegations = @{}
    AgentSemaphores = @{}
    CircuitBreakers = @{}
    Metrics = @{
        TotalDelegations = 0
        SuccessCount = 0
        FailureCount = 0
        StartTime = Get-Date
    }
    DependencyQueue = @{}
}
$script:MetricsData = @{
    delegations = @{}
    agents = @{}
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}
#endregion

#region Concurrency Control
function Initialize-Semaphores {
    foreach ($limit in $AutoDelegation.concurrencyLimits.PSObject.Properties) {
        $script:OrchestratorState.AgentSemaphores[$limit.Name] = @{
            Max = $limit.Value
            Current = 0
            Queue = [System.Collections.Queue]::new()
        }
    }
}

function Wait-ForAgentSlot {
    param([string]$AgentType)
    
    $limit = $AutoDelegation.concurrencyLimits.$AgentType
    if (-not $limit) { $limit = $AutoDelegation.concurrencyLimits.default }
    
    $sem = $script:OrchestratorState.AgentSemaphores[$AgentType]
    if (-not $sem) {
        $sem = @{ Max = $limit; Current = 0; Queue = [System.Collections.Queue]::new() }
        $script:OrchestratorState.AgentSemaphores[$AgentType] = $sem
    }
    
    while ($sem.Current -ge $sem.Max) {
        if ($Verbose) { Write-Host "[CONCURRENCY] Waiting for slot: $AgentType ($($sem.Current)/$($sem.Max))" }
        Start-Sleep -Milliseconds 500
    }
    $sem.Current++
    if ($Verbose) { Write-Host "[CONCURRENCY] Acquired slot: $AgentType ($($sem.Current)/$($sem.Max))" }
}

function Release-AgentSlot {
    param([string]$AgentType)
    
    $sem = $script:OrchestratorState.AgentSemaphores[$AgentType]
    if ($sem -and $sem.Current -gt 0) {
        $sem.Current--
        if ($Verbose) { Write-Host "[CONCURRENCY] Released slot: $AgentType ($($sem.Current)/$($sem.Max))" }
    }
}
#endregion

#region Circuit Breaker
function Initialize-CircuitBreakers {
    $agents = @("BA", "SAD", "DEV", "QA", "OPS", "GOV", "DOC", "SCRIPT-GOV", "REPORT", "GITFLOW-*")
    foreach ($agent in $agents) {
        $script:OrchestratorState.CircuitBreakers[$agent] = @{
            State = "CLOSED"
            FailureCount = 0
            LastFailureTime = $null
            Threshold = 3
            TimeoutSeconds = 60
        }
    }
}

function Get-CircuitState {
    param([string]$AgentType)
    
    $cb = $script:OrchestratorState.CircuitBreakers[$AgentType]
    if (-not $cb) { return "CLOSED" }
    
    if ($cb.State -eq "OPEN") {
        $timeSinceOpen = (Get-Date) - $cb.LastFailureTime
        if ($timeSinceOpen.TotalSeconds -gt $cb.TimeoutSeconds) {
            $cb.State = "HALF_OPEN"
            if ($Verbose) { Write-Host "[CIRCUIT] Circuit HALF_OPEN: $AgentType" }
        }
    }
    return $cb.State
}

function Record-CircuitSuccess {
    param([string]$AgentType)
    
    $cb = $script:OrchestratorState.CircuitBreakers[$AgentType]
    if ($cb) {
        $cb.State = "CLOSED"
        $cb.FailureCount = 0
    }
}

function Record-CircuitFailure {
    param([string]$AgentType)
    
    $cb = $script:OrchestratorState.CircuitBreakers[$AgentType]
    if (-not $cb) { return }
    
    $cb.FailureCount++
    $cb.LastFailureTime = Get-Date
    
    if ($cb.FailureCount -ge $cb.Threshold) {
        $cb.State = "OPEN"
        if ($Verbose) { Write-Host "[CIRCUIT] Circuit OPEN: $AgentType (failures: $($cb.FailureCount))" }
    }
}
#endregion

#region Tiered Routing
function Find-AgentByTieredRouting {
    param([string]$TaskDescription)
    
    if (-not $UseTieredRouting -and -not $AutoDelegation.features.tieredRouting) {
        return $null
    }
    
    $bindings = $AutoDelegation.routingBindings | Sort-Object { $_.tier }
    
    foreach ($binding in $bindings) {
        $pattern = $binding.value
        if ($TaskDescription -match $pattern) {
            if ($Verbose) { Write-Host "[ROUTING] Tier $($binding.tier) match: $($binding.agent) for pattern: $pattern" }
            return $binding.agent
        }
    }
    
    return $null
}

function Find-AgentByKeyword {
    param([string]$TaskDescription)
    
    $bestMatch = $null
    $bestScore = 0
    
    foreach ($kv in $AutoDelegation.keywordMappings.PSObject.Properties) {
        $keywords = $kv.Value
        $score = 0
        foreach ($keyword in $keywords) {
            if ($TaskDescription -match [regex]::Escape($keyword)) {
                $score++
            }
        }
        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestMatch = $kv.Name
        }
    }
    
    if ($bestMatch -and $Verbose) {
        Write-Host "[ROUTING] Keyword match: $bestMatch (score: $bestScore)"
    }
    
    return $bestMatch
}
#endregion

#region Skill Dependencies
function Test-SkillDependencies {
    param([string]$SkillName)
    
    if (-not $SkillDeps.dependencies.$SkillName) {
        return $true
    }
    
    $deps = $SkillDeps.dependencies.$SkillName
    $requires = $deps.requires
    
    foreach ($dep in $requires) {
        $orderDep = $SkillDeps.ordering_rules.$dep
        $orderCurrent = $SkillDeps.ordering_rules.$SkillName
        
        if ($orderDep -and $orderCurrent -and $orderDep -ge $orderCurrent) {
            if ($deps.blocking) {
                if ($Verbose) { Write-Host "[DEPS] BLOCKING: $SkillName requires $dep to run first" }
                return $false
            }
        }
    }
    
    return $true
}

function Get-ExecutionOrder {
    param([array]$Skills)
    
    return $Skills | ForEach-Object {
        @{ Skill = $_; Order = $SkillDeps.ordering_rules.$_ }
    } | Where-Object { $_.Order } | Sort-Object Order | ForEach-Object { $_.Skill }
}
#endregion

#region Metrics
function Initialize-Metrics {
    foreach ($agent in $MetricsConfig.per_agent_metrics.PSObject.Properties) {
        $script:MetricsData.agents[$agent.Name] = @{
            total_delegations = 0
            successes = 0
            failures = 0
            avg_time_seconds = 0
            last_success = $null
            last_failure = $null
        }
    }

    $runtimeState = $MetricsConfig.runtime_state
    if ($runtimeState) {
        $script:OrchestratorState.Metrics.TotalDelegations = [int]$runtimeState.total_delegations
        $script:OrchestratorState.Metrics.SuccessCount = [int]$runtimeState.success_count
        $script:OrchestratorState.Metrics.FailureCount = [int]$runtimeState.failure_count
    }
}

function Record-Metric {
    param(
        [string]$AgentType,
        [string]$Result,  # "success" or "failure"
        [int]$DurationSeconds
    )
    
    if (-not $script:MetricsData.agents[$AgentType]) {
        $script:MetricsData.agents[$AgentType] = @{
            total_delegations = 0
            successes = 0
            failures = 0
            avg_time_seconds = 0
            last_success = $null
            last_failure = $null
        }
    }
    
    $agentMetrics = $script:MetricsData.agents[$AgentType]
    $agentMetrics.total_delegations++
    
    if ($Result -eq "success") {
        $agentMetrics.successes++
        $agentMetrics.last_success = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    } else {
        $agentMetrics.failures++
        $agentMetrics.last_failure = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }
    
    # Update average time
    if ($agentMetrics.total_delegations -gt 0) {
        $totalTime = $agentMetrics.avg_time_seconds * ($agentMetrics.total_delegations - 1) + $DurationSeconds
        $agentMetrics.avg_time_seconds = [math]::Round($totalTime / $agentMetrics.total_delegations, 2)
    }
    
    # Update global metrics
    $script:OrchestratorState.Metrics.TotalDelegations++
    if ($Result -eq "success") {
        $script:OrchestratorState.Metrics.SuccessCount++
    } else {
        $script:OrchestratorState.Metrics.FailureCount++
    }
}

function Write-MetricsSummary {
    $summaryPath = Join-Path $PSScriptRoot "..\..\.session\metrics-report.json"
    $script:MetricsData.timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    
    # Calculate success rates
    $totalDel = 0
    if ($script:OrchestratorState.Metrics.TotalDelegations) {
        $totalDel = [int]$script:OrchestratorState.Metrics.TotalDelegations
    }
    
    $successCount = 0
    if ($script:OrchestratorState.Metrics.SuccessCount) {
        $successCount = [int]$script:OrchestratorState.Metrics.SuccessCount
    }
    
    $startTime = $script:OrchestratorState.Metrics.StartTime
    if (-not $startTime) { 
        $startTime = Get-Date 
    } else {
        # Convert from string if restored from JSON
        try {
            $startTime = [DateTime]::Parse($startTime)
        } catch {
            $startTime = Get-Date
        }
    }
    
    $successRate = 0
    if ($totalDel -gt 0) {
        $successRate = [math]::Round(($successCount * 100.0) / $totalDel, 2)  # 2 decimal places
    }
    
    $uptimeSeconds = ((Get-Date) - $startTime).TotalSeconds
    $uptime = [math]::Round($uptimeSeconds, 2)
    
    $script:MetricsData.summary = @{
        total_delegations = $totalDel
        success_rate = $successRate
        uptime_seconds = $uptime
    }
    
    try {
        $json = $script:MetricsData | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($summaryPath, $json, [System.Text.Encoding]::UTF8)
    } catch {
        if ($Verbose) { Write-Host "[METRICS] Warning: Failed to write metrics: $_" }
    }
    
    if ($Verbose) {
        Write-Host "=== METRICS SUMMARY ==="
        Write-Host "Total Delegations: $($script:MetricsData.summary.total_delegations)"
        Write-Host "Success Rate: $($script:MetricsData.summary.success_rate)%"
        Write-Host "Report saved to: $summaryPath"
    }

    Save-PersistentMetrics -SessionSummary $script:MetricsData.summary
}

function Save-PersistentMetrics {
    param([hashtable]$SessionSummary)

    if (-not $MetricsConfig.reporting.persistence.enabled) {
        return
    }

    try {
        $metricsPath = Join-Path $ConfigPath "metrics-config.json"
        $current = Get-Content $metricsPath -Raw | ConvertFrom-Json

        if (-not $current.runtime_state) {
            $current | Add-Member -NotePropertyName runtime_state -NotePropertyValue @{}
        }

        $durationToAdd = 0
        if ($SessionSummary -and $SessionSummary.uptime_seconds) {
            $durationToAdd = [double]$SessionSummary.uptime_seconds
        }

        $tokenUsage = 0
        foreach ($agentMetric in $script:MetricsData.agents.PSObject.Properties) {
            $tokenUsage += ([int]$agentMetric.Value.total_delegations * 750)
        }

        $current.runtime_state.session_count = [int]$current.runtime_state.session_count + 1
        $current.runtime_state.total_delegations = [int]$current.runtime_state.total_delegations + [int]$script:OrchestratorState.Metrics.TotalDelegations
        $current.runtime_state.success_count = [int]$current.runtime_state.success_count + [int]$script:OrchestratorState.Metrics.SuccessCount
        $current.runtime_state.failure_count = [int]$current.runtime_state.failure_count + [int]$script:OrchestratorState.Metrics.FailureCount
        $current.runtime_state.cumulative_duration_seconds = [double]$current.runtime_state.cumulative_duration_seconds + $durationToAdd
        $current.runtime_state.cumulative_token_usage = [int]$current.runtime_state.cumulative_token_usage + $tokenUsage
        $current.runtime_state.last_updated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

        $totalDelegations = [math]::Max(1, [int]$current.runtime_state.total_delegations)
        $current.metrics.delegation_success_rate.current = [math]::Round(([int]$current.runtime_state.success_count * 100.0) / $totalDelegations, 2)
        $current.metrics.delegation_failure_rate.current = [math]::Round(([int]$current.runtime_state.failure_count * 100.0) / $totalDelegations, 2)
        $current.metrics.average_time_to_completion.current = [math]::Round(([double]$current.runtime_state.cumulative_duration_seconds / $totalDelegations), 2)
        $current.metrics.token_usage_per_session.current = [int]$current.runtime_state.cumulative_token_usage
        $current.metrics.circuit_breaker_trips.current = [int]$current.runtime_state.circuit_breaker_trips
        $current.metrics.skill_dependency_violations.current = [int]$current.runtime_state.skill_dependency_violations

        $json = $current | ConvertTo-Json -Depth 12
        [System.IO.File]::WriteAllText($metricsPath, $json, [System.Text.Encoding]::UTF8)
    }
    catch {
        if ($Verbose) { Write-Host "[METRICS] Warning: Failed to persist metrics: $_" }
    }
}
#endregion

#region Cross-Session Continuity
function Save-OrchestratorState {
    $statePath = Join-Path $PSScriptRoot "..\..\.session\orchestrator-state.json"
    
    $state = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        active_delegations = $script:OrchestratorState.ActiveDelegations
        circuit_breakers = $script:OrchestratorState.CircuitBreakers
        metrics_summary = $script:OrchestratorState.Metrics
    }
    
    try {
        $json = $state | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($statePath, $json, [System.Text.Encoding]::UTF8)
    } catch {
        if ($Verbose) { Write-Host "[CONTINUITY] Warning: Failed to save state: $_" }
    }
    
    if ($Verbose) { Write-Host "[CONTINUITY] State saved to: $statePath" }
}

function Restore-OrchestratorState {
    $statePath = Join-Path $PSScriptRoot "..\..\.session\orchestrator-state.json"
    
    if (Test-Path $statePath) {
        $state = Get-Content $statePath | ConvertFrom-Json
        
        if ($state.active_delegations) {
            $script:OrchestratorState.ActiveDelegations = $state.active_delegations
        }
        if ($state.circuit_breakers) {
            $script:OrchestratorState.CircuitBreakers = $state.circuit_breakers
        }
        if ($state.metrics_summary) {
            $script:OrchestratorState.Metrics = $state.metrics_summary
        }
        
        if ($Verbose) { Write-Host "[CONTINUITY] State restored from: $statePath" }
        return $true
    }
    
    return $false
}
#endregion

#region Delegation Core
function Get-SubagentType {
    param([string]$AgentType)
    
    if ($SubagentMapping.mapping.$AgentType) {
        return $SubagentMapping.mapping.$AgentType.primary_subagent
    }
    
    # Check if it's already a valid subagent type
    if ($SubagentMapping.opencode_subagent_capabilities.$AgentType) {
        return $AgentType
    }
    
    return "general"
}

function Get-BehaviorPrompt {
    param([string]$BehaviorType)
    
    if ($BehaviorPrompts.$BehaviorType) {
        return $BehaviorPrompts.$BehaviorType
    }
    
    return $BehaviorPrompts.balanced
}

function Invoke-Delegation {
    param(
        [string]$TaskDescription,
        [string]$AgentType,
        [string]$SubagentType,
        [hashtable]$BehaviorPrompt,
        [string]$DelegationId
    )
    
    $startTime = Get-Date
    
    try {
        # Build prompt with behavior
        $prompt = @"
$(if ($BehaviorPrompt) { $BehaviorPrompt.system_prompt + "`n" })
Task: $TaskDescription

$(if ($BehaviorPrompt) { "Communication Style: $($BehaviorPrompt.communication_style)`nVibe: $($BehaviorPrompt.vibe)" })
"@
        
        if ($DryRun) {
            Write-Host "[DRY RUN] Would delegate to $SubagentType`: $TaskDescription"
            return @{ success = $true; dry_run = $true; delegation_id = $DelegationId }
        }
        
        if (-not (Test-Path $AutoDelegationWrapper)) {
            throw "Canonical delegation wrapper not found: $AutoDelegationWrapper"
        }

        if ($Verbose) { Write-Host "[DELEGATE] $DelegationId → $SubagentType`: $TaskDescription" }

        $wrapperResult = & $AutoDelegationWrapper -Agent $AgentType -Task $TaskDescription -AsJson | ConvertFrom-Json
        $status = if ($wrapperResult -and $wrapperResult.status) { [string]$wrapperResult.status } else { "unknown" }
        $isSuccess = $status -in @("ready", "partial", "dispatched")
        $tokenEstimate = 0
        if ($wrapperResult -and $wrapperResult.token_estimate) {
            $tokenEstimate = [int][math]::Ceiling([double]$wrapperResult.token_estimate / 4)
        } elseif ($wrapperResult -and $wrapperResult.delegation -and $wrapperResult.delegation.token_estimate) {
            $tokenEstimate = [int][math]::Ceiling([double]$wrapperResult.delegation.token_estimate / 4)
        }

        $result = @{
            success = $isSuccess
            delegation_id = $DelegationId
            agent_type = $AgentType
            subagent_type = $SubagentType
            delegated_via = "auto-delegation-wrapper"
            wrapper_status = $status
            token_estimate = $tokenEstimate
            duration_seconds = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
        }

        if ($wrapperResult) {
            $result.wrapper_result = $wrapperResult
        }
        
        return $result
    }
    catch {
        return @{
            success = $false
            delegation_id = $DelegationId
            error = $_.Exception.Message
            duration_seconds = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
        }
    }
}
#endregion

#region Main Orchestration
function Start-Orchestrator {
    # Initialize all systems
    Initialize-Semaphores
    Initialize-CircuitBreakers
    Initialize-Metrics
    
    if ($EnableContinuity -or $true) {  # Always try to restore
        Restore-OrchestratorState | Out-Null
    }
    
    if ($Verbose) {
        Write-Host "=== ORCHESTRATOR STARTED ==="
        Write-Host "Task: $TaskDescription"
        Write-Host "Agent: $AgentType"
        Write-Host "Behavior: $Behavior"
    }
    
    # Determine agent if not specified
    if (-not $AgentType) {
        $AgentType = Find-AgentByTieredRouting -TaskDescription $TaskDescription
        if (-not $AgentType) {
            $AgentType = Find-AgentByKeyword -TaskDescription $TaskDescription
        }
        if (-not $AgentType) {
            $AgentType = "general"
        }
    }
    
    # Check circuit breaker
    $circuitState = Get-CircuitState -AgentType $AgentType
    if ($circuitState -eq "OPEN") {
        Write-Host "[CIRCUIT] Circuit OPEN for $AgentType - using fallback"
        $AgentType = "general"
    }
    
    # Get subagent type
    $subagentType = Get-SubagentType -AgentType $AgentType
    
    # Get behavior prompt
    $behaviorPrompt = Get-BehaviorPrompt -BehaviorType $Behavior
    
    # Check dependencies
    if (-not (Test-SkillDependencies -SkillName $subagentType)) {
        Write-Host "[DEPS] Dependencies not met for $subagentType - queuing"
        if ($MetricsConfig.runtime_state) {
            $MetricsConfig.runtime_state.skill_dependency_violations = [int]$MetricsConfig.runtime_state.skill_dependency_violations + 1
        }
        $script:OrchestratorState.DependencyQueue[$TaskDescription] = @{
            agent = $AgentType
            subagent = $subagentType
            timestamp = Get-Date
        }
        return @{ status = "queued"; reason = "dependencies" }
    }
    
    # Acquire concurrency slot
    if ($EnableConcurrency -or $true) {
        Wait-ForAgentSlot -AgentType $AgentType
    }
    
    try {
        # Execute delegation
        $delegationId = "del-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(Get-Random -Maximum 9999)"
        
        $result = Invoke-Delegation `
            -TaskDescription $TaskDescription `
            -AgentType $AgentType `
            -SubagentType $subagentType `
            -BehaviorPrompt $behaviorPrompt `
            -DelegationId $delegationId
        
        # Record metrics
        if ($EnableMetrics -or $true) {
            Record-Metric `
                -AgentType $AgentType `
                -Result $(if ($result.success) { "success" } else { "failure" }) `
                -DurationSeconds $result.duration_seconds
        }
        
        # Update circuit breaker
        if ($result.success) {
            Record-CircuitSuccess -AgentType $AgentType
        } else {
            Record-CircuitFailure -AgentType $AgentType
        }
        
        # Save state
        if ($EnableContinuity -or $true) {
            Save-OrchestratorState
        }
        
        return $result
    }
    finally {
        # Release concurrency slot
        if ($EnableConcurrency -or $true) {
            Release-AgentSlot -AgentType $AgentType
        }
    }
}
#endregion

#region Entry Point
if ($TaskDescription) {
    $result = Start-Orchestrator
    
    # Write final metrics
    Write-MetricsSummary
    
    # Output result
    $result | ConvertTo-Json -Depth 10
    
    if ($Verbose) {
        Write-Host "=== ORCHESTRATOR COMPLETED ==="
    }
}
else {
    Write-Host "Usage: .\auto-delegate-orchestrator.ps1 -TaskDescription 'your task' [-AgentType BA|SAD|DEV|QA|OPS|GOV|DOC] [-Behavior balanced|fast|precise|exploratory|creative|strict] [-Verbose] [-DryRun]"
}
#endregion
