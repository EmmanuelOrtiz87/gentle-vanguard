# Guardian Fallback Protocol

## Concept

Foundation's orchestrator is **self-sufficient** but can optionally invoke GGA (Gentleman Guardian Angel) as guardian when blocked.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FOUNDATION ORCHESTRATOR                               │
│                                                                              │
│    Primary execution engine - operates 100% without external tools          │
│                                                                              │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
            ┌───────────────┐           ┌───────────────┐
            │   CAN PROCEED  │           │   BLOCKED?    │
            └───────┬───────┘           └───────┬───────┘
                    │                           │
                    ▼                           ▼
            ┌───────────────┐           ┌───────────────┐
            │  EXECUTE       │           │  SELF-HEAL    │
            │  NORMALLY      │           │  ATTEMPT      │
            └───────────────┘           └───────┬───────┘
                                                │
                                ┌───────────────┴───────────────┐
                                │                               │
                                ▼                               ▼
                        ┌───────────────┐           ┌───────────────┐
                        │   HEALED?     │           │  STILL       │
                        └───────┬───────┘           │  BLOCKED?     │
                                │                   └───────┬───────┘
                    ┌───────────┴───────────┐               │
                    │                       │               ▼
                    ▼                       ▼       ┌───────────────┐
            ┌───────────────┐           ┌───────────────┐│   GGA        │
            │   RESUME      │           │   GGA         ││   AVAILABLE? │
            │   EXECUTION   │           │   FALLBACK    │└───────┬───────┘
            └───────────────┘           │   (OPTIONAL)   │        │
                                        └───────────────┘        ▼
                                                        ┌───────────────┐
                                                        │     YES      │
                                                        │   Invoke     │
                                                        │   GGA        │
                                                        └───────┬───────┘
                                                                │
                                                                ▼
                                                        ┌───────────────┐
                                                        │     NO        │
                                                        │   Flag for    │
                                                        │   Manual      │
                                                        │   Review      │
                                                        └───────────────┘
```

## Dependency Model

### Required (Core)
| Component | Purpose | Can Fail Without GGA? |
|-----------|---------|----------------------|
| project-orchestrator | Master conductor | NO |
| invoke-ai-review.ps1 | Native AI review | NO |
| code-review-orchestrator | 7-dimension review | NO |
| session-workflow | Session management | NO |

### Optional (Enhancement)
| Component | Purpose | Works Without? |
|-----------|---------|----------------|
| GGA (gga) | Guardian fallback | **YES** |

## Invocation Triggers

### Automatic Triggers
1. **Unknown error** - Orchestrator encounters unrecognized error
2. **Block detected** - Cannot determine next step
3. **Complex decision** - Multiple equally valid paths
4. **PR ready check** - Final review before merge

### Manual Triggers
```powershell
# Direct GGA invocation
gga run                    # Review staged files
gga run --pr-mode         # Full PR review
gga run --ci              # CI mode

# Foundation native (always available)
wf review --scope full    # 7-dimension review
invoke-ai-review.ps1 run # Native replacement
```

## Fallback Decision Protocol

### Step 1: Self-Assessment
```powershell
function Test-CanProceed {
    param($Context)
    
    # Check: Are all dependencies available?
    # Check: Is the next step deterministic?
    # Check: Is error recoverable?
    
    if ($allDependenciesMet -and $deterministicStep -and $recoverableError) {
        return $true
    }
    return $false
}
```

### Step 2: Self-Healing
```powershell
function Invoke-SelfHealing {
    param($Context)
    
    # Attempt common fixes:
    # - Retry with backoff
    # - Clear cache
    # - Reset state
    # - Fallback to default
    
    if ($healed) {
        Write-Host "[ORCHESTRATOR] Self-healed successfully"
        return $true
    }
    return $false
}
```

### Step 3: GGA Fallback
```powershell
function Invoke-GgaFallback {
    if (-not (Test-GgaAvailable)) {
        Write-Warn "[FALLBOR] GGA not available"
        return $false
    }
    
    Write-Host "[ORCHESTRATOR] Invoking GGA guardian..."
    
    switch ($Context.Type) {
        'CODE_REVIEW' {
            gga run
        }
        'PR_REVIEW' {
            gga run --pr-mode
        }
        'DECISION' {
            gga run --ci  # Last commit review
        }
        default {
            gga run --ci
        }
    }
    
    return ($LASTEXITCODE -eq 0)
}
```

### Step 4: Manual Flag
```powershell
function Flag-ForManualReview {
    param($Context)
    
    Write-Warn "[ORCHESTRATOR] Blocked - manual intervention required"
    
    # Create issue or flag for human review
    $issue = @{
        Title = "Orchestrator Blocked: $($Context.BlockReason)"
        Body = "Context: $( $Context | ConvertTo-Json )"
        Labels = @("blocked", "needs-review")
    }
    
    # Optionally create GitHub issue
    # gh issue create @issue
}
```

## Integration Points

### In wf.ps1
```powershell
# Before executing critical operations
if (-not (Test-CanProceed -Context $context)) {
    $healed = Invoke-SelfHealing -Context $context
    if (-not $healed) {
        Invoke-GgaFallback -Context $context
    }
}
```

### In Session Close
```powershell
# Before session end
$tasksComplete = Test-AllTasksComplete

if (-not $tasksComplete) {
    if (Test-GgaAvailable) {
        gga run --ci  # Final review
    } else {
        Flag-Incomplete -Context $context
    }
}
```

### In PR Flow
```powershell
# Before PR merge
$reviewResult = wf review --scope full

if (-not $reviewResult.Passed) {
    if (Test-GgaAvailable) {
        gga run --pr-mode  # GGA second opinion
    }
    Flag-ForManualApproval -Context $context
}
```

## Error Handling Matrix

| Error Type | Self-Heal | GGA Fallback | Manual Flag |
|------------|-----------|--------------|-------------|
| Unknown syntax | ✅ Retry | - | - |
| Missing dependency | ⚠️ Install | - | - |
| Blocked decision | ❌ | ✅ Assist | ✅ |
| Complex refactor | ❌ | ✅ Review | ✅ |
| Security issue | ❌ | ✅ Validate | ✅ |
| Persistent failure | ❌ | ✅ Diagnose | ✅ |

## Commands Reference

### Foundation Native (Always)
```powershell
wf review --scope full         # 7-dimension review
wf review --scope quick        # Fast review
invoke-ai-review.ps1 run       # Native AI review
wf compact-start               # Session handoff
```

### GGA Fallback (Optional)
```powershell
gga run                       # Staged files review
gga run --ci                  # Last commit
gga run --pr-mode             # Full PR
gga config                    # Show config
```

## Best Practices

1. **Trust Foundation first** - Orchestrator should attempt self-healing before GGA
2. **Log fallback invocations** - Track when GGA is needed for improvement
3. **Prefer native over external** - Use `invoke-ai-review.ps1` over `gga run` when possible
4. **Flag, don't fail** - When GGA unavailable, flag for manual review, don't block

## Monitoring

Track fallback frequency:
```powershell
# Log fallback events
$fallbackEvent = @{
    Timestamp = Get-Date
    Reason = $Context.BlockReason
    SelfHealAttempted = $true
    SelfHealSuccess = $healed
    GgaInvoked = $true
    GgaAvailable = Test-GgaAvailable
}

# Append to telemetry
$fallbackEvent | ConvertTo-Json | Out-File -Append "docs/management/fallback-log.jsonl"
```

---
**Last Updated:** 2026-04-17
**See Also:** `skills/guardian-fallback-skill/SKILL.md`
