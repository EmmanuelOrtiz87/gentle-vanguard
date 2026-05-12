# Fallback Strategy Normatives — Foundation

Canonical standards for agent fallback behavior, error recovery, and graceful degradation.
Last updated: 2026-05-12 | Version: 1.0.0

---

## 1. Fallback Strategy Overview

When agent routing fails or confidence is low, Foundation MUST fallback gracefully.

### Default Fallback: Clarify with BA

```json
{
  "fallbackStrategy": {
    "default": "clarify-ba",
    "tier1_noMatch": "clarify-ba",
    "tier2_lowConfidence": "clarify-ba",
    "tier3_error": "clarify-ba",
    "timeout": "escalate-orchestrator"
  }
}
```

**Meaning**: If trigger doesn't match any skill or confidence is low, activate Business Analyst (BA) agent with `sdd-lifecycle` skill to:
1. Ask clarifying questions
2. Explore user intent
3. Route to correct agent

---

## 2. Confidence Tiers

### Tier 1: High Confidence (≥80%)

**Action**: `dispatch_immediately`

```
User input: "implement new API endpoint"
Trigger matched: "implement"
Agent code: DEV
Confidence: 95%
→ ACTION: Dispatch DEV agent immediately with sdd-lifecycle skill
```

### Tier 2: Medium Confidence (60-79%)

**Action**: `dispatch_with_summary`

```
User input: "make this faster"
Potential triggers: ["optimize", "performance", "refactor"]
Confidence: 72%
→ ACTION: Dispatch with summary: "Did you mean to OPTIMIZE this code?"
→ If user confirms, dispatch DEV agent
→ If user clarifies, fall through to BA
```

### Tier 3: Low Confidence (<60%)

**Action**: `activate_ba_exploration`

```
User input: "what do you think?"
Matched triggers: [none significant]
Confidence: 28%
→ ACTION: Route to BA agent (sdd-lifecycle skill)
→ BA asks: "What specific area would you like help with?"
→ BA re-routes based on answer
```

---

## 3. Fallback Triggers

| Scenario | Trigger | Confidence | Fallback | Action |
|----------|---------|------------|----------|--------|
| **No match** | User input doesn't match any keyword | <40% | BA clarification | Ask user for clarification |
| **Ambiguous** | Multiple triggers equally likely | 50% | BA summary & confirm | Show options to user |
| **Timeout** | Routing takes >5s | N/A | Escalate orchestrator | Page on-call engineer |
| **Skill unavailable** | Matched skill not loaded | N/A | Fallback skill defined | Use alternative skill |
| **Agent quota exceeded** | Agent hit token budget | N/A | Queue + notify | Queue task, notify user ETA |
| **Runtime error** | Skill execution failed | N/A | Log + retry OR escalate | Retry 3x, then escalate |

---

## 4. BA Clarification Flow

When routing falls back to BA, execute this interactive flow:

```powershell
# scripts/workflows/ba-clarification.ps1

[CmdletBinding()]
param([string]$UserInput)

# Step 1: Parse user intent
$intent = Analyze-UserIntent $UserInput

# Step 2: Ask clarifying question
$question = @"
I understand you're asking about: $(Suggest-Topic $intent)

Could you clarify what you'd like help with?

📋 Common options:
  1. 🏗️  Architecture & Design — Design systems, APIs, databases
  2. 💻 Implementation — Write code, refactor, fix bugs
  3. 🧪 Testing & QA — Test strategies, quality gates
  4. 🚀 DevOps & Deployment — Infrastructure, CI/CD, deployment
  5. 📚 Documentation — Docs, guides, comments
  6. 🔒 Security & Compliance — Auth, security review
  7. 💼 Business & Planning — Requirements, roadmap, estimates
  8. ❓ Something else...

Please respond with a number or describe what you need.
"@

Write-Output $question

# Step 3: Parse response
$response = Read-Host "Your choice"

# Step 4: Route to correct agent
$routing = @{
    "1" = "SAD"      # Solution Architect
    "2" = "DEV"      # Developer
    "3" = "QA"       # QA Engineer
    "4" = "OPS"      # DevOps Engineer
    "5" = "DOC"      # Documentation
    "6" = "GOV"      # Governance
    "7" = "BA"       # Business Analyst
    "8" = "BA"       # Back to BA for more details
}

$agent = $routing[$response]
Dispatch-Agent -AgentCode $agent -UserInput $UserInput -Confidence 0.8
```

---

## 5. Fallback Scenarios

### Scenario 1: Skill Not Found

```
User: "Use my custom-widget skill"
Matched trigger: "custom-widget"
Skill lookup: NOT FOUND
Confidence: 0% (skill doesn't exist)

FALLBACK:
1. Log warning: "Skill 'custom-widget' not found"
2. Try fallback (generic skill): "project-orchestrator-skill"
3. Route to BA: "I don't have a 'custom-widget' skill. 
   Would you like me to create one or help you with project setup instead?"
```

### Scenario 2: Multiple Equally Likely Matches

```
User: "how do I set up testing?"
Possible triggers:
  - "testing" (Confidence: 80%) → QA agent
  - "setup" (Confidence: 75%) → OPS agent
  - "implementation" (Confidence: 60%) → DEV agent

Disambiguation:
1. Log: "Ambiguous input, multiple skill matches"
2. Ask user: "Would you like help with:
   - [1] Testing strategies & tools?
   - [2] Infrastructure setup?
   - [3] Implementation guidance?
   - Choose: [1-3]"
3. Route based on user selection
```

### Scenario 3: Agent Quota Exceeded

```
User: "analyze this large dataset"
Agent code: DATA-SCIENTIST
Matched skill: "data-scientist-skill"
Confidence: 95% (good match)
BUT: DATA-SCIENTIST agent token budget: 18,000 / 20,000 used today

FALLBACK:
1. Log warning: "Agent quota exceeded"
2. Queue task: Add to job queue with priority
3. Notify user: "Your task is queued. 
   Estimated processing time: 2 hours 15 minutes.
   You'll receive a notification when complete.
   Queue position: 3 of 8."
4. Option: Escalate to orchestrator for higher priority
```

### Scenario 4: Skill Runtime Failure

```
User: "run tests on this code"
Matched skill: "testing-skill"
Confidence: 95%
Dispatch: SUCCESS (initially)
Execution: FAILED after 30 seconds (database connection error)

FALLBACK (Automatic Retry):
1. Log error: "Skill execution failed: database connection"
2. Retry 1: Wait 5s, retry skill (exponential backoff)
3. Retry 2: Wait 10s, retry skill
4. Retry 3: Wait 20s, retry skill
5. If all retries fail:
   → Log CRITICAL error
   → Route to OPS agent (infrastructure issue)
   → Notify user: "Testing infrastructure error. 
      OPS team has been notified. 
      ETA for fix: 30 minutes."
```

### Scenario 5: Timeout (>5 seconds to route)

```
User: "complex request with nested requirements"
Routing attempt: TIMEOUT (5s exceeded)

FALLBACK:
1. Log: "Routing timeout"
2. Escalate to orchestrator (GOV agent)
3. Notify user: "Request is complex. 
   I'm escalating to our orchestrator for manual routing.
   You'll hear back within 5 minutes."
4. Orchestrator:
   → Reviews input manually
   → Selects most appropriate agent + skill
   → Dispatches with explanation
```

---

## 6. Error Handling in Fallbacks

### Classification: 4-Level Error Ladder

| Level | Severity | Action | Example |
|-------|----------|--------|---------|
| **DEBUG** | Informational | Log & continue | Cache miss, retry attempt |
| **WARN** | Minor issue | Log & notify | Deprecated endpoint, slow operation |
| **ERROR** | Significant failure | Log & fallback | Skill failed, retry exhausted |
| **CRITICAL** | System failure | Log & escalate | Database down, auth failure |

### Error Handling Template

```powershell
[CmdletBinding()]
param([string]$Input)

try {
    # PRIMARY: Attempt to dispatch
    $result = Dispatch-Agent -Input $Input -ErrorAction Stop
    return $result
}
catch [SkillNotFoundException] {
    # FALLBACK 1: Skill doesn't exist
    Write-Warning "Skill not found for trigger: $trigger"
    return Dispatch-Agent -AgentCode "BA" -Skill "sdd-lifecycle"
}
catch [LowConfidenceException] {
    # FALLBACK 2: Low confidence
    Write-Warning "Confidence too low ($confidence%)"
    return Ask-Clarification -UserInput $Input
}
catch [TimeoutException] {
    # FALLBACK 3: Timeout
    Write-Error "Routing timeout after 5s"
    return Escalate-ToOrchestrator -Input $Input
}
catch [Exception] {
    # FALLBACK 4: Unexpected error
    Write-Error "Unexpected error: $_"
    throw  # Re-throw to calling context
}
```

---

## 7. Configuration: config/fallback-strategy.json

```json
{
  "fallbackStrategy": {
    "enabled": true,
    "version": "1.0.0",
    
    "routing": {
      "default": "clarify-ba",
      "tier1": { "minConfidence": 0.80, "action": "dispatch_immediately" },
      "tier2": { "minConfidence": 0.60, "maxConfidence": 0.79, "action": "dispatch_with_summary" },
      "tier3": { "maxConfidence": 0.59, "action": "activate_ba_exploration" },
      "timeout": {
        "seconds": 5,
        "action": "escalate-orchestrator"
      }
    },
    
    "retryPolicy": {
      "maxRetries": 3,
      "backoff": "exponential",
      "backoffMs": [100, 500, 2000],
      "retryableErrors": [
        "TimeoutException",
        "TemporaryFailure",
        "ResourceUnavailable"
      ]
    },
    
    "fallbackSkills": {
      "default": "sdd-lifecycle",
      "onSkillNotFound": "project-orchestrator-skill",
      "onTimeout": "session-workflow-skill",
      "onQuotaExceeded": "session-workflow-skill"
    },
    
    "escalation": {
      "enabled": true,
      "targets": ["orchestrator", "devops", "security"],
      "notification": {
        "channels": ["slack", "email"],
        "severity": "CRITICAL"
      }
    },
    
    "userCommunication": {
      "askClarification": true,
      "showOptions": true,
      "retryNotification": true,
      "queueNotification": true,
      "estimatedTimeFormat": "human-readable"
    }
  }
}
```

---

## 8. Testing Fallback Scenarios

### Unit Tests

```powershell
# tests/fallback-strategy.tests.ps1

Describe "Fallback Strategy" -Tag "CI" {
    
    It "routes low-confidence to BA" {
        $result = Invoke-Routing -Input "???" -ExpectConfidence 0.2
        $result.AgentCode | Should Be "BA"
        $result.Skill | Should Be "sdd-lifecycle"
    }
    
    It "disambiguates multiple matches" {
        $result = Invoke-Routing -Input "setup testing framework" -InteractiveResponse "1"
        $result.AgentCode | Should Be "QA"
    }
    
    It "retries on skill failure" {
        $callCount = 0
        Mock-Skill -Name "failing-skill" -CallCount ([ref]$callCount)
        
        Invoke-SkillWithFallback -Skill "failing-skill"
        
        $callCount | Should Be 3  # Retried 3 times
    }
    
    It "escalates on timeout" {
        $result = Invoke-Routing -Input "complex query" -Timeout 6
        $result.EscalatedTo | Should Be "orchestrator"
    }
}
```

---

## 9. Documentation & Communication

### User-Facing Messages

```markdown
### 📋 Low Confidence Route

"I'm not 100% sure what you're asking for. Let me clarify:

Would you like help with:
- 🏗️  **System Design** — Architecture, APIs, data structures
- 💻 **Implementation** — Write code, refactor, debug
- 🧪 **Testing** — Test strategies, quality assurance
- 🚀 **DevOps** — Infrastructure, deployment, CI/CD
- 📚 **Docs** — Documentation, guides, comments
- 🔒 **Security** — Auth, security review, compliance
- 💼 **Planning** — Requirements, estimates, roadmap

Just reply with a number [1-7] or describe more specifically."
```

### Retry Notification

```
⏳ **Retrying...**
Previous attempt failed due to temporary issue.
Retry 1 of 3... (waiting 5s before retry)
```

### Queue Notification

```
📋 **Task Queued**
Your analysis request has been queued.
Position in queue: 3 of 8
Estimated wait: 2 hours 15 minutes

You'll receive a notification when processing starts.
Need urgent processing? Reply: "PRIORITY"
```

---

## 10. Governance & Monitoring

### SLOs for Fallback

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Fallback rate | <5% of requests | >8% |
| BA clarification success | >85% | <75% |
| Retry success rate | >70% | <60% |
| Timeout incidents | <1% | >2% |
| Escalation rate | <2% | >5% |

### Monitoring Dashboard

```json
{
  "fallbackMetrics": {
    "totalRequests": 10234,
    "fallbacks": {
      "count": 412,
      "rate": "4.0%",
      "breakdown": {
        "lowConfidence": "40%",
        "skillNotFound": "15%",
        "ambiguous": "30%",
        "error": "15%"
      }
    },
    "baClarity": {
      "asked": 164,
      "clarified": 139,
      "success_rate": "84.8%"
    },
    "retries": {
      "attempted": 56,
      "succeeded": 39,
      "success_rate": "69.6%"
    }
  }
}
```

---

## References

- [config/auto-delegation.json](../config/auto-delegation.json) — Routing rules
- [config/fallback-strategy.json](../config/fallback-strategy.json) — Fallback config
- [AI-NORMATIVES.md](AI-NORMATIVES.md) — Agent profiles
- Project: sdd-lifecycle skill
