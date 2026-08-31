# ConfigService + DI Container (F2.6, phase 1)

Typed, zod-validated access to startup-critical environment configuration, plus a
minimal factory-based DI container. No framework, no full refactor — incremental
per `docs/plans/STACK-EVOLUTION-PLAN-2026.md` item F2.6.

## ConfigService — `src/config/config-service.ts`

Centralizes the ~30 env vars that matter at startup (paths, ports, session
identity, tenant, model selection, runtime flags, optional cloud hooks). The
other ~220 `process.env` usages in `src/` are unchanged and migrate in later
batches.

```ts
import { getConfigService } from './config/config-service.js';

const cfg = getConfigService();
const result = cfg.validate();            // { ok, issues[], summary }
if (!result.ok) LOG.warn(`[CONFIG] ${result.summary}`);

cfg.get('PORT');                          // 3000 (default) — typed, coerced
cfg.get('NODE_ENV');                      // 'development' | 'test' | 'production'
cfg.get('GV_QUIET');                      // boolean
cfg.isSet('AGENT_MODEL');                 // true only if explicitly set
```

- **Local-first (ADR-0017)**: in `local` mode (default) nothing is
  hard-required — only malformed values (bad types) fail validation.
- **Strict mode** (`validate({ mode: 'strict' })`): enforces `STRICT_REQUIRED`
  (cloud webhook vars) — reserved for cloud promotion, never local startup.
- Empty/whitespace strings count as unset; defaults are documented in
  `configEnvSchema`.
- Singleton: `getConfigService()` / `resetConfigService()`.
- Tests: `createTestConfig({ PORT: '8080' })` builds an isolated service — no
  process.env mutation, no singleton hacks.

Wired into `src/core/session-autostart.ts` `main()`: validation runs right after
the banner and logs an INFO (ok) or WARN (issues) summary.

## DI Container — `src/core/container.ts`

```ts
import { createContainer, createAppContainer } from './core/container.js';

const c = createAppContainer();
const cfg = c.resolve('config');                 // ConfigService singleton
const guard = c.resolve('tokenBudgetGuard');     // { check(task, risk, chars) }
const database = c.resolve('db');                // DatabaseManager via src/database/db.ts
```

- Lazy factories, memoized per container, circular-dependency detection,
  duplicate-registration guard, `registerValue` for prebuilt instances.
- Each test creates its own container — isolation by construction.

### Pilot consumers (this batch)

| Key                | Factory                                            |
| ------------------ | -------------------------------------------------- |
| `config`           | `getConfigService()`                               |
| `db`               | `db()` (src/database/db.ts re-export)              |
| `tokenBudgetGuard` | thin wrapper over `runGuard` from token-budget-guard |

### Remaining singletons to migrate in later batches

- `src/database/db-init.ts`
- `src/tokens/token-tracker.ts`
- `src/skills/skill-usage-tracker.ts`
- `src/monitor/performance-slo-monitor.ts`
- `src/orchestration/adaptive-router/index.ts`
- `src/resilience/error-memory.ts`
- `src/resilience/post-mortem-trigger.ts`
- `src/review/result-gatekeeper.ts`
- `src/core/session-metrics-tracker.ts`
- `src/tools/event-sourcing.ts`
- `src/cli/backlog.ts`

Wire them incrementally (one consumer per batch) — do not refactor all at once.

## Tests

`npx tsx --test tests/unit/config-service.test.ts tests/unit/container.test.ts`
