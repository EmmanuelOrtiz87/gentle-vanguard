# Gentle-Vanguard Production Runbook

**Version:** 4.0. **Last Updated:** 2026-06-19

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Load Balancer                      │
├─────────────┬───────────────────┬───────────────────┤
│  Dashboard  │   WebSocket WS    │     MCP Server    │
│  (port 80)  │   (port 8081)     │    (port 3001)    │
├─────────────┴───────────────────┴───────────────────┤
│               Observability Stack                    │
│  Jaeger :16686  │  Prometheus :9091  │  OTel :4317   │
└─────────────────────────────────────────────────────┘
```

## Deployment

### Docker Compose (dev/staging)

```bash
docker compose up -d
```

### Kubernetes (production)

```bash
kubectl apply -f config/k8s/gentle-vanguard-deployment.yml
kubectl get pods -n gentle-vanguard
kubectl get svc -n gentle-vanguard
```

## Health Checks

| Service    | Endpoint      | Expected | Interval |
| ---------- | ------------- | -------- | -------- |
| Dashboard  | `/api/health` | 200      | 30s      |
| WebSocket  | `/api/health` | 200      | 30s      |
| MCP Server | `/health`     | 200      | 30s      |
| Jaeger     | `:16686`      | UI loads | 60s      |
| Prometheus | `:9090/graph` | UI loads | 60s      |

## Start/Stop

### Start sequence

1. Start Jaeger + Prometheus + OTel Collector
2. Start MCP server (depends on nothing)
3. Start WebSocket server (depends on MCP)
4. Start Dashboard (depends on MCP)

### Stop sequence

1. Stop Dashboard
2. Stop WebSocket server
3. Stop MCP server
4. Stop observability stack

## Alerts (Dashboard)

| Rule             | Condition                 | Severity | Action       |
| ---------------- | ------------------------- | -------- | ------------ |
| High error rate  | >5% errors in 5min window | CRITICAL | Page on-call |
| Budget exceeded  | >90% token budget         | HIGH     | Notify admin |
| Slow dispatch    | >1s avg dispatch latency  | WARN     | Log          |
| Circuit breaker  | OPEN state >60s           | CRITICAL | Restart      |
| Cloud cost spike | >$0.01 in 1h              | WARN     | Notify       |

## Recovery

### MCP Bridge Failure

```TypeScript
npx tsx src/cli/gv.ts -SkillId __healthcheck__ -InvocationType DryRun
# If this fails, restart MCP:
docker compose restart mcp-server
```

### Checkpoint Rollback

```TypeScript
npx tsx src/cli/gv.ts -Action list
npx tsx src/cli/gv.ts -CheckpointId ckpt-20260619-103000 -DryRun
npx tsx src/cli/gv.ts -CheckpointId ckpt-20260619-103000 -AutoBackup
```

### Dashboard WS Recovery

```TypeScript
# Check watchdog
Get-Content .runtime/dashboard-ws.log -Tail 5
# Restart
npx tsx src/dashboard-stop.ts
npx tsx src/dashboard-start.ts
```

## Data Persistence

| Data          | Location                      | Retention | Backup                 |
| ------------- | ----------------------------- | --------- | ---------------------- |
| Session state | `.session/`                   | 72h       | Checkpoint snapshots   |
| Event store   | `.session/event-store/`       | 90d       | JSONL files            |
| Audit logs    | `.session/audit/`             | 90d       | Archive after rotation |
| Cloud metrics | `.session/cloud-metrics.json` | 30d       | In checkpoint          |
| Traces        | `.telemetry/traces/`          | 14d       | OTel collector export  |

## Monitoring Commands

```TypeScript
# System health
npx tsx src/maintenance-watchtower.ts --action health

# Session quality
npx tsx src/session-scoring.ts -Action report

# Cloud metrics
Get-Content .session/cloud-metrics.json | ConvertFrom-Json | Select-Object -ExpandProperty stats

# Audit trail
npx tsx src/audit-pipeline.ts -Action query -EventType correction -LastHour

# Checkpoint list
npx tsx src/checkpoint-manager.ts list

# Auto-correction rules
npx tsx src/correction-rules-engine.ts -Mode report

# Tracing export
npx tsx src/tracing-instrument.ts -Action export
```

## Troubleshooting

| Symptom                    | Likely Cause              | Check                                     |
| -------------------------- | ------------------------- | ----------------------------------------- |
| Dashboard shows no data    | WS server down            | `Test-NetConnection localhost:8081`       |
| Cloud routing always fails | Circuit breaker OPEN      | `Get-Content .session/cloud-metrics.json` |
| Checkpoints not created    | Disk space                | `Get-PSDrive C`                           |
| Audit pipeline silent      | Missing `.session/audit/` | `Test-Path .session/audit/`               |
| OTel traces not in Jaeger  | Collector not running     | `curl localhost:4318`                     |
| Saga stuck in 'running'    | Process killed mid-step   | Check `$saga.status`                      |
