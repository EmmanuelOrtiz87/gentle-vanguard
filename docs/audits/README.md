# 📅 Audits#

<p align="center">
  <b>Systematic governance-validated repository audits</b>
</p>

---

## 📋 Purpose#

| Goal | Description |
|------|-------------|
| **🎯 Operational Visibility** | Capture delivery status, risk posture, test availability |
| **🔍 Traceability** | Preserve auditable timeline for releases and retrospectives |
| **📊 Governance** | Validate compliance with SDD, security, and quality gates |

> 💡 **TIP:** All outputs use `YYYY-MM-DD-HHmmss` timestamps for unique identification.

---

## 📂 Directory Structure#

```
docs/audits/
├── 📄 README.md                    # This file - audit hub
├── 📊 YYYY-MM-DD-HHmmss-audit.md    # Individual audit reports
├── 📋 script-normalization-report.md   # Script governance report
└── (archived in git history)        # Older audits via git log
```

---

## 🚀 Quick Start#

### Generate New Audit#
```powershell
.\scripts\wf.ps1 audit
# Output: docs/audits/YYYY-MM-DD-HHmmss-audit.md
```

### Validate Governance#
```powershell
.\scripts\diagnostics\validate-script-governance.ps1
# Expected: EXIT:0 (all checks passed)
```

### Strict Cleanup (CI)#
```powershell
.\scripts\wf.ps1 health -StrictCleanup
# Non-zero exit is blocking
```

---

## 📊 Audit Reports#

| Report | Description | Link |
|--------|-------------|------|
| **📋 Latest Audit** | Current repository state | Auto-generated timestamp |
| **📊 Normalization** | Script governance compliance | [script-normalization-report.md](script-normalization-report.md) |

---

## 🔍 Audit Workflow#

### Step 1: Generate Context Pack#
```powershell
.\scripts\wf.ps1 context-pack
# Output: docs/sessions/YYYY-MM-DD-HHmmss-context-pack.md
```
Captures: branch, recent commits, changed files, platform health.

### Step 2: Activate Compact Context#
```powershell
.\scripts\wf.ps1 compact-start
# Reads: latest context-pack from docs/sessions/ (by timestamp)
# Logs: docs/sessions/metrics/context-usage.csv
```
Auto-activates on `wf.ps1 start-session` if health is RED.

### Step 3: Generate Audit Document#
```powershell
.\scripts\wf.ps1 audit
# Output: docs/audits/YYYY-MM-DD-HHmmss-audit.md
```
Full report with: delivery status, operational risk, test suite, git tracking.

### Step 4: Governance Validation#
```powershell
.\scripts\diagnostics\validate-script-governance.ps1
```
Validates canonical path references and no deprecated dependencies.

### Step 5: Review Session Metrics#
```powershell
.\scripts\wf.ps1 context-metrics
# Reads: docs/sessions/metrics/context-usage.csv
```
Displays: total events, context-pack calls, compact-start calls, efficiency indicators.

### Step 6: Manual Homologation (Optional)#
```powershell
# Preview cleanup actions
.\scripts\wf.ps1 homologate

# Apply cleanup and reference updates
.\scripts\wf.ps1 homologate apply
```
Normalizes workspace before release or when strict cleanup reports drift.

---

## 📚 Related Documentation#

| Document | Purpose |
|-----------|---------|
| **📖 Session Guide** | [../guides/SESSION-GUIDE.md](../guides/SESSION-GUIDE.md) |
| **🏗️ Architecture** | [../architecture/README.md](../architecture/README.md) |
| **📋 Audit Workflow** | [../guides/AUDIT-WORKFLOW.md](../guides/AUDIT-WORKFLOW.md) |
| **📅 Audit Workflow** | [../guides/AUDIT-WORKFLOW.md](../guides/AUDIT-WORKFLOW.md) |

---

## 🚀 Quick Commands Reference#

| Command | Description | Output |
|----------|-------------|--------|
| `wf audit` | Generate audit report | `docs/audits/YYYY-MM-DD-HHmmss-audit.md` |
| `wf context-pack` | Generate context pack | `docs/sessions/YYYY-MM-DD-HHmmss-context-pack.md` |
| `wf compact-start` | Activate compact context | `docs/sessions/metrics/context-usage.csv` |
| `wf context-metrics` | Review session metrics | Console output |
| `wf homologate` | Preview cleanup | Console output |
| `wf homologate apply` | Apply cleanup | Updated references |

---

<p align="center">
  <b>📅 Ready to audit?</b><br>
  <code>.\scripts\wf.ps1 audit</code>
</p>
