# Prompt Studio v4 — Gemas nativas (Gem Manager local-first + Google)

**Fecha:** 2026-09-05 · **Estado:** implementado (backend + frontend, smoke verificado)
**Origen:** evolución solicitada de `apps/prompt-studio` tras research competitivo de
prompts.chat y alpackaai.xyz (ver `docs/reference/PROMPT-LIBRARY-BENCHMARK.md`).

## 1. Research: ¿hay API pública de Gems de Gemini?

**Conclusión corta: NO existe API oficial pública de CRUD de Gems.**

Evidencia verificada con el stack (web:select + scrape, 2026-09-05):

- `https://ai.google.dev/gemini-api/docs/gems` → **404** (página no existe; confirmado por scrape
  de jina-reader). Google no documenta endpoints de Gem manager para desarrolladores.
- La feature "Gems" es un producto de `gemini.google.com` (Gemini web / AI Studio) con endpoints
  internos no publicados.
- Comunidad: `HanaokaYuzu/Gemini-API` (PyPI `gemini_webapi`, Apache-2.0) documenta el acceso a
  Gems vía reverse-engineering de la web app con las cookies de sesión:
  - Auth: cookies `__Secure-1PSID` (+ `__Secure-1PSIDTS`) de una sesión logueada en
    `https://gemini.google.com` (no es OAuth ni API key).
  - `fetch_gems(include_hidden=True)` — lista gemas del usuario INCLUYENDO las predefinidas que
    Gemini oculta por defecto.
  - `create_gem(name, prompt, description)` / `update_gem(...)` / `delete_gem(...)` — CRUD.
  - Aplicar una gem como system prompt en una conversación (solo una por chat).
  - Regla: las gemas predefinidas del sistema **no** pueden editarse ni eliminarse.

### Implicación de diseño (ADR-0017, local-first)

Depender de cookies de sesión de un navegador para la funcionalidad principal es frágil
(expiran, Device Bound Session Credentials de Chromium reducen su vida útil a horas) y
constituye uso de API no pública. Decisión: **Gem Manager nativo local-first** como fuente de
verdad de las gemas del usuario, con **conector Google opcional** para lo que sí tiene API
pública:

| Capacidad                      | Mecanismo                          | Público | Local-first |
| ------------------------------ | ---------------------------------- | ------- | ----------- |
| CRUD de gemas propias          | SQLite `gems` + `gem_versions`     | ✅      | ✅          |
| Pool por defecto curado (GV)   | Seed idempotente de 12 gemas       | ✅      | ✅          |
| Chat con una gema              | Gemini API `:generateContent` con `system_instruction` | ✅ | ✅ (API key opcional) |
| Login con Google               | OAuth ID token → `oauth2.googleapis.com/tokeninfo`     | ✅ | ✅          |
| Sync bidireccional con cuenta Gemini | reverse-eng cookies `__Secure-1PSID` | ⚠️ no oficial | no recomendado como default |

## 2. Modelo de datos (nuevo en v4)

```sql
CREATE TABLE gems (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,            -- nombre outcome-driven
  instructions TEXT NOT NULL,    -- el prompt completo (Rol/Tarea/Criterios/Formato/Verificación)
  description TEXT DEFAULT '',   -- "de X a Y"
  category TEXT DEFAULT '',      -- taxonomía benchmark (8 categorías)
  tags TEXT DEFAULT '',
  model TEXT DEFAULT 'gemini-2.0-flash',
  origin TEXT DEFAULT 'local',   -- local | default | imported
  favorite INTEGER DEFAULT 0,
  google_id TEXT DEFAULT '',
  created_at TEXT, updated_at TEXT
);
CREATE TABLE gem_versions (      -- historial snapshot inmutable
  id TEXT PRIMARY KEY, gem_id TEXT, version INTEGER,
  reason TEXT, snapshot TEXT, created_at TEXT
);
```

## 3. Pool por defecto (12 gemas GV, curadas)

| Gema | Categoría | Transformación |
| ---- | --------- | -------------- |
| Revisor de código senior | Desarrollo | PR descuidado → review accionable (severidad+evidencia) |
| Arquitecto de sistemas | Desarrollo | idea vaga → diseño con ADR y trade-offs |
| Copiloto de implementación | Desarrollo | tarea → código aplicable |
| El Cerrador de Ventas B2B | Negocios | lead frío → cierre consultivo |
| Estratega de precios | Negocios | precio ad-hoc → estructura de pricing |
| Creador de hooks virales | Marketing/Redes | idea plana → hook que convierte |
| Replicador de contenido 1→15 | Marketing/Redes | un post → 15 piezas multiplataforma |
| Tutor que enseña hacer | Educación | duda → comprensión con práctica |
| Optimizador de fichas de producto | E-commerce | ficha plana → ficha CRO+SEO |
| Asesor de finanzas personales | Finanzas | deuda/ahorro vago → plan accionable |
| Constructor de CV anti-ATS | Empleo | CV genérico → CV que pasa filtros |
| Director de imagen AI | Imagen | idea visual → prompt de imagen reutilizable |

## 4. API REST nueva (server.ts)

| Endpoint | Método | Descripción |
| -------- | ------ | ----------- |
| `/api/gems?origin=&category=&q=` | GET | listar gemas + facets de categorías |
| `/api/gems` | POST | crear (origin local/imported) |
| `/api/gems/:id` | GET/PUT/DELETE | leer/editar/eliminar (defaults → 403) |
| `/api/gems/:id/duplicate` | POST | copiar una predefinida a local editable |
| `/api/gems/:id/chat` | POST | chat con `system_instruction` de la gema |
| `/api/gems/:id/versions[/:vid][/restore]` | GET/POST | historial + restore |
| `/api/auth/status` | GET | sesión Google activa |
| `/api/auth/google` | POST | verificar ID token (`tokeninfo`) → sesión |
| `/api/auth/logout` | POST | cerrar sesión |
| `/api/gemini/status` | GET | ¿hay API key de Gemini configurada? |
| `/api/gemini/key` | POST | guardar API key (`.runtime/prompt-studio/gemini-key.json`) |

Regla de integridad: las gemas `origin='default'` **no** pueden editarse ni eliminarse (403 con
mensaje "duplicala primero"). El historial versiona `name/instructions/description/category/tags/model`.

## 5. UI (v4)

- Pestaña "Guías" **eliminada** (reemplazada por "Gemas"). Las guías de uso quedan implícitas en
  la ayuda de la vista y en el flujo de conversión prompt→gema.
- Vista **Gemas**: conectores (estado Google + estado API key Gemini), búsqueda libre, chips de
  origen (Todas/Tuyas/Pool) y categoría, editor (crear/editar), lista con badges de origen,
  acciones por origen (default: duplicar; local: editar/eliminar), **chat nativo** embebido
  con la gema seleccionada.
- **Convertir prompt actual en gema**: desde el creador, un botón abre el editor de gema
  precargado con el prompt generado (instrucciones = prompt).

## 6. Seguridad / privacidad

- `auth.json` y `gemini-key.json` viven en `.runtime/prompt-studio/` (gitignored).
- La API key y el ID token **nunca** van al repo ni al bundle del frontend.
- El login con Google solo identifica (email/name/picture) — no da acceso a datos de Gemini web.
- Todo el CRUD es local; sin llamadas externas salvo el chat (si hay API key) y la verificación
  del ID token.

## 7. Pendiente / siguiente nivel

- Sync bidireccional real con la cuenta Gemini (cookies) — documentado como opción frágil;
  preferir export/import de gemas como plantillas JSON.
- Ampliar pool: 8-10 gemas más por categoría usando uso real.
- OAuth completo (flujo redirect con client ID configurable) para login sin pegar token manual.

## 8. Referencias

- Benchmark original: `docs/reference/PROMPT-LIBRARY-BENCHMARK.md`
- Código: `apps/prompt-studio/server/server.ts`, `apps/prompt-studio/src/App.tsx`,
  `apps/prompt-studio/src/i18n.ts` (apps desacopladas del repo del stack — git propio)
- Research web: `HanaokaYuzu/Gemini-API` (Apache-2.0), `ai.google.dev` (404 Gems docs)