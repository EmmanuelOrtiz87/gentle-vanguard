# OPS & DEVOPS — Consolidated Normatives

**Source files:** DEVOPS, OBSERVABILITY, DISASTER-RECOVERY, RESILIENCE, FALLBACK-STRATEGY,
INCIDENT-MANAGEMENT, OPTIMIZATION-STACK, TEAM-MODE

## CI/CD Pipeline (Source: NORMATIVAS-DEVOPS.md)

- Pipeline: Commit → Build → Test → Security → Deploy → Monitor
- Commit: dependency resolution, compilation, artifact creation
- Test: unit + integration + coverage (80% min); security: SAST + DAST + dependency scan
- Deploy: staging first, approval gate → production; immutable artifacts, blue-green

## Observability (Source: NORMATIVAS-OBSERVABILITY.md)

- Three pillars: logs (structured JSON, ELK/Splunk), traces (OpenTelemetry), metrics
  (Prometheus/Datadog)
- Log levels: DEBUG → INFO → WARN → ERROR → CRITICAL; every log = single JSON line
- Health check endpoint: `/health` returning component status + latency + version
- Dashboard: auto-refresh 30s, live-feed background, retention: logs 30d, traces 7d, metrics 90d

## Disaster Recovery (Source: NORMATIVAS-DISASTER-RECOVERY.md)

- RPO: 1h standard, 5min for configs/sessions; RTO: 4h; MTO: 8h
- T1 (Engram DB): post-session backup, 30d retention; T2 (configs): per-change, 90d
- DR test: quarterly restore drill; emergency restore: `restore-engram.ps1 -PointInTime <ISO8601>`

## Resilience (Source: NORMATIVAS-RESILIENCE.md)

- Retry with exponential backoff: Engram (3x, 500ms, 1.5x), Git (2x, 2s, 2x), API calls (3x, 1s, 2x)
- Timeout enforcement: every operation MUST have timeout; default 30s external, 15s internal
- Circuit breaker: 3 consecutive failures → open (30s cooldown) → half-open (1 probe) → closed

## Fallback Strategy (Source: NORMATIVAS-FALLBACK-STRATEGY.md)

- Default: clarify-ba — when no skill matches or confidence low, activate BA agent
- Timeout: escalate-orchestrator — re-route to orchestrator for re-delegation
- Degraded mode: reduce parallelism, disable non-critical skills, limit max tokens
- Graceful message: "I'm having trouble processing this. Let me try a different approach."

## Incident Management (Source: NORMATIVAS-INCIDENT-MANAGEMENT.md)

- Severity: P1 (15min response, 1hr mitigation), P2 (1hr/4hr), P3 (4hr/24hr), P4 (24hr/1wk)
- Lifecycle: DETECT → TRIAGE → CONTAIN → MITIGATE → RESOLVE → POST-MORTEM
- Post-mortem required for P1/P2 within 48h; blameless, action items tracked

## Optimization Stack (Source: NORMATIVA-OPTIMIZATION-STACK.md)

- CLAUDE.md ≤65 lines; SHA256 cache TTL ≤30min; pre-task compression ≥25%
- Token tracking per turn (`token-usage.json`); cache file ≤5MB (auto-clean weekly)
- Validation: `verify-optimization-stack.ps1` in health-check and CI

## Team Mode (Source: NORMATIVA-TEAM-MODE.md)

- `-MaxParallel` ≤ CPU cores; `-TimeoutSeconds` required (no orphan jobs)
- `-Synthesize` for cohesive output; logs in `.session/team-mode/` (no commit)
- Skills must exist in `.atl/skill-registry.md` and respond via MCP
