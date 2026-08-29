# 🔀 Adaptive Router Module Architecture

**Location:** `src/orchestration/adaptive-router/`  
**Barrel Entry:** `src/orchestration/adaptive-router.ts` (26 lines)  
**Status:** Core Orchestration  
**Lines:** 997 → 7 modules (F2.5 refactor)

---

## Overview

The Adaptive Router intelligently routes tasks to the best-fit agent based on task complexity, workload, agent performance, and learned delegation patterns. It replaces static agent assignment with ML-driven routing.

**Key Responsibility:** Dynamic task-to-agent matching with continuous performance optimization.

---

## Module Structure (7 modules)

```
adaptive-router/
├── types.ts             # TypeDefs: Task, Agent, Route, Score
├── config.ts            # Routing configuration + defaults
├── scoring.ts           # Score computation (complexity, agent fit)
├── routing-table.ts     # Persistent routing decisions + learning
├── seed-data.ts         # Default agent configurations (21 agents)
├── collect-feedback.ts  # Gather success/failure metrics
├── index.ts             # Main orchestration (26L)
└── README.md            # This file
```

---

## Routing Algorithm

```
Task Input
  ↓
[scoring.ts] Compute Score:
  - Complexity (lines, cyclomatic, external deps) → 0-100
  - Agent fit (skills, past success) → 0-100
  - Workload (current queue depth) → penalty 0-50
  - Priority (user-requested agent?) → boost 0-100
  ↓
[routing-table.ts] Lookup learned routes:
  - Check if task signature seen before
  - Recall best historical agent
  ↓
[Decision]
  - If confident score: route to top agent
  - Otherwise: try agent 1, 2, 3 with fallback
  - If all fail: escalate to human
```

---

## Task Complexity Signals

| Signal | Weight | Source |
|--------|--------|--------|
| LOC (lines of code) | 15% | Code analysis |
| Cyclomatic complexity | 20% | AST parsing |
| External dependencies | 15% | Dependency graph |
| File count | 10% | glob analysis |
| Test coverage gap | 15% | Coverage report |
| Prior success rate | 25% | Routing table history |

**Result:** Complexity score 0-100

---

## Agent Profiles (21 built-in)

**Core Agents:**
1. `explore` - Codebase research & discovery
2. `task` - Execute commands (build, test, lint)
3. `general-purpose` - Full-capability multi-step
4. `code-review` - Read-only analysis
5. `research` - External research & verification
6. `security-review` - Security vulnerability hunting

**Specialized Agents:**
7. `frontend-design` - React/UI/CSS
8. `backend-api` - Node/Express/gRPC
9. `database-expert` - SQL/migrations
10. `devops-engineer` - CI/CD/infrastructure
11. `performance-tuning` - Optimization
12. `documentation-writer` - Docs & ADRs
13-21. ... (skill-specific, role-based)

---

## Routing Table

**File:** `.session/routing/routing-table.json`

```json
{
  "routes": [
    {
      "id": "route-001",
      "taskSignature": "code-review:typescript:150-500",
      "agents": [
        { "agentId": "code-review", "score": 95, "successRate": 0.98, "attempts": 50 },
        { "agentId": "general-purpose", "score": 72, "successRate": 0.85, "attempts": 10 }
      ],
      "lastUsed": "2026-08-29T10:30:00Z",
      "successCount": 49,
      "failureCount": 1
    }
  ],
  "learningStats": {
    "totalRoutings": 1250,
    "accuracyScore": 0.92,
    "autoEscalations": 23
  }
}
```

---

## Scoring Breakdown

```typescript
import { computeScore } from './adaptive-router/scoring';

const score = computeScore({
  task: {
    type: 'code-review',
    lines: 350,
    complexity: 8,
    externalDeps: ['axios', 'lodash'],
    fileCount: 12,
    testGap: 15
  },
  agentProfile: {
    id: 'code-review',
    skills: ['typescript', 'testing', 'performance'],
    successRate: 0.94,
    avgComplexityHandled: 6.5
  },
  workload: {
    queueDepth: 2,
    currentMemory: 850,
    maxMemory: 2000
  }
});

// Returns: { score: 87, reasoning: "Good fit, moderate workload" }
```

---

## Learning Feedback Loop

```
Task Executed by Agent
  ↓
[collect-feedback.ts] Gather:
  - Success/failure
  - Time taken
  - Resource usage
  - Human feedback (if reviewed)
  ↓
[routing-table.ts] Update:
  - Success count ↑
  - Average latency updated
  - Success rate recalculated
  ↓
Next similar task uses updated routing
```

---

## Configuration

**File:** `config/model-router.json`

```json
{
  "routing": {
    "strategy": "ml-adaptive",  // "static", "round-robin", "ml-adaptive"
    "confidence_threshold": 0.75,
    "auto_escalation_threshold": 0.40,
    "learning_enabled": true
  },
  "agents": [
    {
      "id": "explore",
      "skills": ["research", "discovery", "architecture"],
      "maxConcurrent": 3,
      "timeoutMs": 600000
    }
  ],
  "thresholds": {
    "complexityHigh": 70,
    "complexityMedium": 40,
    "complexityLow": 0
  }
}
```

---

## Usage

### Programmatic

```typescript
import { route } from './src/orchestration/adaptive-router';

const result = await route({
  type: 'code-review',
  description: 'Review PR for security issues',
  codeLines: 350,
  priority: 'high'
});

console.log(`Routed to: ${result.agent}`);
console.log(`Confidence: ${result.confidence}`);
```

### CLI

```bash
# Test routing (dry-run)
npm run route:test --type "code-review" --lines 500

# View routing table
npm run route:table

# View routing stats
npm run route:stats

# Reset routing (learn from scratch)
npm run route:reset
```

---

## Performance Metrics

| Metric | Target |
|--------|--------|
| Routing decision latency | <50ms |
| Learning update latency | <100ms |
| Routing accuracy | >90% |
| Success rate of recommendations | >85% |
| Escalation rate | <5% |

---

## Integration Points

**Input:**
- Task description + metadata
- Code analysis (complexity, lines, deps)
- Agent workload (queue depth, memory)
- Session history

**Output:**
- Recommended agent + confidence
- Alternative agents (fallback chain)
- Routing decision → logging/audit

**Feedback Loop:**
- Task success/failure
- Agent metrics (time, resources)
- Human feedback (preferred agent)

---

## Test Coverage

**Location:** `tests/unit/adaptive-router/`
- `scoring.test.ts` - Score computation accuracy
- `routing-table.test.ts` - Persistence & learning
- `integration.test.ts` - End-to-end routing
- `performance.test.ts` - Latency benchmarks

**Target:** 85%+ coverage

---

## Troubleshooting

**Q: Routing decisions are poor**
```bash
npm run route:reset
npm run route:retrain
# Trains on last 1000 successful routes
```

**Q: Specific task type always fails**
```bash
npm run route:stats --type "task-type"
# Shows success rate by agent
```

**Q: Route escalation rate high**
```bash
# Increase confidence threshold:
npm run config:update -- --key routing.confidence_threshold --value 0.50
```

---

## Future Enhancements

- Multi-turn agent assignment (reassign if agent struggles)
- Cost-based routing (token budget optimization)
- Geographic routing (latency-aware)
- Team preference learning (human hints)
- Real-time workload balancing

---

**See:** `docs/modules/MODULE-STRUCTURE.md`  
**Configuration:** `config/model-router.json`  
**Tests:** `tests/unit/adaptive-router/*.test.ts`

