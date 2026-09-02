---
name: archify-studio
description: Genera diagramas de sistemas interactivos y de alta calidad (architecture, workflow, sequence, dataflow, lifecycle) a partir de un JSON IR tipado o una descripción de un sistema, usando el motor Archify absorbido en Gentle-Vanguard. El motor produce un HTML autocontenido con visor interactivo (search, pan/zoom, route probe, story playback), además de comparación de arquitectura (delta/PR-proof) y exports SVG/PNG/HTML. Incluye persistencia en Nexus DB, CLI nativo, API REST, skill GV y integración completa con Command Center. Source: external-adopted (tt-a1i/archify, MIT, v2.16.0).
---

# Archify Studio — Diagramas de sistemas interactivos (GV)

App nativa de Gentle-Vanguard que absorbe el motor **Archify v2.16.0** (MIT, ~39k ⭐) para producir diagramas de sistemas **interactivos y autocontenidos** (un solo HTML) con layout semántico (no auto-layout).

**Ubicación**: `apps/archify/` (engine + server REST + frontend React + CLI client)

**Registro Command Center**: app `archify` (API 4790 + Vite 5179) — prender/apagar a demanda via `http://127.0.0.1:8090`

---

## 🎯 Cuándo usar

- Visualizar arquitectura de sistemas/proyectos o describirla para diagramas interactivos
- Modelar workflows (CI/CD, approvals), secuencias (API calls, auth), dataflow (ETL, lineage) o lifecycles (state machines)
- Comparar dos versiones de arquitectura (**Delta / PR-proof** machine-readable con receipt)
- Producir artifacts portables para documentos, ADRs, reportes, runbooks, propuestas comerciales
- Generar diagramas en CI/CD gates (Delta gate), runbooks de incident response, data lineage para compliance

---

## 🧠 Mentalidad (del motor Archify)

- **Layout semántico** es la clave: el autor (agente) decide agrupación, jerarquía y narrativa espacial; **NO** es auto-layout (dagre/elk) ni tema Mermaid
- **Veracidad**: search/focus/route/reach derivan del JSON IR, no de topología inventada
- **Un artifact HTML autocontenido** + exports **SVG/PNG/HTML** + visor interactivo (search, pan/zoom, route probe, semantic lens, upstream/downstream reach, story playback, presentation mode)
- **Delta / PR-proof** machine-readable con receipt para code review gates
- **Veracidad del motor**: search/focus/route/reach derivan del JSON IR, no de topología inventada

---

## 📐 JSON IR — Formato estricto del motor (v2.16.0)

**Reglas críticas** (validar con `/api/validate` antes de renderizar):

- `schema_version`: **número entero** (1 o 2), **NO string**
- `type` por componente: **SOLO** `frontend | backend | database | cloud | security | messagebus | external`
- Nodos usan `id` + `type` + `label` (+ `sublabel` opcional); **NO** `title`/`kind` (properties adicionales → 422)
- Props adicionales → **422 Unprocessable Entity**

| Diagrama | schema_version | Estructura | Posicionamiento |
|----------|---------------|------------|-----------------|
| **architecture** | 1 | `components[]` + `boundaries[]` + `connections[]` | **REQUIERE** `pos:[x,y]` en cada component (layout libre; layout estricto: cruce edges/solape labels → 422) |
| **workflow** | 2 | `lanes[]` + `nodes[]` + `edges[]` | cada node con `col` + `lane` |
| **sequence** | 1 | `participants[]` + `messages[]` | `messages[].y` >= 160; variant: `default` \| `return` |
| **dataflow** | 1 | `stages[]` (SOLO `{label}`) + `nodes[]` + `flows[]` | nodes con `stage` + `row` |
| **lifecycle** | 1 | `lanes[]` + `states[]` + `transitions[]` | cada state con `col`; type: `start`\|`active`\|`waiting`\|`decision`\|`success`\|`failure`\|`neutral`\|`external` |

### Para Delta (architecture) — MÁS ROBUSTO

Usa **ejemplos reales del motor** (`engine/examples/checkout-platform.{base,head}.architecture.json`) que ya están validados — un layout manual ingenuo casi siempre falla por constraints de cruce/solape.

### Architecture válido (mínimo)

```json
{
  "schema_version": 1,
  "diagram_type": "architecture",
  "meta": { "title": "Web App", "subtitle": "High-level" },
  "components": [
    { "id": "users", "type": "external", "label": "Users", "pos": [40, 40] },
    { "id": "api", "type": "backend", "label": "API", "pos": [260, 40] },
    { "id": "db", "type": "database", "label": "DB", "pos": [480, 40] }
  ],
  "boundaries": [],
  "connections": [
    { "id": "users-to-api", "from": "users", "to": "api", "label": "HTTPS", "variant": "emphasis" },
    { "id": "api-to-db", "from": "api", "to": "db", "label": "SQL" }
  ]
}
```

### Connection variants

- `default` — línea continua
- `emphasis` — gruesa/principal
- `security` — estilo seguridad (rojo/punteado)
- `dashed` — punteado (para async/opcional)

---

## 🚀 Uso operativo

### Opción A — App nativa (recomendada, UI completa)

1. **Prender**: `npm run cc:start` → Command Center `http://127.0.0.1:8090` → click **"Archify Studio"** → abre `http://127.0.0.1:5179`
2. **Pestaña Estudio**: elegir tipo, pegar/editar JSON IR, ✓ Validar, ver en visor interactivo
3. **Exportar**: botones **HTML** / **SVG** / **PNG** (2x retina)
4. **Delta/PR**: pestaña Delta → pegar base + head → Comparar → receipt JSON
5. **Biblioteca**: 💾 Guardar / 📋 Duplicar / 🗑️ Eliminar (localStorage + Nexus events)

### Opción B — API REST directa (server puerto 4790)

```bash
# Health
curl http://127.0.0.1:4790/api/health

# Render → artifact HTML autocontenido
curl -s -X POST http://127.0.0.1:4790/api/render \
  -H 'content-type: application/json' \
  -d '{"type":"architecture","diagram":{...}}' > diagram.html

# Validate
curl -s -X POST http://127.0.0.1:4790/api/validate \
  -H 'content-type: application/json' \
  -d '{"type":"architecture","diagram":{...}}'

# Delta → { receipt, baseSvg, headSvg, html }
curl -s -X POST http://127.0.0.1:4790/api/delta \
  -H 'content-type: application/json' \
  -d '{"base":{...},"head":{...}}' > delta.html

# Examples
curl -s http://127.0.0.1:4790/api/examples
```

**Endpoints**:
- `GET /api/health` → `{ok, engine, types, port}`
- `GET /api/examples` / `GET /api/examples/:file`
- `POST /api/render` `{type, diagram}` → `{artifact}`
- `POST /api/validate` `{type, diagram}` → `{valid, error?}`
- `POST /api/delta` `{base, head}` → `{receipt, baseSvg, headSvg, html}`

---

### Opción C — CLI nativo del stack (scripts npm)

```bash
# Scripts npm (desde raíz del stack)
archify:render     # node apps/archify/engine/bin/archify.mjs render <type> <input.json> [output.html]
archify:compare    # node apps/archify/engine/bin/archify.mjs compare architecture <base> <head> [out.html]
archify:validate   # node apps/archify/engine/bin/archify.mjs validate <type> <input.json>
archify:cli        # CLI completo del motor (render, compare, validate, preview, inspect, guide, brands, examples, doctor, demo)
archify:start      # node --import tsx apps/archify/server/server.ts  (API server)
archify:smoke      # Smoke test E2E del server
archify:api        # **CLIENTE CLI DE LA API REST** (vía confiable)
```

### Cliente CLI de la API (`archify:api`) — **VÍA CONFIABLE**

```bash
# Health
npx archify:api health

# Validate
npx archify:api validate architecture mi-diagrama.json

# Render
npx archify:api render architecture mi-diagrama.json out.html

# Delta
npx archify:api delta base.json head.json delta.html

# Examples
npx archify:api examples
```

> ⚠️ **IMPORTANTE**: El CLI del motor (`archify:validate`, `archify:compare`) tiene "final artifact checks" que fallan en entornos headless con "Final artifact checks failed". **Para CI/CD, automatización y agentes: usa `archify:api` (API REST)** que usa los renderers directos sin checks frágiles.

---

## 🔗 Integración con el Stack Gentle-Vanguard

| Componente | Integración |
|---|---|
| **Command Center** | App `archify` registrada → prender/apagar a demanda (`http://127.0.0.1:5179`) |
| **Nexus DB** | Eventos automáticos: `archify.render`, `archify.validate`, `archify.delta` en tabla `events` |
| **Branding GV** | `gv-design-system.css` + shell `.gv-*` + logo + prefijo propio `--ar-*` |
| **Regla de oro** | Spawns `node` ocultos (`windowsHide`, `detached`, `unref`) |
| **Motor reutilizable** | `apps/archify/engine/` → importable por cualquier app/proyecto generado |

### Eventos en Nexus DB (tabla `events`)

| Evento | Payload | Uso |
|---|---|---|
| `archify.render` | `{type, ok}` | Métricas de uso, alertas de fallo |
| `archify.validate` | `{type, valid}` | Calidad de IR, alertas de schema |
| `archify.delta` | `{ok}` | Auditoría de PR gates, compliance |

**Consulta**:
```sql
SELECT type, payload, created_at FROM events WHERE type LIKE 'archify.%' ORDER BY id DESC LIMIT 10;
```

---

## 🔄 CI/CD Integration

### GitHub Actions — Delta Gate

```yaml
# .github/workflows/arch-delta.yml
- name: Archify Delta Gate
  run: |
    npx archify:api delta architecture/base.json architecture/head.json delta.html
    # fail si receipt tiene cambios no permitidos
```

### Cliente CLI en CI (`archify:api`)

```bash
# Render
npx archify:api render architecture arch/base.json out.html

# Delta gate
npx archify:api delta arch/base.json arch/head.json delta.html
# Verificar receipt en delta.html o parsear JSON
```

---

## 🐛 Troubleshooting rápido

| Problema | Causa | Solución |
|---|---|---|
| **App `stopped` en CC** | Procesos murieron | `curl -X POST http://127.0.0.1:8090/api/apps/archify/start` |
| **API 4790 no responde** | Server caído | `curl -X POST http://127.0.0.1:8090/api/apps/archify/start` |
| **Validate/Compare CLI falla** | "Final artifact checks" del wrapper CLI | **Usar `archify:api` (API REST)** |
| **Layout 422 architecture** | Falta `pos` o edges cruzan nodos | Añadir `pos:[x,y]` / mover componentes / usar ejemplos reales |
| **Delta 422** | Layout constraints (cruce/solape) | Usar ejemplos reales `checkout-platform.base/head` |
| **App no en CC** | CC no recargó registro | `npm run cc:stop && npm run cc:start` |
| **Eventos no en Nexus** | Server sin DB | Ver logs server; DB: `.runtime/gentle-vanguard.db` |

---

## 📦 Recursos y ejemplos

| Recurso | Path/URL |
|---|---|
| **Motor upstream** | https://github.com/tt-a1i/archify (MIT, v2.16.0) |
| **Motor docs** | `apps/archify/engine/ENGINE-README.md` |
| **Ejemplos IR (14)** | `apps/archify/engine/examples/*.json` |
| **Delta real** | `checkout-platform.base/head.architecture.json` |
| **App README** | `apps/archify/README.md` |
| **User Guide** | `docs/guides/USER_GUIDE.md` |
| **Business Case** | `docs/business/BUSINESS_CASE.md` |
| **Operations** | `docs/guides/OPERATIONS_GUIDE.md` |
| **Integration** | `docs/guides/INTEGRATION_GUIDE.md` |
| **Stack docs** | `docs/stack-manual-full.md` |

---

## 📄 Licencia

- **Motor Archify**: MIT — copyright (c) 2026 tt-a1i, (c) 2025 Cocoon AI
- **App GV (shell, server, UI, CLI client)**: Parte del stack Gentle-Vanguard
- **Uso comercial**: Permitido (MIT + stack interno)

---

*Skill v1.0 — Archify Studio · Gentle-Vanguard Stack · Listo para agentes y automatización*