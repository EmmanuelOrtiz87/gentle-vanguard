---
name: observability
description:
  Three-tier observability stack: circuit breaker health gates, dynamic dependency graph discovery,
  and auto-escalation with warning→critical→emergency levels.
triggers:
  - observability
  - circuit-breaker
  - dependency-graph
  - escalation
  - health
  - monitoring
---

# Observability Stack

Three complementary modules in `src/` for system health, dependency mapping, and automated incident response.

## Circuit Breaker API (`src/circuit-breaker-api.ts`)

Prevents cascading failures by gating operations behind health checks.

| State | Meaning |
|-------|---------|
| `CLOSED` | Normal operation |
| `OPEN` | Threshold exceeded (default: 5 failures) — rejected |
| `HALF_OPEN` | Timeout elapsed (default: 30s) — trial request allowed |

```typescript
import { registerComponent, recordSuccess, recordFailure, isComponentHealthy } from './circuit-breaker-api';

registerComponent({ name: 'ml-embeddings', threshold: 3, timeoutMs: 15000 });
if (isComponentHealthy('ml-embeddings')) {
  // proceed
  recordSuccess('ml-embeddings');
} else {
  recordFailure('ml-embeddings');
  // fallback
}
```

## Dynamic Dependency Graph (`src/dynamic-dependency-graph.ts`)

Scans `config/session-autostart.config.json` to auto-discover component relationships.

```typescript
import { scanDependencies, getAffectedComponents, getComponentDependencies } from './dynamic-dependency-graph';

scanDependencies();
const downstream = getAffectedComponents('dashboard-ws-start');
const upstream = getComponentDependencies('ml-embeddings');
```

## Auto-Escalation (`src/auto-escalation.ts`)

Escalates when auto-heal fails repeatedly across three tiers.

| Count | Level | Action |
|-------|-------|--------|
| 3 | `warning` | Log to audit |
| 5 | `critical` | Create incident in event store |
| 10 | `emergency` | Record in findings ledger + halt component |

```typescript
import { escalate, clearHistory, getEscalationStatus } from './auto-escalation';

escalate('ml-embeddings', 'Auto-heal failed 3 times', 'OPEN');
const status = getEscalationStatus(); // { components, activeEscalations }
clearHistory('ml-embeddings');        // Reset failure count
```

## CLI Commands

```bash
npx tsx src/circuit-breaker-api.ts status
npx tsx src/dynamic-dependency-graph.ts scan
npx tsx src/auto-escalation.ts status
```
