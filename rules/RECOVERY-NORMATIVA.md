# RECOVERY-NORMATIVA.md

Protocolo de recuperacion, prevencion y mantenimiento de bases de datos SQLite del stack
Gentle-Vanguard.

## Componentes con SQLite

| Componente    | Ruta                            | Critico | Proposito                                   |
| ------------- | ------------------------------- | ------- | ------------------------------------------- |
| CodeGraph     | `.codegraph/codegraph.db`       | SI      | Knowledge graph index (nodes, edges, files) |
| Engram-local  | `.engram-data/*.db`             | NO      | Persistent memory observations              |
| Engram-global | `~/.engram/global/.engram/*.db` | NO      | Global memory across projects               |

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

```powershell
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

## Mantenimiento Periodico

### Verificacion rapida

```bash
npx tsx scripts/recovery/db-health-check.ts
```

### Limpieza de backups antiguos

```powershell
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
