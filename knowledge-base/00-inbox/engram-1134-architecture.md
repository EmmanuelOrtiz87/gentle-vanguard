---
created: 2026-05-25 15:18:26
tags: [engram, architecture]
engram_id: 1134
type: architecture
---

# Integracion completa: notificaciones + modelo configurable

**What**: Integración final del sistema de notificaciones de tokens. Get-EstimatedCost ahora lee config/provider-costs.json para tasas por modelo. token-usage-auto.ps1 pasa -Model al notifier. Comandos /notif compact para toggle compact/verbose mode.

**Why**: El usuario necesitaba visibilidad de consumo con costo preciso según el modelo usado, y control de formato compacto/verbose.

**Where**:
- token-usage-notifier.ps1: parámetro -Model, Get-EstimatedCost actualizado
- token-usage-auto.ps1: pasa -Model $Model al notifier
- pre-process-input.ps1: handler /notif compact
- toggle-token-display.ps1: ValidateSet incluye "compact"

**Learned**:
- Bug menor: toggle-token-display.ps1 línea ~122, el switch de $typeLabel no incluye case "compact" → muestra "[]" vacío. Fix: agregar "compact" { "Compact Mode" }.
- provider-costs.json tiene tasas per-1K-tokens. Get-EstimatedCost multiplica por 1000 para convertir a per-M.
- Claude Sonnet 4: $0.003/1K input = $3/M, $0.015/1K output = $15/M.
- El flujo completo notificador funciona: pre-process captura /notif → toggle-token-display → token-usage-notifier → Show-CurrentMetrics/Show-AccumulatedMetrics.

---
*Imported from Engram on 2026-09-06*
