# ADR-0021: GV Content OS — Superficie de Creación Nativa para el CMS Social

## Status

Accepted

## Date

2026-08-29

## Context

El pipeline de contenido existente (ADR-0018) es una máquina de estados de *operación*
(DRAFT → … → PUBLISHED → MEASURED) con empaquetado offline, pero la experiencia de
*creación* es precaria: `apps/content-cms` persiste en localStorage sin backend,
`marketing-agent`/`social-poster` generan por plantillas hardcodeadas sin LLM, y no hay
calendario, specs por red, imágenes ni flujo natural-language → contenido.

Se evaluaron candidatos externos (detalle y evidencia en
`docs/cms/CMS-PLATFORM-ANALYSIS-2026-08-29.md`, dos rondas):

- **Adopción de código/app:** charlie947/social-media-skills (MIT — skills, no app),
  SamurAIGPT/social-post (MIT, stack opuesto, 36★), Strapi (MIT, backend genérico),
  Directus (MSCL source-available, umbrales de ingresos), Ghost (MIT, editorial),
  trypost.it (SaaS cerrado, benchmark de producto).
- **Frameworks de orquestación:** LangChain/LangGraph (MIT, diferible), CrewAI (Python,
  overkill para TS local-first).

### Opciones consideradas

| Opción | Pros | Cons | Decisión |
| --- | --- | --- | --- |
| Adoptar un CMS headless (Strapi/Directus) como base | Admin, APIs instantáneas | Es backend genérico: la capa social+IA se construye igual; migración de Nexus y stack; licencia MSCL en Directus | ❌ Rechazada |
| Adoptar una app social open source (social-post) | Boilerplate rápido | Stack opuesto (Next/Prisma/cloud), sin calendario ni publicación real, tracción nula | ❌ Rechazada |
| SaaS / producto cerrado (trypost.it) | Producto maduro | Cerrado, datos fuera del stack, contradice ADR-0017 | ❌ Rechazada |
| Frameworks de agentes (LangChain/CrewAI) | Patrones de orquestación | Abstracción prematura; Python rompe local-first TS | ❌ Diferida |
| **Construir nativo re-fundando content-cms + engine, adoptando skills MIT** | Reutiliza Nexus, model-router, tokens GV, ADR-0018; sin migraciones; impronta GV | Más trabajo inicial en UX | ✅ **Elegida** |

## Decision

1. **GV Content OS** (nombre de trabajo) es la superficie de creación del contenido social:
   evolución de `apps/content-cms` (frontend + nuevo backend TS local) que alimenta el
   pipeline del ADR-0018. **ADR-0018 no se revoca** — el engine sigue siendo la máquina de
   estados de operación; el Content OS es la capa de creación/composición/calendario.
2. **MVP** (cortes en `docs/cms/CMS-PLATFORM-ANALYSIS-2026-08-29.md` §4): brief en lenguaje
   natural → variantes multi-red (texto, imagen, texto+imagen), specs por red, composer con
   previews, calendario con horarios recomendados, biblioteca de medios, voz de marca
   (`voice.md` + brand kit GV), publicación asistida (gate humano + export). Sin video, sin
   n8n, sin publicación por API (post-MVP opt-in).
3. **Storage**: Nexus (SQLite) con tablas nuevas: `content_items`, `content_variants`,
   `media_library`, `calendar_slots`, `publish_log`. Modelo diseñado para promoción externa
   sin migración conceptual.
4. **Generación desacoplada**: interface `ContentGenerator` / `MediaGenerator` plugables vía
   model-router (perfiles cheap/balanced/premium). Sin dependencia de un proveedor. Sin
   frameworks de agentes en MVP.
5. **Skills adoptadas** (MIT, `source: external-adopted`): voice-builder, post-writer,
   post-scorer, hook-generator, post-formatter, content-matrix, gemini-carousel,
   gemini-infographic, quote-post, graphic-designer (de charlie947/social-media-skills).
6. **Legacy deprecado**: `src/tools/marketing-agent.ts` y `src/tools/social-poster.ts` se
   reemplazan por el generador del Content OS; se eliminan en F3 tras paridad.

## Consequences

- Una sola fuente de verdad del modelo de contenido (fusiona los 3 modelos duplicados).
- Cero coste de licencias y sin vendor lock-in; todo queda en el patrón local-first del stack.
- La calidad de generación depende del model-router y los skills — el gate humano (ADR-0018)
  sigue siendo obligatorio antes de publicar.
- Publicación por API oficial queda como fase opt-in futura con OAuth por red.

## Referencias

- `docs/cms/CMS-PLATFORM-ANALYSIS-2026-08-29.md` — análisis completo de candidatos (2 rondas)
- `docs/adr/ADR-0017` (local-first), `docs/adr/ADR-0018` (content operations engine)
- `config/content-operations/platforms.json` — matriz de plataformas base
