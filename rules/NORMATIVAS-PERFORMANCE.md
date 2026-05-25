# NORMATIVAS-PERFORMANCE.md — Performance & Efficiency Standards

Version: 1.1.0 Last updated: 2026-05-24 Framework: SLO-based performance governance + token
efficiency 2026 best practices

---

## 1. PROPOSITO

Define performance budgets, SLOs, y estándares de eficiencia para todo el stack Gentle-Vanguard.
Aplica a scripts, configuraciones, agentes AI, y pipelines CI/CD.

---

## 2. SERVICE LEVEL OBJECTIVES (SLOs)

### 2.1 Agent Performance

| Metric                 | Target  | Warning    | Critical | Measurement           |
| ---------------------- | ------- | ---------- | -------- | --------------------- |
| Agent dispatch time    | < 500ms | 500-1000ms | > 1000ms | `metrics-config.json` |
| Skill load time        | < 2s    | 2-5s       | > 5s     | `orchestrator.json`   |
| Agent task completion  | < 30s   | 30-60s     | > 60s    | Delegation metrics    |
| Circuit breaker uptime | 100%    | < 99%      | < 95%    | Circuit breaker state |

### 2.2 Latency Optimization Achievements (2026-05-24)

| Area                         | Before                     | After                        | Savings      | Technique                                                     |
| ---------------------------- | -------------------------- | ---------------------------- | ------------ | ------------------------------------------------------------- |
| `pre-process-input.ps1`      | ~2.6s                      | ~1.7s (cache hit)            | -33-41%      | SHA256 response cache, TTL 30min, prune >1hr                  |
| Autostart pipeline           | ~64s (24 steps, Start-Job) | ~60s (18+6 lazy, in-process) | -6% + ~400ms | Remove Start-Job → `&` directo; lazy loading 6 steps          |
| pwsh process overhead        | ~1.3s per cold start       | ~400ms subsequent            | -69%         | Keep scripts in-process, avoid Start-Job for autostart        |
| Skill loading (86 oversized) | 86 warnings                | 0 warnings                   | -100%        | Split oversized skills, move detail to `references/detail.md` |
| CodeGraph sync on hooks      | Always sync                | Conditional sync             | Variable     | Freshness check via max(WAL, SHM, DB) timestamps in WAL mode  |

### 2.3 Script Performance

| Script Type         | Max Execution | Warning | Critical |
| ------------------- | ------------- | ------- | -------- |
| Interactive (CLI)   | < 2s          | 2-5s    | > 5s     |
| CI/CD step          | < 30s         | 30-60s  | > 60s    |
| Pre-commit hook     | < 5s          | 5-15s   | > 15s    |
| Pre-push hook       | < 60s         | 60-120s | > 120s   |
| Audit sweep (quick) | < 30s         | 30-60s  | > 60s    |
| Audit sweep (full)  | < 5min        | 5-10min | > 10min  |

### 2.3 Token Efficiency

| Metric                    | Target | Warning   | Critical |
| ------------------------- | ------ | --------- | -------- |
| Tokens per session        | < 30K  | 30-50K    | > 50K    |
| Tokens per agent dispatch | < 750  | 750-1500  | > 1500   |
| Daily token budget        | < 30K  | 30-50K    | > 50K    |
| Context compression ratio | > 0.85 | 0.70-0.85 | < 0.70   |

Source: `config/orchestrator.json#subagent_orchestration.token_budget_guard`

---

## 3. PERFORMANCE BUDGETS

### 3.1 Script Optimization Rules

1. **MUST** use `$null` assignment over `| Out-Null` for suppressing output

   ```powershell
   # GOOD: $null = $collection.Add($item)
   # BAD:  $collection.Add($item) | Out-Null
   ```

2. **MUST** use `[void]` cast for return value suppression

   ```powershell
   # GOOD: [void]$collection.Add($item)
   ```

3. **MUST** avoid pipeline for performance-critical loops

   ```powershell
   # GOOD: foreach ($item in $collection) { ... }
   # BAD:  $collection | ForEach-Object { ... }
   ```

4. **MUST** use `-Filter` over `-Include` for `Get-ChildItem`

   ```powershell
   # GOOD: Get-ChildItem -Path $path -Filter "*.ps1"
   # BAD:  Get-ChildItem -Path $path -Include "*.ps1"
   ```

5. **SHOULD** use `System.Collections.ArrayList` over `[array]` for large collections
6. **SHOULD** use `Set-StrictMode -Version Latest` in all scripts
7. **SHOULD** avoid repeated `Get-Content` calls (cache in variable)

### 3.2 Token Optimization

1. **MUST** call `scripts/utilities/token-guard.ps1` before agent dispatch
2. **MUST** use `scripts/utilities/handoff-compress.ps1` for agent-to-agent handoffs
3. **MUST** apply context compression when session exceeds 25K tokens
4. **SHOULD** use cheaper models (gpt-4o-mini) for integration tests
5. **SHOULD** enable `setCacheKey: true` for caching (already configured)
6. **SHOULD** use temperature 0.15-0.3 for deterministic agent output

### 3.3 CI/CD Optimization

1. **MUST** use `concurrency` control to cancel redundant runs (already configured)
2. **MUST** set `timeout-minutes` on every job (already configured)
3. **SHOULD** run fast feedback pipelines on PR (unit tests, lint)
4. **SHOULD** run full regression on merge to develop/main
5. **SHOULD** parallelize independent test stages

---

### 3.4 Response Cache Standards

1. **MUST** use SHA256 hash of `$UserInput` as cache key
2. **MUST** enforce TTL ≤ 30min for cached responses
3. **MUST** prune entries older than 1hr on every write
4. **SHOULD** implement cache in `pre-process-input.ps1` — READ at top, WRITE at end
5. **SHOULD** support `-DisableCache` flag for bypass
6. **SHOULD** use `[System.Collections.ArrayList]` to capture output for caching (avoid intercepting
   `Write-Output`)

### 3.5 Process Startup Optimization

1. **MUST NOT** use `Start-Job` for autostart pipeline — use `&` directo in-process (ahorra ~400ms)
2. **SHOULD** mark non-critical autostart steps as `"lazy": true` in `session-autostart.config.json`
   — ejecutan post-pipeline sin sumar latencia al startup percibido
3. **SHOULD** reduce pipeline steps from 24 to 18 (main) + 6 (lazy)

## 4. SCRIPT PERFORMANCE PATTERNS

### 4.1 PowerShell Performance Anti-Patterns

| Anti-Pattern                  | Impact                 | Fix                        |
| ----------------------------- | ---------------------- | -------------------------- | --------------------- |
| `                             | Out-Null` in loops     | 10-50x slower              | `$null =` or `[void]` |
| `Write-Host` for output       | Slower + stream issues | `Write-Output` or `return` |
| `Get-ChildItem -Include`      | 2-5x slower            | `-Filter` instead          |
| Pipeline `%` in loops         | 5-10x slower           | `foreach` statement        |
| Repeated file reads           | N x slower             | Cache in variable          |
| `Select-Object -Last 1`       | Full enumeration       | Use index `[-1]`           |
| `Where-Object` for small sets | Overhead               | Use `if` in `foreach`      |

### 4.2 PowerShell Performance Patterns

```powershell
# Fast collection building
$list = [System.Collections.ArrayList]::new()
foreach ($item in $source) {
    $null = $list.Add($item)
}

# Fast string building
$sb = [System.Text.StringBuilder]::new()
foreach ($part in $parts) {
    $null = $sb.Append($part)
}
$result = $sb.ToString()

# Fast file reading
$content = Get-Content -Path $path -Raw  # Single read vs line-by-line
```

---

## 5. TOKEN BUDGET GOVERNANCE

### 5.1 Daily Budget Enforcement

```powershell
# Enforced by: scripts/utilities/token-guard.ps1
# Config: config/orchestrator.json#subagent_orchestration.token_budget_guard

$dailyBudget = 30000  # tokens
$softThreshold = 0.70  # 21K tokens → WARN
$hardThreshold = 0.90  # 27K tokens → BLOCK
```

### 5.2 Per-Agent Budget

| Agent   | Budget (tokens) | Notes                         |
| ------- | --------------- | ----------------------------- |
| DEV     | 750             | Implementation tasks          |
| QA      | 750             | Testing tasks                 |
| GOV     | 500             | Governance review             |
| SESSION | 300             | Session mgmt (lightweight)    |
| DOC     | 500             | Documentation                 |
| BA/SAD  | 1000            | Analysis (needs more context) |

---

## 6. COMPLIANCE CHECKPOINTS

TODO implementación DEBE verificar:

1. No `| Out-Null` in loops (critical performance bug)
2. No `Get-ChildItem -Include` without reason documented
3. No pipeline `%` in performance-critical paths
4. Token budget respected per agent dispatch
5. Context compression applied before compaction
6. CI/CD jobs have explicit `timeout-minutes`

---

## 7. REFERENCES

| Resource              | Path                                     |
| --------------------- | ---------------------------------------- |
| Orchestrator Config   | `config/orchestrator.json`               |
| Development Standards | `rules/DEVELOPMENT-STANDARDS.md`         |
| Code Standards        | `rules/NORMATIVAS-CODIGO.md`             |
| Error Handling        | `rules/NORMATIVAS-ERROR-HANDLING.md`     |
| Token Guard Script    | `scripts/utilities/token-guard.ps1`      |
| Handoff Compression   | `scripts/utilities/handoff-compress.ps1` |
| AI Normatives         | `rules/AI-NORMATIVES.md`                 |
| Session Lifecycle     | `rules/NORMATIVAS-SESSION.md`            |
| Quality Gates         | `config/quality-gates.json`              |
| Testing Policy        | `config/testing-policy.json`             |

---

_Version: 1.0.0 — 2026-05-10 — Status: ACTIVE_
