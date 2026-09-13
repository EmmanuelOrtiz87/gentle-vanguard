---
created: 2026-08-04 20:18:24
tags: [engram, architecture]
engram_id: 2535
type: architecture
---

# Stack CLI - Interfaz unificada para operar todas las herramientas

**What**: CLI unificado que expone todas las herramientas del stack desde un punto de entrada
**Why**: ~108 scripts PS1 + ~231 TS dispersos sin interfaz coherente; dificulta operación y onboarding
**Where**:
- src/cli/stack.ts (CLI principal)
- Integración: package.json scripts (stack, stack:health, etc.)
- Comandos: health, watchtower, dashboard, session, codegraph, engram, validate, tools, learning, knowledge

**Architecture**:
- Registry pattern: array COMMANDS[] extensible
- Parsing manual: process.argv.slice(2) como convención existente (gv.ts, graphify.ts)
- Helpers reutilizados: runNpxTsxSync de src/core/run-command.js
- Auto-complete: función printCompletions() para bash/zsh/pwsh

**Commands**:
- stack health [--detailed]
- stack watchtower [health|rebuild|autoheal|report]
- stack dashboard [start|stop|status]
- stack session [start|close|status]
- stack codegraph [sync|query|status]
- stack engram [sync|compact|integrity]
- stack validate [--full]
- stack tools [list|<tool>]
- stack learning [status|suggest|patterns]
- stack knowledge acquire <url> [--source <name>]

**Integration**:
- Reusa helpers existentes: printBanner, runNpxTsxSync
- Dashboard: integra con dashboard-common.ts (ports, process management)
- Session: conecta con session-close-orchestrator.ts
- Codegraph: usa npm run graphify -- query ...

**Learned**:
- Seguir convenciones existentes (manual parsing, no commander)
- Reusar helpers ya probados en dashboard-common.ts
- Extensible por diseño: añadir comando = push a COMMANDS[]
- Shell completions necesarios para UX profesional

---
*Imported from Engram on 2026-09-06*
