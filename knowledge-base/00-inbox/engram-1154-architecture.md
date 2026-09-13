---
created: 2026-05-26 12:25:56
tags: [engram, architecture]
engram_id: 1154
type: architecture
---

# oh-my-openagent capabilities integrated into GV — full stack

**What**: Implementación completa de las 4 capacidades de oh-my-openagent en Gentle-Vanguard stack: Hashline (SHA-256, 411 files, 83,214 hashes), Team Mode (leader+follower+mailbox, 7 acciones), Skill MCP Manager (6 acciones, parseo YAML frontmatter), Dispatch extendido con -Mode team. Integración con lefthook, pre-compact-hook, orchestrator.json.

**Why**: Dotar al stack de GV de las capacidades de hash-anchored edits, orquestación multi-agente, MCPs on-demand vía skills, sin depender de plugins externos.

**Where**:
- scripts/editing/hashline.ps1
- scripts/utilities/WORKFLOW-ORCHESTRATION/team-mode.ps1 (235 líneas)
- scripts/utilities/WORKFLOW-ORCHESTRATION/dispatch-agent.ps1
- scripts/utilities/UTILITIES/skill-mcp-manager.ps1
- scripts/utilities/pre-compact-hook.ps1
- .lefthook.yml, config/orchestrator.json

**Learned**: 9 bugs corregidos en total. Los más críticos: (1) `"hello" -is [PSObject]` = $true — strings tienen PSObject.Properties, checkear antes de [PSObject]; (2) `return @()` = $null — output stream enumera array vacío; (3) `return @(single)` = unwrap — usar comma trick `return , $array`; (4) PSObject ≠ hashtable — ConvertFrom-Json retorna PSObject, requiere conversión recursiva. Ver docs/AGENTS.md#Key-References para más.

---
*Imported from Engram on 2026-09-06*
