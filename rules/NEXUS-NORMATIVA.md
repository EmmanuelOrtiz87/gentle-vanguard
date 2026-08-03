# NEXUS-NORMATIVA.md

## Identity

**Name:** Nexus
**Tagline:** El punto central donde converge toda la información operacional del stack.
**File:** `.runtime/gentle-vanguard.db`
**Type:** SQLite (WAL mode, foreign keys ON)
**Manager:** `DatabaseManager` (singleton en `apps/web-dashboard/server/database/manager.ts`)
**Nacimiento:** Wave 34 — creada como reemplazo ACID de la persistencia fragmentada en JSON

**¿Por qué Nexus?** — En la mitología, el Nexus es el centro del universo, el punto de conexión
entre todos los mundos. Esta base de datos es exactamente eso: el centro donde convergen métricas,
sesiones, trazas, eventos, alertas, feedback, caché, contratos, scoring y ruteo del stack
Gentle-Vanguard. No es un componente más — es el sistema nervioso central.

## Schema (12 tablas, 3 migraciones)

### Migration 001 — Initial Schema (Core operacional)

| Tabla               | Propósito                                              |
| ------------------- | ------------------------------------------------------ |
| `metric_snapshots`  | Time-series: tokens, sesiones, latencia, health cada 30s |
| `sessions`          | Historial de sesiones (upsert por session_id)           |
| `traces`            | Distributed tracing spans (árbol trace_id → span_id)   |
| `events`            | Event sourcing — append-only (type + JSON payload)     |
| `alerts`            | Evaluaciones de alertas (5s broadcast cycle)           |
| `feedback`          | User feedback thumbs up/down por span                  |

### Migration 002 — Stack Tables (Capa operacional extendida)

| Tabla               | Propósito                                              |
| ------------------- | ------------------------------------------------------ |
| `response_cache`    | SHA256 key → response (TTL-aware, hit_count tracking)  |
| `contract_results`  | SDD contract validation results (pass/fail/error)      |
| `skill_usage`       | Per-session skill usage tracking (count, tokens, cost) |
| `token_usage`       | Token accounting con columna generada `total_tokens`   |
| `routing_rules`     | Adaptive router persistence con hit_count              |

### Migration 003 — Session Scoring (Wave 37 E)

| Tabla               | Propósito                                              |
| ------------------- | ------------------------------------------------------ |
| `session_scoring`   | Quality scoring por sesión (delegations, corrections, proactive hits, cloud calls, checkpoints, tracing spans, audit events) |

## Ciclo de Vida

```
[Init] → [Backup] → [Health Check] → [Prune] → [Optimize] → [Restore if needed]
   ↑                                                                     |
   └────────────────────── Continuo ──────────────────────────────────────┘
```

### Init (`npm run db:init`)
- `src/database/db-init.ts` — lazy step en session-autostart
- Auto-crea `.runtime/` directory, instancia DatabaseManager singleton
- Corre todas las migraciones pendientes (idempotente)
- Output: tablas, rows, migrations, size

### Backup (`npm run db:backup`)
- `scripts/database/db-backup.ts` — backup via `.backup` CLI de sqlite3 (online safe)
- Destino: `.runtime/backups/gentle-vanguard_<timestamp>.db`
- Incluye manifest JSON con metadata
- Backup a directorio custom con `--dir <path>`

### Health Check (`npm run db:health`)
- `scripts/database/db-health.ts` — 6 checks en orden
- Checks: file existence → size → WAL/shm → PRAGMA integrity_check → tables/rows → migrations
- Output: `healthy | degraded | missing` con detalles
- Modo `--json` para consumo por other tools

### Prune (`npm run db:prune`)
- `scripts/database/db-prune.ts` — pruneAll() en DatabaseManager
- events > 30d, cache > 7d, token_usage > 90d, orphaned skill_usage
- housekeeping: metric_snapshots (keep 1000), alerts (keep 500), vacuum condicional

### Optimize (`npm run db:optimize`)
- WAL checkpoint TRUNCATE → REINDEX → VACUUM
- Recupera espacio en disco

### Restore (`npm run db:restore`)
- `scripts/database/db-backup.ts restore [latest|<name>]`
- Usa `.restore` CLI de sqlite3 (online safe)
- Si no hay backup, usar `npm run db:init` para regenerar desde cero

## Comandos Rápidos

| Comando              | Descripción                              |
| -------------------- | ---------------------------------------- |
| `npm run db:init`    | Init DB + migrations (idempotente)       |
| `npm run db:health`  | Health check completo (--json para CI)   |
| `npm run db:backup`  | Backup online a `.runtime/backups/`      |
| `npm run db:restore` | Restore latest backup                    |
| `npm run db:list`    | List available backups                   |
| `npm run db:optimize`| WAL checkpoint + REINDEX + VACUUM        |
| `npm run db:prune`   | Prune old data (events, cache, tokens)   |
| `npm run db:prune:backup`| Keep only 10 most recent backups      |

## Pipeline Integration

Todos los steps están en `config/session-autostart.config.json` como **lazy: true** (no bloquean):

| Step                | Script                             | Lazy | Propósito                          |
| ------------------- | ---------------------------------- | ---- | ---------------------------------- |
| `db-init`           | `src/database/db-init.ts`          | ✅   | Init + migrations cada sesión      |
| `db-health-check`   | `scripts/recovery/db-health-check.ts` | ✅ | Validate SQLite integrity          |
| `db-prune`          | `scripts/database/db-prune.ts`     | ✅   | Prune old data cada sesión         |

## Watchtower Monitoring

El componente `gentle-vanguard-db` en la watchtower (`src/core/maintenance-watchtower.ts`)
verifica en cada ciclo de auto-heal:

1. **database file** — existencia y tamaño
2. **WAL file** — tamaño (> 5MB = WARN)
3. **integrity check** — PRAGMA integrity_check (transient lock = WARN, corruption = FAIL)
4. **size** — conteo de tablas y rows

## Guardrails (Estabilidad, Escalabilidad, Eficacia, Eficiencia)

### Estabilidad
- **WAL mode** — lecturas no bloquean escrituras ni viceversa
- **Singleton** — DatabaseManager previene conexiones múltiples
- **Migration idempotente** — cada migration se aplica una sola vez
- **onStepFailure: continue** — si un step lazy falla, el pipeline continúa
- **Backup antes de restore** — siempre hay un punto de restauración

### Escalabilidad
- **Prune automático** — evita crecimiento infinito de tablas
- **Housekeeping** — metric_snapshots keep 1000, alerts keep 500
- **Cache TTL** — response_cache con expiración por tiempo
- **Índices** — todas las tablas tienen índices en columnas de query común

### Eficacia
- **Foreign keys ON** — integridad referencial
- **Integrity check** — en cada health check y watchtower cycle
- **Backup online** — `.backup` CLI de sqlite3 es seguro para DB en uso
- **Restore verificado** — restore con validación post-operación

### Eficiencia
- **Lazy steps** — DB init/prune corre en background, no bloquea sesión
- **Vacuum condicional** — solo cada ~500 writes
- **Prune granular** — cada tabla con su propio TTL (30d/7d/90d)
- **WAL checkpoint** — mantiene WAL pequeño

## Relaciones con el Stack

| Componente          | Relación con Nexus                                       |
| ------------------- | -------------------------------------------------------- |
| **Dashboard**       | Lee métricas, sesiones, trazas, alertas, feedback via WS  |
| **Session Scoring** | Escribe/lee quality scores por sesión (migration 003)    |
| **Adaptive Router** | Persiste y consulta routing_rules con hit_count          |
| **Response Cache**  | Cachea respuestas SHA256 con TTL para ahorrar tokens     |
| **Audit Pipeline**  | Almacena eventos de auditoría (append-only)              |
| **Event Sourcing**  | Almacena eventos del event store                         |
| **Watchtower**      | Monitorea integridad, tamaño, WAL en cada ciclo          |
| **Token Budget**    | Almacena token_usage por sesión para tracking de costos  |
| **Skill Router**    | Persiste skill_usage para recomendaciones                |
| **SDD Contracts**   | Almacena contract_results para validación                |

## Política de Retención

| Tabla               | Retención | ¿Por qué?                                    |
| ------------------- | --------- | -------------------------------------------- |
| `events`            | 30 días   | Event sourcing — suficiente para debugging   |
| `response_cache`    | 7 días    | Cache — los datos cambian rápido             |
| `token_usage`       | 90 días   | Cost tracking — necesitamos histórico largo  |
| `metric_snapshots`  | 1000 rows | Time-series — suficiente para tendencias     |
| `alerts`            | 500 rows  | Alert history — solo las más recientes       |
| `sessions`          | ∞         | Historial permanente de sesiones             |
| `traces`            | ∞         | Tracing permanente para debugging            |
| `feedback`          | ∞         | Feedback permanente para mejora continua     |
| `contract_results`  | ∞         | Contratos permanentes para auditoría         |
| `skill_usage`       | ∞ (con cleanup de orphans) | Skills vigentes                |
| `routing_rules`     | ∞         | Reglas de ruteo permanentes                  |
| `session_scoring`   | ∞         | Scoring permanente para evaluación           |

## Identity Manifest (para el orquestador)

```json
{
  "name": "Nexus",
  "type": "SQLite (WAL mode)",
  "path": ".runtime/gentle-vanguard.db",
  "manager": "DatabaseManager (singleton)",
  "tables": 12,
  "migrations": 3,
  "purpose": "Operational database — metrics, sessions, traces, events, alerts, feedback, cache, contracts, scoring, routing",
  "autoInit": true,
  "autoPrune": true,
  "autoBackup": true,
  "monitoredBy": "watchtower (gentle-vanguard-db component)",
  "pipelineSteps": ["db-init", "db-health-check", "db-prune"]
}
```
