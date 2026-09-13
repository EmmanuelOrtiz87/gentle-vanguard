---
created: 2026-09-03 03:18:31
tags: [engram, decision]
engram_id: 3641
type: decision
---

# Gap analysis detallado: GV vs Gentle-AI v2.5.0 + MS AGT v4.1.0

**What**: Análisis detallado de gaps entre el stack Gentle-Vanguard y las versiones actuales de Gentle-AI (v2.5.0, stable 2026-09-01) y Microsoft Agent Governance Toolkit (v4.1.0, public preview).

**Why**: El usuario quiere validar si hay actualizaciones o complementos necesarios para evolucionar el stack, entendiendo que GV ya está en su mejor versión pero los repos externos pueden cubrir puntos flojos.

**Where**: Análisis de arquitectura de ambos repos + comparativa con src/ y config/ de GV.

**Learned**:

## GENTLE-AI v2.5.0 — "Review Closes Where Proof Ends"

Últimos commits (2026-09-02): review stop-hook para Claude Code, retry de validators malformados, cooldown state persistence, model assignments en delegación orgánica.

**Lo que GV YA cubre**: SDD 7 fases, RDD con kill-switch, Engram, skills, MCP, guardrails, routing probabilístico (adaptive-steps), acknowledge pattern (receipt-manager).

**Novedades Gentle-AI que GV NO tiene**:
1. **Context7 MCP server** — docs live de frameworks/librerías (GV usa web-crawler pero no Context7)
2. **GGA (Gentleman Guardian Angel)** — AI provider switcher con fallbacks (GV tiene model-fallback.json pero no switcher runtime)
3. **SDD Research Lane con evidencia auditable** — GV tiene sdd:research pero Gentle-AI lo integra como fase obligatoria post-Explore
4. **Review stop-hook** — hook que entrega la ruta preflight una vez por sesión candidata (GV no tiene esto)
5. **OpenCode SDD Profiles** — perfiles de modelo por fase (cheap/balanced/premium) — GV tiene config/model-router.json con perfiles pero no el patrón `gentle-orchestrator`

## MICROSOFT AGT v4.1.0 — Enterprise governance

Últimos commits (2026-08-31): signed http trust verification, replay attack prevention en Django trust middleware.

**Lo que GV YA cubre**: RDD kill-switch (rdd-kill-switch.ts), saga orchestrator, circuit breakers, chaos engineering, event-sourcing hash-chained (audit tamper-evident), review lenses, MCP gateway (lifecycle), guardrails input/output.

**Capacidades AGT que GV NO tiene**:
1. **Policy Engine determinista** (YAML/OPA/Cedar, fail-closed) — GV tiene guardrails reactivos (heuristic stub) pero NO policy engine preventivo determinista. Este es el gap MÁS importante.
2. **Zero-trust identity intra-agent** (SPIFFE/DID/mTLS) — GV no tiene identity layer entre agentes.
3. **MCP Security Gateway runtime** (tool poisoning, rug pulls, schema drift, typosquatting, hidden instructions) — GV tiene mcp-gateway.ts SOLO para lifecycle (start/stop), NO para seguridad runtime.
4. **Privilege rings** (4 niveles de aislamiento de ejecución) — GV no tiene sandboxing por anillo.
5. **Kill switch con SLO/error budgets** — GV tiene rdd-kill-switch pero no SLO/error-budget integrado.
6. **Shadow AI discovery** — detectar agentes no registrados.
7. **OWASP Agentic Top 10 compliance** — GV tiene skills de ciberseguridad pero no mapeo formal 10/10.
8. **Decision BOM / audit trail export** para SOC 2 / EU AI Act.

## VEREDICTO

GV está a la par o supera en: SDD, RDD, dashboard, design system, token tracking, process hygiene, event-sourcing audit.

Los gaps REALES de valor son:
1. **Policy Engine determinista fail-closed** (AGT) — el más valioso
2. **MCP Security Gateway runtime** (AGT) — tool poisoning/rug pull/drift
3. **Zero-trust identity** (AGT) — SPIFFE/DID
4. **Context7 MCP** (Gentle-AI) — docs live
5. **GGA provider switcher** (Gentle-AI) — fallback runtime
6. **OWASP Agentic Top 10 mapping** (AGT)

**Conclusión**: GV NO necesita reemplazar nada. Los complementos de mayor ROI son los de AGT (governance runtime determinista) y 2-3 de Gentle-AI (Context7, GGA, SDD profiles). Se recomienda priorizar: (1) Policy Engine, (2) MCP Security Gateway, (3) OWASP mapping.

---
*Imported from Engram on 2026-09-06*
