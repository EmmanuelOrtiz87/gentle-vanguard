# Token Budget Policy

**Version:** 1.0.0 | **Date:** 2026-07-04 | **Status:** Active

## Purpose

Define token consumption limits and cost controls for all AI agent operations in Gentle-Vanguard.
Enforces budget discipline while maintaining quality output.

---

## Token Cost Reference (2026)

| Model             | Input $/1M | Output $/1M | Best For                        |
| ----------------- | ---------- | ----------- | ------------------------------- |
| GPT-4o            | $2.50      | $10.00      | Complex reasoning, architecture |
| Claude 3.5 Sonnet | $3.00      | $15.00      | Code generation, analysis       |
| GPT-4o-mini       | $0.15      | $0.60       | Simple tasks, formatting        |
| Claude 3 Haiku    | $0.25      | $1.25       | Quick lookups, validation       |
| Gemini 2.0 Flash  | $0.10      | $0.40       | Bulk processing, embedding      |

---

## Budget Limits

### Per-Task Limits

| Task Complexity           | Max Tokens | Max Cost | Model Tier    |
| ------------------------- | ---------- | -------- | ------------- |
| Trivial (typo, rename)    | 2,000      | $0.02    | Mini/Haiku    |
| Simple (1-3 files)        | 8,000      | $0.08    | Mini/Sonnet   |
| Medium (multi-file)       | 20,000     | $0.20    | Sonnet        |
| Complex (architecture)    | 50,000     | $0.50    | GPT-4o/Sonnet |
| Critical (security, data) | 80,000     | $0.80    | GPT-4o        |

### Per-Agent Daily Limits

| Agent Type | Daily Token Limit | Daily Cost Limit |
| ---------- | ----------------- | ---------------- |
| BA/Explore | 50,000            | $0.50            |
| SAD/Design | 80,000            | $0.80            |
| DEV/Apply  | 100,000           | $1.00            |
| QA/Verify  | 40,000            | $0.40            |
| OPS        | 30,000            | $0.30            |
| GOV        | 20,000            | $0.20            |
| Self-Diag  | 15,000            | $0.15            |

### Session Limits

| Metric                     | Limit   | Action on Exceed                    |
| -------------------------- | ------- | ----------------------------------- |
| Total session tokens       | 500,000 | Warn, then pause non-critical       |
| Total session cost         | $5.00   | Alert, require approval to continue |
| Context window utilization | 80%     | Trigger compaction                  |
| Conversation turns         | 50      | Force summary + new thread          |

---

## Model Selection Rules

### Decision Tree

```
Is the task trivial (typo, rename, single line)?
  → YES: Use GPT-4o-mini or Claude 3 Haiku
  → NO: Continue

Is the task primarily code generation or analysis?
  → YES: Use Claude 3.5 Sonnet (best code quality)
  → NO: Continue

Is the task architectural or security-critical?
  → YES: Use GPT-4o (best reasoning)
  → NO: Continue

Is the task bulk processing (>10 items)?
  → YES: Use Gemini 2.0 Flash (cheapest)
  → NO: Use Claude 3.5 Sonnet (default)
```

### Forbidden Patterns

1. **No GPT-4o for formatting tasks** — Use mini/Haiku
2. **No Sonnet for simple lookups** — Use mini/Haiku
3. **No repeated context loading** — Cache and reuse
4. **No unbounded generation** — Always set max_tokens

---

## Cost Optimization Strategies

| Strategy                   | Savings | Quality Impact | Implementation           |
| -------------------------- | ------- | -------------- | ------------------------ |
| Shorter system prompts     | 15-30%  | Low            | Review prompts monthly   |
| Context compression        | 20-40%  | Medium         | Compaction at 80% window |
| Model routing (easy→cheap) | 40-60%  | Low            | Decision tree above      |
| Fewer reasoning steps      | 10-25%  | Medium         | Limit chain-of-thought   |
| Response caching (SHA256)  | 5-15%   | None           | 30min TTL cache          |
| Limit conversation history | 30-50%  | Low            | Keep 10 turns max        |

---

## Alerting Rules

| Condition                 | Severity | Action                        |
| ------------------------- | -------- | ----------------------------- |
| Agent exceeds daily limit | WARNING  | Log, notify in next response  |
| Session exceeds $5.00     | CRITICAL | Pause, require human approval |
| Context window > 80%      | WARNING  | Auto-compact old turns        |
| Cost spike (>2x average)  | WARNING  | Investigate agent behavior    |
| Runaway token usage       | CRITICAL | Kill agent task immediately   |

---

## Monitoring & Reporting

### Daily Report (auto-generated)

```
Token Budget Daily Report — {date}
─────────────────────────────────
Total Tokens: {total} / {limit} ({percent}%)
Total Cost: ${cost} / ${limit}
Top Agent: {agent} ({tokens} tokens)
Cache Hit Rate: {rate}%
Model Distribution: {model_breakdown}
```

### Weekly Rollup

- Week-over-week cost trend
- Agent efficiency ranking
- Model selection accuracy
- Optimization opportunities identified

---

## Enforcement

1. **Pre-response hook** validates token count before sending
2. **Token-budget-guard.ps1** tracks consumption in real-time
3. **Session-autostart** initializes daily counters
4. **Session-close** generates daily report
5. **Watchtower** checks budget health weekly

---

## Related Files

- `scripts/utilities/telemetry/TELEMETRY-METRICS/token-budget-guard.ps1`
- `config/session-autostart.config.json`
- `rules/NORMATIVAS-PERFORMANCE.md`
- `rules/CONTEXT-ENGINEERING.md`
