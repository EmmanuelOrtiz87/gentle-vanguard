# Demo 02 — Orchestrator and AI Cycle (v2.14.0)

**Audience:** Development Team  
**Duration:** ~15 min  
**Stack version:** v2.14.0+

---

## Goal

Show how the orchestrator and skills drive AI-assisted implementation flow — from input routing
through confidence-based delegation to execution.

---

## Scope

1. Session context generation and pre-process routing
2. Confidence-based delegation across agents
3. English-first routing principle (no magic headers)
4. Skill-aware workflow execution
5. Custom rules injection and enforcement

---

## Components Demonstrated

1. `pre-process-input.ps1` — input routing and trigger detection
2. `context-pack.ps1` — compact session context generation
3. `orchestrator-next-steps.ps1` — priority-ordered action suggestions
4. `custom-rules.ps1` — dynamic rule injection per task type
5. `config/auto-delegation.json` — trigger → skill → agent mappings

---

## Run Steps

### Step 1 — Show pre-process-input routing output

```powershell
# Test routing with a "fix" request (bug fix — direct DEV routing)
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/pre-process-input.ps1 `
  -UserInput "Fix the login redirect bug" -WorkspaceRoot "."
# Expected:
# TRIGGER_MATCH_FOUND: true
# SKILL: sdd-lifecycle
# AGENT: DEV (direct — no BA gate for bug fixes)
# ACTION: APPLY — proceed with DEV implementation

# Test routing with a "build" request (new feature — BA gate required)
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/pre-process-input.ps1 `
  -UserInput "Build a reporting dashboard" -WorkspaceRoot "."
# Expected:
# TRIGGER_MATCH_FOUND: true
# SKILL: sdd-lifecycle
# AGENT: BA
# ACTION: PLAN_MODE_REQUIRED — BA EXPLORE phase first
```

**English-First Routing Principle:** The system routes on natural language intent — no special
prefixes, no magic headers, no structured tags required. "Fix X" routes to DEV. "Build X" routes to
BA → PLAN_MODE. The pre-processor parses intent directly from plain English.

### Step 2 — Examine the delegation configuration

```powershell
# View the trigger-to-skill mapping (the routing table)
Get-Content config/auto-delegation.json | ConvertFrom-Json | ConvertTo-Json -Depth 5
# Shows: trigger patterns → skill → agent → confidence thresholds

# Key structure:
# {
#   "triggers": {
#     "implement|build|create|develop|make": {
#       "skill": "sdd-lifecycle",
#       "agent": "BA",
#       "confidence": 0.85,
#       "action": "PLAN_MODE_REQUIRED"
#     },
#     "fix|bug|error|broken|crash": {
#       "skill": "sdd-lifecycle",
#       "agent": "DEV",
#       "confidence": 0.90,
#       "action": "APPLY"
#     }
#   }
# }
```

**Confidence-Based Delegation:**

- High-confidence matches (>0.85): automatic routing, no confirmation needed
- Medium-confidence (0.70–0.85): routed but flagged for user confirmation
- Low-confidence (<0.70): presented as suggestions, user chooses
- Confidence thresholds are configurable in `config/auto-delegation.json`

### Step 3 — Generate session context

```powershell
# Pack all relevant context for a new task
./scripts/utilities/gv.ps1 context-pack "Implement demo task-tracker CLI"
# Expected:
# [CONTEXT-PACK] Scanning project structure...
# [CONTEXT-PACK] Found 3 relevant SDD specs
# [CONTEXT-PACK] Loading last 2 session artifacts
# [CONTEXT-PACK] Context pack written to .context/session-context.json
# [CONTEXT-PACK] Estimated tokens: 2,450

# Compact start for continuation (lighter weight)
./scripts/utilities/gv.ps1 compact-start "task-tracker implementation"
# Expected:
# [COMPACT] Continuation prompt generated (320 tokens)
# [COMPACT] Includes: current task, files touched, last decision
```

### Step 4 — Get orchestrator recommendations

```powershell
# Show priority-ordered next steps
./scripts/utilities/orchestrator-next-steps.ps1
# Expected output:
# ┌────────────────────────────────────────────────────────┐
# │ Orchestrator Recommended Actions                        │
# │ Priority │ Action                     │ Confidence     │
# │ P0       │ Start SDD for new feature  │ 0.92 (auto)    │
# │ P1       │ Run context-pack           │ 0.88 (auto)    │
# │ P2       │ Review active session      │ 0.75 (confirm) │
# │ P3       │ Check quality gate status  │ 0.62 (suggest) │
# └────────────────────────────────────────────────────────┘
```

### Step 5 — Custom rules injection

```powershell
# Show current active custom rules
./scripts/utilities/custom-rules.ps1 status
# Expected:
# [RULES] Active rules for current session:
#   - TypeScript + Zod patterns loaded (from typescript-skill)
#   - SDD lifecycle rules active (from sdd-lifecycle)
#   - Session token budget: 30K/day

# Export rules for inspection
./scripts/utilities/custom-rules.ps1 export
# Expected: outputs the full ruleset being injected into AI context
```

### Step 6 — Communication mode awareness

```powershell
# View available response modes
./scripts/utilities/gv.ps1 response-mode list
# Expected:
# Available modes:
#   ultra     → 4 lines max, no preamble (default for power users)
#   lleno     → Full detail, verbose output (break-glass)
#   balanced  → Moderate detail, some preamble

# Check efficiency matrix
./scripts/utilities/response-mode-efficiency-matrix.ps1
# Shows token savings estimates per mode vs. full verbose
```

---

## Expected Outcome

1. Team sees that routing is **intent-driven** (plain English), not syntax-dependent
2. Bug fixes route directly to DEV; new features demand BA → EXPLORE first
3. Confidence thresholds control automation level — no unnecessary confirmations
4. Context packs reduce token waste by loading only relevant artifacts
5. Custom rules are injected dynamically per skill, keeping AI context focused
6. Response modes give fine-grained control over verbosity and token consumption
