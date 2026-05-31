# Claude Code + Cline Optimization Guide

## Objetivo

Unificar Claude Code y Cline con el mismo nivel de optimizacion y automatizacion temporal ya
aplicado en OpenCode, Codex y Windsurf.

## Referencias oficiales

- Claude Code Best Practices: https://code.claude.com/docs/es/best-practices
- Claude Code docs index: https://code.claude.com/docs/llms.txt
- Cline Overview: https://docs.cline.bot/cline-overview
- Cline docs index: https://docs.cline.bot/llms.txt

## Cambios aplicados

### 1. Perfil adaptativo automatizado (nuevo)

- Script:
  [scripts/utilities/PROFILE-ADAPTIVE/adaptive-claude-cline-profile.ps1](../../scripts/utilities/PROFILE-ADAPTIVE/adaptive-claude-cline-profile.ps1)
- Notificacion:
  [scripts/utilities/NOTIFY/notify-claude-cline-optimization.ps1](../../scripts/utilities/NOTIFY/notify-claude-cline-optimization.ps1)

Comportamiento:

1. Detecta horario pico o presion de tokens.
2. Crea snapshot baseline de Claude/Cline.
3. Aplica overlay optimizado en forma temporal.
4. Notifica el cambio.
5. Restaura baseline automaticamente cuando el sistema se normaliza.

### 2. Integracion en autostart

Se agrego el paso adaptativo en:

- [scripts/utilities/session-autostart.cmd](../../scripts/utilities/session-autostart.cmd)
- [scripts/utilities/SESSION/session-autostart.ps1](../../scripts/utilities/SESSION/session-autostart.ps1)
- [config/session-autostart.config.json](../../config/session-autostart.config.json)

### 3. Claude Code configurado para local-first y control

Actualizado:

- [.claude/settings.json](../../.claude/settings.json)

Mejoras practicas:

- Referencias oficiales de best practices e indice de docs.
- Contexto selectivo y limites de contexto.
- Permisos seguros por defecto (`on-request`, web bloqueada por defecto).
- Registro del perfil adaptativo y notificacion operativa.

### 4. Cline alineado a automatizacion completa

Actualizado:

- [config/tool-cline.json](../../config/tool-cline.json)

Mejoras practicas:

- `adaptiveProfile` para automatizacion temporal.
- Inclusiones de archivos de control (`.clinerules.optimized`, `.clineignore`,
  `.claude/settings.json`).

### 5. Registro de plataforma Claude Code

Nuevo:

- [config/tool-claude-code.json](../../config/tool-claude-code.json)

Permite mapear Claude Code como plataforma first-class dentro del mismo esquema de hooks,
pre-process y automatizacion.

## Estado por herramienta

- OpenCode: optimizado + automatizado
- Codex: optimizado + automatizado
- Windsurf: optimizado + automatizado
- Claude Code: optimizado + automatizado
- Cline: optimizado + automatizado

## Operacion diaria

```powershell
# Ver estado adaptativo Claude/Cline
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-claude-cline-profile.ps1 -Mode Status

# Forzar optimizacion temporal
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-claude-cline-profile.ps1 -Mode Optimize

# Forzar restauracion baseline
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-claude-cline-profile.ps1 -Mode Restore
```

## Validacion recomendada

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/agent-verify.ps1 -Domain config,structure -Json
```

Resultado esperado:

- `failed = 0`
- `result = PASS` o `PASS_WITH_WARNINGS`
