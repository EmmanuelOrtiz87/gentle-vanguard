# NORMATIVAS-CONFIG-SAFETY

> Normas para mantener tool configs libres de props no estándar.

## 1. Solo props del schema oficial

Cada tool config (`.windsurf/config.json`, `.continue/config.json`, `opencode.json`, etc.) solo debe contener propiedades definidas en su schema oficial. Las props no estándar son ignoradas silenciosamente, dando falsa sensación de que funcionan.

## 2. Props de proyecto van en `config/`

Toda configuración específica del proyecto (workspace, aiSettings, preProcessing, etc.) debe ir en `config/<tool>-project-settings.json`. El tool config puede referenciarlo via `rules` o documentación.

## 3. `systemPromptOptimization` nunca en tool configs

La optimización de prompts está centralizada en `config/system-prompt-optimization.json`. Cualquier tool config con `systemPromptOptimization` será rechazada.

## 4. Validación automática al inicio

El pipeline de autostart ejecuta `validate-tool-configs.ps1` que verifica todos los tool configs contra schemas oficiales. Si falla, se reporta pero no bloquea (para no interrumpir sesiones urgentes).

## 5. CI debe validar tool configs

Todo PR debe pasar `validate-tool-configs.ps1` antes de mergear. Ver `test-suite.yml` para integración.

## 6. Nuevas configs requieren schema conocido

Antes de agregar un nuevo tool config (`.github/copilot-instructions.md`, `.cursorrules`, etc.), verificar su schema oficial. Si no existe schema, documentar las props en `docs/research/`.

## 7. Fix, no tolerar

Cuando se detecta una prop no estándar, se debe mover a `config/<tool>-project-settings.json` inmediatamente. Las props ignoradas silenciosamente son deuda técnica.

## 8. `-Fix` para limpieza automática

`validate-tool-configs.ps1 -Fix` remueve automáticamente las props no estándar de los tool configs. Útil en `pre-commit` hooks.

## Referencias

- OpenCode schema oficial: `config/opencode.schema.json`
- systemPromptOptimization: `config/system-prompt-optimization.json`
- Windsurf project settings: `config/windsurf-project-settings.json`
- Continue project settings: `config/continue-project-settings.json`
