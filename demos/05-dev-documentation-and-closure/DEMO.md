# Demo 05 — Documentation and Session Closure (v2.14.0)

**Audience:** Development Team / Documentation Lead  
**Duration:** ~10 min  
**Stack version:** v2.14.0+

---

## Goal

Show how documentation and closure steps keep delivery consistent — from session finalization
through metrics consolidation to dashboard refresh.

---

## Scope

1. Session closure with standard artifacts (review, audit, summary)
2. Metrics consolidation across all sessions
3. Dashboard refresh after consolidation
4. PR-ready output preparation

---

## Components Demonstrated

1. `end-session.ps1` — closes session and writes final artifacts
2. `finalize-session.ps1` — generates review + audit reports
3. `day-end-closure.ps1` — end-of-day consolidation sweep
4. `consolidate-metrics.ps1` — aggregates session metrics into unified dashboard data
5. `create-pull-request.ps1` — PR creation with auto-generated body
6. HTML Dashboard — refreshed view of consolidated data

---

## Run Steps

### Step 1 — Close a single session with artifacts

```powershell
# End the current session and generate closure artifacts
./scripts/utilities/gv.ps1 end-session demo-task-tracker
# Expected:
# [SESSION] Closing demo-task-tracker
# [ENGRAM] Saving session summary to persistent memory
# [ARTIFACTS] Writing session review...
# [ARTIFACTS] Writing session audit...
# [ARTIFACTS] Session closed cleanly

# Verify artifacts were created
Get-ChildItem docs/reviews/ -Filter "*demo-task-tracker*" | Select-Object Name
Get-ChildItem docs/audits/ -Filter "*demo-task-tracker*" | Select-Object Name
# Expected: review and audit markdown files exist with timestamps
```

### Step 2 — Generate review and audit reports

```powershell
# Generate a session review
./scripts/utilities/generate-session-review.ps1
# Expected output:
# ┌─────────────────────────────────────────┐
# │ Session Review                          │
# │ Commands executed: 24                   │
# │ Files modified: 7                       │
# │ Quality gates: 3/3 PASS                 │
# │ Decisions recorded: 2                   │
# │ Review verdict: ✅ All checks passed    │
# └─────────────────────────────────────────┘
# Output written to: docs/reviews/YYYY-MM-DD-HHmmss-review.md

# Generate an audit report
./scripts/utilities/generate-session-audit.ps1
# Expected:
# [AUDIT] Session audit generated
# [AUDIT] Coverage: commands, files, tokens, gates, decisions
# Output: docs/audits/YYYY-MM-DD-HHmmss-audit.md

# Generate a weekly audit summary
./scripts/utilities/generate-audit-report.ps1 -Period weekly
# Expected:
# [AUDIT] Weekly report generated
# [AUDIT] Period: YYYY-MM-DD to YYYY-MM-DD
# [AUDIT] Sessions: N | Total tokens: NNN | Pass rate: NN%
```

### Step 3 — Finalize session with standard closure

```powershell
# Run the full session finalization
./scripts/utilities/finalize-session.ps1
# Expected:
# [FINALIZE] Checking all session artifacts...
# [FINALIZE] Session review: present ✓
# [FINALIZE] Session audit: present ✓
# [FINALIZE] Engram summary: saved ✓
# [FINALIZE] Metrics: finalized ✓
# [FINALIZE] All closure criteria met
```

### Step 4 — Day-end closure with metrics consolidation

```powershell
# Run the end-of-day closure sweep
./scripts/utilities/day-end-closure.ps1 -Force
# Expected:
# ┌─────────────────────────────────────────┐
# │ Day-End Closure                         │
# │ Sessions closed: 3                      │
# │ Metrics consolidated: 3/3               │
# │ Total tokens used: 28,400 / 30,000      │
# │ Engram summaries: 3                     │
# │ Dashboard: pending refresh              │
# └─────────────────────────────────────────┘
```

**What day-end-closure does:**
1. Iterates all sessions not yet finalized
2. Ensures each has review + audit artifacts
3. Saves session summaries to Engram persistent memory
4. Triggers metrics consolidation (calls `consolidate-metrics.ps1`)
5. Reports summary to stdout

### Step 5 — Consolidate metrics across all sessions

```powershell
# Run the metrics consolidation explicitly
.\scripts\utilities\TELEMETRY-METRICS\consolidate-metrics.ps1
# Expected:
# ┌─────────────────────────────────────────┐
# │ Metrics Consolidation                   │
# │ Sessions processed: 3                   │
# │ Metrics files written:                  │
# │   .metrics/dashboard-data.json          │
# │   .metrics/session-summary.csv          │
# │ Dashboard data refreshed                │
# └─────────────────────────────────────────┘

# Verify the consolidated data
Get-Content .metrics/dashboard-data.json | ConvertFrom-Json | ConvertTo-Json
# Shows:
# {
#   "sessions": [
#     {"id": "session-A", "duration": "01:15:30", "commands": 42, "tokens": 12400},
#     {"id": "session-B", "duration": "00:45:12", "commands": 28, "tokens": 8100},
#     {"id": "session-C", "duration": "02:10:05", "commands": 67, "tokens": 18900}
#   ],
#   "totals": {"sessions": 3, "commands": 137, "tokens": 39400},
#   "period": {"start": "2026-05-15", "end": "2026-05-15"}
# }
```

### Step 6 — Refresh the dashboard with consolidated data

```powershell
# Generate the dashboard HTML (now includes consolidated metrics)
./scripts/utilities/gv.ps1 dashboard
# → Regenerates reports/dashboard.html
# → Opens in browser

# Dashboard now shows:
# 1. Consolidated KPI Cards:
#    - Sessions Today: 3
#    - Total Commands: 137
#    - Token Utilization: 39,400 (above daily budget — needs review)
#    - Quality Pass Rate: 100%
#
# 2. Session Comparison Chart:
#    Bar chart comparing duration, commands, and tokens per session
#
# 3. Daily Trend Graph:
#    Shows token usage and session count over the last 7 days
#
# 4. Budget Alert Bar:
#    Red highlight if total exceeded 30K daily cap
```

### Step 7 — Prepare PR-ready output

```powershell
# Create a pull request with auto-generated body
./scripts/utilities/create-pull-request.ps1 --help
# Expected: shows usage with parameters for title, body, branch
# The generated body includes:
#   - Summary of changes
#   - Links to SDD specs
#   - Quality gate results
#   - Review/Audit artifact references

# Check documentation consistency
./scripts/utilities/gv.ps1 verify
# Expected: 14/14 PASS including doc quality checks
# Look for: documentation-coherence, artifact-completeness
```

---

## Expected Outcome

1. Session closes with standard artifacts (review + audit markdown files)
2. Metrics are consolidated across all sessions into unified dashboard data
3. Dashboard refresh reflects consolidated execution data
4. Token budget utilization is visible and actionable
5. PR-ready output includes all quality and governance evidence
6. Day-end closure produces a single source of truth for management reporting

