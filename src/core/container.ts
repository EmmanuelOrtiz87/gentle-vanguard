/**
 * Minimal DI container (STACK-EVOLUTION-PLAN F2.6) — factories, no framework.
 *
 * Pilot wiring (this batch): ConfigService, token budget guard, database (db()).
 * Remaining singletons to migrate in later batches:
 *   - src/database/db-init.ts            (getInstance)
 *   - src/tokens/token-tracker.ts        (getInstance)
 *   - src/skills/skill-usage-tracker.ts  (getInstance)
 *   - src/monitor/performance-slo-monitor.ts (getInstance)
 *   - src/orchestration/adaptive-router/index.ts (getInstance)
 *   - src/resilience/error-memory.ts     (getInstance)
 *   - src/resilience/post-mortem-trigger.ts (getInstance)
 *   - src/review/result-gatekeeper.ts    (getInstance)
 *   - src/core/session-metrics-tracker.ts (getInstance)
 *   - src/tools/event-sourcing.ts        (getInstance)
 *   - src/cli/backlog.ts                 (getInstance)
 * Do NOT refactor them all at once — wire incrementally per plan F2.6+.
 */
import { getConfigService, ConfigService } from '../config/config-service.js';
import { db } from '../database/db.js';
import { runGuard } from '../tokens/token-budget-guard.js';

export interface Container {
  /** Register a lazy factory. Factories run at most once per container. */
  register<T>(key: string, factory: (c: Container) => T): void;
  /** Register an already-built value (still resolvable via factories' `c`). */
  registerValue<T>(key: string, value: T): void;
  /** Resolve (memoized). Throws on unknown key or re-entrant resolution. */
  resolve<T>(key: string): T;
  has(key: string): boolean;
  /** Keys registered so far (diagnostics/tests). */
  keys(): string[];
}

export function createContainer(): Container {
  const factories = new Map<string, (c: Container) => unknown>();
  const instances = new Map<string, unknown>();
  const resolving = new Set<string>();

  const c: Container = {
    register(key, factory) {
      if (factories.has(key) || instances.has(key)) {
        throw new Error(`container: key already registered: ${key}`);
      }
      factories.set(key, factory);
    },
    registerValue(key, value) {
      if (factories.has(key) || instances.has(key)) {
        throw new Error(`container: key already registered: ${key}`);
      }
      instances.set(key, value);
    },
    resolve(key) {
      if (instances.has(key)) return instances.get(key) as never;
      const factory = factories.get(key);
      if (!factory) throw new Error(`container: nothing registered for key: ${key}`);
      if (resolving.has(key)) {
        throw new Error(`container: circular dependency detected at key: ${key}`);
      }
      resolving.add(key);
      try {
        const value = factory(c);
        instances.set(key, value);
        return value as never;
      } finally {
        resolving.delete(key);
      }
    },
    has(key) {
      return factories.has(key) || instances.has(key);
    },
    keys() {
      return [...new Set([...factories.keys(), ...instances.keys()])];
    },
  };

  return c;
}

/**
 * Default application container with the pilot registrations (F2.6).
 * Everything is lazy — constructing the container touches no filesystem.
 */
export function createAppContainer(): Container {
  const c = createContainer();
  c.register('config', () => getConfigService());
  c.register('db', (cc) => {
    // db() lazily imports the DatabaseManager singleton (apps/web-dashboard).
    void cc.resolve('config'); // demonstrate dependency resolution; kept side-effect free
    return db();
  });
  c.register('tokenBudgetGuard', (cc) => {
    const config = cc.resolve<ConfigService>('config');
    const quiet = config.get('GV_QUIET');
    return {
      check(task: string, risk: string, chars: number) {
        return runGuard({
          mode: 'pre-task',
          task,
          risk,
          chars,
          actualPrompt: 0,
          actualCompletion: 0,
          record: false,
          strict: false,
          asJson: true,
          quiet,
        });
      },
    };
  });
  return c;
}
