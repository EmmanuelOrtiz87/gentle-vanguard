# Gentle-Vanguard CLI — Quick Start Guide

**Command:** `gentle-vanguard` (replaces `gv` to avoid Windows Defender Firewall conflicts)

---

## ⚡ Installation

### Option 1: Automatic (Recommended)

```TypeScript
cd c:\Workspace_local\gentle-vanguard
.\scripts\utilities\install-gentle-vanguard-cli.ps1
```

Then restart TypeScript and use `gentle-vanguard` anywhere.

### Option 2: Manual

Add this to your TypeScript profile (`$PROFILE`):

```TypeScript
function gentle-vanguard {
    & ".\scripts\utilities\WORKFLOW-ORCHESTRATION\gentle-vanguard.ps1" @args
}
```

Then:

```TypeScript
. $PROFILE
```

### Option 3: Direct Execution

```TypeScript
.\scripts\utilities\WORKFLOW-ORCHESTRATION\gentle-vanguard.ps1 <command> [options]
```

---

## 📊 Available Commands

### Dashboard & Monitoring

#### 1. **Static Dashboard** (single snapshot)

```TypeScript
gv dashboard
```

- Generates `reports/dashboard.html`
- 8 professional sections (Overview, Costs, ROI, Benchmarks, etc.)
- Open in browser manually

#### 2. **Dashboard with Auto-Open**

```TypeScript
gv dashboard open
```

- Generates HTML and opens in default browser

#### 3. **Live Dashboard** (continuous refresh ⭐ NEW)

```TypeScript
gv dashboard live
```

- **Refreshes every 15 seconds** (dev + management real-time monitoring)
- Updates live snapshots, events, routing quality
- Every 4 cycles: runs full benchmark to update baseline/history
- Auto-opens in browser
- Press `Ctrl+C` to stop

---

### Benchmarking & Quality Gates

#### 1. **Full Stack Benchmark**

```TypeScript
gv benchmark full
```

- Runs 4-layer validation:
  1. gv command latency vs SLO
  2. Routing accuracy (multilenguaje)
  3. Agent-verify tests domain
  4. **Baseline regression detection** (EWMA smoothing)
- Output: JSON with status (PASS/WARN/FAIL)

#### 2. **Benchmark with Auto-Remediation** ⭐ NEW

```TypeScript
gv benchmark full remediate
```

- Runs full benchmark
- If any layer FAILS: executes local diagnostics playbook
- Generates incident report: `reports/incidents/stack-benchmark-remediation-<timestamp>.md`
- Does NOT auto-escalate (you control when to act)

#### 3. **Benchmark with Baseline Reset**

```TypeScript
gv benchmark full baseline-update
```

- Forces baseline update from current metrics
- Use after incident recovery or performance optimization

---

### Session & Workflow

#### Start Development Session

```TypeScript
gv start-session
```

- Initializes session context, loads Engram memory, checks health
- The underlying session manager persists session start/close records to Engram

#### Health Check

```TypeScript
gv health
```

- Verifies all subsystems: tokens, routing, context, hooks, structure

#### Verify Code Quality

```TypeScript
gv check
```

- Runs the configured quality gates, including tests and hook validation

#### Run Real Coverage Gate

```TypeScript
npx tsx src/cli/gv.ts
```

- Executes declared Pester `CodeCoverage` targets from `tests/coverage-config.json`
- Current declared workflows cover `session-manager.ps1`, `post-session-learning.ps1`,
  `session-autostart.ps1`, `detect-tool.ps1`, and `pre-close-validator.ps1`

#### Run Post-Session Learning Explicitly

```TypeScript
npx tsx src/cli/gv.ts -SessionId "session-YYYY-MM-DD-01"
```

- Persists learning summaries or improvement proposals to Engram
- Uses `.local/improvement-proposals/` as the local review backlog

---

## 📈 Common Workflows

### **For Developers**

**During development:**

```TypeScript
# Start session
gv start-session

# Monitor in real-time
gv dashboard live &

# Before commit
gv check

# Check regression after changes
gv benchmark full
```

**If something breaks:**

```TypeScript
gv benchmark full remediate
# → Review incident report in reports/incidents/
```

---

### **For Managers/Ops**

**Real-time monitoring:**

```TypeScript
gv dashboard live
# → Open http://localhost:xxxx in browser
# → Refreshes every 15 seconds
# → Shows: token usage, routing quality, costs, ROI, agents/skills, events
```

**Weekly health check:**

```TypeScript
gv health
# → GREEN: all systems operational
# → YELLOW: warnings (review logs)
# → RED: failure (contact on-call)
```

---

## 📊 Dashboard Sections (Live)

1. **Overview** — Session KPIs, dispatch counts, token usage
2. **Operations Live** ⭐ — Real-time traffic light, routing accuracy, events
3. **Costs & Savings** — Budget tracking, MoM trends, ROI status
4. **Executive ROI** — Financial metrics for leadership
5. **Benchmark Guard** ⭐ — Baseline regression trends, latency history
6. **Agent/Skill Drilldown** ⭐ — Load distribution, P95 latencies, bottlenecks
7. **Stack Metrics** — System health (tokens, context, governance)
8. **Metrics Explorer** — Raw telemetry tables
9. **Events** — Recent event history

---

## 🔧 Advanced Usage

### Auto-Refresh Dashboard in Browser

```TypeScript
# Browser auto-refreshes every 30 seconds
gv dashboard live -RefreshSeconds 30

# Run 10 cycles then stop
gv dashboard live -Iterations 10
```

### Benchmark with Custom Intervals

```TypeScript
# Update baseline every 8 benchmark cycles
gv dashboard live -BenchmarkEvery 8 -RefreshSeconds 10
```

### Enable Auto-Remediation for Monitoring

```TypeScript
# Runs incident playbook automatically on benchmark failure
gv dashboard live -AutoRemediateOnFail

# Check results in reports/incidents/
```

---

## 📝 Output Artifacts

| File                                           | Purpose                             |
| ---------------------------------------------- | ----------------------------------- |
| `reports/dashboard.html`                       | Main dashboard (HTML)               |
| `reports/stack-benchmark.json`                 | Latest benchmark results            |
| `reports/stack-benchmark-baseline.json`        | EWMA-smoothed baseline              |
| `reports/stack-benchmark-history.json`         | Last 240 benchmark cycles           |
| `reports/stack-benchmark-history.jsonl`        | Append-only audit log               |
| `reports/stack-live-observability-latest.json` | Live snapshot (live dashboard feed) |
| `reports/incidents/*.md`                       | Auto-remediation incident reports   |

---

## ⚠️ Troubleshooting

### "gentle-vanguard: command not found"

```TypeScript
# Solution 1: Reload profile
. $PROFILE

# Solution 2: Run full path
.\scripts\utilities\WORKFLOW-ORCHESTRATION\gentle-vanguard.ps1 health

# Solution 3: Reinstall
.\scripts\utilities\install-gentle-vanguard-cli.ps1
```

### "Windows Defender Firewall" still triggers

```TypeScript
# Use full path instead of 'gv'
.\scripts\utilities\WORKFLOW-ORCHESTRATION\gentle-vanguard.ps1 dashboard live
```

### Dashboard doesn't refresh

```TypeScript
# Check if browser has auto-refresh meta tag
# If not, manually refresh (F5) or wait for next cycle

# Check logs
cat reports/stack-live-observability-latest.json | ConvertFrom-Json | Select -Expand timestamp
```

---

## 📞 Support

- **Quick help:** `gv help`
- **Health issues:** `gv health -Verbose`
- **Benchmark details:** `gv benchmark full | ConvertFrom-Json | Select *`
- **Live monitoring:** `gv dashboard live -Iterations 1` (single cycle for testing)

---

**Updated:** 2026-05-13  
**Status:** Production Ready ✅
