---
created: 2026-05-30 04:50:29
tags: [engram, architecture]
engram_id: 1226
type: architecture
---

# Optimizaciones aplicadas - resumen final

**What**: 4 sesiones de optimización de tokens y costos completadas. Todas las mejoras implementadas, verificadas y documentadas.

**Why**: Costos elevados por: (1) system prompt inflado 117 líneas, (2) sin cache de respuestas, (3) subagentes sin compresión, (4) modelos premium (glm-5).

**Where**:
- CLAUDE.md: comprimido 117→58 líneas (-50% tokens)
- scripts/utilities/pre-process-input.ps1: cache SHA256 + token tracking + pre-compact hook
- scripts/hooks/pre-task-compress.ps1: compresión de prompts subagentes (~30%)
- opencode.json: modelo cambiado glm-5→qwen-3.6-plus (6 ocurrencias, 4x ahorro)
- scripts/utilities/* → subdirectorios DETECT/, SESSION/, TOKEN/, HANDOFF/, PERFORMANCE-OPTIMIZATION/

**Learned**:
- PowerShell 7.6.1 parser rechaza [WORD] al inicio de strings entre comillas dobles en funciones — usar lambdas inline
- OpenCode envía historial completo + system prompt + tool schemas cada turno — crecimiento lineal inevitable
- Ahorro total estimado: 5-8x reducción de costos
- PSScriptAnalyzer: 0 errores en scripts modificados
- Sesión session-2026-05-30_0131 cerrada formalmente

---
*Imported from Engram on 2026-09-06*
