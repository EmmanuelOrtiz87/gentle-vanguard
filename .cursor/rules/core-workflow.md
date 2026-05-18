# Core Workflow

Reglas fundamentales de operación para todos los agentes en Gentle-Vanguard.

## Pre-processing (SIEMPRE activo)

**Antes de responder a CUALQUIER input del usuario:**
1. Ejecutar: `powershell -File scripts/utilities/pre-process-input.ps1 -UserInput "INPUT" -WorkspaceRoot "."`
2. Parsear output:
   - `TRIGGER_MATCH_FOUND` → leer `skills/<skill-name>/SKILL.md` y seguir instrucciones
   - `PLAN_MODE_REQUIRED` con `AGENT: BA` → activar BA/sdd-explore primero. Completar EXPLORE antes de implementar.
   - `NO_TRIGGER_MATCH` → comportamiento normal

## Session Management

- **Iniciar sesión**: `scripts/utilities/session-autostart.cmd` (Windows)
- **Proyecto**: gentle-vanguard | Rama: develop
- **Session ID**: session-YYYY-MM-DD-XX

## LOCAL-FIRST

1. Local project knowledge (skills/, docs/, rules/) primero
2. Scripts y herramientas locales segundo
3. Web search/fetch: DENY (excepto cuando el orquestador lo autorice)

## SDD Flow para nuevas features

1. **BA (explore)**: `skills/sdd-lifecycle/SKILL.md` — análisis de requerimientos
2. **SAD (design)**: `openspec/config.yaml` — diseño de arquitectura
3. **DEV (apply)**: implementación
4. **QA (verify)**: verificación

Para bugs: ir directo a DEV/APPLY, saltar BA.

## Skill Loading (sin skill tool nativo)

Cursor no expone skill tool. Para emular:
1. Consultar `.atl/skill-registry.md` para encontrar el skill correcto
2. Leer `skills/<skill-name>/SKILL.md` directamente
3. Skills críticos siempre disponibles: `sdd-lifecycle`, `code-review-orchestrator`, `session-workflow`

## Memoria entre sesiones (emulación)

- **Contexto persistente**: `.engram-data/`
- **Resumen de sesión**: `scripts/.session/startup-summary.json`
- **Restaurar contexto**: `pwsh -NoProfile -File scripts/utilities/engram_mem_context.ps1`
- **Session logs**: `logs/` y `session/`

## Respuestas

- **Idioma**: español (términos técnicos en inglés)
- **Estilo**: conciso, directo, sin preamble/postamble
- **Profile**: ultra — compresión agresiva
- **Chat level**: compact — max 4 líneas texto antes de tool calls
