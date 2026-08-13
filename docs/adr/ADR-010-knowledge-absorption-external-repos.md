# ADR-010: Absorción de Conocimiento Externo (Cybersecurity Skills, cariddi, diagram-design, watermarks-remover)

## Status

Accepted

## Date

2026-08-13

## Context

El stack Gentle-Vanguard debía robustecerse absorbiendo conocimiento externo de 4 repositorios
compartidos vía LinkedIn:

| Repo | Licencia | Contenido | Veredicto |
| --- | --- | --- | --- |
| `mukul975/Anthropic-Cybersecurity-Skills` | Apache-2.0 | 817 skills de ciberseguridad para agentes AI, 29 dominios, mapeadas a 6 frameworks (MITRE ATT&CK v19.1, NIST CSF 2.0, ATLAS, D3FEND, AI RMF, F3) | **Absorber** |
| `edoardottt/cariddi` | GPL-3.0 | Crawler de recon en Go: endpoints, secrets, API keys, tokens | **Reimplementar patrones** (sin copiar código) |
| `cathrynlavery/diagram-design` | MIT | 27 tipos de diagramas editoriales HTML/SVG self-contained | **Absorber** |
| `guillaumemeyer/watermarks-remover` | MIT | Remoción de marcas de proveniencia AI (C2PA, SynthID, Unicode, EXIF/XMP) | **Absorber con política dual** |

### Restricciones de licencia

- **GPL-3.0 (cariddi)**: incompatible con nuestro stack TS propietario. No se puede copiar código.
  Los patrones de detección de secrets (regex) son hechos técnicos públicos (formatos de tokens);
  se reimplementan en TS con estructura propia.
- **Apache-2.0 (cybersecurity-skills)**: compatible. Se absorben 25 skills seleccionadas.
- **MIT (diagram-design, watermarks-remover)**: compatible.

### Consideración ética (watermarks-remover)

La funcionalidad de *remoción* de marcas de proveniencia AI choca con la identidad del stack
(traceability, hash-chained audit, governance). Decisión: la capacidad existe pero es
**estrictamente on-demand** — el comportamiento normal es **inspección/verificación** de
proveniencia, y la remoción solo se activa ante una solicitud explícita e inequívoca del usuario
sobre contenido propio.

## Decision

### 1. Skills de ciberseguridad absorbidas (25/817 seleccionadas)

Criterio de selección: relevancia directa al stack (AI/LLM security, DevSecOps, supply chain,
API security, compliance, MCP security). Ubicadas en `.opencode/skills/` nivel 1, registradas en
`SKILL_REGISTRY` de `src/skill-frontmatter-sync.ts`.

Dominios cubiertos:
- **AI/LLM Security**: red-teaming con garak/promptfoo, prompt-injection (directa/indirecta/RAG),
  guardrails, system-prompt leakage, agentic tool invocation, MCP tool-poisoning
- **DevSecOps / Supply Chain**: security scanning en CI/CD, secret scanning (gitleaks), SBOM
  (generación/análisis), dependency-confusion, ataques supply-chain en CI/CD
- **API Security**: testing OWASP API Top 10, API inventory/discovery, WebSocket security
- **Compliance**: NIST 800-30, NIST CSF maturity, ISO 27001, GDPR, CMMC Level 2

Cada skill conserva su frontmatter rico original (mapeos MITRE ATT&CK, ATLAS, NIST CSF/AI RMF,
tags, versión, autor) + bloque `triggers` del formato de la casa.

### 2. Secret-scanner nativo (`src/secret-scanner.ts`)

Reimplementación TS pura de patrones de detección de secrets (80 patrones) inspirados en el
catálogo de cariddi, **sin copiar su código GPL-3.0**:

- `scanText` / `scanFiles` / `scanUrl`
- Entropy Shannon (≥3.5 bits/char) opcional para filtrar falsos positivos
- Redacción automática (`redact`: primeros 4 + últimos 4 chars)
- Reporte por categoría (aws/gcp/azure/github/gitlab/llm/slack/payment/cloud/generic/private-key)
  y riesgo (high/medium/low)
- CLI: `npx tsx src/secret-scanner-cli.ts --scan <path|url>`
- Config: `config/secret-scanner.json`
- Tests: `tests/unit/secret-scanner.test.ts` (29 tests)

### 3. diagram-design absorbido

`.opencode/skills/diagram-design/` (145 archivos, MIT, v2.3). 27 tipos de diagramas editoriales
HTML/SVG self-contained, sin build step. Mejora la documentación del stack (ADRs, reportes,
arquitectura) reemplazando el "Mermaid-slop" por diagramas editoriales en colores de marca.

### 4. ai-provenance con política dual

`.opencode/skills/ai-provenance/` (20 archivos, MIT):

| Modo | Comportamiento | Activación |
| --- | --- | --- |
| **INSPECCIÓN** (default) | Detectar/reportar/verificar C2PA, Unicode, SynthID, metadatos | Automática, comportamiento normal |
| **REMOCIÓN** (on-demand) | Limpiar C2PA/Unicode/metadatos | **Solo** solicitud explícita e inequívoca del usuario sobre contenido propio |

La política está documentada en el SKILL.md y en este ADR. La remoción se considera una
capacidad de emergencia/privacidad, no parte del flujo normal. Referencia a `references/ethics.md`
del skill original como guardrail.

## Consequences

### Positivas

- El stack gana un catálogo de 27 skills de ciberseguridad con mapeos a frameworks MITRE/NIST,
  ejecutables por los agentes (gov-agent, security hardening)
- Detección nativa de secrets (80 patrones) sin dependencias externas ni sidecars
- Diagramas editoriales para documentación
- Capacidad de verificación de proveniencia AI alineada con la identidad de traceability del stack

### Negativas / Riesgos

- 25 skills añaden ~30 MB al repo (referencias, scripts). Mitigación: se seleccionaron 25 de 817.
- Las skills de cibersec incluyen técnicas ofensivas (red-team); uso restringido a entornos
  autorizados (notice legal presente en cada SKILL.md)
- La política on-demand de ai-provenance requiere disciplina del orquestador: nunca remover
  marcas sin solicitud explícita
- cariddi sigue siendo un binario externo útil para recon masivo; no se integra como sidecar en
  esta iteración (posible follow-up)

## Follow-ups

- [ ] Hookear `secret-scanner` en pre-commit/CI (complemento a gitleaks)
- [ ] Añadir componente de security-scan a la watchtower
- [ ] Integración opcional del binario cariddi como sidecar (mismo patrón que witr-wrapper)
- [ ] Registrar skills absorbidas en `config/skill-dependencies.json` y `config/subagent-mapping.json`
