<#
.SYNOPSIS
    Auto-Delegation Router - Intelligent task routing to specialized subagents
    
.DESCRIPTION
    Provides keyword-based auto-routing, decision trees, confidence scoring,
    and opt-in control for automatic subagent delegation.
    
.EXAMPLE
    $routing = Route-TaskToAgent -TaskDescription "Implement login feature"
    
.NOTES
    Author: workspace-foundation
    Version: 1.0
#>

param()

# ============================================================================
# CONFIGURATION LOADING
# ============================================================================

function Get-AutoDelegationConfig {
    <#
    .SYNOPSIS
        Load auto-delegation configuration from JSON file
    #>
    param(
        [string]$ConfigPath = "config/auto-delegation.json"
    )
    
    $defaultConfig = @{
        Enabled = $false
        ConfidenceThreshold = 60
        MaxParallelAgents = 3
        FallbackStrategy = "manual"
        LoggingEnabled = $true
        MetricsEnabled = $true
        Features = @{
            KeywordExtraction = $true
            DecisionTree = $true
            ConfidenceScoring = $true
            AutoRetry = $false
            AutoEscalation = $true
        }
        Thresholds = @{
            HighConfidence = 80
            MediumConfidence = 60
            LowConfidence = 40
        }
    }
    
    if (Test-Path $ConfigPath) {
        try {
            $loadedConfig = Get-Content $ConfigPath | ConvertFrom-Json
            return $loadedConfig
        }
        catch {
            Write-Warning "Failed to load config from $ConfigPath, using defaults"
            return $defaultConfig
        }
    }
    
    return $defaultConfig
}

function Set-AutoDelegationConfig {
    <#
    .SYNOPSIS
        Save auto-delegation configuration to JSON file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Config,
        
        [string]$ConfigPath = "config/auto-delegation.json"
    )
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
        return @{
            Status = "Success"
            Message = "Auto-delegation configuration updated"
            ConfigPath = $ConfigPath
        }
    }
    catch {
        return @{
            Status = "Error"
            Message = "Failed to save configuration: $_"
            Error = $_
        }
    }
}

# ============================================================================
# KEYWORD EXTRACTION ENGINE
# ============================================================================

function Extract-TaskKeywords {
    <#
    .SYNOPSIS
        Extract domain-specific keywords from task description
        
    .PARAMETER TaskDescription
        The task description to analyze
        
    .PARAMETER MaxKeywords
        Maximum number of keyword matches to return
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskDescription,
        
        [int]$MaxKeywords = 10
    )
    
    $config = Get-AutoDelegationConfig
    $keywordMap = $config.keywordMappings
    
    $extractedKeywords = @{}
    $taskLower = $TaskDescription.ToLower()
    
    foreach ($agent in $keywordMap.PSObject.Properties.Name) {
        $matchCount = 0
        foreach ($keyword in $keywordMap.$agent) {
            if ($taskLower -match "\b$keyword\b") {
                $matchCount++
            }
        }
        if ($matchCount -gt 0) {
            $extractedKeywords[$agent] = $matchCount
        }
    }
    
    # Sort by match count descending and limit to MaxKeywords
    $sorted = $extractedKeywords.GetEnumerator() | 
        Sort-Object -Property Value -Descending | 
        Select-Object -First $MaxKeywords
    
    $result = @{}
    foreach ($item in $sorted) {
        $result[$item.Name] = $item.Value
    }
    
    return $result
}

# ============================================================================
# DECISION TREE ENGINE
# ============================================================================

function Evaluate-DecisionTree {
    <#
    .SYNOPSIS
        Evaluate decision tree to determine agent routing
        
    .PARAMETER TaskDescription
        The task description
        
    .PARAMETER Keywords
        Extracted keywords hashtable
        
    .PARAMETER Context
        Additional context for decision making
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskDescription,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Keywords,
        
        [hashtable]$Context = @{}
    )
    
    $decisions = @()
    
    # Level 1: Primary domain detection
    if ($Keywords.Count -gt 0) {
        $primaryAgent = ($Keywords.GetEnumerator() | Select-Object -First 1).Name
        $primaryScore = $Keywords[$primaryAgent]
        
        $decisions += @{
            Level = 1
            Agent = $primaryAgent
            Reason = "Primary domain match"
            Score = $primaryScore
        }
        
        # Level 2: Secondary agent detection
        if ($Keywords.Count -gt 1) {
            $secondaryAgent = ($Keywords.GetEnumerator() | Select-Object -Index 1).Name
            $secondaryScore = $Keywords[$secondaryAgent]
            
            if ($secondaryScore -ge ($primaryScore * 0.6)) {
                $decisions += @{
                    Level = 2
                    Agent = $secondaryAgent
                    Reason = "Secondary domain match"
                    Score = $secondaryScore
                }
            }
        }
    }
    
    # Level 3: Context-based adjustments
    if ($Context.RiskLevel -eq "high") {
        $agentsInDecisions = $decisions | Select-Object -ExpandProperty Agent
        if ($agentsInDecisions -notcontains 'QA') {
            $decisions += @{
                Level = 3
                Agent = 'QA'
                Reason = "High-risk context requires QA"
                Score = 5
            }
        }
    }
    
    # Level 4: Dependency-based routing
    if ($TaskDescription -match 'deploy|release|production') {
        $agentsInDecisions = $decisions | Select-Object -ExpandProperty Agent
        if ($agentsInDecisions -notcontains 'OPS') {
            $decisions += @{
                Level = 4
                Agent = 'OPS'
                Reason = "Deployment/release requires OPS"
                Score = 8
            }
        }
    }
    
    return $decisions
}

# ============================================================================
# CONFIDENCE SCORING SYSTEM
# ============================================================================

function Calculate-ConfidenceScore {
    <#
    .SYNOPSIS
        Calculate confidence score for routing decision
        
    .PARAMETER Keywords
        Extracted keywords
        
    .PARAMETER DecisionTree
        Decision tree results
        
    .PARAMETER Context
        Additional context
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Keywords,
        
        [Parameter(Mandatory = $true)]
        [array]$DecisionTree,
        
        [hashtable]$Context = @{}
    )
    
    $baseScore = 0
    $adjustments = @()
    
    # Base score from keyword matching
    $totalKeywordMatches = ($Keywords.Values | Measure-Object -Sum).Sum
    $baseScore = [Math]::Min(100, ($totalKeywordMatches * 15))
    
    # Adjustment: Multiple agents detected
    if ($Keywords.Keys.Count -gt 1) {
        $adjustments += @{
            Factor = "Multi-agent detection"
            Adjustment = 10
        }
        $baseScore += 10
    }
    
    # Adjustment: Clear single agent
    if ($Keywords.Keys.Count -eq 1) {
        $adjustments += @{
            Factor = "Clear single agent"
            Adjustment = 15
        }
        $baseScore += 15
    }
    
    # Adjustment: Context alignment
    if ($Context.HasClearObjective) {
        $adjustments += @{
            Factor = "Clear objective"
            Adjustment = 5
        }
        $baseScore += 5
    }
    
    # Adjustment: Ambiguous keywords
    if ($Keywords.Keys.Count -gt 3) {
        $adjustments += @{
            Factor = "Ambiguous routing"
            Adjustment = -15
        }
        $baseScore -= 15
    }
    
    # Cap at 100
    $finalScore = [Math]::Min(100, [Math]::Max(0, $baseScore))
    
    $confidenceLevel = switch ($finalScore) {
        { $_ -ge 80 } { "High" }
        { $_ -ge 60 } { "Medium" }
        { $_ -ge 40 } { "Low" }
        default { "Very Low" }
    }
    
    return @{
        Score = $finalScore
        BaseScore = $baseScore
        Adjustments = $adjustments
        Confidence = $confidenceLevel
    }
}

# ============================================================================
# ROUTING ENGINE
# ============================================================================

function Route-TaskToAgent {
    <#
    .SYNOPSIS
        Route task to appropriate agent(s) based on analysis
        
    .PARAMETER TaskDescription
        The task description to route
        
    .PARAMETER AutoDelegationEnabled
        Whether auto-delegation is enabled
        
    .PARAMETER Context
        Additional context for routing
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskDescription,
        
        [bool]$AutoDelegationEnabled = $true,
        
        [hashtable]$Context = @{}
    )
    
    $config = Get-AutoDelegationConfig
    
    # Check if auto-delegation is enabled
    if (-not $AutoDelegationEnabled -or -not $config.Enabled) {
        return @{
            Status = "AutoDelegationDisabled"
            Message = "Auto-delegation is disabled. Manual routing required."
            RequiresManualDecision = $true
        }
    }
    
    # Step 1: Extract keywords
    $keywords = Extract-TaskKeywords -TaskDescription $TaskDescription
    
    if ($keywords.Count -eq 0) {
        return @{
            Status = "NoKeywordsFound"
            Message = "Unable to extract domain keywords. Manual routing required."
            RequiresManualDecision = $true
            Suggestion = "Provide more specific task description"
        }
    }
    
    # Step 2: Evaluate decision tree
    $decisionTree = Evaluate-DecisionTree -TaskDescription $TaskDescription -Keywords $keywords -Context $Context
    
    # Step 3: Calculate confidence
    $confidence = Calculate-ConfidenceScore -Keywords $keywords -DecisionTree $decisionTree -Context $Context
    
    # Step 4: Determine routing
    $primaryAgent = $decisionTree | Where-Object { $_.Level -eq 1 } | Select-Object -First 1
    $secondaryAgents = @($decisionTree | Where-Object { $_.Level -gt 1 } | Select-Object -ExpandProperty Agent)
    
    # Step 5: Apply confidence threshold
    $confidenceThreshold = $config.ConfidenceThreshold
    
    if ($confidence.Score -lt $confidenceThreshold) {
        return @{
            Status = "LowConfidence"
            Message = "Confidence score below threshold ($($confidence.Score)%)"
            RequiresManualDecision = $true
            PrimaryAgent = $primaryAgent.Agent
            ConfidenceScore = $confidence.Score
            Suggestion = "Review suggested agents and confirm manually"
        }
    }
    
    # Step 6: Return routing decision
    return @{
        Status = "Success"
        PrimaryAgent = $primaryAgent.Agent
        SecondaryAgents = $secondaryAgents
        ConfidenceScore = $confidence.Score
        ConfidenceLevel = $confidence.Confidence
        Keywords = $keywords
        DecisionTree = $decisionTree
        Adjustments = $confidence.Adjustments
        RequiresManualDecision = $false
    }
}

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

function Enable-AutoDelegation {
    <#
    .SYNOPSIS
        Enable automatic delegation
    #>
    param(
        [string]$ConfigPath = "config/auto-delegation.json"
    )
    
    $config = Get-AutoDelegationConfig -ConfigPath $ConfigPath
    $config.Enabled = $true
    
    Set-AutoDelegationConfig -Config $config -ConfigPath $ConfigPath
    
    return @{
        Status = "Enabled"
        Message = "Auto-delegation is now enabled"
    }
}

function Disable-AutoDelegation {
    <#
    .SYNOPSIS
        Disable automatic delegation
    #>
    param(
        [string]$ConfigPath = "config/auto-delegation.json"
    )
    
    $config = Get-AutoDelegationConfig -ConfigPath $ConfigPath
    $config.Enabled = $false
    
    Set-AutoDelegationConfig -Config $config -ConfigPath $ConfigPath
    
    return @{
        Status = "Disabled"
        Message = "Auto-delegation is now disabled"
    }
}

function Set-ConfidenceThreshold {
    <#
    .SYNOPSIS
        Set confidence threshold for routing
    #>
    param(
        [Parameter(Mandatory = $true)]
        [int]$Threshold,
        
        [string]$ConfigPath = "config/auto-delegation.json"
    )
    
    if ($Threshold -lt 0 -or $Threshold -gt 100) {
        return @{
            Status = "Error"
            Message = "Threshold must be between 0 and 100"
        }
    }
    
    $config = Get-AutoDelegationConfig -ConfigPath $ConfigPath
    $config.ConfidenceThreshold = $Threshold
    
    Set-AutoDelegationConfig -Config $config -ConfigPath $ConfigPath
    
    return @{
        Status = "Success"
        Message = "Confidence threshold updated to $Threshold"
    }
}

# ============================================================================
# METRICS AND ANALYTICS
# ============================================================================

function Get-RoutingMetrics {
    <#
    .SYNOPSIS
        Get routing metrics and analytics
    #>
    param(
        [string]$MetricsPath = "logs/routing-metrics.json"
    )
    
    if (Test-Path $MetricsPath) {
        try {
            return Get-Content $MetricsPath | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to load metrics from $MetricsPath"
        }
    }
    
    return @{
        TotalRoutings = 0
        SuccessfulRoutings = 0
        LowConfidenceRoutings = 0
        ManualOverrides = 0
        AverageConfidenceScore = 0
        AgentDistribution = @{}
    }
}

function Log-RoutingDecision {
    <#
    .SYNOPSIS
        Log routing decision to metrics
    #>
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$RoutingResult,
        
        [string]$MetricsPath = "logs/routing-metrics.json"
    )
    
    $config = Get-AutoDelegationConfig
    
    if (-not $config.MetricsEnabled) {
        return
    }
    
    $metrics = Get-RoutingMetrics -MetricsPath $MetricsPath
    
    $metrics.TotalRoutings++
    
    if ($RoutingResult.Status -eq "Success") {
        $metrics.SuccessfulRoutings++
        
        if (-not $metrics.AgentDistribution.PSObject.Properties[$RoutingResult.PrimaryAgent]) {
            $metrics.AgentDistribution | Add-Member -NotePropertyName $RoutingResult.PrimaryAgent -NotePropertyValue 0
        }
        $metrics.AgentDistribution.($RoutingResult.PrimaryAgent)++
    }
    elseif ($RoutingResult.Status -eq "LowConfidence") {
        $metrics.LowConfidenceRoutings++
    }
    
    # Update average confidence score
    if ($RoutingResult.ConfidenceScore) {
        $metrics.AverageConfidenceScore = (
            ($metrics.AverageConfidenceScore * ($metrics.TotalRoutings - 1)) + $RoutingResult.ConfidenceScore
        ) / $metrics.TotalRoutings
    }
    
    # Ensure logs directory exists
    $logsDir = Split-Path $MetricsPath
    if (-not (Test-Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    }
    
    $metrics | ConvertTo-Json -Depth 10 | Set-Content $MetricsPath
}

# ============================================================================
# EXPORTS
# ============================================================================

# Export functions (only if running as module)
if ($MyInvocation.MyCommand.Module) {
    Export-ModuleMember -Function @(
        'Get-AutoDelegationConfig',
        'Set-AutoDelegationConfig',
        'Extract-TaskKeywords',
        'Evaluate-DecisionTree',
        'Calculate-ConfidenceScore',
        'Route-TaskToAgent',
        'Enable-AutoDelegation',
        'Disable-AutoDelegation',
        'Set-ConfidenceThreshold',
        'Get-RoutingMetrics',
        'Log-RoutingDecision'
    )
}