# AI-Assisted Development Frameworks — Research Synthesis

> Research conducted 2026-05-30 across 6 domains. Recommendations are proven patterns from Claude Code, Cursor, Copilot, Mem0/Letta, Sourcegraph SCIP, and production frameworks.

---

## 1. Knowledge Persistence

### Data Model

| Field | Purpose | Provenance |
|-------|---------|------------|
| `topic_key` | Stable upsert key — same topic overwrites, no dupes | Mem0, Claude Code |
| `confidence` | Semantic conflict resolution weight (0.0–1.0) | Engram production |
| `provenance` | Which agent/model created it | Claude Code |
| `relation_ids` | Links to parent/related observations | Claude Code, Letta |
| `ttl` | Auto-expire ephemeral observations | Mem0 |

**Content format**: `**What**/**Why**/**Where**/**Learned**` — structured markdown both humans and LLMs parse reliably.

### Auto-Trigger Rules (Don't wait for manual saves)

| Trigger | Condition | Action |
|---------|-----------|--------|
| Turn threshold | 5+ turns without save | Auto-save decision chain |
| File creation | New file > 50 lines | Save `architecture` type |
| Bug pattern | Same error appears twice | Save `bugfix` with full context |
| Session midpoint | 15 min elapsed, >2000 tokens | Auto-compact + summary |

### Retention Lifecycle

| Age | Action |
|-----|--------|
| < 24h | Keep all (hot tier, full fidelity) |
| 1–7d | Deduplicate by `topic_key` (warm, condensed summary) |
| 7–30d | Summarize — compress to 1/3 size |
| > 30d | Archive to cold storage (gzipped JSONL) |

### Session Lifecycle

Enhance start/end:

```powershell
# Session start — add provenance
$session = @{
    id = $SessionId; project = $ProjectName
    tool = (detect-tool.ps1).name
    model = $env:LLM_MODEL ?: "unknown"
    start_time = (Get-Date -Format "o")
}
# Session end — auto-compact and archive
```

### Context Injection (Tiered)

1. **Hot** — always inject (last 24h, priority > 0.7)
2. **Warm** — on `mem_search "lessons learned"` (done)
3. **Cold** — lazy load on file/error match

### Quick Wins

1. Add `topic_key` to engram saves — enables upsert, eliminates duplicates
2. Increase auto-save triggers (turn-threshold + file-change)
3. Add session midpoint summary at 15 min
4. Add `relations` table for semantic conflict resolution

---

## 2. CodeGraph / Code Index

### Current State

27 files indexed (JS/TS/Go only). ~533 PowerShell files are invisible.

### What to Index (Prioritized)

| PS Symbol | Example | Node Kind |
|-----------|---------|-----------|
| Functions/cmdlets | `function Get-Process { }` | `function` |
| Parameters | `param([string]$Name)` | `param` |
| Classes (PS 5+) | `class MyClass : Base` | `class` |
| Modules | `Export-ModuleMember` | `module` |
| Dot-sourcing | `. .\lib.ps1` | `imports` edge |
| Comment-based help | `# .SYNOPSIS ...` | `docstring` |

### Relationships to Capture

| Edge | PS Example |
|------|------------|
| `calls` | `Get-Item` → cmdlet definition |
| `imports` | `. .\lib.ps1`, `Import-Module` |
| `defines` | `function X`, module export |
| `extends` | `class A : B` |
| `references` | Variable usage, type refs |

### Implementation

Add `tree-sitter-powershell` to the parser pipeline. Update config:

```json
{
  "include": ["**/*.ps1", "**/*.psm1", "**/*.psd1"],
  "languages": ["powershell", "typescript", "javascript", "go"]
}
```

### What NOT to Index

- Generated output (MOF, exported CSV/JSON >1MB)
- `node_modules/`, `.venv/`, `go/pkg/mod/`
- `bin/`, `obj/`, `dist/`, `build/`
- `.env`, `*.key`, `secrets/`, `*.log`

### Projected Size

| Metric | Current | With PS |
|--------|---------|---------|
| Files | 27 | ~560 |
| Nodes | 172 | 4,000–8,000 |
| Edges | 251 | 8,000–15,000 |
| DB | 1.1 MB | 5–15 MB |

SQLite handles this trivially.

---

## 3. System Health Verification

### Multi-Layer Architecture

| Layer | What to Check | PowerShell |
|-------|--------------|------------|
| Filesystem Integrity | Checksum verification (not just existence) | `Get-FileHash` on manifests |
| Dependency Graph | All transitive deps resolvable, no conflicts | `Get-Module -ListAvailable` + version pin |
| Runtime Health | PS version, execution policy, module load perf | `$PSVersionTable`, `Get-ExecutionPolicy` |
| Config Integrity | Schema validation of JSON configs | `Test-Json` with schema |
| State Consistency | Caches, temp dirs, lock files not stale | Age check on `.lock` files |
| Network Reachability | LLM endpoints responsive | `Test-NetConnection` + auth token |
| Permission Boundaries | Required ACLs on key paths | `Get-Acl` on scripts/, .opencode/ |
| Resource Pressure | Disk, memory, process count | `Get-CimInstance Win32_LogicalDisk` |

### Metrics to Track

- **Startup Latency** — cold/warm load time (target <500ms)
- **Module Load Time** — per-module import duration
- **API Round-Trip** — p50/p95/p99 via `Measure-Command`
- **Cache Hit Rate** — hits / total lookups
- **Error Rate** — failed commands / total per session
- **Process Leak Detection** — orphan PowerShell child processes
- **Schema Drift** — config version vs framework version

### Self-Healing Patterns

| Pattern | Trigger | Action |
|---------|---------|--------|
| Reinitialize | Config parse failure | Regenerate from defaults |
| Cache Rebuild | Stale/missing cache | Clear + rebuild incrementally |
| Dependency Repair | Missing module | `Install-Module -Force` |
| Temp Cleanup | Disk >90% or age >24h | `Remove-Item $tempDir\* -Recurse` |
| State Reconcile | Lock file from crashed session | Remove orphaned locks |
| Circuit Breaker | API latency >5s | Backoff 30s, degrade gracefully |

### Self-Diagnosis Phases

1. **Liveness** — PS version, module load, config parses
2. **Correctness** — checksums match, deps resolved, schema valid
3. **Performance** — timing metrics, memory, disk pressure
4. **Connectivity** — API endpoints, auth tokens, package feeds
5. **Auto-repair** — attempt fixes per failed check (with `-WhatIf`)

---

## 4. Norm Enforcement Automation

### Three-Layer Enforcement Model

```
Layer 1: Pre-hook validation (per-turn)
Layer 2: Autonomous enforcement agent (per-N-turns)
Layer 3: Post-hoc audit (session-end)
```

### Layer 1 — Pre-Hook Validation (`pre-process-input.ps1`)

Before every turn, scan input for violations:

| Rule ID | Pattern | Severity |
|---------|---------|----------|
| SEC-001 | Secrets/tokens/passwords in plan text | block |
| OPS-001 | Destructive commands (rm -rf, Remove-Item -Recurse) | warn |
| GIT-001 | Force push without approval | block |
| PERF-001 | Input exceeds 4000 tokens | warn + suggest compact |
| ARCH-001 | No SDD preflight before new feature | block |

### Layer 2 — Autonomous Enforcement Agent

Run every N turns (recommended: 5). Scan conversation + file changes against active NORMATIVAS files. Log violations, auto-fix where possible (e.g., missing docstrings, incorrect config props).

### Layer 3 — Session-End Audit

At session close, run `auto-norm-enforcer.ps1`:
- Report all violations by severity and category
- Generate `.session/norms-summary.json` for trend tracking
- Auto-update `LEARNED-NORMS.md` from patterns detected

### Mature Patterns from Industry

- **Cursor rules**: `.cursorrules` with pattern matching on file create/edit operations — auto-applied via language server hooks
- **Claude Code CLAUDE.md**: Best-practice documentation enforced by prompt injection at session start — violations are "remembered" across turns
- **Pre-commit hooks**: `lint-staged`, `husky` — gate on commit, not on write (industry consensus: catch early, but don't block flow)
- **Auto-norm learner**: Scan Engram for repeated violations, auto-create new NORMATIVAS entry

---

## 5. Optimization Stack Integrity

### Test Matrix (12 tests across 4 layers)

| Layer | Test | What It Verifies | Cadence |
|-------|------|-----------------|---------|
| **Token Compression** | Compression ratio ≥ 40% | Handoff/compact scripts still achieve target | Per-commit |
| | Semantic fidelity ≥ 0.85 | Compressed output preserves meaning (BLEU/ROUGE) | Per-commit |
| | Edge case: empty/trivial input | No crash on degenerate inputs | CI |
| **Caching** | Cache hit rate ≥ 80% | SHA256 TTL cache still effective | Per-commit |
| | TTL expiry behavior | Old entries evicted, fresh entries served | Weekly |
| | Eviction correctness | No stale data served after TTL | CI |
| **Model Routing** | Correct model per phase | SDD-design uses Sonnet, SDD-impl uses Haiku, etc. | Per-commit |
| | Fallback on 4xx/5xx | Graceful degrade when primary model unavailable | CI |
| | Cost limits respected | Per-phase budget not exceeded | Per-session |
| **Prompt Template** | Schema validation | All required fields present in rendered prompt | CI |
| | Snapshot match | Rendered output matches golden snapshot | Per-commit |
| | No template drift | Variables still resolved correctly | Weekly |

### Optimization Integrity Ratio (OIR)

Single metric to catch regressions:

```
OIR = (passing_tests / total_tests) * (compression_ratio / target_ratio) * (cache_hit_rate / target_hit_rate)
```

Target: OIR ≥ 0.85. Alert on OIR < 0.7.

### Implementation (Pester)

```powershell
Describe "TokenCompression" {
    It "compresses by at least 40%" {
        $result = & $handoffCompress -Input $testInput -PassThru
        $result.CompressionRatio | Should -BeGreaterOrEqual 0.40
    }
}
```

One file per concern under `tests/optimization/`.

---

## 6. Backup Strategy for AI Knowledge Bases

### Frequency

| Scenario | Frequency | Method |
|----------|-----------|--------|
| Active daily use | Per-session (auto) + end-of-session snapshot | Copy-on-write before save |
| Pre-destructive op | Immediate manual | Full backup |
| Idle/inactive | Weekly scheduled | Full backup |
| CI touching memory | Pre-deploy | Full backup |

### Format

**Primary**: Append-only NDJSON (newline-delimited JSON)

```
.backups/
├── engram/
│   ├── observations-20260530.ndjson
│   ├── relations-20260530.ndjson
│   └── sessions-20260530.ndjson
```

Why NDJSON beats monolithic JSON:
- Append-only — no rewrite on every write
- Line-based — `git diff` works, `Select-String` works per-line
- Partial restore — replay from line N, skip last M corrupted lines
- Compression ratio — same `.gz` ratio as monolithic

**Archive**: gzipped NDJSON (~10-15x reduction)

### Restore Test (Automated, Weekly)

```powershell
Function Test-BackupIntegrity {
    # 1. Validate each JSON line (ConvertFrom-Json in try/catch)
    # 2. Check referential integrity (all relation IDs exist)
    # 3. Count vs pre-backup manifest
    # 4. Simulate 3 queries: exact match, search, session replay
    # 5. Tag backup as "verified" or "corrupt"
}
```

### Disaster Recovery

Best pattern for JSON-based stores: **Git-based** (Pattern C)

```powershell
# Init git repo inside .engram-data/
git init
# Auto-commit on every mutation
git add . && git commit -m "mem: obs-42 topic_key=auth/model"
# Weekly compaction
git gc --aggressive
# Rollback = git revert or git checkout
```

Why Git fits:
- JSON text is git-friendly (diffs, compresses, merges)
- Zero extra infra — git is already present
- `git reflog` for fine-grained recovery
- Branching for experimental memory states

### Integrity Checks (in `mem_doctor`)

1. Parse all JSON — fail on malformed lines
2. Check for NaN/Infinity float values (common embedding corruption)
3. Verify timestamps in ascending order (append-only invariant)
4. Count observations vs manifest checksum
5. Verify no duplicate IDs

---

## Summary: Top-3 Quick Wins per Domain

| Domain | #1 | #2 | #3 |
|--------|----|----|----|
| Knowledge persistence | Add `topic_key` for upsert | Turn-threshold auto-saves (5 turn) | Relations table for conflict resolution |
| CodeGraph | Add PS parser to pipeline | Include `**/*.ps1` in config | Map PS-specific node kinds |
| Health verification | 5-phase self-diagnosis (liveness→repair) | Cache hit rate + API latency tracking | Self-healing for common failures |
| Norm enforcement | Pre-hook input validation (secrets, destructive) | Auto-enforcer every 5 turns | Session-end audit with trend tracking |
| Optimization integrity | 12-test matrix (Pester) + OIR metric | Compression ratio + cache hit rate as CI gates | Snapshot testing for prompt templates |
| Backup | Append-only NDJSON format | Git-based rollback (Pattern C) | Weekly automated restore test |

---

*Generated 2026-05-30 from web research across 6 domains. Each recommendation is sourced from proven production patterns in Claude Code, Cursor, Copilot, Mem0/Letta, Sourcegraph SCIP, and SRE practice.*
