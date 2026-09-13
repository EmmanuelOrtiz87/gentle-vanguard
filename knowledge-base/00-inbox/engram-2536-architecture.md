---
created: 2026-08-04 20:18:37
tags: [engram, architecture]
engram_id: 2536
type: architecture
---

# Learning Engine + Knowledge Acquisition - Sistema de aprendizaje automático

**What**: Motor de aprendizaje que extrae patrones de errores, sugiere mejoras, y adquiere conocimiento externo
**Why**: Necesidad de "absorber conocimiento y hacerlo nativo del stack" sin intervención manual constante
**Where**:
- src/learning-engine.ts (motor de patrones y sugerencias)
- src/knowledge-acquisition.ts (fetch e integración externa)
- .session/learning/patterns.json (almacenamiento local)
- .session/knowledge-cache/ (caché de conocimiento externo)
- Integración: Engram para persistencia cross-session

**Architecture - Learning Engine**:
- learnFromError(error, context): extrae patrones, dedup por hash, frecuencia tracking
- suggestImprovement(domain): scoring por severidad × frecuencia × recencia
- integrateKnowledge(source, content): almacenamiento con SHA256 dedup
- Auto-generación: patrones > 3 ocurrencias → sugerencia automática

**Architecture - Knowledge Acquisition**:
- fetchUrl(url, timeout): con circuit breaker y retry
- parseContent(raw, mimeType): HTML strip, JSON parse, Markdown extract
- extractTags(): taggeado automático por keywords
- Integración: LLamada a learning-engine para absorción

**Data Model**:

  ```json
  {
    "patterns": [{ "id", "message", "domain", "severity", "frequency", "lesson" }],
    "suggestions": [{ "id", "type", "priority", "description", "rationale", "implemented" }],
    "knowledge": [{ "id", "source", "sha256", "tags", "integratedAt" }],
    "domains": { "name": { "count", "lastSuggestion" } }
  }
  ```

**CLI**:
- learning-engine.ts --status (estadísticas)
- learning-engine.ts --suggest [domain] (top 5 sugerencias)
- learning-engine.ts --patterns (ver patrones aprendidos)
- knowledge-acquisition.ts --fetch <url> --source <name>

**Integration**:
- Engram: mem_save para cross-session recall
- Error-memory.ts: reutiliza sistema existente
- Session-close-guardian: learnFromMistake() integra aquí

**Learned**:
- Composición > Duplicación: reusa error-memory, auto-norm-learner
- Deduplicación SHA256 esencial para knowledge acquisition
- Tags automáticos permiten retrieval semántico posterior
- Circuit breaker en fetch evita bloqueos por timeouts

---
*Imported from Engram on 2026-09-06*
