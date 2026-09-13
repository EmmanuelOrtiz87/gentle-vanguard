---
created: 2026-09-03 03:15:58
tags: [engram, decision]
engram_id: 3639
type: decision
---

# Análisis comparativo: Gentle-Vanguard vs repos externos (Gentle-AI + Microsoft AGT)

**What**: Realicé un análisis exhaustivo comparando el stack Gentle-Vanguard actual contra dos referencias clave del ecosistema: Gentle-AI (Gentleman Programming) y Agent Governance Toolkit (Microsoft).

**Why**: El usuario solicitó determinar si hay actualizaciones o mejoras necesarias basándose en las versiones actuales de estos repos externos. Ambos representan estados del arte en el ecosistema AI agent/desarrollo con agentes.

**Where**: Análisis de arquitectura, documentación web, y comparativa de capacidades.

**Learned**:

## Análisis Comparativo - Estado 2026-09-03

### 1. GENTLE-AI (Gentleman Programming) v2.5.0

**Estado**: Stable release, ecosistema consolidado

**Componentes principales que YA tenemos cubiertos:**
- ✅ SDD (Spec-Driven Development) completo con 7 fases
- ✅ RDD (Receipt-Driven Development) nativo con 5 gates
- ✅ Engram para memoria persistente
- ✅ Skills library (199+ habilidades)
- ✅ MCP integration
- ✅ Guardrails con learning

**Novedades potentes de Gentle-AI que NO tenemos:**
1. **Context7 MCP Server**: Documentación live de frameworks/librerías
2. **GGA (Gentleman Guardian Angel)**: AI provider switcher para fallbacks
3. **SDD Research Lane**: Evidencia externa auditable vinculada a SDD
4. **Handoff/Routing probabilístico**: "Elige la ruta más pequeña que logra el objetivo"
5. **Resilience handler v4**: Re-entrada a gates de revisión con tokens
6. **Acknowledge-approved pattern**: Tiempos de espera explícitos
7. **Topología de agentes revisada**: Delegación full vs solo-agent

### 2. AGENT GOVERNANCE TOOLKIT (Microsoft)

**Estado**: Public Preview v4.1.0, enterprise-grade

**Capacidades que NO tenemos y podrían sumar valor:**

**A. GOBERNANZA EJECUTABLE (Policy Engine)**
- Policy enforcement en YAML/OPA/Cedar con deterministic evaluation
- Zero-trust identity con SPIFFE/DID/mTLS
- Audit logging tamper-evident con Decision BOM
- Privilege rings (4 niveles de aislamiento)
- Tool guard con `@govern` wrapper

**B. CUMPLIMIENTO ESTÁNDARES**
- OWASP Agentic AI Top 10 completo (10/10)
- NIST AI RMF 1.0 (GOVERN/MAP/MEASURE/MANAGE)
- EU AI Act mapping automatizado
- SOC 2 controls con audit trail export
- 992 conformance tests con especificaciones RFC 2119

**C. SEGURIDAD MCP AVANZADA**
- MCP Security Gateway (tool poisoning, drift, typosquatting)
- Rug-pull detection con hash pinning
- SSRF detection en tools URL-fetching
- Toxic flow analysis (combinaciones de tools peligrosas)
- Runtime proxy para MCP (scans en tiempo real)

**D. OPERABILITY/RESILIENCE**
- Kill switch con SLO/error budgets
- Saga orchestration para rollback automático
- Circuit breakers nativos
- Chaos engineering para agents
- Shadow AI discovery (find unregistered agents)

### 3. ANÁLISIS DE GAPS - GENTLE-VANGUARD

**Fortalezas actuales:**
- Stack muy completo con SDD nativo
- Dashboard de observabilidad real-time
- 92 skills de ciberseguridad
- RDD con 5 gates bien definidos
- Design system consolidado v2
- Token tracking multi-tool
- Process hygiene y hygiene-checks

**Oportunidades de mejora identificadas:**

1. **MCP Security Gateway**: Tenemos skills de audit pero no el gateway runtime
2. **Policy Engine determinista**: Nuestros guardrails son reactivos, no preventivos
3. **Zero-trust identity intra-agent**: Podríamos implementar SPIFFE/DID
4. **Kill switch + chaos testing**: No tenemos termination control en agents
5. **EU AI Act compliance**: Necesitamos mapeo de controls
6. **Handoff/Routing mejorado**: Podríamos adoptar el modelo de "ruta más pequeña"
7. **Acknowledge pattern de RDD**: Mejoraría nuestra gestión de aprobaciones

**Conclusión**: El stack Gentle-Vanguard está en excelente estado y muchas de sus capacidades están a la par o superan a los repos externos (dashboard, design system, token tracking). Las áreas de mejora son principalmente en governance runtime determinista estilo Microsoft AGT y ciertos refinamientos SDD de Gentle-AI.

---
*Imported from Engram on 2026-09-06*
