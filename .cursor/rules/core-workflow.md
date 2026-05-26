# Core Workflow

Reglas fundamentales de operacion para todos los agentes en Gentle-Vanguard.

## Fase 0: Tool Detection

Ejecutar ANTES de cualquier accion:

```powershell
$detected = pwsh -NoProfile -File scripts/utilities/detect-tool.ps1 -AsJson | ConvertFrom-Json
$detected.name  # opencode|claude-code|cline|cursor|windsurf|unknown
```

Cargar config desde `config/orchestrator.json#toolProfiles.<name>`.

## Pre-processing (SIEMPRE activo — con response cache)

**Antes de responder a CUALQUIER input del usuario:**

1. Ejecutar con `-UserInput` (no `-Prompt`):
   ```powershell
   pwsh -NoProfile -File scripts/utilities/pre-process-input.ps1 -UserInput "INPUT" -WorkspaceRoot "."
   ```
2. El script tiene **response cache** (SHA256, TTL 30min, -33-41% latency). Usar `-DisableCache`
   para bypass cuando sea necesario.
3. Parsear output:
   - `TRIGGER_MATCH_FOUND` -> leer `skills/<skill-name>/SKILL.md`
   - `PLAN_MODE_REQUIRED` con `AGENT: BA` -> activar BA/sdd-explore primero
   - `NO_TRIGGER_MATCH` -> comportamiento normal

## Session Management

- **Iniciar sesion**: `scripts/utilities/session-autostart.cmd` (Windows)
- **Autostart pipeline**: 18 steps principales + 6 lazy (self-diagnosis, metrics, dashboard,
  live-feed, skill-size, adaptive-profile)
- **Proyecto**: gentle-vanguard | **Rama**: develop
- **Session ID**: session-YYYY-MM-DD-XX

## Startup Sequence

1. `pre-process-input.ps1` BEFORE primera respuesta
2. `scripts/utilities/session-start-optimized.ps1` (autostart pipeline in-process, sin Start-Job)
3. Leer `scripts/.session/startup-summary.json`
4. `todowrite` — crear task list
5. `mem_search "lessons learned"`

## LOCAL-FIRST

1. Local project knowledge (skills/, docs/, rules/) primero
2. Scripts y herramientas locales segundo
3. Web search/fetch: DENY

## SDD Flow para nuevas features

1. **BA (explore)**: `skills/sdd-lifecycle/SKILL.md`
2. **SAD (design)**: `openspec/config.yaml`
3. **DEV (apply)**: implementacion
4. **QA (verify)**: verificacion Para bugs: ir directo a DEV/APPLY, saltar BA.

## Skill Loading (sin skill tool nativo)

Cursor no expone skill tool. Para emular:

1. Consultar `.atl/skill-registry.md` para encontrar el skill correcto
2. Leer `skills/<skill-name>/SKILL.md` directamente
3. Skills criticos siempre disponibles: `sdd-lifecycle`, `code-review-orchestrator`,
   `session-workflow`

## Memoria entre sesiones (emulacion)

- **Contexto persistente**: `.engram-data/`
- **Resumen de sesion**: `scripts/.session/startup-summary.json`
- **Restaurar contexto**: `pwsh -NoProfile -File scripts/utilities/engram_mem_context.ps1`
- **Session logs**: `logs/` y `session/`

## Respuestas

- **Idioma**: espanol (terminos tecnicos en ingles)
- **Estilo**: conciso, directo, sin preamble/postamble
- **Profile**: ultra (compresion agresiva)
- **Chat level**: compact (max 4 lineas texto antes de tool calls)
