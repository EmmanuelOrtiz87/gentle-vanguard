# Foundation CLI — Quick Start Guide

**Command:** `foundation` (replaces `wf` to avoid Windows Defender Firewall conflicts)

---

## ⚡ Installation

### Option 1: Automatic (Recommended)
```powershell
cd c:\Workspace_local\foundation
.\scripts\utilities\install-foundation-cli.ps1
```

Then restart PowerShell and use `foundation` anywhere.

### Option 2: Manual
Add this to your PowerShell profile (`$PROFILE`):
```powershell
function foundation {
    & ".\scripts\utilities\WORKFLOW-ORCHESTRATION\foundation.ps1" @args
}
```

Then:
```powershell
. $PROFILE
```

### Option 3: Direct Execution
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\foundation.ps1 <command> [options]
```

---

## 📊 Available Commands

### Dashboard & Monitoring

#### 1. **Static Dashboard** (single snapshot)
```powershell
foundation dashboard
```
- Generates `reports/dashboard.html`
- 8 professional sections (Overview, Costs, ROI, Benchmarks, etc.)
- Open in browser manually

#### 2. **Dashboard with Auto-Open**
```powershell
foundation dashboard open
```
- Generates HTML and opens in default browser

#### 3. **Live Dashboard** (continuous refresh ⭐ NEW)
```powershell
foundation dashboard live
```
- **Refreshes every 15 seconds** (dev + management real-time monitoring)
- Updates live snapshots, events, routing quality
- Every 4 cycles: runs full benchmark to update baseline/history
- Auto-opens in browser
- Press `Ctrl+C` to stop

---

### Benchmarking & Quality Gates

#### 1. **Full Stack Benchmark**
```powershell
foundation benchmark full
```
- Runs 4-layer validation:
  1. wf command latency vs SLO
  2. Routing accuracy (multilenguaje)
  3. Agent-verify tests domain
  4. **Baseline regression detection** (EWMA smoothing)
- Output: JSON with status (PASS/WARN/FAIL)

#### 2. **Benchmark with Auto-Remediation** ⭐ NEW
```powershell
foundation benchmark full remediate
```
- Runs full benchmark
- If any layer FAILS: executes local diagnostics playbook
- Generates incident report: `reports/incidents/stack-benchmark-remediation-<timestamp>.md`
- Does NOT auto-escalate (you control when to act)

#### 3. **Benchmark with Baseline Reset**
```powershell
foundation benchmark full baseline-update
```
- Forces baseline update from current metrics
- Use after incident recovery or performance optimization

---

### Session & Workflow

#### Start Development Session
```powershell
foundation start-session
```
- Initializes session context, loads engram memory, checks health

#### Health Check
```powershell
foundation health
```
- Verifies all subsystems: tokens, routing, context, hooks, structure

#### Verify Code Quality
```powershell
foundation verify
```
- Runs all tests, linting, commit hooks

---

## 📈 Common Workflows

### **For Developers**

**During development:**
```powershell
# Start session
foundation start-session

# Monitor in real-time
foundation dashboard live &

# Before commit
foundation verify

# Check regression after changes
foundation benchmark full
```

**If something breaks:**
```powershell
foundation benchmark full remediate
# → Review incident report in reports/incidents/
```

---

### **For Managers/Ops**

**Real-time monitoring:**
```powershell
foundation dashboard live
# → Open http://localhost:xxxx in browser
# → Refreshes every 15 seconds
# → Shows: token usage, routing quality, costs, ROI, agents/skills, events
```

**Weekly health check:**
```powershell
foundation health
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
```powershell
# Browser auto-refreshes every 30 seconds
foundation dashboard live -RefreshSeconds 30

# Run 10 cycles then stop
foundation dashboard live -Iterations 10
```

### Benchmark with Custom Intervals
```powershell
# Update baseline every 8 benchmark cycles
foundation dashboard live -BenchmarkEvery 8 -RefreshSeconds 10
```

### Enable Auto-Remediation for Monitoring
```powershell
# Runs incident playbook automatically on benchmark failure
foundation dashboard live -AutoRemediateOnFail

# Check results in reports/incidents/
```

---

## 📝 Output Artifacts

| File | Purpose |
|------|---------|
| `reports/dashboard.html` | Main dashboard (HTML) |
| `reports/stack-benchmark.json` | Latest benchmark results |
| `reports/stack-benchmark-baseline.json` | EWMA-smoothed baseline |
| `reports/stack-benchmark-history.json` | Last 240 benchmark cycles |
| `reports/stack-benchmark-history.jsonl` | Append-only audit log |
| `reports/stack-live-observability-latest.json` | Live snapshot (live dashboard feed) |
| `reports/incidents/*.md` | Auto-remediation incident reports |

---

## ⚠️ Troubleshooting

### "foundation: command not found"
```powershell
# Solution 1: Reload profile
. $PROFILE

# Solution 2: Run full path
.\scripts\utilities\WORKFLOW-ORCHESTRATION\foundation.ps1 health

# Solution 3: Reinstall
.\scripts\utilities\install-foundation-cli.ps1
```

### "Windows Defender Firewall" still triggers
```powershell
# Use full path instead of 'wf'
.\scripts\utilities\WORKFLOW-ORCHESTRATION\foundation.ps1 dashboard live
```

### Dashboard doesn't refresh
```powershell
# Check if browser has auto-refresh meta tag
# If not, manually refresh (F5) or wait for next cycle

# Check logs
cat reports/stack-live-observability-latest.json | ConvertFrom-Json | Select -Expand timestamp
```

---

## 📞 Support

- **Quick help:** `foundation help`
- **Health issues:** `foundation health -Verbose`
- **Benchmark details:** `foundation benchmark full | ConvertFrom-Json | Select *`
- **Live monitoring:** `foundation dashboard live -Iterations 1` (single cycle for testing)

---

**Updated:** 2026-05-13  
**Status:** Production Ready ✅
