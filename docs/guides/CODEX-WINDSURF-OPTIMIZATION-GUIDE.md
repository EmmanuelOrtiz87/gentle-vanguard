# Codex + Windsurf Optimization Guide

## Objetivo
Estandarizar y potenciar el uso de Codex y Windsurf con configuraciones prácticas, seguras y eficientes para trabajo diario en este repositorio.

## Referencias oficiales usadas
- Codex Best Practices: https://developers.openai.com/codex/learn/best-practices
- Codex Security/Approvals: https://developers.openai.com/codex/agent-approvals-security
- Windsurf Advanced: https://docs.windsurf.com/es/windsurf/advanced
- Windsurf docs index: https://docs.windsurf.com/llms.txt

## Cambios aplicados

### Codex
- Config nativa añadida: [.codex/config.toml](../../.codex/config.toml)
- Config del workspace actualizada: [.codex/config.json](../../.codex/config.json)
- Metadata de integración actualizada: [config/tool-codex.json](../../config/tool-codex.json)
- Rutas y guía corregidas: [docs/CODEX.md](../CODEX.md)

Prácticas activadas:
- `approval_policy = on-request`
- `sandbox_mode = workspace-write`
- `web_search = disabled` (local-first)
- `network_access = false` en sandbox workspace-write
- perfiles de operación (`local_first_safe`, `readonly_review`)
- plan-first para tareas complejas y plantilla Goal/Context/Constraints/Done

### Windsurf
- Config del workspace actualizada: [.windsurf/config.json](../../.windsurf/config.json)
- Ignora de indexado añadida: [.codeiumignore](../../.codeiumignore)
- Metadata de integración actualizada: [config/tool-windsurf.json](../../config/tool-windsurf.json)

Prácticas activadas:
- Contexto local-first con Fast Context
- Indexación acotada por `.codeiumignore`
- `cascade.gitignoreAccess = false` por defecto
- búsqueda web/docs deshabilitada por defecto
- soporte avanzado declarado para SSH, Dev Containers y WSL

## Automatización inteligente (temporal)
Se implementó un controlador adaptativo para Codex y Windsurf:
- [scripts/utilities/adaptive-codex-windsurf-profile.ps1](../../scripts/utilities/adaptive-codex-windsurf-profile.ps1)
- Notificación operativa: [scripts/utilities/notify-codex-windsurf-optimization.ps1](../../scripts/utilities/notify-codex-windsurf-optimization.ps1)

Integración en inicio de sesión:
- [config/session-autostart.config.json](../../config/session-autostart.config.json)
- [scripts/utilities/session-autostart.cmd](../../scripts/utilities/session-autostart.cmd)
- [scripts/utilities/session-autostart.sh](../../scripts/utilities/session-autostart.sh)

Comportamiento:
1. Detecta señales (horario pico o presión de tokens).
2. Aplica perfil optimizado temporal.
3. Notifica el cambio en tiempo real.
4. Si el sistema se normaliza, restaura baseline automáticamente.

Persistencia interna (runtime):
- `scripts/.session/adaptive-codex-windsurf-state.json`
- `scripts/.session/codex-config.baseline.toml`
- `scripts/.session/windsurf-config.baseline.json`

## Comandos útiles

```powershell
# Estado del controlador adaptativo
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-codex-windsurf-profile.ps1 -Mode Status

# Forzar optimización temporal
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-codex-windsurf-profile.ps1 -Mode Optimize

# Forzar restauración baseline
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-codex-windsurf-profile.ps1 -Mode Restore

# Notificación manual al equipo
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/notify-codex-windsurf-optimization.ps1
```

## Validación recomendada

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/agent-verify.ps1 -Domain config,structure -Json
```

Resultado esperado:
- `result`: PASS o PASS_WITH_WARNINGS
- `failed`: 0

## KPIs sugeridos
- Tiempo de primera respuesta por tarea
- Tokens por sesión
- Cantidad de prompts con plan-first en tareas complejas
- Cantidad de accesos externos evitados por configuración
- Estabilidad de contexto (menos deriva entre turnos)
