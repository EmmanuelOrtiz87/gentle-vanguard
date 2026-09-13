---
created: 2026-07-07 22:44:41
tags: [engram, architecture]
engram_id: 1489
type: architecture
---

# v6.6-v7.0 stack completo — MCP SDK, Knowledge Layer, Multi-repo

**What**: Implementación completa del roadmap v6.6 MCP SDK, v6.7 Knowledge Layer, v7.0 Multi-repo Orchestration. Stack verificado: build 0 errores TS, watchtower 79/79 PASS.

**Why**: Completar la visión del roadmap local-first extensible, cerrando v6.5 formalmente y entregando v6.6, v6.7 y v7.0.

**Where**:
- scripts/utilities/MCP/mcp-manager.ps1 — create action multi-lenguaje (ts, js, py, go, rs) + -Build/-Register/-Start
- scripts/utilities/knowledge/knowledge-query.ps1 — query engine unificado (events, traces, feedback, checkpoints)
- scripts/utilities/MCP/mcp-mesh-scan.ps1 — 3 acciones: discover, status, sync multi-repo
- apps/web-dashboard/server/knowledge-api.ts — REST endpoint GET /api/knowledge
- apps/web-dashboard/src/components/KnowledgePanel.tsx — React UI search + source checkboxes
- apps/web-dashboard/src/components/MultiRepoView.tsx — React UI multi-repo server status
- apps/web-dashboard/src/App.tsx — rutas /knowledge y /multi-repo + nav links
- docs/sdd/v6.6-mcp-sdk-sdd.md, v6.7-knowledge-layer-sdd.md, v7.0-multi-repo-orchestration-sdd.md
- CHANGELOG.md, ROADMAP.md, VERSION

**Learned**: v6.6 create action requirió manejar 5 lenguajes con diferentes package managers y entry points. knowledge-query.ps1 usa filesystem-level queries a través de .session/ y .telemetry/. Build final confirma que los nuevos chunks KnowledgePanel (4.62kB) y MultiRepoView (5.18kB) se generan correctamente con code splitting.

---
*Imported from Engram on 2026-09-06*
