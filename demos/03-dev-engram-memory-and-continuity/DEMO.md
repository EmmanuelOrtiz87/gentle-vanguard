# Demo 03 — Engram Memory and Continuity (v2.14.0)

**Audience:** Development Team  
**Duration:** ~10 min  
**Stack version:** v2.14.0+

---

## Goal

Show cross-session continuity using Engram memory, session history, and execution metrics tracking.

---

## Scope

1. Start and continue sessions with full context recovery
2. Recover prior decisions, bugs fixed, and patterns established
3. Track execution metrics across sessions (duration, commands, tokens)
4. View consolidated dashboard with session execution data

---

## Components Demonstrated

1. `run-engram.ps1` — Engram memory CLI for saving/retrieving observations
2. `compact-start.ps1` — lightweight session continuation prompt
3. `session-metrics-tracker.ps1` — captures execution metrics per session
4. `detect-ide-session.ps1` — detects active IDE/tool sessions
5. HTML Dashboard — consolidated view of session execution data
6. Engram memory tools: `mem_save`, `mem_search`, `mem_context`

---

## Run Steps

### Step 1 — Verify Engram health and project detection

```powershell
# Run diagnostics to confirm Engram is operational
./scripts/utilities/run-engram.ps1 --help
# Expected: lists all available Engram commands

# Detect the current project from working directory
# (Available as engram_mem_current_project tool in AI-assisted flows)
# Returns: project name, source, path, available alternatives

# Run full diagnostics
# (Available as engram_mem_doctor tool)
# Returns: structured operational status
```

### Step 2 — Register a session and save observations

```powershell
# Start a new session
./scripts/utilities/wf.ps1 start-session demo-memory
# Expected:
# [SESSION] Registered: session-YYYY-MM-DD-XX
# [ENGRAM] Context bridge active
# [TRACKER] Metrics collection started

# Save an important decision to persistent memory
# (Conceptual — uses mem_save in AI-assisted flow)
# Title: "Switched from sessions to JWT"
# Type: decision
# Content includes:
#   **What**: Replaced express-session with jsonwebtoken
#   **Why**: Session storage doesn't scale across instances
#   **Where**: src/middleware/auth.ts, src/routes/login.ts
#   **Learned**: Must set httpOnly and secure flags

# Search past memory for related decisions
# (Conceptual — uses mem_search tool)
# Query: "authentication architecture"
# Expected: returns past decisions about auth patterns, JWT configs, known pitfalls
```

### Step 3 — Session metrics tracking

```powershell
# The session-metrics-tracker automatically captures:
# - Session duration (start → current)
# - Number of commands executed
# - Files modified
# - Token consumption estimate
# - Quality gate results

# View current session execution metrics
# (Available as part of wf status)
./scripts/utilities/wf.ps1 status
# Expected to show:
# ┌─────────────────────────────────────────┐
# │ Session Execution Metrics               │
# │ Duration      │ 00:32:15                │
# │ Commands run  │ 24                      │
# │ Files touched │ 7                       │
# │ Tokens used   │ 8,420 / 30,000          │
# │ Gates passed  │ 3/3                     │
# └─────────────────────────────────────────┘

# Generate compact continuation prompt for handoff
./scripts/utilities/wf.ps1 compact-start "handoff after memory demo"
# Expected:
# [COMPACT] Continuation prompt generated
# [COMPACT] Includes: last 3 decisions, current files, open tasks
# [COMPACT] Token cost: ~350 tokens (vs. 2K+ for full context)
```

### Step 4 — Dashboard with session execution data

```powershell
# Generate and open the HTML dashboard
./scripts/utilities/wf.ps1 dashboard
# → Generates reports/dashboard.html
# → Opens in default browser

# Dashboard sections showing execution metrics:
# 1. KPI Cards:
#    - Active Sessions: N
#    - Total Dispatches: NNN
#    - Token Spend Today: NN.K / 30K
#    - Quality Pass Rate: NNN%
#
# 2. Session Timeline Chart:
#    - Shows session start/end times
#    - Command density over time
#    - File modification events
#
# 3. Execution Metrics Table:
#    ┌──────────────┬──────────┬──────────┬──────────┐
#    │ Session      │ Duration │ Commands │ Tokens   │
#    ├──────────────┼──────────┼──────────┼──────────┤
#    │ session-A    │ 01:15:30 │ 42       │ 12,400   │
#    │ session-B    │ 00:45:12 │ 28       │ 8,100    │
#    │ session-C    │ 02:10:05 │ 67       │ 18,900   │
#    └──────────────┴──────────┴──────────┴──────────┘
#
# 4. Token Budget Gauge:
#    Visual indicator of remaining daily budget
#    Green (>30% remaining) / Yellow (10-30%) / Red (<10%)
```

### Step 5 — Context recovery across sessions

```powershell
# On day 2, restore previous context
./scripts/utilities/wf.ps1 compact-start "continue task-tracker from yesterday"
# Expected:
# [ENGRAM] Restored context from session-YYYY-MM-DD-XX
# [ENGRAM] Found 5 past observations
# [ENGRAM] Last state: task-tracker CLI implemented, review pending

# The AI assistant now has:
# - Knowledge of previous implementation decisions
# - Awareness of what was tested vs. untested
# - Understanding of the project's coding conventions
# - No repeated onboarding required
```

### Step 6 — Session closure with metrics finalization

```powershell
# End session and finalize metrics
./scripts/utilities/wf.ps1 end-session demo-memory
# Expected:
# [SESSION] Closing demo-memory
# [TRACKER] Finalizing execution metrics...
# [TRACKER] Writing to .metrics/session-YYYY-MM-DD-XX.json
# [ENGRAM] Saving session summary to persistent memory
# [SESSION] Closed cleanly

# View the metrics file
Get-Content .metrics/session-YYYY-MM-DD-XX.json | ConvertFrom-Json | ConvertTo-Json
# Shows: duration, commands, files, tokens, gates, decisions recorded
```

---

## Expected Outcome

1. Memory tools are reachable and session-aware
2. Execution metrics are captured automatically per session
3. Dashboard reflects consolidated session execution data
4. Context is resumed quickly on day 2 — no repeated onboarding
5. Token efficiency: compact-start uses ~350 tokens vs. 2K+ for full reload
6. Team sees tangible AI collaboration continuity across sessions
