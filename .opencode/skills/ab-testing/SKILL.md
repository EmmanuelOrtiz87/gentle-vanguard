---
name: ab-testing
description:
  A/B experimentation framework for comparing configuration variants, routing strategies, and
  behavioral changes. Determines statistical winners with auto-rollback on degradation.
triggers:
  - ab-test
  - experiment
  - variant
  - a/b
  - split-test
---

# AB Testing Framework

`src/ab-testing-framework.ts` — stores experiments, assignments, and results in `.session/experiments/`.

## API Reference

| Function | Purpose |
|----------|---------|
| `createExperiment(config)` | Create a draft experiment with variants (traffic must sum to 100%) |
| `startExperiment(id)` | Move experiment from draft to running |
| `assignVariant(expId, sessionId)` | Weighted-random assignment, stable per session |
| `recordResult(expId, variantId, metrics)` | Record metric outcomes per variant |
| `evaluateExperiment(expId)` | Determine winner with significance check (effect > 5%) |
| `rollbackExperiment(expId)` | Halt and mark as rolled-back |

## Usage

```typescript
import { createExperiment, assignVariant, recordResult, evaluateExperiment } from './ab-testing-framework';

const exp = createExperiment({
  name: 'Routing strategy v2',
  variants: [
    { id: 'v1', name: 'Current', config: { strategy: 'latency' }, trafficPercent: 50 },
    { id: 'v2', name: 'Proposed', config: { strategy: 'cost-weighted' }, trafficPercent: 50 },
  ],
  targetMetric: 'avgLatency',
  minSampleSize: 100,
  significanceLevel: 0.95,
});

startExperiment(exp.id);
const variant = assignVariant(exp.id, 'session-123');
recordResult(exp.id, variant.id, { avgLatency: 142 });
const { winner, significant } = evaluateExperiment(exp.id);
if (winner && significant) console.log(`Winner: ${winner}`);
```

## CLI

```bash
npx tsx src/ab-testing-framework.ts list
npx tsx src/ab-testing-framework.ts evaluate <experiment-id>
```

## Integration with Session Scoring

Results from `evaluateExperiment()` feed into `session-scoring-autocompare.ts` via `.session/quality-trend.json`. Experiment wins that improve quality metrics are persisted in `contract_results` (Nexus table). Rolled-back experiments trigger an anomaly signal in the auto-escalation pipeline.
