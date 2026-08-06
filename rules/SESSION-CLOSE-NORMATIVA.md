# SESSION-CLOSE-NORMATIVA.md

Protocolo autónomo de cierre de sesión — garantiza que toda sesión, sin importar su duración o
complejidad, quede completamente documentada, respaldada y recuperable.

## Filosofía

Cada sesión debe cerrarse como si fuera la última. No importa si fue una sesión de 5 minutos o 5
horas: el stack debe quedar en un estado consistente, rastreable y restaurable.

## Ciclo de Cierre (Orden Obligatorio)

```
[1. PRE-CLOSE]  →  [2. PERSIST]  →  [3. BACKUP]  →  [4. AUDIT]  →  [5. CLEANUP]  →  [6. VERIFY]
```

### Fase 1: PRE-CLOSE

Acciones inmediatas antes de cualquier limpieza:

- [ ] Registrar timestamp de cierre en session-current.json
- [ ] Detener workers activos del swarm (si los hay)
- [ ] Cerrar tracing span activo
- [ ] Tomar snapshot final de métricas (tool calls, tokens, archivos)
- [ ] Calcular session scoring final

### Fase 2: PERSIST

Guardar todo el conocimiento de la sesión:

- [ ] **Engram**: Guardar session summary con Goal, Discoveries, Accomplished, Next Steps, Relevant
      Files
- [ ] **Engram**: Guardar memoria de decisiones/arquitectura/bugs encontrados
- [ ] **Nexus DB**: Escribir métricas finales (tokens, tool calls, errores)
- [ ] **Nexus DB**: Escribir session_scoring final
- [ ] **Nexus DB**: Escribir token_usage final
- [ ] **Nexus DB**: Escribir trace final de cierre
- [ ] **Nexus DB**: Escribir evento de session.ended en event store
- [ ] **Session Files**: Actualizar session-current.json con datos finales
- [ ] **Session Files**: Crear session-{date}.json con datos completos

### Fase 3: BACKUP

Crear puntos de restauración:

- [ ] **Checkpoint**: Crear checkpoint del estado de sesión (session files, configs)
- [ ] **Nexus Backup**: Backup de `.runtime/gentle-vanguard.db`
- [ ] **Engram Backup**: Backup de `.engram-data/` y SHA256 checksums
- [ ] **Snapshot**: Snapshot opcional de `.session/` completo
- [ ] **Manifest**: Escribir manifest con metadata del backup

### Fase 4: AUDIT

Registro permanente de lo ocurrido:

- [ ] **Audit Pipeline**: Loggear session.end con metadata completa
- [ ] **Event Store**: Append session.ended con payload de resumen
- [ ] **Tracing**: Cerrar span de sesión con atributos finales
- [ ] **CodeGraph**: Sync index si hubo cambios en archivos
- [ ] **Dashboard WS**: Emitir métricas finales vía WebSocket

### Fase 5: CLEANUP

Limpieza de recursos temporales:

- [ ] Flushear caches de sesión (normativa-cache, prompt-cache, preprocess-cache)
- [ ] Resetear token tracking
- [ ] Prunear checkpoints viejos (>14 días)
- [ ] Limpiar sesiones huérfanas (>8 horas)
- [ ] Compactar context-log
- [ ] Cerrar dashboard WS watchdog (si es última sesión del día)

### Fase 6: VERIFY

Validar que todo quedó correcto:

- [ ] Verificar que Engram tiene la session summary guardada
- [ ] Verificar que Nexus DB tiene los datos de la sesión
- [ ] Verificar que el checkpoint se creó correctamente
- [ ] Verificar que el backup de Nexus se completó
- [ ] Verificar integridad del audit log
- [ ] Reportar resumen de cierre (exit: OK o FAIL con detalles)

## Coordinación con el Orquestador

El **Session Close Orchestrator** (`src/session-close-orchestrator.ts`) es el único responsable de
ejecutar este protocolo. El orquestador:

1. Se ejecuta **automáticamente** al detectar fin de sesión
2. Puede ejecutarse **a demanda** vía:
   ```bash
   npx tsx src/session-close-orchestrator.ts --reason "manual"
   ```
3. Reporta el resultado de cada fase (PASS/FAIL)
4. Si una fase falla, registra el error pero **continúa** (resiliencia)
5. Al final, emite un reporte consolidado

## Puntos de Restauración

### Checkpoints (rápidos, frecuentes)

- Ubicación: `.session/checkpoints/`
- Contenido: session-current.json, configs activas, token-usage
- Retención: 14 días
- Creación: Al inicio de sesión y al cierre

### Snapshots (completos, menos frecuentes)

- Ubicación: `.session/snapshots/`
- Contenido: `.session/` completo + `.runtime/gentle-vanguard.db` + `.engram-data/` SHA256
- Retención: 30 días
- Creación: Al cierre de sesiones con `--reason evolution|release|major-change`

### Backups de Base de Datos

- Ubicación: `.runtime/backups/`
- Contenido: gentile-vanguard.db (online-safe via `.backup` CLI)
- Retención: 10 backups más recientes
- Creación: Automático al cierre de cada sesión

## Restauración

### Desde checkpoint (rápido)

```bash
npx tsx src/checkpoint-manager.ts restore <checkpoint-id>
```

### Desde snapshot (completo)

```bash
npx tsx src/rollback-orchestrator.ts --source snapshot --id <snapshot-id>
```

### Desde backup de Nexus

```bash
npm run db:restore <backup-name>
```

### Desde backup de Engram

```bash
npx tsx src/backup-engram.ts --mode restore --id <backup-id>
```

## Reglas Críticas

1. **TODA** sesión debe ejecutar el protocolo de cierre, sin excepción
2. **NO** se puede omitir la fase PERSIST (fase 2) — es la única obligatoria
3. **SI** una fase falla, registrar el error en audit con severidad `warning` y continuar
4. **SI** la fase PERSIST falla completamente, marcar sesión como `closed-with-warnings`
5. **LOS** checkpoints se crean tanto al inicio como al cierre de sesión
6. **EL** session scoring debe calcularse antes de cualquier limpieza (fase 1)
7. **EL** orden de las fases es obligatorio — no se puede reordenar

## Herramientas de Diagnóstico

```bash
# Verificar el último cierre de sesión
npx tsx src/session-close-orchestrator.ts --verify

# Listar checkpoints disponibles
npx tsx src/checkpoint-manager.ts list

# Verificar integridad de Nexus DB
npm run db:health

# Verificar estado de Engram
engram doctor
```

## Referencias

- `src/session-close-orchestrator.ts` — Implementación del orquestador
- `src/session-cleanup-start.ts` — Script de cleanup (invocado por el orquestador)
- `src/checkpoint-manager.ts` — Gestión de checkpoints
- `config/session-autostart.config.json` — Steps de cierre en la pipeline
- `rules/RECOVERY-NORMATIVA.md` — Protocolo de recuperación de bases de datos
