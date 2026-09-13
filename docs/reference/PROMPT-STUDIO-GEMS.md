# Prompt Studio v4 — Gemas nativas (Gem Manager local-first + Google)

**Fecha:** 2026-09-05 · **Estado:** implementado (backend + frontend, smoke verificado) **Origen:**
evolución solicitada de `apps/prompt-studio` tras research competitivo de prompts.chat y
alpackaai.xyz (ver `docs/reference/PROMPT-LIBRARY-BENCHMARK.md`).

## 1. Research: ¿hay API pública de Gems de Gemini?

**Conclusión corta: NO existe API oficial pública de CRUD de Gems.**

Evidencia verificada con el stack (web:select + scrape, 2026-09-05):

- `https://ai.google.dev/gemini-api/docs/gems` → **404** (página no existe; confirmado por scrape de
  jina-reader). Google no documenta endpoints de Gem manager para desarrolladores.
- La feature "Gems" es un producto de `gemini.google.com` (Gemini web / AI Studio) con endpoints
  internos no publicados.
- Comunidad: `HanaokaYuzu/Gemini-API` (PyPI `gemini_webapi`, Apache-2.0) documenta el acceso a Gems
  vía reverse-engineering de la web app con las cookies de sesión:
  - Auth: cookies `__Secure-1PSID` (+ `__Secure-1PSIDTS`) de una sesión logueada en
    `https://gemini.google.com` (no es OAuth ni API key).
  - `fetch_gems(include_hidden=True)` — lista gemas del usuario INCLUYENDO las predefinidas que
    Gemini oculta por defecto.
  - `create_gem(name, prompt, description)` / `update_gem(...)` / `delete_gem(...)` — CRUD.
  - Aplicar una gem como system prompt en una conversación (solo una por chat).
  - Regla: las gemas predefinidas del sistema **no** pueden editarse ni eliminarse.

### Implicación de diseño (ADR-0017, local-first)

Depender de cookies de sesión de un navegador para la funcionalidad principal es frágil (expiran,
Device Bound Session Credentials de Chromium reducen su vida útil a horas) y constituye uso de API
no pública. Decisión: **Gem Manager nativo local-first** como fuente de verdad de las gemas del
usuario, con **conector Google opcional** para lo que sí tiene API pública:

| Capacidad                            | Mecanismo                                              | Público       | Local-first                 |
| ------------------------------------ | ------------------------------------------------------ | ------------- | --------------------------- |
| CRUD de gemas propias                | SQLite `gems` + `gem_versions`                         | ✅            | ✅                          |
| Pool por defecto curado (GV)         | Seed idempotente de 12 gemas                           | ✅            | ✅                          |
| Chat con una gema                    | Gemini API `:generateContent` con `system_instruction` | ✅            | ✅ (API key opcional)       |
| Login con Google                     | OAuth ID token → `oauth2.googleapis.com/tokeninfo`     | ✅            | ✅                          |
| Sync bidireccional con cuenta Gemini | reverse-eng cookies `__Secure-1PSID`                   | ⚠️ no oficial | no recomendado como default |

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

| Gema                              | Categoría       | Transformación                                          |
| --------------------------------- | --------------- | ------------------------------------------------------- |
| Revisor de código senior          | Desarrollo      | PR descuidado → review accionable (severidad+evidencia) |
| Arquitecto de sistemas            | Desarrollo      | idea vaga → diseño con ADR y trade-offs                 |
| Copiloto de implementación        | Desarrollo      | tarea → código aplicable                                |
| El Cerrador de Ventas B2B         | Negocios        | lead frío → cierre consultivo                           |
| Estratega de precios              | Negocios        | precio ad-hoc → estructura de pricing                   |
| Creador de hooks virales          | Marketing/Redes | idea plana → hook que convierte                         |
| Replicador de contenido 1→15      | Marketing/Redes | un post → 15 piezas multiplataforma                     |
| Tutor que enseña hacer            | Educación       | duda → comprensión con práctica                         |
| Optimizador de fichas de producto | E-commerce      | ficha plana → ficha CRO+SEO                             |
| Asesor de finanzas personales     | Finanzas        | deuda/ahorro vago → plan accionable                     |
| Constructor de CV anti-ATS        | Empleo          | CV genérico → CV que pasa filtros                       |
| Director de imagen AI             | Imagen          | idea visual → prompt de imagen reutilizable             |

## 4. API REST v4.1 (server.ts)

| Endpoint                                  | Método         | Descripción                                                                             |
| ----------------------------------------- | -------------- | --------------------------------------------------------------------------------------- |
| `/api/gems?origin=&category=&q=`          | GET            | listar gemas + facets de categorías                                                     |
| `/api/gems`                               | POST           | crear (origin local/imported)                                                           |
| `/api/gems/:id`                           | GET/PUT/DELETE | leer/editar/eliminar (defaults → 403)                                                   |
| `/api/gems/:id/duplicate`                 | POST           | copiar una predefinida a local editable                                                 |
| `/api/gems/:id/chat`                      | POST           | chat con `system_instruction` de la gema — `{ provider: 'stack' \| 'gemini', message }` |
| `/api/gems/:id/versions[/:vid][/restore]` | GET/POST       | historial + restore                                                                     |
| `/api/gems/import-gemini`                 | POST           | import real de tus gemas de Google (`__Secure-1PSID` cookie) — experimental             |
| `/api/auth/status`                        | GET            | sesión Google activa                                                                    |
| `/api/auth/google`                        | POST           | verificar ID token (`tokeninfo`) → sesión                                               |
| `/api/auth/logout`                        | POST           | cerrar sesión                                                                           |
| `/api/gemini/status`                      | GET            | key configurada + `{ keyConfigured, keyValid, models[] }` (valida en vivo)              |
| `/api/gemini/key`                         | POST           | guardar API key — **valida** contra la API antes de aceptarla (400 si inválida)         |

Regla de integridad: las gemas `origin='default'` **no** pueden editarse ni eliminarse (403 con
mensaje "duplicala primero"). El historial versiona
`name/instructions/description/category/tags/model`.

### Chat multi-proveedor (v4.1)

| Proveedor | Mecanismo                                                                      | Requisito                  |
| --------- | ------------------------------------------------------------------------------ | -------------------------- |
| `stack`   | `opencode run -m opencode/big-pickle --format json` (binario real winget/pnpm) | ninguno                    |
| `gemini`  | API de Gemini con `system_instruction` de la gema                              | API key (validada en vivo) |

**Fallback de modelos Gemini**: si el modelo de la gema responde 404/503 (retirado o sobrecarga), se
reintenta automáticamente con la cadena verificada: `gemini-flash-lite-latest` →
`gemini-flash-latest` → `gemini-pro-latest` → `gemini-3.6-flash`.

> ⚠️ Verificado 2026-09-05: Google **retiró** `gemini-2.0-flash`, `gemini-2.5-flash` y
> `gemini-2.5-flash-lite` (404). El pool usa `gemini-flash-lite-latest` (estable, 200).

## 5. UI (v4.1)

- Pestaña "Guías" **eliminada** (reemplazada por "Gemas").
- **Vista Gemas**:
  - **Conectores**: selector de proveedor de chat (Modelo del stack big-pickle / Gemini con
    validación en vivo y contador de modelos), estado de la API key con feedback real
    (`✅ X modelos` / `❌ rechazada`), e **"Importar mis gemas de Google"** (cookie, con estado de
    progreso y resultado).
  - **Filtros de dos filas etiquetadas**: "Origen" (Todas/Tuyas/Pool/Importadas) y "Categoría" (con
    su propio "Todas") — sin duplicados, combinables entre sí.
  - **Cards clickeables** → **modal de detalle** con el prompt completo (instrucciones), badges y
    acciones: **Probar en chat**, **Duplicar/Editar**, **Eliminar** (no-defaults).
  - **Chat embebido (Gem Space)**: historial, toggle Stack/Gemini, etiqueta del provider/modelo en
    cada respuesta, mensaje vacío contextual, estados de error.
- **Convertir prompt actual en gema**: desde el creador, un botón abre el editor de gema precargado
  con el prompt generado (instrucciones = prompt).

## 5b. UI v4.2 — Gem Space por áreas (split-screen)

Refactor de UX de la vista Gemas: de una sola sección monolítica a **4 áreas separadas** (patrón
ConfigView de archify):

1. **Conexión y modelo** (card superior, 3 columnas):
   - _Gemini API_: badge de estado (Conectado · N modelos / Key inválida / Sin key) + input de key
     inline con validación real.
   - _Modelo de chat (Gemini)_: selector global de modelo (lista real de `/api/gemini/status`) con
     opción **Auto** (usa el modelo de cada gema). El override viaja en el body del chat (`model`) y
     el server lo aplica también al proveedor Gemini (v4.2).
   - _Cuenta de Google_: sesión activa + logout, o import de gemas por cookie (inline).
2. **Acciones**: contador de resultados + botones **Convertir prompt actual en gema** y **Nueva
   gema** (antes mezclados con los conectores).
3. **Biblioteca de gemas** (columna izquierda, 5/12): búsqueda, filtros origen/categoría, lista en
   una columna con scroll propio, badge **"en chat"** y highlight de la gema activa.
4. **Chat** (columna derecha, 7/12, `sticky`): **siempre visible** — no requiere "Probar" y no vive
   al final de la página. Estado vacío con quick-picks **Sugeridas** (favoritas/recientes),
   historial por gema en memoria (`Record<gemId, msg[]>`) que sobrevive al cambio de gema,
   auto-scroll, toggle Stack/Gemini en el header, copiar conversación y limpiar.

Otros cambios v4.2:

- **Editor de gema como modal** (antes inline empujaba la lista) + campo de tags + chips rápidos de
  modelos Gemini cuando hay key válida.
- **Bug fix (heredado de v4.1)**: "Nueva gema" no abría el editor (`openGemEditor(null, true)` hacía
  `setGemEditor(null)`); ahora genera un draft vacío.
- **Server**: `stackChat` migrado de `spawnSync` (240s bloqueando TODO el event loop — mientras un
  chat de stack corría, la API entera se congelaba) a `spawn` async con `windowsHide:true`;
  `findOpencodeBin` cacheado (los probes `--version` también bloqueaban). Timeout conserva respuesta
  elegante al cliente.
- Footer/health/package en **4.2.0**.

## 5c. v4.3 — Streaming SSE + historial persistente + filtros combo

**Streaming (Gemini)**: el endpoint `/api/gems/:id/chat` acepta `stream: true` y responde
`text/event-stream` con eventos `meta` → `delta` (texto progresivo) → `done`/`error`. Server usa
`:streamGenerateContent?alt=sse` vía **node:https con `maxHeaderSize` 256KB** (los headers de Gemini
rompen undici — mismo motivo que `httpsFetch`), con fallback de modelos 404/503. El frontend parsea
el stream y hace update progresivo de la última burbuja; si el stream falla cae automáticamente a
request/response. **Gotcha crítico**: el `writeHead` del SSE debe incluir los headers CORS
(`access-control-allow-origin` etc.) que `json()` sí manda — sin ellos el fetch cross-origin
(5176→5177) rechaza en el cliente, cae al fallback y el server persiste el intercambio DOS veces.

**Historial persistente**: tabla `gem_chat_messages` (gem_id, role, content, provider, model,
created_at + índice). El chat endpoint persiste user+assistant por intercambio (best-effort).
`GET/DELETE /api/gems/:id/chat/history` para cargar/limpiar; el DELETE de una gema limpia su
historial. El frontend carga el historial del server la primera vez que se abre el chat de una gema
en la sesión (`chatLoadedRef`), conserva los histos en memoria, y "Limpiar" borra local + server.
**Anti doble-submit**: `chatBusyRef` (ref síncrona) además de `chatLoading` (state).

**Filtros combo**: origen y categoría pasan de pills a dos `<select>` compactos en un `grid-cols-2`
(pedidos explícitos del usuario por espacio), con auto-aplicación al cambiar y counts por categoría.

**Provider auto-preferencia**: si la key Gemini es válida, el chat arranca en `gemini` (una sola vez
por sesión, `providerAutoSet`); big-pickle (opencode-zen) sufre rate limits
(`AI_RetryError: Rate limit exceeded` verificado en logs de opencode) y su timeout bajó de 240s a
120s con mensaje de error orientativo en el chat.

**Footer/health/package en 4.3.0.**

## 5d. v4.4 — Import 1-click por navegador + Mejorar con IA + búsqueda con ranking

**Import por navegador (la vía simple, sin cookie)**: el bloque "Cuenta de Google" ahora ofrece
**"Importar desde mi navegador"** como método primario. Usa `src/ops/gemini-browser-import.ts`
(Playwright + Chromium con perfil persistente en `.runtime/prompt-studio/browser-profile`) a través
de los endpoints `/api/gems/import-browser/status|login|import`:

1. Click → `--check` headless (~10-15s) → ¿el perfil tiene sesión de Google?
2. Sin sesión → estado guiado: **"Abrir ventana de login"** (Chromium headed, detached — el usuario
   inicia sesión UNA vez) + **"Reintentar import"**.
3. Con sesión → `--import` ejecuta el batchexecute DENTRO del navegador real (cookies + fingerprint
   de Chromium) e inserta las gemas con `origin='imported'` + `google_id` real.

Por qué es la vía correcta: Google rechaza las cookies `__Secure-1PSID` pegadas desde Node
(fingerprint TLS no-navegador → degrada a guest). El import por navegador es 1-click para el
usuario; la cookie manual queda como opción avanzada colapsada. Estado UI:
`idle → checking → need-login / login-launched → importing → done`.

**Mejorar con IA (editor de gemas)**: botón "✨ Mejorar con IA" junto a las instrucciones →
`POST /api/gems/improve` {instructions, name} → meta-prompt de ingeniería de prompts sobre Gemini
(`gemini-flash-lite-latest` + FALLBACK_MODELS, temperature 0.4) → devuelve el texto mejorado que
reemplaza el textarea (guardar aplica; cancelar descarta). Requiere key válida.

**Búsqueda con ranking**: `GET /api/gems?q=` tokeniza la query (máx 6 tokens), matchea por LIKE y
puntúa en JS — nombre x4, tags x3, descripción x2, instrucciones x1, favoritas +0.5 (estilo
BM25-lite nativo). **Fix**: los filtros de origen/categoría ahora aplican también con query activa
(antes se ignoraban).

**Otro**: preferencia de proveedor de chat persistida en `localStorage` (`ps-chat-provider`).
**Footer/health/package en 4.4.0.**

## 5e. v4.5 — Login del import arreglado (feedback de uso real)

Prueba de usuario reveló 3 fallas en el flujo de login, todas corregidas:

1. **La ventana de login abría la landing de Gemini** (sin sesión → página de marketing, el usuario
   no encontraba dónde loguearse). Ahora abre el **formulario de email/contraseña de Google
   directo**: `accounts.google.com/ServiceLogin?continue=https://gemini.google.com/app`. Login
   normal de Google (email + contraseña + 2FA); al terminar redirige a Gemini.
2. **Chromium de Playwright → Chrome real** (`channel: 'chrome'` con fallback al bundled): Google
   desconfía del Chromium empaquetado en el login ("Este navegador no es seguro"); el Chrome real
   del sistema con perfil persistente es indistinguible de un login normal.
3. **"Reintentar import" estaba `disabled` en estado login-launched** (bug de flujo: no había camino
   de vuelta). Ahora siempre habilitado + instrucciones explícitas en pantalla + **auto-detección de
   sesión** cada 15s mientras la ventana está abierta: cuando el usuario cierra la ventana ya
   logueado, el próximo check encuentra el token y el import corre solo.

**Server**: `runBrowserImport` migrado de `spawnSync` (bloqueaba la API ~10-15s por check) a `spawn`
async con `windowsHide` — verificado: health responde en 3ms durante un check. El estado
`login-launched` ignora silenciosamente los errores de perfil lockeado (la ventana de login mantiene
el lock del perfil hasta cerrarse). **Footer/health/package en 4.5.0.**

## 5f. v4.5.1 — Import REAL de gemas: 3 bugs de parsing resueltos (instrucciones íntegras)

Prueba end-to-end con la cuenta real reveló que el import devolvía **0 gemas** aunque la respuesta
de Google las contenía. Causas encontradas y corregidas en `src/ops/gemini-browser-import.ts`:

1. **Parser length-prefixed roto**: `parseFrames` con regex `(\d+)\n` fallaba en TODOS los frames
   del batchexecute (formato cambiado) → 0 gems parseadas silenciosamente. Reemplazado por
   extracción JSON-aware por regex: `\["wrb\.fr","<rpcid>","((?:[^"\\]|\\.)*)"` →
   `JSON.parse('"' + captura + '"')` para des-escapar el payload. Validado contra respuesta real.
2. **Instrucciones truncadas**: el RPC de lista (CNgdBe) trae el prompt cortado a ~100 chars
   (preview) — limitación también presente en la librería de referencia Gemini-API. Descubierto y
   validado el RPC de detalle **`HcT8bb` con payload `["<gem_id>"]`** que devuelve las instrucciones
   COMPLETAS (Gemini-API lo define como `GET_BOT` pero no lo usa). El import hace ahora un detalle
   por gema custom y reemplaza el preview si el texto es mayor.
3. **Semántica de payloads invertida**: `[4]` devuelve las CUSTOM y `[2]` las del sistema (al revés
   de lo documentado en Gemini-API). Clasificación estable por forma de id: custom = hex (ej.
   `36c023573889`), sistema = kebab-case (ej. `canvas-create-infographics`). Solo las custom se
   importan (el sistema son 60+ y no se editan).

También: `getArg` corregido por `hasFlag` (un flag booleano al final de argv se perdía y el modo CLI
caía a `check` silenciosamente). Nota tsx: `page.evaluate` falla con `__name is not defined` —
definir `window.__name = (f) => f` antes.

**Resultado verificado con cuenta real**: 4 gemas custom importadas con instrucciones íntegras (5690
/ 4224 / 4786 / 2891 chars — antes 100 truncados). La sesión del perfil quedó válida del intento de
login del usuario: no hace falta re-loguearse.

## 5g. v4.6 — Auditoría de rendimiento/UX: 11 mejoras

Auditoría con mediciones reales (latencias por endpoint, revisión de tema claro en browser,
inventario de features dormidas). Implementado:

**Latencia:**

1. **Cache de `/api/gemini/status`** (TTL 5 min, a nivel módulo, invalidado al guardar key): 1.2s
   cold → **6ms cached** (240x). El status validaba la key contra Google en CADA request.
2. **Debounce 250ms** en las búsquedas de gemas y prompts (antes: 1 request por tecla).

**Data safety (local-first):** 3. **Export/Import JSON**: `GET /api/data/export` (attachment
download) y `POST /api/data/import` (transaccional, upsert por id; las gemas `default` del pool GV
NO se sobreescriben con backups). Round-trip verificado: 34.8KB (16 gems + 2 chats). Botones en la
sección Acciones.

**Chat (legibilidad + control):** 4. **Markdown nativo XSS-safe** (`src/Markdown.tsx`, cero
dependencias): headings, listas, bold/italic (incluye `_italic_`), inline code, code fences,
blockquote, hr, links. Escape de TODO el HTML antes de transformar. Respuestas de Gemini legibles de
verdad. 5. **Input multilinea**: textarea con Enter=enviar, Shift+Enter=nueva línea. 6. **Botón
Parar** (AbortController sobre el stream; marca `(interrumpido)`; NO cae al fallback sin stream —
distinción de AbortError en el catch). 7. **Copiar mensaje individual** (icono en hover por
burbuja).

**Features dormidas conectadas:** 8. **Historial de versiones de gemas en UI**: el server guardaba
snapshots desde v4 sin UI. Botón Historial en cards de gemas propias + modal con diff por líneas y
restore. 9. **usage_count**: columna nueva (migración idempotente ALTER TABLE), incrementado en
`persistChat`, badge "N usos" en cards y orden "Más usadas" (`?sort=used`).

**Pulido:** 10. **Tema claro arreglado**: tabla de overrides CSS bajo `[data-theme='light']`
remapeando las utilidades slate-* dark que la app usa (patrón dark-first de v1) — sin tocar el canon
`.gv-*`. Verificado con captura: cards claras, textos legibles, acentos OK. 11. **i18n portugués
completo** (es/en/pt) + **Ctrl+K** enfoca el buscador de la vista activa.

**Footer/health/package/app_version en 4.6.0.**

## 6. Import real de gemas de Google (v4.1, experimental)

Protocolo reverse-engineered (port de `HanaokaYuzu/Gemini-API`, Apache-2.0) — **no es API oficial**:

1. `GET https://gemini.google.com/app` con cookie `__Secure-1PSID` → extrae el access token `SNlM0e`
   (regex `"SNlM0e":\s*"(.*?)"`) + build label/session id/language.
2. `POST https://gemini.google.com/_/BardChatUi/data/batchexecute` con `f.req` para `LIST_BOTS`
   (`CNgdBe`): system hidden (`[4,...]`) + custom (`[2,...]`), headers JSPB + cookies.
3. Parse de la respuesta length-prefixed (`)]}'` + frames); cada gem:
   `[id, [name, description], [prompt]]`.
4. Inserción local con `origin='imported'` + `google_id` real + categorización por nombre.

**Limitación**: depende de la cookie de sesión (caducable). Para el resto de operaciones (el chat,
el CRUD) la app es 100% local. Como no hay API oficial, la UI lo marca como experimental.

### Troubleshooting del import

- **Error `ruta desconocida: POST /api/gems/import-gemini`**: el server API corriendo en `:5177` es
  una **versión vieja** (anterior a v4.1). Reiniciarlo: `npm run app:prompts:stop` +
  `npm run app:prompts:start` (o matar el PID del puerto 5177 y relanzar).
- **Error `HeadersOverflowError` / `fetch failed` en el import**: la respuesta de
  `gemini.google.com/app` trae headers >16KB que rompen el `fetch` nativo de Node 24 (undici).
  Solución implementada: `httpsFetch()` con `node:https` + `maxHeaderSize: 256KB`.
- **`No se pudo obtener el access token (SNlM0e). Cookie inválida o expirada.`**: la cookie
  `__Secure-1PSID` está caducada o fue escrita mal. Google la rota con frecuencia (más rápido con
  Device Bound Session Credentials de Chrome). Copiar fresca desde DevTools → Application → Cookies
  → gemini.google.com. Algunas cuentas requieren también `__Secure-1PSIDTS`.
- **`0 gemas detectadas` / warning**: la cookie es válida pero la cuenta no tiene gemas custom, o
  las predefinidas de sistema no se importan por diseño.
- **Diagnóstico**: toda etapa se loguea en `.runtime/prompt-studio/import-gemini.log` (token,
  batchexecute, frames, gems). Revisarlo ante cualquier fallo.

## 7. Seguridad / privacidad

- `auth.json`, `gemini-key.json` viven en `.runtime/prompt-studio/` (gitignored).
- La API key y el ID token **nunca** van al repo ni al bundle del frontend.
- La cookie `__Secure-1PSID` se envía solo al server local para el import; no se persiste.
- Todo el CRUD es local; las únicas llamadas externas son el chat (Gemini API o binario opencode
  local) y la verificación de key.

## 8. Pendiente / siguiente nivel

- Sync bidireccional (push) de gemas locales hacia la cuenta Gemini aprovechando el mismo protocolo
  `CREATE_BOT`/`UPDATE_BOT_METADATA`/`DELETE_BOT` ya documentado.
- Export/import de gemas como plantillas JSON (alternativa robusta a la cookie de sesión).
- Ampliar pool: 8-10 gemas más por categoría usando uso real.
- OAuth completo (flujo redirect con client ID configurable) para login sin pegar token manual.

## 9. Referencias

- Benchmark original: `docs/reference/PROMPT-LIBRARY-BENCHMARK.md`
- Código: `apps/prompt-studio/server/server.ts`, `apps/prompt-studio/src/App.tsx`,
  `apps/prompt-studio/src/i18n.ts` (apps desacopladas del repo del stack — git propio)
- Research web: `HanaokaYuzu/Gemini-API` (Apache-2.0), `ai.google.dev` (404 Gems docs)
