/* Gentle-Vanguard Academy — Track "optimizacion" (10 lecciones).
 * Contenido educativo basado en cifras reales del stack (AGENTS.md, docs/reference/, config/).
 * Sin dependencias: define window.GV_CONTENT["optimizacion"].
 */
window.GV_CONTENT = window.GV_CONTENT || {};
window.GV_CONTENT["optimizacion"] = {
  lessons: [
    {
      id: "la-economia-de-los-tokens",
      title: "La economía de los tokens: input, output, cache y chat",
      minutes: 9,
      type: "curso",
      md: `## Qué se cobra realmente cuando hablas con un LLM

Cada llamada a un modelo de lenguaje se cobra por **tokens**, no por "mensajes" ni por "tareas". Un token es un fragmento de texto (en inglés ~4 caracteres de promedio; en español algo menos). Cuando un agente de código responde una pregunta, la factura se compone de varias partes que conviene separar mentalmente:

- **Input (prompt):** todo lo que envías al modelo. Incluye tu pregunta, pero también las instrucciones del sistema, las herramientas disponibles y —lo más caro— el historial completo de la conversación.
- **Output (completion):** lo que el modelo genera. Suele cotizarse varias veces más caro que el input.
- **Cache read / cache write:** muchos proveedores permiten reutilizar el prefijo de una conversación previa. Leer del cache cuesta una fracción del input normal; escribirlo cuesta un poco más. Es la palanca de ahorro más ignorada.
- **Reasoning tokens:** en modelos con razonamiento extendido, los tokens de "pensamiento" intermedio también se cobran como output, aunque nunca los veas.

## Por qué se pierde dinero

La pérdida no está en el mensaje que escribes: está en todo lo que viaja "de gratis" con él. La guía de optimización de contexto del stack documentó la realidad de las sesiones con herramientas de código: mientras lo esperable eran ==2-5K tokens por turno==, la medición real arrojó ==37K+ por turno (18x por encima)==. El ratio input:output esperado era 5:1; el real, ==100:1 (20x)==. Y más del 60% de las sesiones superaban el límite razonable, contra un <5% esperado.

La causa raíz es mecánica: la herramienta de chat reenvía el historial completo en cada turno. Cada "siguiente pregunta" repaga todo lo anterior. Un caso de uso repetitivo (por ejemplo, "resume este archivo" veinte veces al día) puede estar pagando el mismo contexto una y otra vez.

## Cómo se mide esto en el stack

El stack registra el consumo real por mensaje en la tabla \`token_transactions\` de Nexus, con columnas separadas para \`input_tokens\`, \`output_tokens\`, \`reasoning_tokens\`, \`cache_read_tokens\`, \`cache_write_tokens\` y \`cost\`, además del modelo y el agente responsable. Esa separación es la que permite responder preguntas de economía: ¿qué parte del gasto es historial repetido? ¿cuánto recuperó el cache? ¿qué agente quema el presupuesto?

Cuando no hay datos reales de la API, la estimación canónica del stack es \`chars / 4 = tokens\` (fórmula definida en la configuración del token guard). Es una aproximación, pero es la misma en todos los scripts, lo que evita inconsistencias entre reportes.

> La regla práctica del stack, respaldada por investigación externa de 2026 ("A Practitioner's Guide to AI Coding Agent Quality & Token Optimization"): no optimices prompts para usar menos tokens — optimízalos para **dirigir bien al modelo**. El ahorro llega como consecuencia de enviar lo correcto, no de enviar poco.

## En el stack

\`\`\`bash
npm run token:status   # presupuesto real: usado / presupuesto / %
npm run token:trace    # trazabilidad: transacciones por agente y ahorros
npx tsx src/tokens/token-ingest.ts   # una pasada de ingesta de tokens reales
\`\`\`

Presupuestos vigentes en \`config/token-budget-guard.json\`: ==5M tokens diarios== y ==3M por sesión==, con consumo real observado del orden de ~1.5M/día.

## Puntos clave

- El costo de una conversación crece con cada turno porque el historial completo se reenvía: input repetido, no mensajes largos, es el gran fugadero.
- Output y reasoning se cobran más caro que input; cache read es la fracción más barata de todas.
- Medir por separado input/output/cache/reasoning (como hace \`token_transactions\`) es requisito para optimizar algo.
- Estimación honesta cuando no hay datos reales: \`chars / 4\`.
- Antes de recortar texto, pregunta si ese texto estaba dirigiendo al modelo o solo pesando.`,
    },
    {
      id: "ahorro-de-contexto",
      title: "Ahorro de contexto: el recurso más caro",
      minutes: 9,
      type: "curso",
      md: `## El contexto es el recurso escaso

La "ventana de contexto" es la cantidad máxima de tokens que el modelo puede atender en una llamada. Parece solo un límite de tamaño, pero el verdadero problema es económico: la atención del modelo compara tokens entre sí, y ese cómputo crece de forma ==cuadrática== con la longitud del contexto. Duplicar el contexto no duplica el costo: lo multiplica mucho más allá de 2x en cómputo, y en la práctica el costo por llamada crece linealmente con los tokens enviados, turno tras turno.

Por eso el contexto es el recurso más caro de una sesión de agente: cada token de historial que viaja sin aportar se paga en **cada** turno siguiente.

## La realidad medida

El stack documentó su propia auditoría de contexto en \`docs/reference/CONTEXT-OPTIMIZATION-GUIDE.md\`:

| Métrica | Esperado | Realidad medida |
| --- | --- | --- |
| Tokens por turno | 2-5K | 37K+ (18x) |
| Ratio input:output | 5:1 | 100:1 (20x) |
| Sesiones sobre límite | <5% | >60% |

La conclusión honesta del documento: la causa raíz (el reenvío del historial completo por parte de la herramienta de chat) **no se puede arreglar desde el stack** — solo mitigar. Se evaluaron cinco caminos (plugin de la herramienta, middleware interceptor, fork de la herramienta, plugin externo, mitigaciones propias) y el implementado fue el quinto.

## Mitigaciones implementadas

Cuatro capas de compresión actúan sobre lo que sí controla el stack:

| Estrategia | Archivo | Impacto |
| --- | --- | --- |
| Compresión de prompt | \`prompt-compression.ts\` | 40-60% por mensaje |
| Compresión de output | \`output-compression.ts\` | 50-70% por respuesta |
| Compresión estructural | \`structural-compression.ts\` | 30-50% en datos |
| Límites por nivel de chat | \`chat-level-enforcer.ts\` | topes duros (200-4000 tokens) |

A eso se suman: el monitor \`context-truncator.ts\` (alerta a ~15K tokens), los checkpoints (\`checkpoint-manager.ts\`) para partir tareas largas, y el protocolo de eficiencia de contexto, que fija objetivos concretos: rating de eficiencia ==mayor a 70%== (alerta si baja de 60%, crítico bajo 50%) y largo promedio de prompt por debajo de ==1302 caracteres==.

## Técnicas de bajo costo que puede aplicar cualquiera

1. **Referenciar en vez de repetir.** El protocolo de eficiencia prescribe citar entradas existentes ("ver decisión previa") en lugar de volver a pegar el contenido.
2. **Límites de sesión.** Cerrar sesión y abrir una nueva cada ~15-20 turnos. Ahorro estimado: ==60-80% de tokens==.
3. **Checkpoint y reinicio.** Guardar estado antes de una tarea larga y restaurar si el contexto creció demasiado, en lugar de arrastrar el historial.
4. **Tiering de memoria.** Memoria caliente (sesión actual), templada (retención 90%, 1 día) y fría (70%, 7 días): lo viejo degrada, no desaparece.

El propio AGENTS.md del repositorio aplica estos principios: existe una **versión slim** de bajo contexto para inyección diaria y un manual completo que solo se carga cuando la tarea lo requiere. Enviar el manual entero en cada sesión sería exactamente el antipatrón que el protocolo combate.

## En el stack

\`\`\`bash
npx tsx src/checkpoint-manager.ts create --label "before-long-task"
npx tsx src/checkpoint-manager.ts list
npm run token:status   # ver dónde va el presupuesto de la sesión
\`\`\`

## Puntos clave

- El costo del contexto es peor que lineal en cómputo (atención cuadrática) y se repite en cada turno.
- La compresión que el stack controla rinde 30-70% según la capa; el historial completo, en cambio, solo lo controla la herramienta.
- Límites duros + alertas tempranas (15K tokens, 70% de presupuesto) evitan la sesión "millones de tokens".
- Cerrar sesión cada 15-20 turnos es la mitigación más barata: 60-80% de ahorro documentado.
- Referencias > repeticiones; slim > completo; tiering > acumulación.`,
    },
    {
      id: "indice-local-de-codigo",
      title: "El índice local de código: responder sin re-leer el repo",
      minutes: 10,
      type: "curso",
      md: `## La idea: un índice en lugar del repositorio entero

Cuando le preguntas algo a un agente de código sobre un repositorio mediano, la estrategia ingenua es leer archivos y volcarlos al contexto hasta que el modelo "vea" la respuesta. El enfoque alternativo —validado por práctica externa de 2026 ("We Cut 94% of AI Coding Tokens With a Local Code Index")— es construir **antes** un índice local del código y enviar al modelo solo las fracciones relevantes. La cifra de referencia: hasta ==94% menos tokens== que re-leer el repo.

Gentle-Vanguard implementa este patrón con **graphify/CodeGraph**: un grafo de conocimiento del código construido por análisis AST (abstract syntax tree), ==determinista, sin LLM y sin red==. Cada build produce nodos de archivo, función, clase y método, y aristas \`contains\` (contiene) y \`calls\` (llama). Sobre ese grafo, las comunidades se detectan por propagación de etiquetas, sin inferencia probabilística: dos builds sobre el mismo código producen el mismo grafo.

## Cómo se usa

El grafo vive en \`graphify-out/\` y se consulta por pregunta, no por archivo:

- \`query "<pregunta>"\` — búsqueda semántica sobre el índice; la vía preferida para preguntas de código.
- \`explain "<node_id>"\` — explicación enfocada de un nodo exacto (los IDs usan rutas separadas por guiones bajos; se encuentran con \`query\` primero).
- \`update .\` — revalidación incremental tras modificar código (los hooks lo disparan solos tras cada Write/Edit).
- \`wiki/index.md\` y \`GRAPH_REPORT.md\` — navegación amplia y revisión de arquitectura cuando query/explain no alcanzan.

En estado estable, el índice del repositorio registraba ==133 archivos, 1410 nodos y 1763 aristas== — un grafo que cabe en contexto y responde preguntas que de otro modo exigirían leer decenas de archivos.

> Regla del stack: para preguntas de código, \`graphify query\` va primero; re-leer archivos es el fallback, no el default.

## Cuándo usar cada herramienta

| Necesidad | Herramienta |
| --- | --- |
| "¿Dónde se valida X?" | \`npm run graphify -- query "..."\` |
| "Explícame esta función exacta" | \`npm run graphify -- explain "<node_id>"\` |
| Navegación amplia / onboarding | \`graphify-out/wiki/index.md\` |
| Revisión de arquitectura | \`graphify-out/GRAPH_REPORT.md\` |
| Impacto de un cambio | \`affected\` (limitado: solo aristas contains/calls) |

Los comandos \`path\` y \`affected\` son deliberadamente "limitados" y el stack lo documenta: al ser AST puro sin extracción semántica con LLM, no hay aristas \`references\`/\`imports\`, y los caminos entre archivos son raros.

## Detalles operativos que evitan sorpresas

1. Si falta \`graphify-out/graph.json\`, el primer paso es siempre \`build\` (tarda segundos, es nativo).
2. Archivos "dirty" del grafo tras hooks o updates incrementales son normales — no son motivo para saltarse graphify.
3. El etiquetado de comunidades usa el free tier de Gemini (==20 requests/día==); un error 429 significa esperar el reset diario, no reintentar en bucle.
4. Gotcha de ecosistema: el paquete npm \`graphify@1.0.0\` es un generador aleatorio de grafos **sin relación** con este stack. El CLI correcto es siempre \`npm run graphify -- <comando>\`.
5. La visualización (\`cluster-only\`/\`label\`) necesita \`GRAPHIFY_VIZ_NODE_LIMIT=40000\` en grafos grandes (el default de 5000 nodos se queda corto).

El índice también alimenta la integración MCP: el servidor **codegraph** expone el grafo como herramientas consultables por cualquier agente compatible con Model Context Protocol, y la watchtower lo verifica en cada ciclo (existencia del índice, conteo de nodos, antigüedad).

## En el stack

\`\`\`bash
npm run graphify -- build          # solo si falta graph.json
npm run graphify -- query "¿quién llama a runNpxTsx?"
npm run graphify -- explain adaptive_auto_delegate_orchestrator_start_orchestrator
npm run graphify -- update .       # tras modificar código
\`\`\`

## Puntos clave

- Un índice AST local y determinista sustituye la re-lectura del repo: hasta 94% menos tokens.
- \`query\` para buscar, \`explain\` para un nodo exacto, \`update .\` después de editar.
- Sin LLM ni red en el build: reproducible y barato; el etiquetado con Gemini es opcional y acotado (20 req/día).
- \`path\`/\`affected\` son limitados por diseño (solo aristas contains/calls del AST).
- Nunca instalar el paquete npm \`graphify\`: el CLI del stack es \`npm run graphify --\`.`,
    },
    {
      id: "response-cache-sha256",
      title: "Response cache SHA-256: respuestas idénticas, costo cero",
      minutes: 8,
      type: "curso",
      md: `## Qué es un cache de respuestas

Si dos peticiones tienen exactamente el mismo input y el mismo contexto, la respuesta del modelo será prácticamente idéntica. Pagar dos veces por ella es gasto puro. Un **response cache** guarda la respuesta de la primera petición indexada por una clave derivada del input, y sirve las repeticiones desde disco: latencia mínima y ==costo cero en tokens==.

Gentle-Vanguard implementa este cache en \`src/response-cache.ts\` con tres decisiones de diseño:

1. **Clave SHA-256** del input + contexto. Colisiones irrelevantes en la práctica, clave de longitud fija.
2. **Persistencia en SQLite** (tabla \`response_cache\` de Nexus, \`.runtime/gentle-vanguard.db\`), no en memoria: sobrevive a reinicios. Los archivos JSON legacy de \`.session/response-cache/\` se migran al primer uso.
3. **Aislamiento por tenant**: cada \`tenant_id\` tiene su namespace; el cache de un tenant nunca sirve respuestas a otro.

## Impacto esperado y medido

:::diagram cache-flow:::

El encabezado de la implementación declara el objetivo: ==33-41% de reducción de latencia== y ==25-35% de reducción de costo en tokens==. El ahorro real se contabiliza después en la tabla \`token_savings\` de Nexus: el acumulado histórico del stack registra del orden de ==1.06M de tokens recuperados por cache reads==.

## TTL e invalidación: la parte difícil

El cache útil es el que **expira bien**. La política del stack:

- **TTL por defecto de 30 minutos** (\`ttlMinutes = 30\` en \`CacheRepo\`). Al escribir una entrada se calcula \`expires_at\`; las lecturas caducadas se tratan como miss y recalculan.
- **Limpieza automática** de entradas expiradas, sin intervención manual.
- **Invalidación por contenido, no por reloj**: la clave incluye el input + contexto; si el contexto cambia (otro archivo, otro prompt), la clave cambia y el cache simplemente no aplica. No hay "respuesta vieja servida por error" para inputs distintos.
- **Retención de métricas al reemplazar**: el upsert preserva el \`hit_count\` acumulado de la entrada previa (\`COALESCE\` sobre la fila existente), de modo que la estadística de uso no se pierde al refrescar una entrada.
- **Prune periódico**: \`npm run db:prune\` elimina entradas de cache de más de 7 días como parte del housekeeping general de Nexus.

El \`hit_count\` por entrada alimenta las métricas agregadas (suma de hits por tenant) y permite calcular el **hit rate** real — la métrica que dice si el cache está pagando su propio costo.

> Un cache sin métricas de hit rate es una apuesta; con métricas es una decisión. Si el hit rate es bajo, el workload no es repetitivo y conviene desactivar el cache antes que mantenerlo "por si acaso".

## Cuándo funciona bien (y cuándo no)

- **Bien**: consultas idempotentes repetidas (resúmenes, clasificaciones, explicaciones de código estable), entornos de demo/test donde se relaanza lo mismo, prompts de sistema largos con preguntas frecuentes.
- **Mal**: sesiones conversacionales donde cada turno cambia el contexto (la clave nunca repite), código que cambia a diario (el TTL caduca antes de repetirse), y cualquier caso donde servir una respuesta de hace 30 minutos sea incorrecto antes que caro.

El mismo patrón de clave con tag aparece en otras partes del stack: el web crawler cachea por proveedor con \`cacheKey\` etiquetada (\`fb\`/\`fc\`) precisamente para ==no envenenar resultados entre proveedores== — misma técnica, distinto dominio.

## En el stack

\`\`\`bash
npm run db:health    # estado de response_cache dentro de Nexus
npm run db:prune     # limpieza: cache >7 días
npm run token:trace  # ahorro por cache reads en token_savings
\`\`\`

## Puntos clave

- Clave SHA-256 de input + contexto: determinista, sin colisiones prácticas, invalidación implícita al cambiar el input.
- TTL por defecto 30 minutos, limpieza automática, retención de \`hit_count\` en los reemplazos.
- Impacto declarado: 33-41% menos latencia, 25-35% menos costo; ~1.06M tokens ahorrados históricamente.
- Aislamiento por tenant obligatorio en cualquier cache multi-inquilino.
- Mide el hit rate: un cache con hits bajos es costo operativo sin retorno.`,
    },
    {
      id: "compresion-estructural",
      title: "Compresión estructural: 5 estrategias y la protección del razonamiento",
      minutes: 10,
      type: "curso",
      md: `## Comprimir datos, no solo texto

La compresión extractiva clásica (recortar el prompt, recortar la respuesta) trata el texto como prosa. Pero gran parte del contexto de un agente de código son **estructuras**: arrays JSON, logs de build, resultados de tests, tablas. Comprimirlas con estrategias que entienden su forma rinde mucho más que recortar líneas.

\`src/compression/structural-compression.ts\` absorbe 5 estrategias (originadas en el proyecto Headroom, re-implementadas en TypeScript puro, sin sidecars):

| Estrategia | Qué hace | Tipo |
| --- | --- | --- |
| SmartCrusher | Comprime arrays JSON con decisión estadística, preservando outliers | Lossy controlado |
| Tabular compaction | JSON tabular a CSV con esquema | ==Lossless== |
| LogCompressor | Colapsa logs y stack-traces de build/test | Lossy |
| TextCrusher + BM25 | Prosa filtrada por relevancia a la query + dedup de shingles | Lossy |
| CrossCompression | Dedup de bytes repetidos entre turnos | Lossless |

El impacto documentado sobre datos estructurados: ==30-50% de reducción==.

## La decisión crítica: input lossless vs output lossy

La interfaz es \`compressStructural(input, { mode })\` y el modo es una decisión de **seguridad**, no de rendimiento:

- \`mode: 'input'\` (prompt / delegación) → **solo estrategias lossless** por defecto (\`input.allowLossy: false\`). Si la compresión descarta una fila del JSON o un párrafo de prosa que el modelo necesitaba para razonar, la respuesta será confiadamente errónea. Un modelo que no ve un dato no sabe que no lo ve.
- \`mode: 'output'\` (respuesta) → **lossy permitido** (\`output.allowLossy: true\`). El modelo ya razonó; recortar la presentación de su respuesta no corrompe el razonamiento.

En el código, \`compressPrompt\` usa \`mode:'input'\` y \`compressOutput\` usa \`mode:'output'\`: la protección está cableada por defecto, no deja la decisión a quien llama.

> Regla para recordar: **el input se comprime sin perder información; el output se puede comprimir con criterio.** Proteger el razonamiento del modelo cuesta unos puntos de ratio; corromperlo cuesta la tarea entera.

## Cuándo usar cada estrategia

1. **Tabular compaction** cuando el contexto es una lista de objetos homogéneos (resultados, filas, inventarios). CSV + esquema es más corto que JSON y no pierde nada.
2. **SmartCrusher** para arrays largos con outliers relevantes: comprime la masa y conserva lo anómalo — exactamente lo que un diagnóstico necesita.
3. **LogCompressor** antes de pegar logs de CI a un prompt: los stack-traces repetidos colapsan a una forma canónica.
4. **TextCrusher + BM25** cuando hay prosa abundante y una query clara: filtra por relevancia y deduplica frases repetidas (shingles).
5. **CrossCompression** entre turnos de una misma tarea: el byte repetido de un turno al siguiente se paga una sola vez.

## Validación y configuración

- Config: \`config/structural-compression.json\`.
- Tests: \`tests/unit/structural-compression.test.ts\` — el comportamiento lossless del modo input está cubierto por regresión.
- La práctica externa de 2026 (guías de reducción de tokens para agentes) ubica esta familia de técnicas —compresión semántica, logs a SQLite (50-99% de corte), presupuestos de razonamiento acotados— entre las de mayor retorno.

## En el stack

\`\`\`bash
npm test -- tests/unit/structural-compression.test.ts   # regresión del contrato de modos
cat config/structural-compression.json                  # umbrales y flags por estrategia
npm run token:trace                                     # ahorro por compresión en token_savings
\`\`\`

## Puntos clave

- 5 estrategias orientadas a la forma del dato (arrays, tablas, logs, prosa, turnos): 30-50% sobre datos estructurados.
- \`mode:'input'\` = lossless por defecto: protege el razonamiento; \`mode:'output'\` = lossy aceptable.
- La distinción input/output está cableada en \`compressPrompt\`/\`compressOutput\`, no a merced del caller.
- Elige estrategia por la forma del contenido, no por el ratio de compresión prometido.
- Compresión lossy en input = ahorro que se paga en alucinaciones.`,
    },
    {
      id: "lru-cache-y-prompt-cache-ordering",
      title: "Caché LRU por tenant y ordenamiento prompt-cache friendly",
      minutes: 8,
      type: "curso",
      md: `## Dos niveles de cache que no hay que confundir

Esta lección junta dos técnicas de cacheo que operan en capas distintas:

1. **Cache LRU por tenant del dashboard** — una técnica de ingeniería de servidores para absorber ráfagas de lecturas sin servir datos viejos.
2. **Ordenamiento prompt-cache friendly** — un principio de diseño de prompts para maximizar los aciertos del cache de prefijo (KV-cache) del proveedor del LLM.

## El cache LRU por tenant del dashboard

El dashboard empuja métricas por WebSocket cada ==5 segundos==, pero además sirve endpoints REST (\`/api/metrics\`, \`/api/traces\`, ...) que pueden recibir ráfagas de peticiones entre pushes. Cada consulta a better-sqlite3 es síncrona: sin cache, una ráfaga de REST ejecuta la misma query pesada muchas veces en el mismo instante.

\`apps/web-dashboard/server/cache/tenant-lru-cache.ts\` resuelve esto con un cache **LRU (least recently used) con scope por tenant** y tres decisiones finas:

- **TTL por defecto de 3 segundos — deliberadamente menor que el intervalo de push de 5s.** Cada push computa datos frescos; las peticiones REST concurrentes dentro de esa ventana comparten una única computación. Nunca se sirve un dato más viejo que un ciclo de push.
- **Capacidad de 64 entradas por nombre de cache**, con evicción del elemento menos recientemente usado cuando se supera.
- **Invalidación dirigida**: \`invalidate('metrics')\` limpia un cache para todos los tenants; \`invalidate('metrics', 'acme')\` solo uno; \`invalidate()\` todo. Los repos pueden forzar coherencia inmediata tras una escritura.

La clave compuesta es \`tenantId + firma de parámetros\`, y el cache expone estadísticas propias (hits, misses, evictions, expirations, hit rate) — el mismo principio de la lección anterior: cache sin métricas es apuesta.

El patrón de uso:

\`\`\`typescript
const data = getOrLoad('metrics', tenantId, () => computeHeavy(), { ttlMs: 3000 });
invalidate('metrics', tenantId); // tras una escritura, si hace falta
\`\`\`

## Ordenamiento prompt-cache friendly: el principio

Los proveedores de LLM cachean el **prefijo** de la conversación: si el comienzo del prompt es byte a byte idéntico a una llamada anterior, ese prefijo se lee del cache a precio reducido. La consecuencia práctica es una regla de ordenamiento:

- **Primero lo estable** (instrucciones de sistema, herramientas, contexto base que no cambia).
- **Al final lo volátil** (la pregunta del turno, los datos que acaban de cambiar).

Si pones contenido volátil al principio, cada cambio invalida el prefijo completo y el cache nunca acierta. La literatura de optimización de contexto de 2026 lo formula como "reorder stable content to the front".

El stack aplica el principio en el nivel que controla: el **AGENTS.md slim** — una versión de bajo contexto para inyección diaria, con el manual completo cargado solo bajo demanda. Es el mismo patrón: prefijo estable y pequeño, material pesado fuera del camino caliente.

> Honestidad ante todo (marca del stack): el **ordenamiento explícito de los prompts dirigidos al modelo con objetivo de cache de prefijo NO está implementado hoy**; está registrado como candidato de optimización en \`docs/research/EXTERNAL-BEST-PRACTICES-2026-08.md\`. Lo implementado es el principio aplicado a la entrega de instrucciones (slim vs full) y el monitoreo de umbrales vía budget guard.

## En el stack

\`\`\`bash
npx tsx src/dashboard-start.ts   # WS + frontend: métricas vía cache LRU por tenant
npm run watchtower:health       # el ciclo verifica dashboard-ws (API 200, PIDs vivos)
\`\`\`

## Puntos clave

- LRU + TTL corto (3s < intervalo de push de 5s): absorbe ráfagas sin servir datos rancios.
- Scope por tenant y capacidad acotada (64 entradas): aislamiento y memoria predecible.
- Cache de prefijo del LLM: contenido estable al frente, volátil al final — un cambio temprano invalida todo el prefijo.
- El stack aplica el principio en instrucciones (AGENTS.md slim); el ordenamiento fino de prompts es candidato documentado, no una característica existente.
- Toda capa de cache necesita sus propias métricas de hit rate para justificarse.`,
    },
    {
      id: "budget-guard",
      title: "Budget guard: presupuestos, alertas y límites",
      minutes: 9,
      type: "curso",
      md: `## Un presupuesto sin guardia es una esperanza

Saber cuánto gastaste la semana pasada no evita quedarte sin presupuesto hoy. El **token budget guard** es el componente que convierte los límites en enforcement: monitorea el consumo en tiempo real, alerta por umbrales y —en el modo más estricto— bloquea el dispatch de nuevos agentes.

## Los números vigentes

\`config/token-budget-guard.json\` es la **fuente única de verdad** de presupuestos (versionada, con schema propio):

| Límite | Valor |
| --- | --- |
| Diario | ==5,000,000 tokens== |
| Por sesión | ==3,000,000 tokens== |
| Por agente | 100,000 tokens |
| Umbral soft | 70% |
| Umbral hard | 90% |

Contexto de realidad: el consumo observado del stack es del orden de ==~1.5M tokens/día== contra el presupuesto de 5M — margen sano, pero precisamente porque hay guardia: el presupuesto está calibrado sobre datos reales, no al revés.

## Cómo responde el guard a cada nivel

1. **Zona normal (< 70%)**: sin acción.
2. **Soft threshold (70%)**: alerta WARNING — se registra y notifica, el trabajo continúa. La guía de subagentes prescribe aquí: modo compacto, dividir en slices más chicos, \`context-pack\` antes de la próxima lane.
3. **Hard threshold (90%)**: el guard rechaza nuevos dispatch. La política de subagentes manda parar lanes no esenciales y ejecutar el flujo de cierre seguro preservando estado y handoff.
4. **Runaway (consumo desbocado)**: severidad ==CRITICAL== con acción \`kill_task\` — el único caso en que el guard mata la tarea.
5. **Cost spike 2x**: acción \`investigate\` — un salto de 2x en costo dispara investigación, no corte.

El modo de enforcement actual es **soft y no bloqueante** (\`mode: "soft"\`, \`nonBlocking: true\`): alerta y registra sin romper sesiones. La matriz de alertas completa (\`dailyTokensExceeded\`, \`agentLimitExceeded\`, \`taskLimitExceeded\`, \`costSpike2x\`, \`runawayUsage\`) declara severidad y acción por evento.

## Límites por agente

Además de los topes globales, cada agente tiene su presupuesto propio en tokens y pasos: el orquestador ==2000-4500 tokens y 12 steps==; \`sdd-explore\`, \`sdd-design\`, \`sdd-verify\` y \`doc-agent\` 2000-5000 con 6 steps; \`session-agent\` 1000-2000. Un agente glotón no puede comerse el presupuesto de los demás.

El guard también persiste métricas de uso (\`docs/sessions/metrics/token-guard-usage.csv\`) con la columna de tokens **reales** al lado de los **estimados**: los valores reales de la API (\`usage.prompt_tokens\` / \`usage.completion_tokens\`) reemplazan la estimación \`chars/4\` cuando existen, y los ceros no sobrescriben estimaciones válidas.

## Qué hacer cuando salta una alerta

- Soft (70%): continuar en compacto, achicar slices, cerrar sesiones viejas.
- Hard (90%): parar lanes paralelas no esenciales, preservar estado (checkpoint), cerrar con handoff soportado por Engram.
- La alerta obligatoria incluye: tokens estimados actuales, usado hoy, porcentaje proyectado del presupuesto, umbral exacto alcanzado y alternativas sugeridas con comandos ejecutables.

## En el stack

\`\`\`bash
npm run token:status    # presupuesto real: usado / presupuesto / %
npm run token:ingest    # refresca los datos reales que lee el guard
cat config/token-budget-guard.json   # límites vigentes (fuente única)
\`\`\`

## Puntos clave

- Daily 5M / perSession 3M / perAgent 100K, con umbrales soft 70% y hard 90%.
- Escalada progresiva: WARNING en soft, bloqueo de dispatch en hard, \`kill_task\` solo en runaway.
- Modo actual soft y no bloqueante: la guardia observa y alerta sin romper la sesión.
- Tokens reales de la API > estimación chars/4; el CSV conserva ambos para comparar.
- Un presupuesto calibrado contra consumo real (~1.5M/día) es señal de medición, no de suerte.`,
    },
    {
      id: "perfiles-de-modelo-y-routing",
      title: "Perfiles cheap/balanced/premium y routing de modelos",
      minutes: 9,
      type: "curso",
      md: `## No todas las tareas merecen el mismo modelo

La intuición es simple: resumir un log no necesita el mismo músculo que diseñar una arquitectura. El error común es extremarla — usar el modelo más caro para todo (caro) o el más barato para todo (incorrecto en lo crítico). La solución del stack es un **router de modelos** con perfiles nombrados y reglas de escalada.

## Los tres perfiles (por fase SDD)

\`config/model-router.json\` define los perfiles \`cheap\`, \`balanced\` (activo por defecto) y \`premium\`. Cada perfil ajusta **temperatura** y **hallucinationGuard** por fase del ciclo SDD (BA/analizar, SAD/diseñar, DEV/implementar, QA/verificar):

| Fase | cheap | balanced (default) | premium |
| --- | --- | --- | --- |
| BA | 0.7 / low | 0.7 / low | 0.5 / medium |
| SAD | 0.5 / low | 0.3 / medium | 0.2 / high |
| DEV | 0.3 / medium | 0.15 / high | 0.1 / critical |
| QA | 0.2 / medium | 0.1 / critical | ==0.0 / critical== |

La lógica de fondo: la exploración (BA) tolera temperatura alta porque genera opciones; la verificación (QA) exige temperatura cercana a cero y guardia crítica porque un falso positivo ahí se propaga. \`premium\` no es "más creativo": es ==más estricto== en las fases donde la corrección manda.

## Tiering por dominio de negocio

Sobre los perfiles, el **domainTiering** clasifica dominios por riesgo:

- \`premium\` → **finance, legal, gov**: temperatura 0.1, guardia critical. "Los modelos financieros deben balancear; el output legal escala ante la duda. Tolerancia cero a alucinación."
- \`balanced\` → mkt, sales, hr, bus-tele, knowledge, sia: 0.25 / high — calidad creativa sin sobre-restringir.
- \`fastCheap\` → gitflow, ops, session: 0.15 / medium — tareas deterministas, velocidad sobre razonamiento.

## Cuándo escalar de modelo

La política de routing (\`fastCheapToStrongReasoning\`) escala a razonamiento fuerte cuando la tarea supera alguno de estos umbrales: texto de ==10,000 caracteres==, ==30 ítems==, o indicadores explícitos como "architectural decision", "security review" o "data model design". El stack también define niveles abstractos de capacidad (\`fastCheap\`, \`strongCoding\`, \`strongReasoning\`, \`strongReview\`) con niveles de *thinking* asociados (off/medium/high), de modo que la política hable de capacidades y no de marcas de modelos.

## Failover: degradar en lugar de fallar

Cuando el modelo preferido no está disponible, el router no se rinde: la cadena de failover es \`opencode → ollama → lm-studio2\`, con el modelo free-tier (\`opencode/mimo-v2.5-free\`) como respaldo garantizado, cambio automático al agotar cuota (\`auto-switch\`) y notificación del cambio. La política de reintentos distingue errores transitorios (\`APIConnectionError\`, \`RateLimitError\`, \`InternalServerError\`: hasta 3 reintentos con backoff de 1s) de errores fail-fast (\`AuthenticationError\`, \`BadRequestError\`, \`NotFoundError\`: no reintentes, avisa).

La temperatura misma está gobernada: solo puede modificarse desde el flujo de asignación de modelo (route set o TUI); los comandos sueltos están bloqueados, los cambios se auditan y el rango válido es 0.0-2.0.

## En el stack

\`\`\`bash
npm run profile:list            # perfiles disponibles
npm run profile:status          # perfil activo
npm run profile:set -- premium  # dry-run
npm run profile:apply -- premium # aplicar y persistir
\`\`\`

## Puntos clave

- cheap/balanced/premium ajustan temperatura + guardia de alucinación por fase SDD; el activo por defecto es balanced.
- El tiering por dominio pone finance/legal/gov en premium (0.1/critical) y las tareas deterministas en fastCheap.
- Escalada objetiva: >10K caracteres, >30 ítems, o indicadores de decisión arquitectónica/seguridad.
- Failover en cadena a proveedores locales antes que fallar; reintentos solo para errores transitorios.
- "Premium" significa más estricto, no más creativo — y la temperatura está auditada y bloqueada fuera del flujo oficial.`,
    },
    {
      id: "token-tracking-real",
      title: "Token tracking real: 4 fuentes convergen en Nexus",
      minutes: 9,
      type: "curso",
      md: `## Medir lo que ya está en disco, no instalar nada

El problema clásico del seguimiento de tokens en un entorno multi-herramienta: cada herramienta (ZCode, Codex, MiniMax, opencode) usa su propio formato y su propio lugar de persistencia. La tentación es un plugin por herramienta — frágil y acoplado. La solución del stack es un **daemon de ingesta agnóstico** (\`src/tokens/token-ingest.ts\`) que lee los datos que cada herramienta **ya persiste en disco** y los consolida en un solo lugar: Nexus.

## Las cuatro fuentes

:::diagram tokens-pipeline:::

| Herramienta | Formato | Ubicación |
| --- | --- | --- |
| opencode | SQLite (tablas \`session\`, \`message\`) | \`~/.local/share/opencode/opencode.db\` |
| zcode | JSONL (\`model-io-sess_*.jsonl\`, usage por request) | \`~/.zcode/cli/rollout/\` |
| codex | JSONL (\`rollout-*.jsonl\` anidados por fecha, eventos token_count) | \`~/.codex/sessions/\` |
| minimax | SQLite (tabla \`local_runtime_token_usage\`) | \`~/.minimax/v2/sqlite/runtime-state.sqlite\` |

El diseño es extensible: un registry \`detectSources()\` registra las fuentes disponibles y añadir una quinta herramienta es añadir un lector, no reescribir el pipeline.

## Autoridad de los datos: quién manda sobre quién

El stack es explícito sobre la jerarquía (evita el clásico "dos reportes, dos verdades"):

1. **Rollouts JSONL de cada herramienta** — autoridad de uso **bruto** cuando la herramienta los produce.
2. **Nexus** (tablas \`token_usage\`, \`token_transactions\`, \`token_savings\`) — autoridad de los **agregados y transacciones** ingeridos.
3. Snapshots heredados (\`.session/token-usage.json\`, \`.session/session-current.json\`) — estado para consumidores viejos, nunca reemplazan a Nexus.
4. \`token-usage-reader.ts\` — lector único con fallbacks explícitos: Nexus primero, luego el reporte live.

## Qué se puede responder con esto

- **Por transacción** (\`token_transactions\`): input/output/reasoning/cache/cost/model por mensaje, con el agente responsable.
- **Por agente**: orquestador (parent ROOT) vs subagentes (parent != ROOT), agrupados e individuales — la pregunta "¿qué subagente quema el presupuesto?" tiene respuesta directa.
- **Por sesión** (\`token_usage\`): histórico acumulado del orden de ==241 sesiones y 658M tokens==.
- **Ahorros** (\`token_savings\`): cache reads (~==1.06M tokens== recuperados) más la compresión del stack (prompt/output/structural).

Esta granularidad es la que habilita análisis empíricos del estilo del paper externo "How Do Coding Agents Spend Your Money?" — correlacionar consumo por mensaje con outcomes reales, pero con datos propios y locales.

## Ciclo de vida

El daemon arranca como step lazy \`token-ingest-init\` (\`--watch 30\`) al inicio de sesión: captura en vivo cada 30 segundos hasta el cierre, sin bloquear el arranque. También corre en modo pasada única (\`--once\`). Los reportes derivados (\`reports/stack-live-observability-latest.json\`) se actualizan en cada pasada y alimentan el dashboard — ==sin mock data==: todo deriva de trazas reales.

## En el stack

\`\`\`bash
npm run token:ingest   # una pasada de consolidación
npm run token:trace    # trazabilidad: transacciones por agente + ahorros
npm run token:status   # presupuesto real: usado / presupuesto / %
\`\`\`

## Puntos clave

- 4 fuentes reales (opencode SQLite, zcode JSONL, codex JSONL, minimax SQLite) → un daemon agnóstico → Nexus.
- Jerarquía de autoridad explícita: rollouts para lo bruto, Nexus para agregados, snapshots legacy solo compatibilidad.
- Tres tablas, tres preguntas: \`token_transactions\` (¿quién?), \`token_usage\` (¿cuándo/cuánto?), \`token_savings\` (¿cuánto ahorré?).
- Daemon lazy \`--watch 30\`: observabilidad continua sin costo de arranque.
- 241 sesiones / 658M tokens históricos y ~1.06M tokens recuperados por cache: los números existen porque se midieron.`,
    },
    {
      id: "checklist-de-optimizacion",
      title: "Checklist de optimización: audita tu propio consumo",
      minutes: 8,
      type: "curso",
      md: `## La auditoría como hábito

Todo lo anterior —cache, compresión, índices, presupuestos, perfiles— solo compone si lo revisas periódicamente. Esta lección ordena la auditoría de consumo propio en un recorrido reproducible de ~15 minutos, con los comandos del stack y qué buscar en cada salida.

## Paso 1: estado del presupuesto

\`\`\`bash
npm run token:status
\`\`\`

Busca tres cosas: el **% del presupuesto diario** (¿estás cerca del soft 70% antes de mediodía?), el **uso por sesión** contra el tope de 3M, y la **tendencia** — compara con el día anterior. Un salto de 2x dispara la acción \`investigate\` del budget guard: no lo ignores.

## Paso 2: trazabilidad por agente

\`\`\`bash
npm run token:trace
\`\`\`

Aquí aparecen las transacciones por agente y los ahorros. Preguntas de filtro:

1. ¿Qué agente concentra el consumo? Si un subagente supera sistemáticamente su rango (p.ej. orquestador 2000-4500 tokens), el paquete de tarea puede estar inflado.
2. ¿El ratio input:output es razonable? Un ratio 100:1 señala historial acumulado: hora de cerrar sesión o crear checkpoint.
3. ¿Los ahorros crecen? \`token_savings\` debe acumular cache reads y compresión; si está plano, el cache no está pegando (revisa el hit rate de \`response_cache\`).

## Paso 3: salud de las piezas que ahorran

\`\`\`bash
npm run watchtower:health   # 95 checks / 21 componentes
npm run db:health           # Nexus: response_cache, routing, tablas
\`\`\`

La watchtower verifica en un ciclo: dashboard-ws (API 200, PIDs vivos), codegraph (índice existente, nodos, antigüedad), engram, MCP (config + bridge), session, hooks y más — ==95 checks sobre 21 componentes==, con 95/95 PASS como estado esperado. Un WARN en codegraph significa que tus consultas están cayendo a re-lectura de archivos (más tokens) sin que nadie te avisara.

## Paso 4: decisiones de routing y perfiles

\`\`\`bash
npm run profile:status
npm run token:ingest   # refrescar datos antes de decidir
\`\`\`

Si el día es de tareas mecánicas y voluminosas, \`cheap\` basta; si toca diseño o revisión de seguridad, \`premium\` (recuerda: premium = más estricto, temperatura 0.0-0.1 en DEV/QA). El domainTiering ya cubre finance/legal/gov, pero el perfil global es tuyo.

## Paso 5: higiene del grafo y la base

\`\`\`bash
npm run graphify -- update .
npm run db:prune
\`\`\`

\`update .\` tras modificar código mantiene vigente el índice que evita re-leer el repo; \`db:prune\` limpia cache >7 días, eventos >30 días y \`token_usage\` >90 días — Nexus liviano y métricas dentro de la ventana útil.

## Paso 6: el dashboard como panel de control

\`npx tsx src/dashboard-start.ts\` levanta el observatorio: métricas en vivo (push cada 5s vía WS con tolerancia HTTP), waterfall de trazas, alertas (8 reglas en \`config/dashboard-alerts.json\`) y feedback por span. Todo deriva de trazas reales — si una métrica se ve rara, hay una traza detrás que lo explica.

> Ritmo sugerido: pasos 1-2 diarios (2 minutos), 3-6 semanales (15 minutos). Una auditoría que no cabe en la rutina no se hace.

## En el stack

\`\`\`bash
npm run token:status && npm run token:trace   # pasos 1-2 en una línea
npm run watchtower:health && npm run db:health # paso 3
npm run graphify -- update . && npm run db:prune # paso 5
\`\`\`

## La checklist resumida

- Presupuesto: % diario, uso por sesión, saltos 2x.
- Trazas: agente dominante, ratio input:output, ahorros crecientes.
- Salud: 95 checks de watchtower, Nexus íntegro.
- Routing: perfil activo acorde al tipo de día.
- Higiene: graphify actualizado, prune al día.
- Panel: dashboard con alertas activas y sin datos mock.

## Puntos clave

- La auditoría es un loop corto y repetible: medir (token:status/trace) → verificar salud (watchtower/db) → decidir (perfil) → limpiar (graphify/prune).
- Los síntomas clave se leen en números: % del presupuesto, ratio input:output, hit rate del cache, edad del índice.
- 95/95 PASS en watchtower es la línea base; cualquier WARN ahí es fuga de tokens silenciosa aguas abajo.
- Ninguna optimización sobrevive sin re-medición: el stack está diseñado para que medir sea el camino corto.`,
    },
  ],
};
