# RECOVERY-NORMATIVA.md

Protocolo de recuperacion, prevencion y mantenimiento de bases de datos SQLite del stack
Gentle-Vanguard.

## Componentes con SQLite

| Componente    | Ruta                            | Critico | Proposito                                   |
| ------------- | ------------------------------- | ------- | ------------------------------------------- |
| CodeGraph     | `.codegraph/codegraph.db`             | SI  | Knowledge graph index (nodes, edges, files) |
| Engram-local  | `.engram-data/*.db`                   | SI  | Persistent memory — decisions, bugs, architecture, conventions, agent/skill performance, stack historical context |
| Engram-global | `~/.engram/global/.engram/*.db`       | SI  | Global memory — cross-project knowledge, learned behaviors, patterns across repos |
| **Nexus**     | `.runtime/gentle-vanguard.db`         | SI  | Operational DB — metrics, sessions, traces, events, alerts, feedback, cache, contracts, scoring, routing |

## Error "no such column: data"

### Causa Raiz

El script `scripts/recovery/schema-integrity.ts` (version anterior) verificaba si las tablas tenian
una columna `data` y la agregaba automaticamente a cualquier tabla que no la tuviera. Esto corrompia
los schemas agregando columnas donde no pertenecian.

**ESTA CORREGIDO.** El script actual es READ-ONLY — solo verifica, nunca modifica.

### Si el error persiste

**Sintomas:**

- Todas las herramientas devuelven: `no such column: "data"`
- Errores SQLite en tool calls del runtime opencode

**Diagnostico rapido:**

```bash
npx tsx scripts/recovery/db-health-check.ts
```

**Recuperacion automatica:**

```bash
npx tsx scripts/recovery/db-restore.ts repair
```

**Recuperacion manual:**

```TypeScript
# 1. Verificar estado
npx tsx scripts/recovery/schema-integrity.ts

# 2. Si hay corrupcion, listar backups disponibles
npx tsx scripts/recovery/db-restore.ts list

# 3. Restaurar desde backup
npx tsx scripts/recovery/db-restore.ts restore <backup-name>

# 4. Si no hay backup, renombrar y regenerar
Rename-Item ".codegraph" ".codegraph-corrupt-$(Get-Date -Format yyyyMMddTHHmmss)"
# Reiniciar opencode — regenerara el index automaticamente
```

## Scripts de Recovery

| Script                                 | Tipo      | Descripcion                                       |
| -------------------------------------- | --------- | ------------------------------------------------- |
| `scripts/recovery/schema-integrity.ts` | Read-only | Verifica schemas contra definiciones canonicas    |
| `scripts/recovery/db-health-check.ts`  | Read-only | Health check completo con auto-repair WAL/REINDEX |
| `scripts/recovery/db-restore.ts`       | Write     | Restore desde backups o repair completo           |
| `scripts/recovery/rescue-database.ts`  | Write     | Rescue rapido (backup + delete si corrupt)        |

## Flujo de Prevencion

1. **Al inicio de sesion**: `db-health-check.ts` corre como lazy step
2. **Antes de modificar schemas**: `schema-integrity.ts` verifica estado actual
3. **Automatico**: WAL checkpoint + REINDEX si integrity_check falla
4. **Backups**: Se crean antes de cualquier modificacion automatica

## Restore Points

Ubicacion: `.session/restore-points/`

Cada restore point es un JSON con:

- `id`: Identificador unico
- `timestamp`: ISO 8601
- `type`: Tipo de evento (schema-integrity, backup-restore, etc.)
- `issues`: Lista de problemas encontrados
- `actions`: Acciones tomadas

## Session Close & Recovery Points

El orquestador de cierre de sesion (`src/session-close-orchestrator.ts`) ejecuta 6 fases que generan
puntos de recuperacion:

| Fase | Accion | Punto de recuperacion |
|------|--------|----------------------|
| PRE-CLOSE | Timestamp, cierre de tracing | `.session/session-current.json` |
| PERSIST | Engram summary, session scoring, event store, token metrics | `.engram-data/`, `.session/event-store/`, `.session/metrics/` |
| BACKUP | Checkpoint, Nexus backup, Engram backup | `.session/checkpoints/`, `.runtime/backups/`, `.engram-backups/` |
| AUDIT | Audit log, CodeGraph sync | `.session/audit/logs/` |
| CLEANUP | Kill procesos hijos (CodeGraph MCP, Dashboard WS, timeout daemon), flush caches | limpia `.session/cache/` |
| VERIFY | Session file, Nexus health, checkpoint/backup existence | Reporte en `.session/close-report-*.json` |

### Procesos que mata el CLEANUP

1. **CodeGraph MCP server** — `codegraph.js serve --mcp`
2. **Dashboard WebSocket** — `websocket-server.ts`
3. **Timeout Monitor Daemon** — `timeout-monitor.ts --daemon`
4. **Orphans** — cualquier proceso `tsx` hijo de session-*.ts residual

### Como restaurar desde un cierre

```bash
# 1. Verificar el ultimo reporte de cierre
cat .session/close-report-*.json

# 2. Restaurar checkpoint (dry-run primero)
npx tsx src/checkpoint-manager.ts restore --dry-run

# 3. Restaurar Nexus DB
npx tsx scripts/database/db-restore.ts list
npx tsx scripts/database/db-restore.ts restore <backup-name>
```

## Pipeline Integration

El orquestador de cierre se ejecuta como lazy step en la pipeline de sesion:
- `session-scoring-close` — registra el evento de cierre en scoring (habilitado)
- `session-close-orchestrator` — ejecuta las 6 fases de cierre (nuevo, lazy)
- Ambos steps son `required: false` y `lazy: true` para no bloquear el inicio

## Mantenimiento Periodico

### Verificacion rapida

```bash
npx tsx scripts/recovery/db-health-check.ts
```

### Limpieza de backups antiguos

```TypeScript
Get-ChildItem ".recovery/schema-backups" -Directory |
  Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-30) } |
  Remove-Item -Recurse -Force
```

### Compactar WAL

```bash
sqlite3 .codegraph/codegraph.db "PRAGMA wal_checkpoint(TRUNCATE);"
```

## Reglas Criticas

1. **NUNCA** ejecutar scripts que agreguen columnas automaticamente
2. **SIEMPRE** hacer backup antes de modificar cualquier .db
3. **VERIFICAR** integridad despues de cualquier operacion
4. **NO** eliminar `.codegraph/` a menos que sea ultima opcion
5. **PREFERIR** restore desde backup sobre rebuild
