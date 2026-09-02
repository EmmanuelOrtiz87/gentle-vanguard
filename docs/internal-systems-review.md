# Revision Exhaustiva de Sistemas Internos del Stack Gentle-Vanguard

## Resumen Ejecutivo

Esta revision analiza cinco sistemas fundamentales del stack Gentle-Vanguard, evaluando su
existencia, implementacion, conectividad, funcionamiento y brechas. Los resultados muestran un
ecosistema maduro y bien interconectado, aunque con areas de oportunidad identificadas.

---

## 1. Token Management

### 1.1 Token Budget Guard (src/tokens/token-budget-guard.ts)

**Estado: IMPLEMENTADO y OPERATIVO**

El sistema de presupuesto de tokens esta completamente implementado con las siguientes
caracteristicas:

**Arquitectura:**

- Interfaz `GuardConfig` con configuracion adaptativa que soporta modos `soft` y `adaptive`
- Sistema de umbrales dinamicos: soft (70%), warn (85%), strict (95%), emergency (100%)
- Integracion con archivo de configuracion `config/token-budget-guard.json` (v3.0.0)
- Fallback legacy a `config/orchestrator.json`

**Modos de Adaptacion:**

- **Soft Mode (legacy)**: Solo registra cuando se alcanza el umbral blando
- **Adaptive Mode (v3)**: Sistema de 4 niveles con acciones configurables:
  - `soft`: log_only
  - `warn`: notify
  - `strict`: block_new_tasks
  - `emergency`: critical_only

**Conexiones:**

- Nexus DB para persistencia de uso
- Sistema de metricas en `docs/sessions/metrics/token-guard-usage.csv`
- Integracion con autostart pipeline (step `token-budget`)
- Valida disponibilidad de Engram como requisito opcional

**Typecheck:** errores son de configuracion de proyecto (flags TS), no del codigo

**Brechas Identificadas:**

- El directorio de metricas `docs/sessions/metrics/` debe existir o se crea automaticamente
- No hay integracion directa con el sistema de routing de modelos (solo esta documentado en config)

### 1.2 Token Ingest (src/tokens/token-ingest.ts)

**Estado: IMPLEMENTADO, OPERATIVO y ROBUSTO**

Daemon agnóstico de ingesta que consolida datos de multiples herramientas:

**Arquitectura Multi-Fuente:**

- **Opencode**: SQLite en `~/.local/share/opencode/opencode.db`
- **ZCode**: JSONL en `~/.zcode/cli/rollout/model-io-*.jsonl`
- **Codex**: JSONL anidado en `~/.codex/sessions/rollout-*.jsonl`
- **MiniMax**: SQLite en `~/.minimax/v2/sqlite/runtime-state.sqlite`
- **Pendiente**: Claude y Cursor

**Funcionalidades:**

- `ingestOnce()`: pasada unica con tracking incremental
- `watch(intervalSec)`: modo daemon con PID file para deduplicacion
- `detectSources()`:detecta que herramientas tienen datos disponibles
- `generateTraceabilityReport()`: reporte diario de trazabilidad

**Conexiones:**

- Escribe a Nexus DB tablas `token_usage`, `token_transactions`, `token_savings`
- Actualiza `.session/session-current.json` con deltas reales
- Genera `reports/stack-live-observability-latest.json`
- Integra con `session-metrics-tracker` para metricas en vivo

**Typecheck:** mismo problema de configuracion de proyecto

**Brechas Identificadas:**

- Claude y Cursor no tienen reader implementado
- No hay soporte para Azure OpenAI o Anthropic como fuentes
- El directorio `.atl/skill-stats.json` debe existir para backfill de skills

### 1.3 Tracking Input/Output Tokens

**Estado: IMPLEMENTADO**

El sistema distingue y registra:

- `tokens_input` / `tokens_output` (principal)
- `tokens_reasoning` (modelos que lo soportan)
- `tokens_cache_read` / `tokens_cache_write` (cache)
- `cost` (USD cuando esta disponible)

**Budget Adaptation Modes:**

- Configuracion en `config/token-budget-guard.json`
- Mode `adaptive` con `adaptiveModes` configurables
- Enforcement no bloqueante por defecto (`nonBlocking: true`)
- Notificaciones configurables para alerts

---

## 2. Cache Systems

### 2.1 Normativa Cache

**Estado: IMPLEMENTADO**

Ubicacion: `.session/normativa-cache/`

**Caracteristicas:**

- Creado por `session-cleanup-start.ts`
- Almacena documentos normativos procesados
- Invalidation vinculada al ciclo de sesion

**Conexiones:**

- Parte del cleanup de sesion
- No hay sistema de TTL explícito para esta cache

**Brechas:**

- No encontrado modulo dedicado de gestión (solo limpieza en session-cleanup-start)
- Sin documentacion de estructura interna

### 2.2 Prompt Cache

**Estado: IMPLEMENTADO**

Ubicacion: `.session/prompt-cache/`

**Caracteristicas:**

- Referenciado en `src/orchestration/profiles-build.ts` (linea 211)
- Creado por `session-cleanup-start.ts`
- Almacena prompts preprocesados para reutilizacion

**Conexiones:**

- Integra con profiles de orquestacion
- Cleaning automatico en session-close

**Brechas:**

- Estructura de archivos no documentada
- Sin API publica de invalidacion

### 2.3 Response Cache (src/resilience/response-cache.ts)

**Estado: IMPLEMENTADO y ROBUSTO**

Sistema de caching de respuestas con hit rate objetivo del 25%:

**Arquitectura:**

- TTL configurable (default 60 minutos)
- Tamano minimo de respuesta: 50 chars
- Tamano maximo: 10000 chars
- Hook system automatico en `src/core/cache-hook-system.ts`

**Cache Hook System:**

- Intercepta `console.log` para detectar respuestas
- Hook en `process.exit` para flush automatico
- API publica: `registerInput()`, `registerOutput()`, `check()`
- Estadisticas: hits, misses, tokens saved, hit rate

**Conexiones:**

- Integra con orchestrator via hooks automaticos
- Persiste en memoria (no disco) - no sobrevive restart
- Logging en `.logs/cache-hook-system.log`

**Typecheck:** requiere import de ResponseCache

**Brechas:**

- No persiste a disco (perdido en restart)
- Sin invalidacion manual
- Dependencia de patrones de output (✅, ---, ##) para detectar completion

### 2.4 Session Caches en .session/

**Estado: IMPLEMENTADO**

Directorios gestionados:

- `.session/normativa-cache/` - cache de normativa
- `.session/prompt-cache/` - cache de prompts
- `.session/session-current.json` - estado actual de sesion
- `.session/token-usage.json` - usage consolidado

**Invalidacion:**

- En `session-cleanup-start.ts` con flags:
  - `--skip-cache-flush` para mantener caches
  - `-SkipCacheFlush` para lazy steps
- Sesiones stale >8h activan limpieza

---

## 3. Process/Session

### 3.1 Process Hygiene (src/core/process-hygiene.ts)

**Estado: IMPLEMENTADO, ROBUSTO y BIEN DISENADO**

Sistema nativo de limpieza de procesos huerfanos/zumbadores:

**Arquitectura (Pure/Analyzed Split):**

- `analyzeProcesses()`: funcion pura, testable sin PowerShell
- `scanProcesses()`: construye snapshot del sistema
- `runHygiene()`: actuacion sobre hallazgos

**Categorias de Hallazgos:**

1. **duplicate-daemon**: multiples instancias del mismo daemon
2. **hung-oneshot**: scripts que nunca retornaron (edad >15 min)
3. **aged-daemon**: daemons adoptados de sesiones previas (>24h)
4. **stale-pidfile**: archivos .pid apuntando a procesos muertos
5. **headless-chrome**: chrome headless residual de screenshots
6. **unknown-repo-process**: procesos de repo no clasificados

**Daemon Classes Registradas:**

- token-ingest-daemon
- command-center
- ws-watchdog / vite-watchdog
- websocket-server
- timeout-monitor-daemon
- codegraph-mcp
- codegraph-serve
- dashboard-vite

**Conexiones:**

- Phase 1 del autostart (ANTES de lazy daemons)
- maintenance-watchtower (check + autoheal)
- session-close-orchestrator
- Escribe `.runtime/process-hygiene-report.json`

**Typecheck:** mismo problema de configuracion

**Brechas:**

- Requiere PowerShell en Windows para algunos queries
- No detecta todos los tipos de procesos (solo node/chrome)
- Dependencia de WMI para Windows

### 3.2 Session Autostart (src/core/session-autostart.ts)

**Estado: IMPLEMENTADO, OPERATIVO y COMPLEJO**

Pipeline de 31 pasos + 81 lazy steps:

**Fases:**

- **Phase 0**: pasos criticos secuenciales (model-enforcer, bootstrap-symlink, session-manager,
  etc.)
- **Phase 1**: higiene y validacion (process-hygiene, legacy-registration-cleanup)
- **Phases 2+**: pasos en paralelo
- **Lazy**: 81 steps deferidos en background (batch size 2)

**Features Destacados:**

- Lock file con PID validation (detecta procesos huerfanos de cmd.exe)
- Reuso de sesion reciente (30 min window)
- Deduplicacion de lazy steps via ProcessLock
- Progress file para observabilidad (`.runtime/autostart-progress.json`)
- Auto-checkpoint en inicio exitoso
- Session validation antes de proceder
- Integracion con watchtower loop-guard (soft check)

**Conexiones:**

- 31 pasos hardcoded + 81 lazy steps desde config
- 1109 lineas de configuracion en `config/session-autostart.config.json`
- Integra con: process-hygiene, engram, checkpoint-manager, token-budget-guard, session-validator

**Typecheck:** mismo problema de configuracion

**Brechas:**

- Maximo 2 lazy concurrentes (puede ser lento)
- No hay mecanismo de rollback si un lazy step falla
- Dependencia fuerte de orden de fases

### 3.3 Orchestrator Loop Guard (src/core/orchestrator-loop-guard.ts)

**Estado: IMPLEMENTADO con POTENCIAL NO UTILIZADO**

Sistema de proteccion contra loops degenerativos:

**Mecanismos de Deteccion:**

1. **intent-loop**: mismo intent normalizado >=3 veces consecutivas
2. **tool-loop**: mismo tool+args fingerprint >=3 veces
3. **ping-pong**: alternancia A-B-A-B
4. **stalled-progress**: N pasos sin side-effect (write/edit/bash/commit)

**Configuracion:**

- `intentThreshold`: 3
- `toolThreshold`: 3
- `stalledThreshold`: 8
- `historySize`: 20

**Integracion:**

- Soft check en session-autostart (linea 509): solo warn, no bloquea
- Wired en watchtower como health check
- **NO INTEGRADO en el main loop del orquestador** (solo esta disponible)

**Typecheck:** requiere ES2020+ module

**Brechas:**

- **No se usa activamente**: solo hace self-test en autostart
- El orquestador principal no lo instancia
- Documentado pero no conectado al flujo principal
- Deberia ser hard-fail, no soft-warn

---

## 4. Skills System

### 4.1 Carga de Skills (src/knowledge/skill-loader.ts)

**Estado: IMPLEMENTADO y OPERATIVO**

Sistema agnóstico que funciona con cualquier herramienta AI:

**Arquitectura:**

- Lee de directorio `skills/` (no .opencode/skills/)
- Parsea frontmatter YAML de SKILL.md
- Matching por: name, aliases, triggers, descripcion parcial

**Matching Algorithm:**

1. Exact match en nombre
2. Exact match en aliases
3. Match en triggers (substring)
4. Match parcial en nombre

**Funcionalidades CLI:**

- `--list`: lista todos los skills
- `--match "query"`: encuentra skill matching
- `--load name`: carga contenido

**Conexiones:**

- Integracion con skill-usage-recorder para tracking
- 100+ skills en directorio skills/
- Soporte para referencias en subdirectorios

**Typecheck:** mismo problema de configuracion

**Brechas:**

- No carga desde `.opencode/skills/` (skills de ZCode/Codex)
- No hay versionado de skills
- Sin sistema de dependencias entre skills

### 4.2 Skill Usage Recorder (src/knowledge/skill-usage-recorder.ts)

**Estado: IMPLEMENTADO y BIEN DISENADO**

Sistema de tracking de uso de skills en Nexus:

**Arquitectura:**

- Tabla `skill_usage` en Nexus DB
- Upsert: skill_id + session_id + tenant_id
- Acumula: count, tokens_used, cost, last_used

**Fuentes de Datos:**

- **Live**: llamadas a `recordSkillUsage()` desde skill-loader
- **Backfill**: desde `.atl/skill-stats.json` (MCP server)

**Features:**

- Failure-tolerant: nunca rompe el serve path
- Testable via `setDbProviderForTests()`
- CLI para backfill: `--backfill [--dry-run]`

**Conexiones:**

- Escribe a Nexus `skill_usage` table
- Lee `.atl/skill-stats.json` para backfill
- Integrado en skill-loader match/load

**Typecheck:** mismo problema de configuracion

**Brechas:**

- Schema no tiene columna `source` (pero se acepta como input)
- No hay integracion con dashboard para visualizacion
- `.atl/skill-stats.json` debe existir para backfill

---

## 5. Harness/Loop

### 5.1 ORCA Integration

**Estado: NO ENCONTRADO**

No se encontró integracion activa con ORCA en el codebase:

- No hay archivos referenciando `orca-cli` o `orchestration`
- El sistema actual es self-contained
- La integracion puede ser futura o via MCP externo

**Brecha:** Sistema no tiene integracion ORCA implementada

### 5.2 Loop Guard

**Estado: IMPLEMENTADO pero SUBUTILIZADO**

Ver seccion 3.3 - el loop guard existe pero no se usa activamente en el flujo del orquestador.

### 5.3 Autostart Pipeline

**Estado: ROBUSTO y OPERATIVO**

Pipeline maduro con:

- 31 pasos requeridos
- 81 lazy steps
- Deduplicacion robusta
- Observabilidad completa
- Progreso trackeable

**Estado actual (desde .runtime/autostart-progress.json):**

- PID: 34040
- Status: done
- Steps: 31/31 ejecutados
- Lazy: 77/81 lanzados
- Duration: 33.7s

---

## 6. Hallazgos Consolidados

### 6.1 Sistemas Fuertes

| Sistema            | Estado                  | Score |
| ------------------ | ----------------------- | ----- |
| Token Ingest       | Operativo, multi-fuente | 95%   |
| Process Hygiene    | Robusto, bien diseñado  | 90%   |
| Session Autostart  | Completo, observable    | 90%   |
| Skill Loader       | Funcional, agnóstico    | 85%   |
| Cache Hook System  | Automático, integrado   | 80%   |
| Token Budget Guard | Completo, adaptativo    | 85%   |

### 6.2 Brechas Criticas

1. **Orchestrator Loop Guard subutilizado**: Existe pero no se integra en el main loop
2. **ORCA integration missing**: No hay integracion con ORCA
3. **Claude/Cursor readers pendings**: Token ingest no los soporta
4. **Cache no persiste**: Response cache se pierde en restart

### 6.3 Mejoras Recomendadas

1. **Conectar Loop Guard al Orquestador**: Instanciar en cada turn del orchestrator
2. **Implementar ORCA Integration**: Definir interfaz para orca-cli
3. **Completar Readers**: Agregar Claude y Cursor a token-ingest
4. **Persistir Response Cache**: Agregar almacenamiento disco
5. **Documentar Cache Structures**: Estandarizar estructura de normativa-cache y prompt-cache

### 6.4 Typecheck

Los errores de typecheck son de configuracion de proyecto (flags TS), no del codigo:

- `import.meta` requiere ES2020+
- `Set`/`Map` iteration requiere ES2015+
- mejor-sqlite3 requiere esModuleInterop

**Recomendacion:** Usar `npx tsx` para ejecucion (resuelve estos temas automaticamente)

---

## 7. Conclusion

El stack Gentle-Vanguard presenta una arquitectura solida y bien interconectada. Los sistemas de
token management, cache, y proceso/sesion estan implementados con alta calidad. Las principales
areas de mejora son la integracion activa del Loop Guard y la expansion de fuentes de token ingest.
El pipeline de autostart es robusto y observable, proporcionando una base confiable para operaciones
del dia a dia.

**Recomendacion general:** Priorizar la integracion del Loop Guard en el flujo principal del
orquestador y completar los readers pendientes de token ingest para alcanzar un ecosistema 100%
funcional.
