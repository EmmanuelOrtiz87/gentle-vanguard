---
created: 2026-09-09 19:44:56
tags: [engram, architecture]
engram_id: 3821
type: architecture
---

# Fase 2 absorción Gentle-AI: adaptive-steps --risk-aware + Context7 MCP

**What**: Fase 2 de absorción Gentle-AI v2.7.0 completada: (1) `adaptive-steps --risk-aware` — ajusta el presupuesto de steps según risk tier (low→+0, standard→+8 sdd-verify, high→+16 rdd-4r-review), integrado con classifyRisk(); (2) Context7 MCP agregado a config/mcp-registry.json (server externo, npx @upstash/context7-mcp, autoStart:false opt-in); (3) doc ABSORPTION-GENTLE-AI-V2.7.md actualizada (6 secciones de absorción + verificación + backlog).
**Why**: Usuario pidió avanzar con el backlog de absorción de la release v2.7.0 de Gentle-Programming/gentle-ai.
**Where**: src/orchestration/adaptive-steps.ts (riskAwareStepBonus + integración en --estimate/--auto), config/mcp-registry.json (server context7), docs/reference/ABSORPTION-GENTLE-AI-V2.7.md
**Learned**: (1) Commits: 4ddd334e (adaptive-steps) + 7ed7ef43 (context7 + doc). (2) Context7 es opt-in porque requiere red (el stack es local-first, ADR-0017). (3) La telemetría anónima de instalación y el SDD archive compose quedaron en backlog por bajo valor para un stack local-first que ya tiene telemetría OTel y artifacts .sdd/.

---
*Imported from Engram on 2026-09-09*
