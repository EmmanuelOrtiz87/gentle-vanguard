---
name: auto-delegation-router
description: >
  Automatic delegation router for intelligent subagent routing based on task keywords,
  decisión trees, and confidence scoring. Enables autonomous agent selection with opt-in control.
license: Apache-2.0
metadata:
  author: gentleman-programming
  versión: "1.0"
  status: "ACTIVE"
  priority: "CRITICAL"
---

# AUTO-DELEGATION ROUTER SKILL

## Overview

The `auto-delegation-router` skill provides intelligent, automatic routing of tasks to specialized subagents based on:
- **Keyword analysis** - Extracts domain keywords from task descriptions
- **decisión trees** - Multi-level decisión logic for agent selection
- **Confidence scoring** - Quantifies routing confidence (0-100%)
- **Opt-in control** - Flag-based enable/disable of automatic routing

### Key Capabilities
-  Keyword-based auto-routing
-  Multi-level decisión trees
-  Confidence scoring system
-  Fallback routing strategies
-  Opt-in/opt-out control
-  Routing analytics and metrics

---

## Architecture

### 1. Keyword Extraction Engine

```powershell
function Extract-TaskKeywords {
    param(
        [string]$TaskDescription,
        [int]$MaxKeywords = 10
    )
    
    # Domain-specific keyword mappings
    $keywordMap = @{
        # Business Analysis keywords
        'BA' = @('requirement', 'user story', 'bdd', 'gherkin', 'acceptance', 'specification', 
                 'feature analysis', 'stakeholder', 'business logic', 'workflow')
        
        # Solution Architecture keywords
        'SAD' = @('architecture', 'design', 'sdd', 'api design', 'database', 'schema', 
                  'technical decisión', 'system design', 'microservice', 'integration')
        
        # Development keywords
        'DEV' = @('implement', 'code', 'develop', 'feature', 'refactor', 'bug fix', 
                  'component', 'endpoint', 'frontend', 'backend', 'security', 'performance')
        
        # QA keywords
        'QA' = @('test', 'testing', 'qa', 'validation', 'e2e', 'unit test', 
                 'integration test', 'playwright', 'pytest', 'quality', 'judgment day')
        
        # DevOps keywords
        'OPS' = @('deploy', 'ci/cd', 'docker', 'kubernetes', 'infrastructure', 
                  'terraform', 'helm', 'release', 'devops', 'pipeline')
        
# Governance keywords
        'GOV' = @('governance', 'compliance', 'metrics', 'monitoring', 'observability', 
                  'incident', 'security audit', 'review', 'audit')
        
        # Script Governance - PowerShell syntax, parser errors
        'SCRIPT-GOV' = @('script', 'powershell', 'parser error', 'syntax error', 
                        'validate script', 'script validation', 'governance script',
                        'hook', 'pre-push', 'pre-commit', 'fix script', 'auto-fix')
    }
    
    $extractedKeywords = @{}
    $taskLower = $TaskDescription.ToLower()
    
    foreach ($agent in $keywordMap.Keys) {
        $matchCount = 0
        foreach ($keyword in $keywordMap[$agent]) {
            if ($taskLower -match "\b$keyword\b") {
                $matchCount++
            }
        }
        if ($matchCount -gt 0) {
            $extractedKeywords[$agent] = $matchCount
        }
    }
    
    return $extractedKeywords | Sort-Object -Property Values -Descending | Select-Object -First $MaxKeywords
}
```

### 2. decisión Tree Engine

```powershell
function Evaluate-decisiónTree {
    param(
        [string]$TaskDescription,
        [hashtable]$Keywords,
        [hashtable]$Context = @{}
    )
    
    $decisións = @()
    
    # Level 1: Primary domain detection
    $primaryAgent = $Keywords.Keys | Select-Object -First 1
    $primaryScore = $Keywords[$primaryAgent]
    
    $decisións += @{
        Level = 1
        Agent = $primaryAgent
        Reason = "Primary domain match"
        Score = $primaryScore
    }
    
    # Level 2: Secondary agent detection (if applicable)
    if ($Keywords.Keys.Count -gt 1) {
        $secondaryAgent = $Keywords.Keys | Select-Object -Index 1
        $secondaryScore = $Keywords[$secondaryAgent]
        
        # Check if secondary agent should be included
        if ($secondaryScore -ge ($primaryScore * 0.6)) {
            $decisións += @{
                Level = 2
                Agent = $secondaryAgent
                Reason = "Secondary domain match"
                Score = $secondaryScore
            }
        }
    }
    
    # Level 3: Context-based adjustments
    if ($Context.RiskLevel -eq "high") {
        # High-risk tasks might need QA involvement
        if ($decisións.Agent -notcontains 'QA') {
            $decisións += @{
                Level = 3
                Agent = 'QA'
                Reason = "High-risk context requires QA"
                Score = 5
            }
        }
    }
    
    # Level 4: Dependency-based routing
    if ($TaskDescription -match 'deploy|release|production') {
        if ($decisións.Agent -notcontains 'OPS') {
            $decisións += @{
                Level = 4
                Agent = 'OPS'
                Reason = "Deployment/release requires OPS"
                Score = 8
            }
        }
    }
    
    return $decisións
}
```

### 3. Confidence Scoring System

```powershell
function Calculate-ConfidenceScore {
    param(
        [hashtable]$Keywords,
        [array]$decisiónTree,
        [hashtable]$Context = @{}
    )
    
    $baseScore = 0
    $adjustments = @()
    
    # Base score from keyword matching
    $totalKeywordMatches = ($Keywords.Values | Measure-Object -Sum).Sum
    $baseScore = [Math]::Min(100, ($totalKeywordMatches * 15))
    
    # Adjustment: Multiple agents detected (higher confidence)
    if ($Keywords.Keys.Count -gt 1) {
        $adjustments += @{
            Factor = "Multi-agent detection"
            Adjustment = 10
        }
        $baseScore += 10
    }
    
    # Adjustment: Clear primary agent (higher confidence)
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
    
    # Adjustment: Ambiguous keywords (lower confidence)
    if ($Keywords.Keys.Count -gt 3) {
        $adjustments += @{
            Factor = "Ambiguous routing"
            Adjustment = -15
        }
        $baseScore -= 15
    }
    
    # Cap at 100
    $finalScore = [Math]::Min(100, [Math]::Max(0, $baseScore))
    
    return @{
        Score = $finalScore
        BaseScore = $baseScore
        Adjustments = $adjustments
        Confidence = switch ($finalScore) {
            { $_ -ge 80 } { "High" }
            { $_ -ge 60 } { "Medium" }
            { $_ -ge 40 } { "Low" }
            default { "Very Low" }
        }
    }
}
```

### 4. Routing Engine with Fallback

```powershell
function Route-TaskToAgent {
    param(
        [string]$TaskDescription,
        [bool]$AutoDelegationEnabled = $true,
        [hashtable]$Context = @{}
    )
    
    if (-not $AutoDelegationEnabled) {
        return @{
            Status = "AutoDelegationDisabled"
            Message = "Auto-delegation is disabled. Manual routing required."
            RequiresManualdecisión = $true
        }
    }
    
    # Step 1: Extract keywords
    $keywords = Extract-TaskKeywords -TaskDescription $TaskDescription
    
    if ($keywords.Count -eq 0) {
        return @{
            Status = "NoKeywordsFound"
            Message = "Unable to extract domain keywords. Manual routing required."
            RequiresManualdecisión = $true
            Suggestión = "Provide more specific task description"
        }
    }
    
    # Step 2: Evaluate decisión tree
    $decisiónTree = Evaluate-decisiónTree -TaskDescription $TaskDescription -Keywords $keywords -Context $Context
    
    # Step 3: Calculate confidence
    $confidence = Calculate-ConfidenceScore -Keywords $keywords -decisiónTree $decisiónTree -Context $Context
    
    # Step 4: Determine routing
    $primaryAgent = $decisiónTree | Where-Object { $_.Level -eq 1 } | Select-Object -First 1
    $secondaryAgents = $decisiónTree | Where-Object { $_.Level -gt 1 } | Select-Object -ExpandProperty Agent
    
    # Step 5: Apply confidence threshold
    $confidenceThreshold = 60
    
    if ($confidence.Score -lt $confidenceThreshold) {
        return @{
            Status = "LowConfidence"
            Message = "Confidence score below threshold ($($confidence.Score)%)"
            RequiresManualdecisión = $true
            PrimaryAgent = $primaryAgent.Agent
            ConfidenceScore = $confidence.Score
            Suggestión = "Review suggested agents and confirm manually"
        }
    }
    
    # Step 6: Return routing decisión
    return @{
        Status = "Success"
        PrimaryAgent = $primaryAgent.Agent
        SecondaryAgents = $secondaryAgents
        ConfidenceScore = $confidence.Score
        ConfidenceLevel = $confidence.Confidence
        Keywords = $keywords
        decisiónTree = $decisiónTree
        Adjustments = $confidence.Adjustments
        RequiresManualdecisión = $false
    }
}
```

### 5. Opt-In Configuration

```powershell
function Get-AutoDelegationConfig {
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
            decisiónTree = $true
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
        $loadedConfig = Get-Content $ConfigPath | ConvertFrom-Json
        return $loadedConfig
    }
    
    return $defaultConfig
}

function Set-AutoDelegationConfig {
    param(
        [hashtable]$Config,
        [string]$ConfigPath = "config/auto-delegation.json"
    )
    
    $Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
    
    return @{
        Status = "Success"
        Message = "Auto-delegation configuration updated"
        ConfigPath = $ConfigPath
    }
}

function Enable-AutoDelegation {
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
```

---

## Usage Examples

### Example 1: Basic Auto-Routing

```powershell
$task = "Implement login feature with React components and security hardening"

$routing = Route-TaskToAgent -TaskDescription $task -AutoDelegationEnabled $true

# Output:
# Status: Success
# PrimaryAgent: DEV
# SecondaryAgents: @('GOV')
# ConfidenceScore: 85
# ConfidenceLevel: High
```

### Example 2: Multi-Agent Routing

```powershell
$task = "Create BDD scenarios for checkout flow and implement payment integration"

$routing = Route-TaskToAgent -TaskDescription $task

# Output:
# Status: Success
# PrimaryAgent: BA
# SecondaryAgents: @('DEV', 'QA')
# ConfidenceScore: 78
# ConfidenceLevel: High
```

### Example 3: Low Confidence Routing

```powershell
$task = "Fix the thing"

$routing = Route-TaskToAgent -TaskDescription $task

# Output:
# Status: LowConfidence
# RequiresManualdecisión: $true
# ConfidenceScore: 25
# Suggestión: "Review suggested agents and confirm manually"
```

### Example 4: Enable/Disable Auto-Delegation

```powershell
# Enable auto-delegation
Enable-AutoDelegation

# Disable auto-delegation
Disable-AutoDelegation

# Check configuration
$config = Get-AutoDelegationConfig
$config.Enabled  # $true or $false
```

---

## Integration with Orchestrator

### Configuration File: `config/auto-delegation.json`

```json
{
  "enabled": false,
  "confidenceThreshold": 60,
  "maxParallelAgents": 3,
  "fallbackStrategy": "manual",
  "loggingEnabled": true,
  "metricsEnabled": true,
  "features": {
    "keywordExtraction": true,
    "decisiónTree": true,
    "confidenceScoring": true,
    "autoRetry": false,
    "autoEscalation": true
  },
  "thresholds": {
    "highConfidence": 80,
    "mediumConfidence": 60,
    "lowConfidence": 40
  }
}
```

### Orchestrator Integration

The orchestrator will:
1. Check if auto-delegation is enabled
2. Extract task keywords
3. Evaluate decisión tree
4. Calculate confidence score
5. Route to primary agent(s)
6. Include secondary agents if applicable
7. Log routing decisión and metrics

---

## Metrics and Analytics

### Routing Metrics

```powershell
function Get-RoutingMetrics {
    param(
        [string]$MetricsPath = "logs/routing-metrics.json"
    )
    
    if (Test-Path $MetricsPath) {
        return Get-Content $MetricsPath | ConvertFrom-Json
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
```

### Tracked Metrics

- Total routing decisións made
- Successful auto-routings vs. manual overrides
- Average confidence score
- Agent selection frequency
- Keyword extraction accuracy
- decisión tree effectiveness

---

## Error Handling

| Scenario | Behavior | Fallback |
|----------|----------|----------|
| No keywords found | Require manual routing | Suggest generic agent |
| Low confidence | Require manual confirmation | Provide suggestións |
| Multiple equally likely agents | Select primary, include secondary | Manual selection |
| Config file missing | Use defaults | Disable auto-delegation |
| Disabled flag | Skip auto-routing | Manual routing |

---

## Performance Expectations

| Operation | Target Time | Max Memory |
|-----------|------------|-----------|
| Keyword extraction | <100ms | <5MB |
| decisión tree evaluation | <50ms | <2MB |
| Confidence calculation | <50ms | <2MB |
| Full routing decisión | <300ms | <10MB |

---

## Future Enhancements

1. **Machine Learning Integration** - Learn from routing decisións over time
2. **User Feedback Loop** - Improve routing based on user corrections
3. **Dynamic Thresholds** - Adjust confidence thresholds based on context
4. **Agent Availability** - Consider agent availability in routing
5. **Historical Analysis** - Track routing success rates per agent
6. **Custom Keyword Mapping** - Allow users to define custom keywords

---

## Commands

```powershell
# Enable auto-delegation
.\scripts\utilities\wf.ps1 auto-delegation enable

# Disable auto-delegation
.\scripts\utilities\wf.ps1 auto-delegation disable

# Test routing for a task
.\scripts\utilities\wf.ps1 auto-delegation route "your task description"

# Get routing metrics
.\scripts\utilities\wf.ps1 auto-delegation metrics

# Update confidence threshold
.\scripts\utilities\wf.ps1 auto-delegation config --threshold 70
```

---

## Delegation Limits - What NOT to Delegate

### Critical Tasks (NEVER Auto-Delegate)
These tasks MUST be handled by the main orchestrator or user:

1. **Core Configuration Changes**
   - Modifications to `AGENTS.md`, `config/mcp-servers.json`
   - Changes to `tools/session-autostart.cmd`, `tools/enforce-response-mode.ps1`
   - Token budget or threshold adjustments in `token-guard-config.json`

2. **Security & Authentication**
   - Credential management
   - Authentication configuration
   - Security policy updates

3. **Session Lifecycle Management**
   - Session start/end operations
   - Context compaction decisións
   - Manual session recovery

4. **User Interaction Required**
   - Tasks where user explicitly says "you do it" without specifying details
   - Tasks requiring human judgment on priorities
   - Release decisións

### Auto-Delegate Appropriate Tasks
- Code implementation (DEV agent)
- Testing (QA agent)
- Architecture design (SAD agent)
- Business analysis (BA agent)
- Deployment operations (OPS agent)
- Script validation (SCRIPT-GOV agent)

### decisión Logic
```powershell
function Test-ShouldDelegate {
    param([string]$TaskDescription)
    
    $neverDelegate = @(
        'AGENTS.md', 'config/', 'session-autostart', 
        'security', 'authentication', 'credential',
        'release', 'deploy to production'
    )
    
    $taskLower = $TaskDescription.ToLower()
    
    foreach ($pattern in $neverDelegate) {
        if ($taskLower -match [regex]::Escape($pattern)) {
            return $false  # Don't delegate
        }
    }
    
    return $true  # Safe to delegate
}
```

---

## References

- Multi-Agent Registry: [skills/multi-agent-registry/SKILL.md](../multi-agent-registry/SKILL.md)
- Orchestrator: [skills/project-orchestrator-skill/SKILL.md](../project-orchestrator-skill/SKILL.md)
- Subagent Architecture: [docs/reference/SUBAGENT-ARCHITECTURE.md](../../docs/reference/SUBAGENT-ARCHITECTURE.md)
