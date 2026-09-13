---
created: 2026-05-25 15:09:11
tags: [engram, architecture]
engram_id: 1131
type: architecture
---

# Sistema de notificaciones token completo y fixes

**What**: Sistema de notificaciones de consumo de tokens implementado y depurado completamente. Incluye 3 scripts core (token-usage-notifier.ps1, token-usage-auto.ps1, toggle-token-display.ps1) + comandos /notif en pre-process-input.ps1.

**Why**: El usuario necesitaba visibilidad en tiempo real del consumo de tokens (input/output/context/cost) por turno y acumulado por sesión, con toggle individual por tipo de notificación.

**Where**:
- `scripts/utilities/token-usage-notifier.ps1` — Core del sistema: Show-CurrentMetrics, Show-AccumulatedMetrics, Show-Status, Get-EstimatedCost
- `scripts/utilities/toggle-token-display.ps1` — Toggle on/off por tipo individual (token/context/cost/accumulated)
- `scripts/utilities/token-usage-auto.ps1` — Bridge que se ejecuta post-respuesta
- `scripts/utilities/pre-process-input.ps1` — Handler de comandos /notif
- `CLAUDE.md` — Regla #6 actualizada: ejecutar CADA turno
- `docs/AGENTS.md` — Sección "Token Notification (Mandatory Every Turn)"

**Learned**:
- 3 bugs raíz: (1) `$repoRoot` detection paraba en `scripts/utilities/CONFIG/` por usar `Test-Path 'config'` en vez de `config\orchestrator.json` — esto afectaba a 43 scripts. (2) `$scriptDir` usado antes de definirse en pre-process-input.ps1. (3) `ConvertTo-Json` sin `-Depth 10` pierde hashtables anidadas.
- La arquitectura existente del notifier era sólida (387 líneas con show/accumulate/summary/toggle/status) pero nunca se ejecutaba porque dependía del agente y no había config inicial.
- `individualToggles` permite control granular: tokenUsage, contextSize, estimatedCost, sessionAccumulated.
- Costo estimado: ~$3/M input + ~$15/M output (Claude Sonnet 4 class conservador).
- Comandos /notif on/off/status/toggle/token/context/cost/accumulated funcionan via pre-process-input hook.

---
*Imported from Engram on 2026-09-06*
