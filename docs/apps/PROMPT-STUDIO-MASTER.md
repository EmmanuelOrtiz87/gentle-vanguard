# Prompt Studio — Documento Maestro

> **Versión:** v4.6.0 · **Fecha:** 2026-09-06 · **Estado:** producción local, estable **Sesión de
> origen:** 2026-09-05/06 (v4.2 → v4.6, 6 releases) **Canon técnico profundo:**
> [`docs/reference/PROMPT-STUDIO-GEMS.md`](../reference/PROMPT-STUDIO-GEMS.md) (§5a–§5g, con gotchas
> y descubrimientos) **Auditoría previa:**
> [`docs/apps/FUNCTIONAL-AUDIT-2026-09-02.md`](FUNCTIONAL-AUDIT-2026-09-02.md)

Este documento consolidan las tres vistas de la app: **negocio** (qué vale y para qué),
**funcional** (cómo se usa, pantalla por pantalla) y **técnico** (cómo está construido).

---

## 1. Negocio

### 1.1 Propuesta de valor

Prompt Studio es la **fábrica local de prompts y asistentes (gemas)** del stack GV: crear,
organizar, mejorar, importar y conversar con asistentes reutilizables — 100% local-first, sin
lock-in de conversaciones, con API keys propias (coste marginal ≈ 0) y datos en un SQLite propio que
el usuario respalda con un click.

**Diferenciadores competitivos (verificados en el benchmark de `PROMPT-LIBRARY-BENCHMARK.md`):**

| Capacidad                                                         | Prompt Studio                      | gemini.google.com | prompts.chat / alpackaai |
| ----------------------------------------------------------------- | ---------------------------------- | ----------------- | ------------------------ |
| Gemas propias + pool curado (12 GV)                               | ✅                                 | ✅ (solo cloud)   | ❌ (biblioteca estática) |
| Import 1-click de gemas de la cuenta Google                       | ✅ (browser + RPC `HcT8bb` propio) | —                 | ❌                       |
| Multi-proveedor (Gemini API + modelo del stack)                   | ✅ con streaming                   | solo Gemini       | su propio LLM            |
| Chat con markdown, streaming, historial persistente y backup JSON | ✅                                 | parcial           | parcial                  |
| Mejorar instrucciones con IA dentro del editor                    | ✅                                 | ❌                | ❌                       |
| Local-first (privacidad, offline-capable, sin suscripción)        | ✅                                 | ❌                | ❌                       |

### 1.2 Casos de uso cubiertos

El pool GV por defecto (12 gemas curadas) + las gemas del usuario cubren: revisión de código,
arquitectura, implementación, ventas B2B, pricing, redes sociales, educación, e-commerce, finanzas
personales, CV/empleo e imagen AI. Los flujos estrella:

1. **Convertir un prompt bien construido en asistente permanente** (botón "Convertir prompt actual
   en gema") — del prompt puntual al asistente reutilizable.
2. **Rescatar las gemas que el usuario ya creó en Gemini web** (import 1-click) — sin
   re-escribirlas, con instrucciones íntegras (4/4 gemas del usuario importadas verificadas).
3. **Refinar instrucciones con IA** ("Mejorar con IA") — de una idea a instrucción estructurada con
   criterios medibles en un click.
4. **Chatear con cualquier gema con markdown y streaming**, con historial que persiste entre
   sesiones y contador de uso real.

### 1.3 Estado y métricas (2026-09-06)

- 16 gemas (12 pool GV + 4 importadas del usuario con instrucciones íntegras).
- i18n completo es/en/pt; tema claro/oscuro consistentes.
- Backup JSON verificado (round-trip 34.8KB, protege el pool).
- Latencia local: gems/prompts 3–4ms; status Gemini 6ms (cached) / ~1.2s cold.
- 6 releases en 2 días (v4.2→v4.6), todos los hooks de CI/commits en verde.

### 1.4 Roadmap de negocio

- **Corto plazo:** rutina de backup (export JSON semanal); poblar usage real para ordenar por uso.
- **Mediano:** panel de settings dedicado (hoy backup vive en Acciones); export/import de gemas como
  "packs" compartibles (marketplace interno GV).
- **Largo:** onboarding de usuarios no técnicos (el import 1-click ya es el patrón), y distribución
  de la app con perfil de navegador incluido.

---

## 2. Funcional (guía de usuario por pantallas)

### 2.1 Tab «Crear» — constructor de prompts

- Formulario estructurado: tipo de tarea, rol, objetivo, contexto, criterios (uno por línea),
  formato de salida y tono → genera el prompt canónico con secciones Role/Task/Context/ Acceptance
  criteria/Output format/Verification.
- **Ejemplo** precarga un caso real; **Nuevo** limpia. Botón copiar + guardar a biblioteca con
  título, etiquetas y categoría (taxonomía de 8 categorías).
- Cada guardado genera una **versión** (historial con diff por líneas y restauración).

### 2.2 Tab «Biblioteca» — prompts guardados

- Búsqueda en lenguaje natural (scoring nativo), filtro por categoría, favoritos.
- Card actions: favorito, editar, **historial de versiones** (diff + restore), eliminar.

### 2.3 Tab «Gemas» — Gem Space (4 áreas separadas)

**① Conexión y modelo** — todo lo de configuración, separado del contenido:

- _Gemini API_: estado real de la key (✓ Conectado · N modelos / Key inválida / Sin key) con
  validación en vivo (cacheada 5 min para apertura instantánea).
- _Modelo de chat (Gemini)_: selector global de los modelos reales de tu cuenta, con **Auto** (usa
  el modelo de cada gema). El override viaja al server.
- _Cuenta de Google_: **Importar desde mi navegador** (1-click — ver §2.4) y cookie manual colapsada
  como opción avanzada.

**② Acciones** — los lanzadores, en su propia zona:

- **Convertir prompt actual en gema** (precarga el editor con el prompt de la vista Crear).
- **Nueva gema** (modal con nombre, descripción, categoría, tags, modelo con chips rápidos).
- **✨ Mejorar con IA** dentro del editor: reescribe las instrucciones con estructura profesional
  (reversible no-guardando).
- **Exportar/Importar backup**: JSON con prompts + gemas + historiales. El import no pisa el pool
  GV.

**③ Biblioteca de gemas** (columna izquierda):

- Búsqueda con ranking (nombre ×4, tags ×3, descripción ×2, instrucciones ×1).
- Filtros combo: Origen (Todas/Tuyas/Pool/Importada), Categoría (con counts), **Orden**
  (Recientes/Favoritas/**Más usadas**).
- Cards con badges (Pool GV / Tuya / Importada / "en chat" / "N usos") y acciones: probar en chat,
  duplicar (pool), **historial de versiones con diff + restaurar**, editar, eliminar.

**④ Chat** (columna derecha, siempre visible):

- Elegís gema por click en la biblioteca, en una **sugerida**, o con el botón "Probar".
- Multi-proveedor (Stack big-pickle / Gemini) con auto-preferencia de Gemini si hay key.
- **Streaming** progresivo de respuestas Gemini, **renderizado markdown**, botón **Parar**, copiar
  conversación / copiar mensaje individual, limpiar conversación.
- **Historial persistente por gema** (sobrevive recargas y sesiones).
- Input multilinea: Enter envía, Shift+Enter salto de línea.

### 2.4 Importar gemas de tu cuenta Google (1-click)

1. **Importar desde mi navegador** → verifica si el navegador propio del stack ya tiene tu sesión de
   Google (~10–15s).
2. Sin sesión → **Abrir ventana de login** → formulario normal de Google (email + contraseña
   - 2FA) → al ver Gemini con tu cuenta, **cerrá esa ventana**.
3. La app detecta la sesión automáticamente (cada 15s) y **importa solo** tus gemas custom con
   instrucciones completas (RPC de detalle; el listado de Google trae el prompt truncado).
4. Alternativa avanzada: cookie manual `__Secure-1PSID` (colapsada).

> Solo se importan las gemas **custom** de tu cuenta; las predefinidas de Google (62) quedan fuera
> por diseño. Si algo falla, "Reintentar import" siempre está activo y el estado lo dice en
> pantalla.

### 2.5 Detalles transversales

- **Ctrl+K** enfoca el buscador de la vista activa.
- Idiomas **es/en/pt** (selector en topbar) y tema **claro/oscuro** persistentes.
- Todo el estado crítico vive en el server (SQLite): recargar no pierde nada.
- Recomendación: **exportar backup JSON** como rutina (la data vive en `.runtime`, efímero).

---

## 3. Técnico

### 3.1 Arquitectura

```
apps/prompt-studio/
├── src/                    # Frontend React 18 + Vite 8 + TS strict
│   ├── App.tsx             # 3 tabs; Gem Space = 4 áreas split-screen (v4.2)
│   ├── Markdown.tsx        # Renderer markdown nativo XSS-safe (v4.6, sin deps)
│   ├── i18n.ts             # es/en/pt (tipado estricto de keys)
│   └── styles.css          # Tokens GV v2 + overrides [data-theme='light'] (v4.6)
├── server/server.ts        # Node http puro (sin frameworks) + better-sqlite3, :5177 loopback
├── start.sh / stop.sh      # Ciclo de vida nativo idempotente (vite :5176 + API :5177)
└── package.json
```

- **Server**: bind `127.0.0.1` only (ADR-0017). Spawn de procesos SIEMPRE async + `windowsHide`
  (normativa procesos-ocultos) — `stackChat` y `runBrowserImport` migrados de `spawnSync` que
  congelaba el event loop.
- **Frontend ↔ API**: cross-origin (5176→5177) con CORS explícito; **gotcha**: el `writeHead` del
  endpoint SSE debe repetir los headers CORS o el fetch rechaza y cae al fallback (§5c).

### 3.2 Datos (SQLite `.runtime/prompt-studio/prompts.db`)

| Tabla               | Contenido                                    | Notas                                          |
| ------------------- | -------------------------------------------- | ---------------------------------------------- |
| `prompts`           | biblioteca de prompts                        | versionado en `prompt_versions`                |
| `gems`              | gemas (origin: `default`/`local`/`imported`) | `usage_count` (v4.6); pool GV seed idempotente |
| `gem_versions`      | snapshots inmutables de gemas                | restore vía endpoint; UI desde v4.6            |
| `gem_chat_messages` | historial de chat por gema                   | persiste entre sesiones (v4.3)                 |

Backup: `GET /api/data/export` / `POST /api/data/import` (transaccional, upsert por id, no pisa
gemas `default`).

### 3.3 Capacidades del server (resumen)

- `prompts` CRUD + versiones + restore · `gems` CRUD + versiones + restore + duplicate
- `gems/:id/chat` — multi-proveedor; **SSE streaming** para Gemini (`:streamGenerateContent?alt=sse`
  vía node:https con `maxHeaderSize` 256KB — los headers de Gemini rompen undici) con eventos
  `meta → delta → done/error`; fallback no-stream
- `gems/:id/chat/history` GET/DELETE · `gems/improve` (mejora con IA)
- `gems/import-browser/status|login|import` — Playwright + Chromium perfil persistente
  (`channel:'chrome'`), login Google directo, parser regex JSON-aware del batchexecute y RPC de
  detalle `HcT8bb` (instrucciones íntegras — descubrimiento propio, §5f)
- `gemini/status` con cache 5min · `data/export|import` · `auth/google` (OAuth id_token)

### 3.4 Rendimiento (medido 2026-09-06)

| Métrica                              | Valor                             |
| ------------------------------------ | --------------------------------- |
| `GET /api/gems` / `GET /api/prompts` | 3–4ms                             |
| `GET /api/gemini/status`             | 1.2s cold → **6ms cached** (240x) |
| Bundle frontend                      | 222KB (66KB gzip)                 |
| Import browser (4 gemas con detalle) | ~30–60s                           |

### 3.5 Seguridad

- Server loopback-only; keys y sesión en `.runtime/` (no se commitean).
- Markdown: escape HTML total antes de transforms (no `dangerouslySetInnerHTML` con input crudo).
- Google login en Chrome real del sistema con perfil propio del stack (no el Chromium de Playwright
  — Google lo bloquea); cookies nunca extraídas del perfil del usuario.

### 3.6 Roadmap técnico

1. Streaming también para el proveedor stack (cuando opencode-zen resuelva sus rate limits).
2. Panel de settings dedicado (mover backup + proveedor + modelo ahí).
3. FTS5 para la búsqueda si el volumen crece (hoy el scoring JS alcanza con LIMIT 200).
4. Export/import de gemas como packs compartibles.

---

## 4. Historial de releases de esta evolución

| Versión | Fecha      | Entregable principal                                                                               |
| ------- | ---------- | -------------------------------------------------------------------------------------------------- |
| v4.2.0  | 2026-09-05 | Gem Space: 4 áreas split-screen, chat siempre visible, fix "Nueva gema" heredado, server async     |
| v4.3.0  | 2026-09-06 | Streaming SSE Gemini, historial de chat persistente, filtros combo, gotcha CORS-SSE                |
| v4.4.0  | 2026-09-06 | Import 1-click por navegador (UI), Mejorar con IA, búsqueda con ranking                            |
| v4.5.0  | 2026-09-06 | Login del import: formulario Google directo + Chrome real + auto-detección                         |
| v4.5.1  | 2026-09-06 | Import REAL: 3 bugs de parsing + RPC `HcT8bb` — gemas del usuario importadas íntegras              |
| v4.6.0  | 2026-09-06 | Auditoría perf/UX: cache 240x, markdown, backup JSON, tema claro, pt, versiones gemas, usage_count |
