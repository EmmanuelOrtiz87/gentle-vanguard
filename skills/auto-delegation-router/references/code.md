# Auto-Delegation Router — Full Code Reference

## 1. Keyword Extraction Engine

```powershell
function Extract-TaskKeywords {
    param([string]$TaskDescription, [int]$MaxKeywords = 10)
    $mappingPath = "config/subagent-mapping.json"
    $subagentMapping = @{}
    if (Test-Path $mappingPath) {
        $mapping = Get-Content $mappingPath | ConvertFrom-Json
        $mapping.mapping.PSObject.Properties | ForEach-Object {
            $subagentMapping[$_.Name] = $_.Value
        }
    }
    $keywordMap = @{
        'BA' = @('requirement', 'user story', 'bdd', 'gherkin', 'acceptance', 'specification', 'feature analysis', 'stakeholder', 'business logic', 'workflow')
        'SAD' = @('architecture', 'design', 'sdd', 'api design', 'database', 'schema', 'technical decision', 'system design', 'microservice', 'integration')
        'DEV' = @('implement', 'code', 'develop', 'feature', 'refactor', 'bug fix', 'component', 'endpoint', 'frontend', 'backend', 'security', 'performance')
        'QA' = @('test', 'testing', 'qa', 'validation', 'e2e', 'unit test', 'integration test', 'playwright', 'pytest', 'quality', 'judgment day')
        'OPS' = @('deploy', 'ci/cd', 'docker', 'kubernetes', 'infrastructure', 'terraform', 'helm', 'release', 'devops', 'pipeline')
        'GOV' = @('governance', 'compliance', 'metrics', 'monitoring', 'observability', 'incident', 'security audit', 'review', 'audit')
        'SCRIPT-GOV' = @('script', 'powershell', 'parser error', 'syntax error', 'validate script', 'script validation', 'governance script', 'hook', 'pre-push', 'pre-commit', 'fix script', 'auto-fix')
    }
    $extractedKeywords = @{}
    $taskLower = $TaskDescription.ToLower()
    foreach ($agent in $keywordMap.Keys) {
        $matchCount = 0
        foreach ($keyword in $keywordMap[$agent]) {
            if ($taskLower -match "\b$keyword\b") { $matchCount++ }
        }
        if ($matchCount -gt 0) { $extractedKeywords[$agent] = $matchCount }
    }
    return $extractedKeywords | Sort-Object -Property Values -Descending | Select-Object -First $MaxKeywords
}
```

## 2. Decision Tree Engine

```powershell
function Evaluate-DecisionTree {
    param([string]$TaskDescription, [hashtable]$Keywords, [hashtable]$Context = @{})
    $decisions = @()
    $primaryAgent = $Keywords.Keys | Select-Object -First 1
    $primaryScore = $Keywords[$primaryAgent]
    $decisions += @{ Level = 1; Agent = $primaryAgent; Reason = "Primary domain match"; Score = $primaryScore }
    if ($Keywords.Keys.Count -gt 1) {
        $secondaryAgent = $Keywords.Keys | Select-Object -Index 1
        $secondaryScore = $Keywords[$secondaryAgent]
        if ($secondaryScore -ge ($primaryScore * 0.6)) {
            $decisions += @{ Level = 2; Agent = $secondaryAgent; Reason = "Secondary domain match"; Score = $secondaryScore }
        }
    }
    if ($Context.RiskLevel -eq "high" -and $decisions.Agent -notcontains 'QA') {
        $decisions += @{ Level = 3; Agent = 'QA'; Reason = "High-risk context requires QA"; Score = 5 }
    }
    if ($TaskDescription -match 'deploy|release|production' -and $decisions.Agent -notcontains 'OPS') {
        $decisions += @{ Level = 4; Agent = 'OPS'; Reason = "Deployment/release requires OPS"; Score = 8 }
    }
    return $decisions
}
```

## 3. Confidence Scoring

```powershell
function Calculate-ConfidenceScore {
    param([hashtable]$Keywords, [array]$decisionTree, [hashtable]$Context = @{})
    $baseScore = 0
    $adjustments = @()
    $totalKeywordMatches = ($Keywords.Values | Measure-Object -Sum).Sum
    $baseScore = [Math]::Min(100, ($totalKeywordMatches * 15))
    if ($Keywords.Keys.Count -gt 1) { $adjustments += @{ Factor = "Multi-agent detection"; Adjustment = 10 }; $baseScore += 10 }
    if ($Keywords.Keys.Count -eq 1) { $adjustments += @{ Factor = "Clear single agent"; Adjustment = 15 }; $baseScore += 15 }
    if ($Context.HasClearObjective) { $adjustments += @{ Factor = "Clear objective"; Adjustment = 5 }; $baseScore += 5 }
    if ($Keywords.Keys.Count -gt 3) { $adjustments += @{ Factor = "Ambiguous routing"; Adjustment = -15 }; $baseScore -= 15 }
    $finalScore = [Math]::Min(100, [Math]::Max(0, $baseScore))
    return @{
        Score = $finalScore; BaseScore = $baseScore; Adjustments = $adjustments
        Confidence = switch ($finalScore) { { $_ -ge 80 } { "High" }; { $_ -ge 60 } { "Medium" }; { $_ -ge 40 } { "Low" }; default { "Very Low" } }
    }
}
```

## 4. Tiered Routing & Concurrency Control

See [auto-delegation-router.ps1](../auto-delegation-router.ps1) for:
- `Get-RoutingBindings`
- `Resolve-Tier`
- `Route-WithTieredSpecificity`
- Concurrency control (`Initialize-ConcurrencyControl`, `Wait-ForAgentSlot`, `Release-AgentSlot`)

## 5. Full Routing Engine

See [auto-delegation-router.ps1](../auto-delegation-router.ps1) for `Route-TaskToAgent` — the main routing function that orchestrates all sub-functions.

## 6. Opt-In Configuration

See [auto-delegation-router.ps1](../auto-delegation-router.ps1) for:
- `Get-AutoDelegationConfig`
- `Set-AutoDelegationConfig`
- `Enable-AutoDelegation`
- `Disable-AutoDelegation`

## Examples

```powershell
# Basic: Implement login feature
Route-TaskToAgent -TaskDescription "Implement login feature with React components and security hardening"
# Output: PrimaryAgent=DEV, SecondaryAgents=@('GOV'), ConfidenceScore=85

# Multi-agent: BDD + payment
Route-TaskToAgent -TaskDescription "Create BDD scenarios for checkout flow and implement payment integration"
# Output: PrimaryAgent=BA, SecondaryAgents=@('DEV','QA'), ConfidenceScore=78

# Low confidence
Route-TaskToAgent -TaskDescription "Fix the thing"
# Output: Status=LowConfidence, ConfidenceScore=25
```

## Performance Targets

| Operation | Max Time | Max Memory |
|-----------|----------|------------|
| Keyword extraction | 100ms | 5MB |
| Decision tree evaluation | 50ms | 2MB |
| Confidence calculation | 50ms | 2MB |
| Full routing decision | 300ms | 10MB |

## Error Handling

| Scenario | Behavior | Fallback |
|----------|----------|----------|
| No keywords found | Manual routing | Suggest generic agent |
| Low confidence | Manual confirmation | Provide suggestions |
| Multiple equally likely | Select primary + secondary | Manual selection |
| Config file missing | Use defaults | Disable auto-delegation |

## Delegation Limits

### Never Auto-Delegate
- AGENTS.md or `config/mcp-servers.json` changes
- `session-autostart.cmd`, `enforce-response-mode.ps1` changes
- Token budget/threshold adjustments
- Credential/security operations
- Session lifecycle management
- Release decisions

### Auto-Delegate Appropriate
- Code implementation (DEV), Testing (QA), Architecture (SAD), Business analysis (BA), Deployment (OPS), Script validation (SCRIPT-GOV)
