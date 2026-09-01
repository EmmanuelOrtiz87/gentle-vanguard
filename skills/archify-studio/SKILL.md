---
name: archify-studio
description: Genera diagramas de sistemas interactivos y de alta calidad (architecture, workflow, sequence, dataflow, lifecycle) a partir de un JSON IR tipado o una descripción de un sistema, usando el motor Archify absorbido en Gentle-Vanguard. El motor produce un HTML autocontenido con visor interactivo (search, pan/zoom, route probe, story playback), además de comparación de arquitectura (delta/PR-proof) y exports. Usar cuando se requiera visualizar arquitectura, flujos, secuencias, dataflow o estados de un sistema/proyecto con calidad editorial interactiva. Source: external-adopted (tt-a1i/archify, MIT, v2.16.0).
---

# Archify Studio — diagramas de sistemas interactivos (GV)

App nativa de Gentle-Vanguard que absorbe el motor **Archify** (MIT) para producir diagramas de
sistemas **interactivos y autocontenidos** (un solo HTML) con layout semántico (no auto-layout).

Ubicación: `apps/archify/` (engine + server REST + frontend React).

## Cuándo usar

- Visualizar la arquitectura de un sistema/proyecto o describirla para un diagrama interactivo.
- Modelar workflows (CI/CD, approvals), secuencias (API calls, auth), dataflow (ETL, lineage) o
  lifecycles (state machines).
- Comparar dos versiones de una arquitectura (delta / PR proof).
- Producir un artifact portable para un documento, ADR o reporte.

## Mentalidad (del motor)

- **Layout semántico** es la clave: el autor (agente) decide agrupación, jerarquía y narrativa
  espacial; NO es un tema de Mermaid ni auto-layout (dagre/elk).
- **Veracidad**: search/focus/route/reach derivan del JSON IR, no de topología inventada.
- **Un artifact HTML autocontenido** + exports PNG/SVG/WebM/share-cards.

## JSON IR (tipos)

Cada tipo tiene un JSON Schema + renderer en `apps/archify/engine/`. **IMPORTANTE — formato estricto
del motor** (v2.16.0), validar con `/api/validate` antes de renderizar:

- `schema_version` es **número entero** (1 o 2), no string.
- `type` por componente: SOLO `frontend | backend | database | cloud | security | messagebus | external`.
- Los nodos usan `id` + `type` + `label` (+ `sublabel`); NO `title`/`kind` (properties adicionales rechazadas).

| Diagrama | schema_version | Estructura | Posicionamiento |
|----------|---------------|------------|-----------------|
| architecture | 1 | components[] + boundaries[] + connections[] | cada component REQUIERE `pos:[x,y]` (layout libre; layout estricto: cruce de edges/solape de labels → 422) |
| workflow | 2 | `lanes[]` + nodes[] + edges[] | cada node con `col`+`lane` |
| sequence | 1 | participants[] + messages[] | `messages[].y` >= 160; variant: default\|return |
| dataflow | 1 | `stages[]` (SOLO {label}) + nodes[] + flows[] | nodes con `stage`+`row` |
| lifecycle | 1 | `lanes[]` + states[] + transitions[] | cada state con `col`; type: start\|active\|waiting\|decision\|success\|failure\|neutral\|external |

Para **delta** de architecture es MÁS ROBUSTO usar los ejemplos reales del motor
(`engine/examples/checkout-platform.{base,head}.architecture.json`) que ya están validados — un
layout manual ingenuo casi siempre falla por constraints de cruce/solape.

Ejemplo architecture válido:

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

## Uso operativo

### Opción A — App nativa (recomendada)

1. Prender desde Command Center: `npm run cc:start` → abrir `http://127.0.0.1:5179` (app `archify`).
2. En la pestaña **Estudio**: elegir tipo, pegar/editar JSON IR, validar y renderizar.
3. **Delta/PR**: pegar base + head y comparar (obtiene receipt machine-readable).
4. **Biblioteca**: guardar/duplicar/eliminar diagramas (localStorage).

### Opción B — API REST directa

Server en `ARCHIFY_PORT` (default 4790). Endpoints:

```bash
# render → devuelve artifact HTML autocontenido
curl -s -X POST http://127.0.0.1:4790/api/render -H 'content-type: application/json' \
  -d '{"type":"architecture","diagram":{...}}'

# validate → schema
curl -s -X POST http://127.0.0.1:4790/api/validate -H 'content-type: application/json' \
  -d '{"type":"workflow","diagram":{...}}'

# delta → { receipt, baseSvg, headSvg, html }
curl -s -X POST http://127.0.0.1:4790/api/delta -H 'content-type: application/json' \
  -d '{"base":{...},"head":{...}}'

# ejemplos IR
curl -s http://127.0.0.1:4790/api/examples
```

### Opción C — CLI del motor (para scripts/agentes)

El motor trae su propio CLI en `apps/archify/engine/bin/archify.mjs`:
`render <type> <input.json> [output.html]`, `compare`, `validate`, `preview`, `inspect`, `check`,
`guide`, `brands`, `doctor`, `demo`.

## Fuente / licencia

Motor heredado de **tt-a1i/archify** (MIT) y **Cocoon-AI/architecture-diagram-generator** (MIT).
El shell React, server REST y frontend son nativos de Gentle-Vanguard. Ver
`apps/archify/engine/ENGINE-README.md` para actualizar el motor.
