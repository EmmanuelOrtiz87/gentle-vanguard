---
created: 2026-07-31 00:32:23
tags: [engram, architecture]
engram_id: 2312
type: architecture
---

# Diagnóstico completo: subagentes rotos y scripts de reemplazo

**What**: Diagnóstico completo del sistema de subagentes de opencode y scripts que reemplazan su funcionalidad en Gentle-Vanguard

**Why**: El otro modelo reportó problemas con subagentes y opencode. Se identificó que se crearon scripts compensatorios (2,668+ líneas en 7+ archivos) que duplican la funcionalidad de subagentes vía child_process en vez de usar el task tool nativo.

**Where**:
- opencode.json — routing fields con sintaxis PowerShell (@{...}) inválida como JSON
- config/auto-delegation.json — 2,495 líneas, ~400 skills mapeados, 15+ agentes que no existen en opencode.json
- src/team-orchestrator.ts (556 líneas) — Swarm Leader-Worker que reemplaza subagentes
- src/agent-message-bus.ts (466 líneas) — Sistema de mensajería entre agentes (duplica task tool)
- src/sdd-pipeline.ts (284 líneas) — Pipeline SDD manual (debería delegar a subagentes)
- src/sia-orchestrator.ts (691 líneas) — Self-Improving Agent (debería ser subagente)
- src/orchestrate-auto-fix.ts (360 líneas) — Referencia a auto-fix-delegate.ps1 que ya no existe
- src/self-diagnosis.ts (137 líneas) — Diagnóstico que recomienda subagentes pero no los usa
- src/hybrid-executor.ts (174 líneas) — Cloud connector que podría ser subagente
- scripts/utilities/ops/REVIEW/ — staged-review.ts (341 líneas), receipt-manager.ts (365 líneas) — deberían ser tareas QA
- scripts/utilities/MODEL-ROUTER/provider-failover.ts — lógica de routing duplicada

**Learned**:
1. PROBLEMA #1 (RAÍZ): opencode.json tiene campo "routing" con sintaxis @{...} de PowerShell en vez de JSON válido
2. PROBLEMA #2: auto-delegation.json define agentes (MKT, SALES, FINANCE, HR, LEGAL) que NO existen en opencode.json — routing fantasma
3. PROBLEMA #3: 100+ usos de spawn/child_process en src/ — la codebase spawnea procesos en vez de delegar a subagentes
4. PROBLEMA #4: TS files duplicados entre src/ y scripts/ — mismo tipo de archivo en dos lugares
5. PROBLEMA #5: session-autostart.cmd referencia session-autostart.ps1 que ya no existe
6. NO HAY scripts .ps1 activos en el árbol principal (todos migrados a TS o eliminados)

---
*Imported from Engram on 2026-09-06*
