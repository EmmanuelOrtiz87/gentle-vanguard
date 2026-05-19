# OpenCode Optimization Guide

## Objetivo

Esta guía documenta la optimización aplicada a OpenCode para reducir costo de tokens, mejorar
latencia y mantener control de herramientas en tiempo real.

## Estado

- Fecha: 2026-05-16
- Archivo principal: [opencode.json](../../opencode.json)
- Validación: `agent-verify.ps1 -Domain config -Json` en PASS

## Cambios Aplicados

### 1. Compactación de contexto

En [opencode.json](../../opencode.json) se activó:

- `compaction.auto: true`
- `compaction.prune: true`

Impacto esperado:

- Menor crecimiento del contexto en sesiones largas
- Reducción de consumo de tokens en iteraciones extensas

### 2. Watcher ignore para ruido de I/O

En [opencode.json](../../opencode.json) se definió `watcher.ignore` con exclusiones de alto ruido:

- `node_modules/**`
- `dist/**`
- `build/**`
- `.git/**`
- `.engram-data/**`
- `tmp-session-debug/**`
- `logs/**`
- `session/**`

Impacto esperado:

- Menos eventos irrelevantes
- Mejor tiempo de respuesta en tareas de lectura/búsqueda

### 3. Permisos globales de herramientas

Se estandarizó `permission` para operación local-first:

- Permitidos: `read`, `glob`, `grep`, `skill`, `question`, `todowrite`, `edit`
- Condicionales: `bash` con reglas granulares (`ask` por defecto + allow para comandos seguros)
- Restringidos: `websearch` y `webfetch` en `deny`
- Seguridad operativa: `doom_loop: deny`, `external_directory: ask`

Impacto esperado:

- Menos desvío a contexto web innecesario
- Menor riesgo de ejecución accidental de comandos no seguros

### 4. Límites de pasos por agente

Se configuró `steps` para controlar loops:

- `orchestrator: 12`
- subagentes: `6`

Impacto esperado:

- Menos iteraciones improductivas
- Mejor predictibilidad de tiempo/costo

### 5. Normalización de claves

Se removió `codesearch` de permisos de agentes por no corresponder al esquema operativo documentado
de OpenCode para permisos estándar.

Impacto esperado:

- Configuración más consistente
- Menos ambigüedad de comportamiento

## Verificación Recomendada

Ejecutar:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/agent-verify.ps1 -Domain config -Json
```

Resultado esperado:

- `result: PASS`
- `failed: 0`

## Operación en Tiempo Real

### Notificación sugerida al equipo

Se recomienda emitir un aviso operativo al iniciar sesión o tras actualizar
[opencode.json](../../opencode.json):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/notify-opencode-optimization.ps1
```

Este aviso comunica:

- Que se aplicó optimización de OpenCode
- Qué cambios impactan la operación
- Comando de verificación rápida para confirmar estado

### Automatización inteligente (temporal)

El sistema ahora incluye automatización adaptativa en
[scripts/utilities/adaptive-opencode-profile.ps1](../../scripts/utilities/adaptive-opencode-profile.ps1)
y se ejecuta automáticamente en los flujos de inicio de sesión:

- [scripts/utilities/session-autostart.cmd](../../scripts/utilities/session-autostart.cmd)
- [scripts/utilities/session-autostart.sh](../../scripts/utilities/session-autostart.sh)
- [config/session-autostart.config.json](../../config/session-autostart.config.json)

Comportamiento:

1. Detecta señales de presión operativa (por ejemplo, horario pico o presión de tokens).
2. Activa perfil OpenCode optimizado en forma temporal.
3. Emite notificación automática del cambio y deja comando de verificación.
4. Cuando detecta normalización de señales, restaura automáticamente la configuración baseline
   previa.

Persistencia y seguridad:

- Estado adaptativo: scripts/.session/adaptive-opencode-state.json
- Snapshot baseline temporal: scripts/.session/opencode-baseline.json

Comandos útiles:

```powershell
# Ver estado adaptativo
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-opencode-profile.ps1 -Mode Status

# Forzar activación temporal
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-opencode-profile.ps1 -Mode Optimize

# Forzar restauración baseline
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/adaptive-opencode-profile.ps1 -Mode Restore
```

## KPIs a Monitorear

- Tiempo a primera respuesta
- Duración total por tarea
- Uso de tokens por sesión
- Tasa de aprobaciones de `bash` fuera de reglas seguras
- Número de sesiones con compactación activada

## Rollback Rápido

Si se requiere rollback parcial:

1. Restaurar valores previos de `permission` en [opencode.json](../../opencode.json)
2. Ajustar o remover `watcher.ignore`
3. Re-ejecutar validación de config

## Referencias Oficiales

- OpenCode ES Docs: https://opencode.ai/docs/es/
- Configuración: https://opencode.ai/docs/es/config/
- Herramientas: https://opencode.ai/docs/es/tools/
- Permisos: https://opencode.ai/docs/es/permissions/
- Agentes: https://opencode.ai/docs/es/agents/
- Reglas: https://opencode.ai/docs/es/rules/
