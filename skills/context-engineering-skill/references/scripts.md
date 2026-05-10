# Script Reference — Context Engineering

## compact-start.ps1

**Path**: `scripts/utilities/WORKFLOW-ORCHESTRATION/compact-start.ps1`  
**Description**: Initialize context tracking and generate compact handoff prompt.

| Param        | Type   | Default                  | Description                    |
| ------------ | ------ | ------------------------ | ------------------------------ |
| `-Objective` | string | "Foundation maintenance" | One-sentence goal (<100 chars) |

**Usage**:

```powershell
# With objective
.\wf.ps1 compact-start "fix ci noise in build pipeline"

# Direct script call
.\scripts\utilities\wf.ps1 compact-start "refactor auth middleware"
```

**Output**: Structured prompt <8000 chars with git diff, commits, branch, objective.

---

## context-pack.ps1

**Path**: `scripts/utilities/WORKFLOW-ORCHESTRATION/context-pack.ps1`  
**Description**: Generate mid-session snapshot of working context.

| Param              | Type   | Default | Description                    |
| ------------------ | ------ | ------- | ------------------------------ |
| `-Objective`       | string | ''      | Current goal                   |
| `-MaxChangedFiles` | int    | 12      | Max files to include           |
| `-MaxCommits`      | int    | 8       | Max commits to include         |
| `-PassThru`        | switch | false   | Return path instead of writing |

**Usage**:

```powershell
.\wf.ps1 context-pack "implementing search feature"
```

**Output**: Snapshot file <15000 chars.

---

## context-metrics-report.ps1

**Path**: `scripts/utilities/WORKFLOW-ORCHESTRATION/context-metrics-report.ps1`  
**Description**: Report compact-start and context-pack usage metrics.

**Usage**:

```powershell
.\wf.ps1 context-metrics
```

**Stored in**: `docs/sessions/metrics/context-usage.csv`

---

## token-efficiency-estimator.ps1

**Path**: `scripts/utilities/TELEMETRY-METRICS/token-efficiency-estimator.ps1`  
**Description**: Estimate token savings from context engineering.

**Defaults**: 20 tasks/month, 14K tokens/task, 40% reduction, $10/1M tokens.

---

## compact-marker (`.session/.compact-marker`)

**Description**: Runtime flag to prevent duplicate compact-start within 60 min.  
**Written by**: `wf.ps1 compact-start` handler.  
**Checked by**: `start-session.ps1` and `Invoke-ContextEfficiencyLiveAssist`.  
**TTL**: 60 minutes.  
**Git**: Ignored via `.gitignore` (`.session/` directory).
