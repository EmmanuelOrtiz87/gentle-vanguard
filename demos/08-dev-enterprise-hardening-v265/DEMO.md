# Demo 08 — Enterprise Hardening Wave (v2.6.4 + v2.6.5)

**Audience:** Tech Lead / Senior Developer / DevOps  
**Duration:** ~20 min  
**Stack version:** v2.6.5+  
**Focus:** New capabilities from the enterprise hardening wave — SDD enforcement, benchmarks, drift detection, PSScriptAnalyzer CI, and automated releases.

---

## What This Demo Shows

This is the "deep technical" demo for developers who want to see the **new v2.6.4+v2.6.5 capabilities** in action:

| Feature | Version | Command |
|---------|---------|---------|
| SDD Gate (blocks commits without spec) | v2.6.4 | `wf sdd-gate` |
| SDD Process Metrics (cycle time, SLO) | v2.6.4 | `wf sdd-metrics` |
| Sync Drift Report (foundation ↔ projects) | v2.6.4 | `wf sync-drift` |
| WF Benchmark (SLO measurement) | v2.6.4 | `wf benchmark` |
| PSScriptAnalyzer CI (static analysis) | v2.6.5 | `.github/workflows/ps-lint.yml` |
| Automated GitHub Releases | v2.6.5 | `git tag v*.*.*` |
| Stack Version command | v2.6.5 | `wf version` |
| Normativas vivas | v2.6.5 | `rules/` directory |

---

## Setup

```powershell
# Ensure you're on main at v2.6.5+
git checkout main
wf version
# Expected: Gentleman Foundation v2.6.5
```

---

## Part 1 — SDD Enforcement (FF-001)

### Why it matters
> "The SDD gate is the technical enforcement of 'no spec = no code'. It's not a policy — it's a hard block."

```powershell
# Check current SDD status
wf sdd-gate
# Expected output:
# [SDD-GATE] Checking for validated SDD documents...
# [PASS] Found 1 validated SDD(s): docs/sdd/YYYY-MM-DD-spec.md (status: validated)

# Simulate what happens without a valid SDD:
# → pre-commit hook fires → EXIT 1 → blocked
# → CI sdd-gate.yml → PR check fails → merge blocked

# Check SDD metrics (cycle time, phase distribution)
wf sdd-metrics
# Shows: status breakdown, avg cycle time per phase, SLO compliance %
```

**Key talking point:** Every SDD that reaches `validated` status has passed through BA → SAD → review. The gate enforces this end-to-end.

---

## Part 2 — SDD Process Metrics (FF-002)

```powershell
wf sdd-metrics
# Output (example):
# ┌─────────────────────────────────────────┐
# │ SDD Process Metrics                     │
# │ Total: 3 | Validated: 1 | Draft: 2     │
# │ Avg cycle time (draft→validated): 2.1d  │
# │ SLO target: 3d | Compliance: 100%       │
# └─────────────────────────────────────────┘

# JSON output for integration:
.\scripts\utilities\TELEMETRY-METRICS\sdd-process-metrics.ps1 -AsJson | ConvertFrom-Json
```

---

## Part 3 — Sync Drift Report (FF-004)

```powershell
wf sync-drift
# Output (example):
# [DRIFT-REPORT] Scanning foundation ↔ workspace...
# [OK] config/auto-delegation.json: in sync
# [WARN] docs/guides/SESSION-GUIDE.md: missing in 2 projects
# [WARN] rules/AI-NORMATIVES.md: version mismatch
# Drift score: 12/100 (LOW)

# JSON output:
.\scripts\utilities\sync-drift-report.ps1 -AsJson
# → {"status": "warn", "drift_score": 12, "issues": [...]}
```

**Key talking point:** Drift detection prevents the common problem where the framework evolves but projects don't get the updates. Score 0 = perfectly synced.

---

## Part 4 — WF Benchmark (FF-006)

```powershell
# Benchmark with default commands (status + health)
wf benchmark

# Benchmark specific commands
wf benchmark status,health,verify

# Expected output:
# ┌─────────────────────────────────────────────┐
# │ Command   │ Time   │ SLO    │ Result       │
# ├───────────┼────────┼────────┼──────────────┤
# │ status    │ 0.82s  │ 5s     │ ✅ PASS      │
# │ health    │ 2.14s  │ 15s    │ ✅ PASS      │
# │ verify    │ 4.31s  │ 30s    │ ✅ PASS      │
# └─────────────────────────────────────────────┘
```

**Key talking point:** SLOs are measured, not assumed. If a command starts degrading, we know before users complain.

---

## Part 5 — PSScriptAnalyzer CI (v2.6.5)

```powershell
# Locally simulate CI (what ps-lint.yml runs on every push):
Import-Module PSScriptAnalyzer
$results = Invoke-ScriptAnalyzer -Path scripts/ -Recurse -Severity Error
if ($results.Count -eq 0) { "✅ 0 blocking errors" } else { $results }

# See the workflow:
Get-Content .github/workflows/ps-lint.yml
```

**Key talking point:**
- `Error` severity = **blocks merge** (unreachable code, null dereference, etc.)
- `Warning` severity = GitHub annotation (advisory, doesn't block)
- 4 rules excluded with documented justification in `rules/POWERSHELL-STANDARDS.md`

---

## Part 6 — Automated GitHub Releases (v2.6.5)

```powershell
# What happens when a tag is pushed:
git tag -a v2.6.5 -m "v2.6.5 release"
git push origin v2.6.5

# → GitHub Actions: release.yml triggers
# → Reads CHANGELOG.md for tag section
# → Creates GitHub Release with release notes
# → Zero manual steps

# Verify release.yml logic:
Get-Content .github/workflows/release.yml
```

**Key talking point:** Before v2.6.5, releases were created manually. Now: tag → push → release is fully automated. The changelog IS the release notes.

---

## Part 7 — Normativas Vivas (v2.6.5)

```powershell
# Show the three new normatives
Get-ChildItem rules/ | Select-Object Name, LastWriteTime

# PowerShell Standards (enforced by ps-lint.yml)
Get-Content rules/POWERSHELL-STANDARDS.md | Select-Object -First 30

# CI Hardening (enforced by agent-verify + audit checklist)
Get-Content rules/CI-HARDENING-STANDARDS.md | Select-Object -First 30

# Testing Standards (enforced by Pester + CI)
Get-Content rules/TESTING-STANDARDS.md | Select-Object -First 30
```

**Key talking point:** These are *living normatives* — they're versioned in git, enforced in CI, and referenced by the verification system. Changing a rule means updating the file AND the CI enforcement.

---

## Part 8 — Stack Version (v2.6.5)

```powershell
wf version
# Output:
# Gentleman Foundation v2.6.5 | orchestrator: v2.6.5
#   Stack: 7.5.0 on windows
#   Skills: 125
```

**Key talking point:** `VERSION` file is the single source of truth. `release.yml` validates that the pushed tag matches `VERSION`. Drift between tag and file = blocked release.

---

## Full Command Reference (v2.6.4+v2.6.5 new commands)

```powershell
wf sdd-gate          # FF-001: Check SDD spec status
wf sdd-metrics       # FF-002: SDD process metrics + cycle time
wf sync-drift        # FF-004: Foundation ↔ project drift detection
wf benchmark         # FF-006: SLO benchmark of wf commands
wf version           # v2.6.5: Stack version + skills count
```

---

## Expected Outcome

Developers leave understanding:
- The pipeline has **zero gaps** — every vector of quality is covered
- New features are **benchmarked against SLOs** (not just "it works")
- **Releasing is a single command** (tag + push)
- **Standards are code** — normativas are enforced in CI, not just documented
