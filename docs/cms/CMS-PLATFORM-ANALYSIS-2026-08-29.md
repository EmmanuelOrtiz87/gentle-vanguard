# CMS de Contenido Social Gentle-Vanguard — Análisis, Verificación y Propuesta

> Fecha: 2026-08-29 · Sesión de análisis y definición de producto Estado: PROPUESTA para acuerdo —
> no implementado aún Alcance: definir qué construir (comprar/adoptar/construir), MVP, arquitectura
> y trazabilidad

---

## 1. Diagnóstico del estado actual (verificado en repo)

No existe un único CMS; el sistema de contenido son **tres piezas desconectadas**:

| Pieza                                              | Ruta                                                                                                                                                             | Estado real                                                                   | Limitación crítica                                                                                           |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Content Operations Engine** (ADR-0018, aceptado) | `src/content-operations/` (~490 líneas), `content/operations/master-manifest.json` (21 jobs reales), `config/content-operations/platforms.json` (11 plataformas) | Código real, testeado (15 tests), en uso                                      | Solo empaqueta y exporta ZIP; publicación 100% manual; **cero LLM**                                          |
| **Content Studio**                                 | `apps/content-cms/` v3.8.2 (React 18 + Vite)                                                                                                                     | CRUD + versionado + rollback + tests (domain/workflow/security/accessibility) | Persistencia solo `localStorage`; sin backend; sin conexión a Nexus; `published` es estado local, no publica |
| **Legacy pre-ADR**                                 | `src/tools/marketing-agent.ts` (592 l.), `src/tools/social-poster.ts` (426 l.), `docs/presentations/resources-index.html`                                        | Funcionales pero pre-ADR                                                      | Copy por **plantillas hardcodeadas**, no LLM; duplican el modelo de dominio                                  |

**Capacidades faltantes respecto del producto deseado:** generación con IA (texto e imágenes), specs
de formato/tamaño/estilo por red, calendario editorial, cronogramas inteligentes, horarios
recomendados, flujo natural-language → contenido, previews fieles por red, biblioteca de medios. El
ADR-0018 reconoce la deuda (refactor fase 2/3 no ejecutada) y las adapters de publicación son "fase
futura" en su propio diseño.

**Conclusión del diagnóstico:** la percepción del usuario es correcta. Lo que existe es un _pipeline
de empaquetado offline_ + un _editor local aislado_ — no un CMS social. No conviene "mejorarlo por
encima": conviene **unificar y re-fundar** aprovechando lo que sí está maduro (state machine del
engine, versionado del Studio, brand tokens).

---

## 2. Candidatos externos evaluados (verificados hoy)

### 2.1 charlie947/social-media-skills — ⭐ 2.8k, MIT, adoptable

- **Qué es:** 17 skills markdown para Claude (post-writer, hook-generator, voice-builder,
  post-scorer, content-matrix, gemini-carousel/infographic, reels-scripting, niche-research,
  analytics-dashboard). backing real: 415k+ followers del autor.
- **Cubre:** capa de _generación/asistencia_ (redacción en voz propia, ideación, prompts de imagen,
  scoring de posts). Patrón destacable: `voice.md` compartido como fuente de identidad editorial.
- **No cubre:** publicación, calendario, storage — no es una app.
- **Compatibilidad con el stack:** ALTA — encaja 1:1 con nuestra infraestructura de skills
  (`.opencode/skills/`, patrón ya usado con las 12 skills adoptadas de las Fases 1-3). MIT.

### 2.2 SamurAIGPT/social-post — ⭐ 36, MIT, descartado como base

- Next.js 14 + Prisma + PostgreSQL + NextAuth + Stripe + MuAPI. Genera texto multi-plataforma con
  previews y créditos de pago.
- **Descarte:** stack contrapuesto al nuestro (Next/Prisma/cloud vs TS nativo/SQLite/local-first
  ADR-0017), tracción casi nula, su demo comparte BD Supabase con otras apps, sin imágenes ni
  calendario. Valor residual: referencia de UI del composer multi-red (MIT, se puede inspirar el
  flujo de intent → editor pre-rellenado).

### 2.3 trypost.it — SaaS cerrado, benchmark de producto (no código)

- Social scheduler SaaS ($12/workspace) con calendario drag-and-drop, publicación vía API oficial
  (12 redes), editor multi-red con preview por formato, brand kits, aprobaciones, biblioteca de
  medios, automations (RSS/webhooks), analytics, y lo más relevante: **MCP server con 31
  herramientas** para que agentes operen el CMS.
- **Valor:** blueprint de producto y UX a imitar funcionalmente, no código reutilizable.

### 2.4 Segunda ronda de candidatos (2026-08-29, mismo día — verificados)

| Candidato                                                       | Veredicto            | Motivo                                                                                                                                                                                                                                                                                                                                  |
| --------------------------------------------------------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **postlight/awesome-cms** (CC0, 3.1k★)                          | Referencia           | Lista curada de 149 CMS. Valor solo como mapa para due diligence; ya cubrimos los relevantes (Strapi, Ghost, Directus, Payload aparecen ahí).                                                                                                                                                                                           |
| **Strapi** (MIT)                                                | Descartado como base | Headless CMS sólido Node/TS, pero es _backend de contenido genérico_: no trae social (calendario, specs por red, publicación). Adoptarlo sería migrar de Nexus a su modelo + su admin + su stack, y encima construir toda la capa social. Duplicaría cimientos que ya tenemos. Su patrón "MCP GA" valida nuestra dirección agent-first. |
| **Directus** (MSCL 1.0, _source-available_, NO open source OSI) | Descartado           | Licencia con umbrales ($5M ingresos / 50 empleados) — restricción futura de crecimiento exactamente del tipo que el producto quiere evitar. Backend genérico sobre Postgres/SQL externo; mismo problema de "capa social a construir" que Strapi.                                                                                        |
| **Ghost** (MIT)                                                 | Descartado           | Editorial/newsletter, no social. Sin generación IA, sin imágenes para redes, sin calendario multi-red. Solo relevante si algún día GV lanza newsletter con membresías (post-MVP, opt-in).                                                                                                                                               |
| **LangChain / LangGraph** (MIT)                                 | Opcional diferido    | Para nuestro flujo MVP (prompt → LLM → post-proceso) la orquestación propia ligera en TS basta (el stack ya tiene model-router, retrieval-grader, compresión). LangGraph se reconsidera cuando haya ramificación/bucles/human-in-the-loop complejo en el pipeline de generación. Cero dependencias nuevas en MVP.                       |
| **CrewAI** (plataforma comercial + OSS, Python)                 | Descartado           | Overkill: runtime Python externo rompe local-first TS. Útil solo si el pipeline fuera genuinamente multi-agente complejo; nuestro caso son calls encadenadas simples.                                                                                                                                                                   |

**Conclusión de la ronda 2:** ningún candidato modifica el plan. Refuerza la decisión nativa: los
CMS headless (Strapi/Directus) resuelven un problema que NO tenemos (modelado genérico de contenido
con admin) y no resuelven el que sí tenemos (capa social + IA). Los frameworks de agentes
(LangChain/CrewAI) son abstracción prematura para el MVP.

---

## 3. Decisión recomendada (ACUERDO PROPUESTO)

> **Re-fundar nuestro CMS de forma nativa (evolución de `apps/content-cms` +
> `src/content-operations`), adoptando la capa de generación de `social-media-skills` (MIT) y usando
> TryPost como blueprint de producto. No se adopta ningún SaaS ni app externa como base de código.**

Justificación:

1. **Nada externo encaja como base ejecutable**: el único repositorio app (social-post) es joven, de
   otro stack, sin calendario ni publicación real. TryPost es cerrado. Los "skills" de Charlie Hills
   son conocimiento, no software — y ese conocimiento se integra _gratis_ en nuestro patrón de
   skills ya existente.
2. **El stack ya tiene 70% de los cimientos**: state machine de contenido (engine),
   versionado/rollback (Studio), brand tokens GV, Nexus DB (23 tablas), skills de marketing
   adoptadas (copywriting, content-strategy, product-marketing, cro, etc.), model-router con
   perfiles cheap/balanced/premium, retrieval grader, compresión estructural, dashboard de
   observabilidad. Partir de otra base implicaría migrar o duplicar todo esto — exactamente el
   riesgo de "letra chica" que el usuario quiere evitar.
3. **Coherencia con la impronta**: local-first (ADR-0017), gate humano de aprobación (ADR-0018),
   audit hash-chained, sin vendor lock-in. Un SaaS externo contradiría la visión del stack.
4. **Lo que sí copiamos del exterior es lo barato y probado**: el conocimiento editorial de los
   skills (MIT) y el diseño de producto de TryPost (benchmark).

---

## 4. Definición de producto — "GV Content OS" (nombre de trabajo)

### 4.1 Visión

Un CMS local-first, ligero y didáctico que convierte **una necesidad en lenguaje natural** en
**publicaciones listas por red** (texto, imagen, texto+imagen), con calendario y criterio de
publicación, gate humano antes de publicar.

### 4.2 Principios (no negociables)

- **Local-first / server-optional** (ADR-0017). Datos en Nexus SQLite, medios en disco local.
- **Agent-first pero con gate humano**: la IA propone; el usuario aprueba antes de salir nada.
- **Una sola fuente de verdad**: modelo de contenido unificado (hoy hay 3 modelos duplicados — se
  consolida).
- **Sin video en MVP**. Sin n8n. Sin competir con WordPress (no es un gestor de webs).
- **Ligero**: no la super-app. Clicks cortos, lenguaje natural, previews fieles.

### 4.3 Capacidades MVP (cortes claros)

| #   | Capacidad                | Detalle                                                                                                                                                                                                                                                                                                                                            |
| --- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C1  | **Brief → contenido**    | Prompt en lenguaje natural ("post de lanzamiento de X para LinkedIn e Instagram") → genera variantes por red con formato, longitud, tono, hashtags y CTAs correctos. Motor: LLM vía model-router (perfil configurable) + skills de redacción adoptadas.                                                                                            |
| C2  | **Voz de marca**         | Archivo `voice.md` + brand kit GV (tokens, tono, prohibiciones). Inspirado en el patrón `voice.md` de social-media-skills.                                                                                                                                                                                                                         |
| C3  | **Imágenes**             | Texto+imagen: generación vía API de imagen (proveedor plugable: Gemini image / otros) + prompts de carrusel/infografía (patrón gemini-carousel) + composición sobre brand tokens.                                                                                                                                                                  |
| C4  | **Specs por red**        | Matriz por plataforma ya existente en `config/content-operations/platforms.json` extendida con: dimensiones de imagen, límites de caracteres, estilos de hook, hashtags óptimos, formato (4:5, 16:9, etc.). Redes MVP: LinkedIn, X, Instagram, Facebook, Telegram, Discord, Reddit, Threads, WhatsApp (channel/status). TikTok y blogs como C-ext. |
| C5  | **Composer multi-red**   | Un contenido → N variantes con preview fiel por red, edición inline, comparación lado a lado.                                                                                                                                                                                                                                                      |
| C6  | **Calendario editorial** | Semana/quincena/mes, drag-and-drop, slots por red, **horarios recomendados por red** (heurística local inicial, luego learning con métricas). Propuesta de cronograma generada por IA desde una necesidad/objetivo.                                                                                                                                |
| C7  | **Publicación asistida** | MVP: gate humano + export por red (copiar al portapapeles, abrir composer pre-rellenado donde la red lo permita, descarga de assets dimensionados). Conexión a las interfaces que ya usa el Content Operations Engine. Publicación por API oficial = **post-MVP** (opt-in, requiere OAuth por red).                                                |
| C8  | **Biblioteca de medios** | Medios en disco local, índice en Nexus, reutilizable entre posts y redes.                                                                                                                                                                                                                                                                          |
| C9  | **Ideación**             | "¿Qué publico esta semana?" → matriz de contenido (pilares × formatos) + propuestas con rationale, desde el objetivo (captar estudiantes, vender servicios, generar audiencia).                                                                                                                                                                    |

### 4.4 Fuera de MVP (explícito)

Video/Reels (solo guiones de texto), publicación automática por API, multi-tenant/equipos, analytics
de rendimiento por post (se prepara el modelo de datos pero no el scraping), integración n8n, blogs
completos (solo "post tipo blog" como formato de contenido).

---

## 5. Arquitectura técnica propuesta

```
apps/content-cms  (evolución → "GV Content OS")
├── frontend: React + Vite + tokens GV (ya existe, re-tematizado)
├── backend local: server TS nativo (nuevo, mismo patrón que web-dashboard WS/REST)
│   ├── domain: modelo unificado de contenido (fusiona engine + studio)
│   ├── generation: orquestador LLM (model-router, perfiles cheap/balanced/premium)
│   │   └── skills de generación: copywriting, content-strategy + adoptadas de social-media-skills
│   ├── media: biblioteca + generación de imágenes (proveedor plugable)
│   ├── scheduler: calendario + heurística de horarios
│   ├── export: reutiliza export-kit + platforms.json del engine (ADR-0018)
│   └── storage: Nexus (tablas nuevas: content_items, content_variants, media_library,
│       calendar_slots, publish_log) — audit hash-chained vía event-sourcing existente
```

Decisiones clave:

- **SQLite/Nexus, no Postgres** — cero coste operativo, patrón ya probado; el modelo de datos se
  diseña para que una futura promoción externa sea posible sin migración conceptual.
- **LLM desacoplado**: interface `ContentGenerator` con adaptadores; el model-router decide modelo
  según perfil. No depender de un proveedor.
- **Imágenes plugable**: mismo patrón `MediaGenerator`.
- **El ADR-0018 NO se revoca**: el engine queda como máquina de estados de _operación_; el CMS es la
  _superficie de creación_ que alimenta ese pipeline. Se documenta como ADR nuevo (ADR-0021
  propuesto: "Content OS — superficie de creación agent-first").
- **Skills adoptadas de social-media-skills**: portar las ~8 relevantes a `skills/` con frontmatter
  `source: external-adopted` + security review (patrón estándar del stack, igual que las Fases 1-3).

---

## 6. Plan de implementación (fases)

| Fase                           | Contenido                                                                                                             | Estimación    |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------- | ------------- |
| **F0 — Fundación** (1 sesión)  | ADR-0021, modelo de dominio unificado, esquema Nexus, backend local esqueleto, adoptar skills MIT con security review | ~1 sesión     |
| **F1 — MVP núcleo**            | C1 (brief→texto multi-red) + C5 (composer con previews) + C4 (specs por red) + persistencia Nexus + voz de marca C2   | 2-3 sesiones  |
| **F2 — Imágenes + calendario** | C3 (texto+imagen) + C6 (calendario + horarios recomendados) + C8 biblioteca                                           | 2-3 sesiones  |
| **F3 — Ideación + cierre**     | C9 (matriz/cronogramas propuestos) + C7 pulido (export asistido) + didáctica/onboarding + observabilidad en dashboard | 1-2 sesiones  |
| **Post-MVP**                   | Publicación por API (OAuth por red, opt-in), analytics, video                                                         | según demanda |

Riesgos identificados y mitigación:

- **Coste de tokens en generación**: perfiles de model-router + compresión estructural
  `mode:'output'` (lossy OK para copy) + caching en Nexus (response cache ya existe).
- **Duplicar modelos otra vez**: F0 fusiona explícitamente los 3 modelos existentes y depreca los
  legacy (`marketing-agent`, `social-poster`) — decisión a registrar en el ADR.
- **Scope creep**: las secciones 4.3/4.4 son el contrato; todo lo demás va a backlog post-MVP.

---

## 7. Acuerdos pendientes de confirmar (para próximas sesiones)

1. ¿Confirma la decisión de construir nativo (sección 3) en vez de adoptar código externo?
2. ¿Nombre del producto? (propuesta de trabajo: "GV Content OS")
3. ¿Proveedores de imagen y LLM preferidos para MVP? (el stack ya soporta Gemini free tier para
   labeling; hacer lo mismo para imágenes es la vía más barata)
4. ¿Publicación asistida (C7) es suficiente para MVP, o alguna red requiere API desde el día 1?
5. ¿Arrancamos F0 en la próxima sesión?

---

## Fuentes

- Repos evaluados: github.com/charlie947/social-media-skills (MIT, 2.8k★),
  github.com/SamurAIGPT/social-post (MIT, 36★), trypost.it (SaaS, benchmark)
- Estado interno: ADR-0018, `src/content-operations/`, `apps/content-cms/`,
  `src/tools/marketing-agent.ts`, `src/tools/social-poster.ts`
