/* Gentle-Vanguard Academy — Track "automatizaciones" (8 lecciones).
 * Contenido educativo basado en procesos reales del stack (AGENTS.md,
 * docs/stack-manual-full.md, src/, config/). Cada lección describe una
 * automatización como flujo: trigger → decisión → efecto.
 * Sin dependencias: define window.GV_CONTENT["automatizaciones"].
 */
window.GV_CONTENT = window.GV_CONTENT || {};
window.GV_CONTENT['automatizaciones'] = {
  lessons: [
    {
      id: 'el-pipeline-de-sesion',
      title: 'El pipeline de sesión: la automatización maestra',
      minutes: 12,
      type: 'curso',
      md: `## Qué corre solo cuando abres sesión

Cuando el hook SessionStart de ZCode detecta que el cwd está dentro del repo, lanza en modo ==fire-and-forget== el pipeline de sesión. Nadie pulsa nada: en ~1.3s el proceso detached arranca y el resto corre en background. El pipeline (\`src/core/session-autostart.ts\` + \`config/session-autostart.config.json\`) declara ==112 steps, 107 habilitados==: 29 síncronos (se esperan) y 78 lazy (se delegan al background).

El objetivo: que el workspace quede **operativo sin intervención humana** — identidad de sesión, memoria, seguridad, grafo de código, presupuesto de tokens, observabilidad y base de datos lista antes de que escribas la primera pregunta.

:::diagram stack-layers:::

:::stats 107~steps habilitados | 29~síncronos (fase 0+1) | 78~lazy en background | 30~min ventana de reuso:::

## El flujo paso a paso

1. **Trigger.** El hook \`src/zcode-hooks/session-start.ts\` spawnea \`node --import tsx src/session-autostart-detached.ts\` con \`detached:true\` y \`stdio:'ignore'\` (invisible en Windows). El launcher fija \`AUTOSTART_LOG_FILE\` → \`.runtime/autostart-detached-*.log\` y redirige ahí toda la consola.
2. **Lock y reuso.** Se lee \`.runtime/session-autostart.lock\`. Si el lock tiene ==menos de 30 minutos== y el pipeline ya completó, se **reusa** ese bootstrap y se sale (cada turno de chat re-invoca el hook; no tiene sentido repetir 29+78 steps). Si el PID del lock vive de verdad (verificado con \`Get-CimInstance\` contra la command line de node), se salta; si está muerto, el lock es stale y se borra. \`--force\` rompe la ventana de reuso.
3. **Identidad.** Se genera \`session-<timestamp>\`, se propaga como \`SESSION_ID\` a todos los hijos (sin esto, el token tracker atribuye consumo a sesiones "unknown"), se escribe \`.session/session-current.json\` y se abre la sesión en **Engram** (\`sessionStart\` del bridge).
4. **Fase 0 — críticos secuenciales.** 6 steps \`required\`: \`model-enforcer\`, \`bootstrap-symlink\`, \`session-manager\` (limpieza), \`engram-policy\`, \`security-orchestrator\` y \`opencode-config-validate\`. Si uno falla, el pipeline **aborta** con exit 1.
5. **Fase 1 — paralelos.** El resto de los 29 síncronos corren con \`Promise.allSettled\`: tool-detection, token-budget, engram-integrity, security-initializer, skill-router, karpathy-guidelines, session-scoring, adaptive-opencode-profile, lefthook-verify, codegraph-sync, cost-tracker-init, validadores de config… Un fallo aquí es WARNING, no aborta.
6. **Lazy — 78 daemons.** Se lanzan en lotes de ==2== (con 150ms entre lotes, para no saturar la CPU) con \`windowsHide:true\` + \`child.unref()\`. Doble dedupe: una única query de PowerShell cachea los scripts node vivos, y un \`ProcessLock\` por step valida el PID. Ya corriendo → skip. Aquí viven: \`dashboard-ws-start\`, \`codegraph-mcp-server-start\`, \`maintenance-watchtower\` (autoheal), \`db-init\` / \`db-health-check\` / \`db-prune\` (Nexus lazy), \`adaptive-router\`, \`adaptive-steps\`, \`model-provider-heal\`, \`timeout-monitor-init\`, \`response-cache-init\`, \`knowledge-base-sync\`, \`token-ingest-init\`…
7. **Cierre.** Audit event \`session.complete\` (hits/misses, duración) y, si no falló ningún required, un **auto-checkpoint** \`auto-session-start\` (punto de rollback garantizado). \`process.exit(0)\` explícito para no bloquear pipes heredados.

Todo el ciclo de vida queda formalizado en \`src/core/session-orchestrator.ts\`: \`idle → bootstrapping → active → cleaning → closing → closed\`, con transiciones permitidas validadas y persistidas (últimas 50) en \`.runtime/session-orchestrator-state.json\`.

## En el stack

\`\`\`bash
npm run session:autostart:detached   # fire-and-forget (~1.3s)
npx tsx src/session-autostart.ts     # alternativa bloqueante
npx tsx src/core/session-orchestrator.ts --status
type .runtime\\autostart-detached-*.log   # ver qué corrió
type logs\\session-autostart-lazy.log     # qué lazy lanzó cada run
\`\`\`

## Qué pasa si se desactiva

El repo sigue siendo editable, pero todo pasa a ser manual: sin sesión en Engram ni \`SESSION_ID\` (tokens mal atribuidos), sin guards de config, sin watchtower autoheal, sin dashboard WS, sin ingesta de tokens, sin checkpoint inicial. Los errores que el pipeline detecta en 30s tardarían en aparecer — y en la peor forma: durante una delegación.

## Puntos clave

- La automatización maestra es **idempotente y con ventana de reuso** (30 min): se puede disparar cada turno sin coste.
- Fase 0 = requeridos que abortan; fase 1 = paralelos tolerantes a fallo; lazy = daemons deduplicados.
- El exit explícito y los spawns ocultos no son detalles: son lo que hace que la automatización sea invisible y no rompa la consola en Windows.
- Cada run queda auditado (\`session.start\`, \`session.skip\`, \`session.complete\`) y termina en checkpoint automático.`,
    },
    {
      id: 'asignacion-automatica-de-modelo',
      title: 'Asignación automática de modelo: quién decide qué modelo responde',
      minutes: 11,
      type: 'curso',
      md: `## Qué se automatiza y para qué

Ningún agente del stack elige su modelo: lo recibe. La decisión vive en \`config/model-router.json\` (v2.2.1) y se aplica en tres niveles — bindings por rol, escalado por complejidad y failover por salud — con una regla transversal: ==todos los agentes heredan el modelo de sesión del orquestador==, y el router solo ajusta por rol los parámetros de calidad (temperature, hallucinationGuard).

La razón de ser es doble: **coste** (no pagar un modelo caro para una tarea determinista) y **resiliencia** (si el modelo activo cae o agota cuota, el stack cambia solo y avisa).

## El flujo de decisión paso a paso

1. **Binding por rol.** La sección \`agentBindings\` define 30 roles con modelo/provider/temperature/hallucinationGuard y su subagente nativo. Por diseño: BA (explora) \`0.7/low\`, DEV \`0.15/high\`, QA \`0.1/critical\`, OPS y GOV \`0.1/critical\`, MKT \`0.5/low\`. El rol determina el perfil de riesgo, no el gusto.
2. **Escalado por complejidad.** \`routingPolicy.fastCheapToStrongReasoning\` escala de nivel fastCheap a strongReasoning cuando el texto excede ==10000 caracteres==, o la tarea ==30 ítems==, o contiene indicadores como "architectural decision", "security review", "data model design". Los \`modelLevels\` (fastCheap / strongCoding / strongReasoning / strongReview) definen el \`thinking\` (off → high).
3. **Tier por dominio (M6).** \`domainTiering\` fija calidad por dominio: \`finance/legal/gov\` → premium (\`0.1/critical\`, "cero tolerancia a alucinación"); \`mkt/sales/hr/…\` → balanced (\`0.25/high\`); \`gitflow/ops/session\` → fastCheap (\`0.15/medium\`). En la delegación, \`resolveAgentTier()\` inyecta esta temperature como override real.
4. **Perfiles por fase SDD.** \`profiles\` (cheap / balanced / premium, activo ==balanced==) ajustan temperature y guard **por fase** (BA/SAD/DEV/QA) — el mismo pipeline corre más barato o más exigente según el perfil activo (\`npm run profile:apply -- premium\`).
5. **Retry y failover.** \`retryStrategy\`: errores transitorios (RateLimit, conexión, 5xx) → hasta ==3 reintentos== con backoff de 1s; errores fail-fast (auth, bad request) → sin reintento. El failover (\`provider-failover.ts\`, \`autoCheck: on-route\`, cache 5 min) consulta \`model-fallback.json\` y conmuta de provider; el fallback final documentado es \`opencode/mimo-v2.5-free\` con \`quotaExhaustedBehavior: auto-switch\` + notificación \`[FALLBACK]\` y \`resetOnRenewal\`.
6. **Salud y degradación.** \`src/smart-model-router.ts\` lee \`config/model-health-registry.json\`: cada error del modelo activo incrementa \`consecutiveErrors\`; a ==3== el modelo se marca \`unavailable\` y se salta a su \`fallbackChain\` (o a la cadena de la estrategia). El cambio se persiste en \`.runtime/model-active.json\` con su causa (\`fallback-<tipo de error>\`).
7. **Vallado.** \`temperaturePolicy\` bloquea cambios de temperature fuera del flujo de asignación (\`lockedByDefault\`, requiere admin, audita). Y \`model-enforcer\` — step **required** de fase 0 del pipeline de sesión — puede reasignar todo el stack al modelo gratuito disponible si la cuota está agotada.

:::stats 30~roles con binding | 4~niveles de capacidad | 3~reintentos con backoff 1s | 5M~tokens/día de presupuesto:::

El coste de cada decisión queda trazado: \`costTracking\` nivel \`per_call\` converge en Nexus (tabla \`token_transactions\`) y alimenta los presupuestos ==5M diarios / 3M por sesión==.

:::diagram tokens-pipeline:::

## En el stack

\`\`\`bash
npx tsx src/smart-model-router.ts check        # salud de todos los modelos
npx tsx src/smart-model-router.ts get-active   # modelo activo y por qué
npm run profile:status                         # perfil SDD activo
npx tsx src/model-provider-healer.ts --status  # salud reciente del proveedor
\`\`\`

## Qué pasa si se desactiva

Sin router, cada agente usaría el default plano: tareas críticas (QA, legal) correrían con la misma laxitud que un blog post, las tareas deterministas pagarían modelo de más, y un error de cuota a las 2am detendría el stack en vez de conmutar al fallback y avisar por notificación.

## Puntos clave

- El router no "elige modelo libremente": aplica **bindings por rol + tier por dominio + umbral de complejidad** — decisiones declarativas, auditables.
- La herencia del orquestador es la regla; los bindings ajustan quality knobs, no el modelo en sí.
- La salud es un contador: 3 errores consecutivos = unavailable = fallback automático persistido en \`.runtime/model-active.json\`.
- Temperature es política, no preferencia: está locked fuera del flujo de asignación.`,
    },
    {
      id: 'asignacion-automatica-de-steps',
      title: 'Asignación automática de steps: el presupuesto de pasos que se auto-escala',
      minutes: 9,
      type: 'curso',
      md: `## Qué se automatiza y para qué

Un subagente con presupuesto de pasos insuficiente no falla ruidosamente: se detiene a mitad de tarea con un "maximum steps reached". El sistema **Adaptive Steps** (\`src/adaptive-steps.ts\`) elimina ese escenario con dos mecanismos: uno **proactivo** (estimar los steps necesarios y escribirlos *antes* de delegar) y uno **reactivo** (cuando el agente reporta agotamiento, subirle el límite y re-despacharlo).

Es una automatización de puro mantenimiento: el lector nunca debería tener que pensar "¿le alcancen los pasos a este agente?".

## El flujo paso a paso (proactivo)

1. **Base por agente.** Cada rol tiene un piso en \`BASELINE\`: orchestrator ==24==, sdd-apply ==40==, sdd-explore/design/verify 30, sia-agent 35, session/knowledge 25, agentes de negocio 20.
2. **Señales de complejidad.** El texto de la tarea se contrasta contra regexes con coste en steps:

| Señal en la tarea | Coste |
| --- | --- |
| \`files, refactor, migrat, implement, feature, module\` | +12 |
| \`complex, large, big, deep, nested, integrat\` | +10 |
| \`explore, investigat, research, audit, review, diagnos\` | +8 |
| \`parallel, multiple, batch, across\` | +8 |
| \`test, verify, validat, typecheck, lint\` | +6 |
| \`config, json, yaml, schema\` / \`doc, readme, guide, adr\` | +4 |

3. **Heurística de archivos.** Un "20 files" en la descripción suma \`N/2\` steps (tope +20).
4. **Tope y redondeo.** El resultado se redondea hacia arriba y se **caps a 80** — el techo duro del sistema.
5. **Escritura dual.** El valor se persiste en \`opencode.json\` (\`agent.<rol>.steps\`) **y** en el frontmatter de \`.opencode/agents/<rol>.md\` (se inserta tras la línea \`model:\` si no existe). La siguiente delegación ya corre con el presupuesto nuevo.

## El flujo reactivo (re-asignación)

1. El orquestador **detecta** "maximum steps reached" en la respuesta del agente.
2. Ejecuta \`adaptive-steps.ts --resume <agente> --task_id <id>\`: lee el steps actual, suma ==+20== (tope 80) y lo aplica en ambos archivos.
3. La salida indica explícitamente: re-despachar con ese \`task_id\` y el nuevo límite — el contexto se **preserva** y el agente continúa donde quedó, no empieza de cero.

:::stats 24~steps base orquestador | +20~por re-asignación | 80~techo duro del sistema:::

La integración en el orquestador sigue una prioridad fija: 1) historial de \`routing-table.json\` si existe, 2) estimación \`--auto\`, 3) defaults de \`opencode.json\`. Con el uso, los valores observados derivan del baseline (p. ej. sdd-apply 52, sdd-explore 38, gov-agent 38 en el manual) porque cada estimación sobreescribe la anterior.

## En el stack

\`\`\`bash
npx tsx src/adaptive-steps.ts --estimate "fix broken ps1 refs in 20 files"
npx tsx src/adaptive-steps.ts --auto "complex refactoring" --agent sdd-apply
npx tsx src/adaptive-steps.ts --resume sdd-apply --task_id ses_xxx
npx tsx src/adaptive-steps.ts --status
\`\`\`

\`adaptive-steps\` corre además como step lazy del pipeline de sesión, así que los presupuestos se recalibran al arrancar.

## Qué pasa si se desactiva

Vuelven los presupuestos congelados: un agente de 20 steps que reciba una migración multi-archivo se apagará a mitad, y la única "recuperación" será re-lanzar a mano perdiendo el contexto. El síntoma clásico es ver la misma tarea delegada dos o tres veces sin que nadie haya pedido eso.

## Puntos clave

- Proactivo (antes de delegar) + reactivo (+20 con \`task_id\` al agotarse) = el agente nunca se queda sin pasos por diseño.
- Las señales son regexes baratas y deterministas sobre el texto de la tarea — no hay LLM decidiendo esto.
- El tope de 80 y el redondeo hacia arriba existen para no quedarse corto: un step de más es barato, una re-delegación completa no.
- La escritura dual (opencode.json + frontmatter) garantiza que cualquier herramienta que lea cualquiera de los dos vea el mismo presupuesto.`,
    },
    {
      id: 'cache-automaticas',
      title: 'Cachés automáticas: lo que no pagas dos veces sin pedirlo',
      minutes: 10,
      type: 'curso',
      md: `## Qué se cachea sin que lo pidas

Tres capas de caché operan por defecto en el stack, en niveles distintos: la **response cache** (respuestas completas del modelo, persistida en Nexus), el **LRU por tenant** del dashboard (hot paths de lectura) y el **prompt-cache del proveedor** (prefijos reutilizados a nivel API). Ninguna requiere opt-in: ya están en el flujo.

:::diagram cache-flow:::

## Response cache SHA-256 — el flujo

1. **Consulta previa.** Antes de llamar al modelo, se calcula la clave: \`SHA-256(input + '|' + context)\`. Ni un byte distinto produce la misma clave.
2. **Hit exacto.** Si la clave existe en la tabla \`response_cache\` (SQLite de Nexus) y no expiró, se devuelve la respuesta guardada, se incrementa \`hit_count\` y se suman los \`tokens_saved\`. El modelo jamás se invoca.
3. **Miss exacto → hit semántico.** Si no hay clave exacta pero el input tiene ==40+ tokens==, se intenta un lookup semántico: vector TF-IDF del input contra los embeddings almacenados, similitud coseno umbral ==0.9==. El umbral es alto a propósito: con 0.85 se detectaron falsos positivos en inputs cortos (verificado 2026-08-14) — prefiero un miss que responder "algo parecido".
4. **Miss total.** Se llama al modelo y la respuesta se guarda con TTL (default ==60 min==, extendido desde 30), \`maxEntries: 1000\`, limpieza de expirados cada 5 min y scoping por \`tenant_id\`. Los JSON legacy de \`.session/response-cache/\` se migran al primer uso.
5. **Invalidación.** Por TTL, por limpieza periódica, o manual (\`cache clear\`). El impacto documentado: ==33-41% menos latencia, 25-35% menos coste de tokens==.

\`\`\`bash
npx tsx src/response-cache.ts stats   # hits/misses/hit-rate/ahorro
npx tsx src/response-cache.ts clear   # invalidación manual total
\`\`\`

## LRU por tenant del dashboard

\`apps/web-dashboard/server/cache/tenant-lru-cache.ts\` protege las rutas calientes (metrics, traces) contra ráfagas de lecturas síncronas sobre SQLite:

1. Cada lectura pasa por \`getOrLoad(name, tenantId, loader)\`: si hay entrada fresca se devuelve; si no, se computa una vez y se guarda.
2. El TTL default es ==3s, deliberadamente menor que el push de 5s== del WebSocket: cada push computa datos frescos, pero las peticiones REST concurrentes dentro de esa ventana comparten un único cómputo.
3. La clave compone \`tenantId + parámetros\` — dos tenants nunca comparten entrada. Tope de 64 entradas por caché con evicción LRU, stats de hits/misses/evictions, y \`invalidate(name, tenantId)\` para coherencia inmediata tras escrituras.

## Prompt-cache del proveedor

A nivel API, el prefijo estable de la conversación se reutiliza: leer del cache del proveedor cuesta una fracción del input normal. El stack no lo activa — lo **contabiliza**: las columnas \`cache_read_tokens\` / \`cache_write_tokens\` de \`token_transactions\` y la tabla \`token_savings\` en Nexus cuantifican cuánto recuperó cada sesión. Es también la razón por la que el AGENTS.md es slim y estable: un prefijo que no cambia es un prefijo cacheable.

:::stats 60~min TTL de response cache | 0.9~umbral semántico | 3s~TTL del LRU (push 5s) | 64~entradas máx por caché:::

## Qué pasa si se desactiva

Nada rompe — pero todo se repaga: la misma pregunta del martes se cobra entera de nuevo, el dashboard recalcula cada lectura concurrente, y el ahorro de cache desaparece silenciosamente del reporte de tokens. La degradación es puramente económica, que es exactamente por lo que pasa desapercibida sin las métricas.

## Puntos clave

- Clave SHA-256 = determinismo total: mismo input + mismo contexto = misma respuesta cacheada, sin heurísticas.
- El fallback semántico está cageado (0.9 + 40 tokens mínimos) porque un falso hit responde "otra pregunta".
- El TTL de 3s del LRU es un contrato con el push de 5s: frescura por push, ahorro dentro de la ventana.
- El prompt-cache del proveedor es pasivo pero medido: lo que no se mide, no se optimiza.`,
    },
    {
      id: 'prompting-automatizado',
      title: 'Prompting automatizado: lo que el stack arma antes de que veas el prompt',
      minutes: 10,
      type: 'curso',
      md: `## Qué se automatiza y para qué

Cuando un agente del stack recibe una tarea, el prompt que llega al modelo ya pasó por un ensamblaje invisible: manual inyectado, prompt de rol, comportamiento comprimido, contexto de memoria y grafo, y estado compactado de transacciones. El objetivo es doble — **consistencia** (dos sesiones distintas producen prompts equivalentes) y **economía de contexto** (inyectar solo lo que el rol necesita, una vez).

## El flujo de ensamblaje paso a paso

1. **Manual slim inyectado.** El orquestador recibe \`AGENTS.md\` — la versión de bajo contexto — como instrucción base; el manual completo (\`docs/stack-manual-full.md\`) solo se carga si la tarea lo requiere. La regla de sincronización lo hace explícito: \`injectAgentsMd: true\` para el orquestador, \`false\` para subagentes (no re-inyectar el manual en cada subagente sería el antipatrón que el protocolo de contexto combate).
2. **Prompt por rol.** \`config/agent-prompts/*.md\` (24 roles: QA, DEV, GOV, LEGAL, SIA,…) define \`Identity\`, \`Core Mission\`, \`Critical Rules\` y \`Automatic Triggers\`. Ejemplo real de QA: *"Default to FAIL — test must prove PASS, not the other way around"* y *"When hedging language appears (should, probably, might): demand concrete evidence"*. El rol llega con su criterio pre-cargado.
3. **Behavior-prompts comprimidos.** \`config/behavior-prompts.json\` (v1.1) contiene comportamientos transversales condensados a 2-4 líneas ("Senior debugging engineer investigating production errors… root cause verification + edge case testing required"), cada uno con \`applies_to\` (roles) y \`opencode_subagent\` (a qué subagente nativo aplica). Un patrón de comportamiento cuesta decenas de tokens, no párrafos.
4. **Contexto de grafo.** Para preguntas de código, el índice de graphify (\`graphify-out/graph.json\`, consultable vía \`npm run graphify -- query\`) permite inyectar el subgrafo relevante en vez de archivos completos — el orden de -94% de tokens documentado para preguntas de código.
5. **Contexto de memoria.** La sesión se abrió en Engram al arrancar (step del pipeline); el contexto de observaciones previas pinadas y recientes está disponible para inyección sin que el agente tenga que buscarlo.
6. **Compresión de entrada.** \`prompt-compression.ts\` (40-60% por mensaje) y la compresión estructural con \`mode:'input'\` — **lossless-only** — actúan sobre lo que viaja al modelo; \`chat-level-enforcer\` aplica topes duros por nivel de chat (200-4000 tokens).
7. **Estado compactado (compact-state).** Las transacciones de review (pre-push, pre-merge, session-start, pipeline) avanzan por una máquina de estados formal: \`initiated → judges_started → verdict_ready → fixes_applied → approved | escalated\` (+ \`failed\`/\`rolled_back\`). Cada transición exige token **CAS** (compare-and-swap) contra el token de la fase previa — dos procesos no pueden transicionar la misma review — y guarda un recovery point para rollback. GC de transacciones stale a las 24h, máximo 50 transiciones por instancia, persistido en \`.session/state-machine\`.

## En el stack

\`\`\`bash
ls config/agent-prompts/            # 24 prompts de rol
npx tsx src/compact-state.ts --status
npx tsx src/compact-state.ts --gc
npm run graphify -- query "how does routing work"
\`\`\`

## Qué pasa si se desactiva

El prompting pasa a ser arte improvisado: cada sesión re-descubre las reglas del rol (o no), el manual completo o nada se inyecta sin criterio de contexto, y las reviews pierden su transaccionalidad — dos gates corriendo sobre los mismos archivos pueden pisarse sin que el CAS lo detecte.

## Puntos clave

- El prompt que ves ya trae: manual slim + rol + comportamiento comprimido + grafo + memoria + estado — ensamblado, no escrito a mano.
- La decisión clave es de **granularidad de inyección**: orquestador sí recibe el manual, subagentes no; slim siempre, completo solo bajo demanda.
- Los behavior-prompts demuestran que un comportamiento se puede especificar en 3 líneas si el rol ya da el resto del contexto.
- compact-state aporta lo que un prompt no puede: garantías — atomicidad (CAS), recoverabilidad (recovery point) y limpieza (GC 24h).`,
    },
    {
      id: 'auto-delegacion-y-routing',
      title: 'Auto-delegación y routing: el loop que aprende con cada tarea',
      minutes: 11,
      type: 'curso',
      md: `## Qué se automatiza y para qué

\`src/route-and-delegate.ts\` es el puente "opera con todas las herramientas": una petición en lenguaje natural entra, y sale un agente nativo ejecutándola. Nadie elige el agente — lo decide una cadena de fuentes de routing ordenadas por cuánta evidencia histórica tienen, y **cada ejecución realimenta la cadena**. Es la automatización que se mejora a sí misma.

:::diagram routing-loop:::

## El flujo completo paso a paso

1. **Clasificación de dominio.** \`matchDomain()\` recorre una tabla de keywords contra la tarea. El orden es crítico y está comentado en el código: las keywords de negocio van **primero** porque son más específicas que los verbos de ingeniería — "review this contract" debe ir a legal, no a code-review por el "review". Las keywords de ≤3 caracteres matchean solo como palabra completa ('pr' no matchea "product").
2. **Recomendación en cascada** (\`recommend-agent.ts\`), de más evidencia a menos:
   - **routing_rules de Nexus**: reglas por tenant que matcheen la tarea, ordenadas por \`priority → successRate → hitCount\`. La confianza es \`successRate/100\` (acotada 0.3-1). Fuente: \`nexus\`.
   - **Overrides de la routing table** (\`.session/routing/routing-table.json\`): patrones de alta prioridad matcheados contra el texto **completo** de la tarea — así "gdpr compliance audit" golpea el override gdpr→legal-agent aunque el dominio derivado sea governance. Fuente: \`override\`.
   - **domainEntries**: mejor agente por dominio aprendido del historial. Fuente: \`routing-table\`.
   - **Static map** (cold start): 17+ dominios con candidatos fijos, confianza 0.3. Fuente: \`static-fallback\`.
3. **Tier de calidad.** \`resolveAgentTier()\` resuelve el tier M6 del agente recomendado (premium/balanced/fastCheap) y su temperature.
4. **Compresión lossless.** La tarea y el contexto se comprimen con \`compressDelegationLossless\` (modo input, protege el razonamiento); si la compresión no mejora, se envía el original.
5. **Delegación nativa.** \`agent-delegator.ts\` ejecuta el agente con la temperature del tier — no la hardcoded. La salida incluye duración, modelo y directorio de artefactos.
6. **Outcome persistido (dos sinks).** El hit se appendea a \`.session/routing/hits.jsonl\` y \`recordRoutingOutcome()\` hace upsert en la tabla \`routing_rules\` de Nexus: \`hit_count +1\`, \`success_count\` según resultado, y \`success_rate\` recalculado — todo dentro de una transacción SQLite.
7. **Rebuild de la tabla.** \`adaptive-router.ts --build\` (corre como step lazy del pipeline) lee cinco fuentes de historia — skill-usage, delegations de metrics, corrections-log, reflections, knowledge concepts — y produce \`agentPerformance\` (successRate por agente) y \`domainEntries\` (bestAgent + alternatives + confidence). Reglas del build: mínimo ==3 data points==, overrides solo con confianza ≥ ==0.8== (máx 20), decay de 14 días, successRate mínimo 0.3, máximo ==3 cambios aplicados por run== (el aprendizaje no puede reescribir el routing de golpe). Los overrides expiran a los 30 días. En cold start, seeds de 17 dominios + 10 overrides (security audit→gov-agent 0.9, code review→sdd-verify 0.9, gdpr→legal-agent 0.9…).

## En el stack

\`\`\`bash
npm run delegate:run -- --task "audit gdpr compliance" --topn 3
npx tsx src/recommend-agent.ts --task "fix broken ps1 references" --refresh
npx tsx src/adaptive-router.ts --status
\`\`\`

## Qué pasa si se desactiva

Sin el loop, el routing queda congelado en el static map: confianza 0.3 para siempre, sin memoria de qué agente rindió mejor en cada dominio, y cada petición cruzada (legal + código, marketing + datos) exige elegir el agente a mano. La tabla no se corrompe — simplemente deja de aprender.

## Puntos clave

- La cascada nexus → override → tabla → static garantiza que la recomendación usa la **mejor evidencia disponible** y degrada con gracia.
- El outcome no se descarta: cada delegación actualiza \`success_rate\` en Nexus y alimenta el próximo rebuild — el loop completo es automático.
- Los frenos (3 cambios por run, decay 14d, overrides con expiry) evitan que una racha mala reescriba el routing entero.
- El matching negocio-primero y el whole-word para keywords cortas son correcciones de bugs reales de routing — el orden de la tabla es parte del diseño.`,
    },
    {
      id: 'auto-healing-y-watchdogs',
      title: 'Auto-healing y watchdogs: lo que el stack repara sin avisarte',
      minutes: 11,
      type: 'curso',
      md: `## Qué se automatiza y para qué

Los componentes caen: un daemon muere, un puerto deja de responder, un proveedor LLM empieza a fallar. El stack asume que ocurrirán y despliega capas de recuperación automática — **watchtower** (salud integral + autoheal), **watchdog del dashboard** (reinicio del WS), **circuit breaker v2** (protección de servicios externos), **model-provider-healer** (errores de proveedor LLM) y el **timeout-monitor** (violaciones de tiempo). La meta operativa: que un componente degradado se recupere antes de que alguien lo note.

:::stats 95~checks del watchtower | 21~componentes vigilados | 10~reinicios máx del watchdog:::

## Watchtower autoheal — el flujo

1. **Trigger.** \`maintenance-watchtower\` corre como step lazy del pipeline de sesión en modo \`autoheal -Quiet\` (también manual: 6 modos — health, rebuild, report, autoheal, continuous, all).
2. **Checks.** Ejecuta 95 checks sobre 21 componentes; cada resultado lleva un \`action\` (\`ok\`, \`restart\`, \`start\`, \`rebuild\`, \`reindex\`, \`manual\`).
3. **Decisión.** \`autoHeal()\` recolecta los resultados con action restart/start que no están PASS.
4. **Dashboard WS caído.** Lee el puerto real de \`.runtime/dashboard-ports.json\`, sondea el puerto: si responde, no hace nada (no compite con el watchdog); si no, lanza el wrapper \`dashboard-ws-launcher.ts\` detached, espera 8s y verifica; si aún no responde, fallback a spawn directo, espera 10s y verifica; si sigue muerto → FAIL con acción \`manual\` (crítico). Nunca lanza a ciegas sin verificar.
5. **CodeGraph caído.** No lo spawnea directo: delega en el daemon canónico \`codegraph-mcp-server-start.ts\`, que mantiene el stdin ABIERTO (sin él el servidor stdio MCP muere al instante) y escribe él mismo el PID real — evitando instancias duplicadas compitiendo por el lock del índice.
6. **Rebuilds.** En modo rebuild/all: rebuild de ml-embeddings y reindex RAG de Engram cuando los checks lo piden (o con \`--force\`).

## Watchdog del dashboard WS

\`dashboard-ws-autostart.ts --watch\` monitorea en loop: health check cada ==5s==; tras ==2 fallos consecutivos== reinicia el servidor; presupuesto de ==10 reinicios==; si el servidor está estable ==5 minutos==, el presupuesto de reinicios se resetea. Guard de instancia única por PID file (nunca dos watchdogs). El stop del stack mata el watchdog **primero** — si no, te reiniciaría el servidor que acabas de apagar.

## Circuit breaker v2 — cuándo abre y cierra

Tres estados por servicio (\`opencode\`, \`nexus\`, \`dashboard_ws\`…), persistidos en \`.runtime/circuit-breaker-v2/state.json\`:

1. **CLOSED (normal).** Las llamadas pasan; se cuentan éxitos y fallos consecutivos.
2. **Apertura.** Con el umbral de fallos alcanzado (opencode: ==5==; nexus: ==3==), el circuito pasa a **OPEN**: las llamadas siguientes fallan rápido, sin esperar el timeout del servicio (30s opencode, 10s nexus).
3. **Semi-recuperación.** Tras el \`resetTimeout\` (60s / 30s) pasa a **HALF_OPEN** y deja pasar un número limitado de llamadas de prueba (3 / 2). Éxitos consecutivos suficientes (2) → CLOSED; un fallo → OPEN de nuevo, con backoff exponencial entre intentos y health checks de 2s.

## Model-provider-healer

Escanea los logs de opencode y \`.session\` buscando firmas de error de \`config/model-health.json\` (p. ej. params no soportados por el proveedor). Si el modelo **activo** falla, lo marca unhealthy en \`.runtime/model-health.json\` con cooldown, y auto-switchea al modelo nativo vía \`model-switch.ts\`. Corre como step lazy (\`model-provider-heal\`); con \`--scan\` solo detecta sin cambiar nada.

## Timeout-monitor

\`trackExecution()\` mide cada operación contra \`config/timeout-config.json\`; el daemon (\`--daemon\`, intervalo 30s) emite alertas según \`config/dashboard-alerts.json\` y persiste métricas en \`.session/metrics\`. No repara: **hace visible** lo que excede los umbrales para que los healers tengan señal.

## En el stack

\`\`\`bash
npm run watchtower:health      # 95/95 PASS esperado
npx tsx src/circuit-breaker-v2.ts --status
npx tsx src/model-provider-healer.ts --scan
npx tsx src/core/timeout-monitor.ts --alerts
\`\`\`

## Qué pasa si se desactiva

La primera caída del WS deja el dashboard ciego hasta el reinicio manual, un proveedor que falla consume timeouts completos en cada llamada (30s por llamada, sin abrir el circuito), y los errores de proveedor LLM se acumulan en logs que nadie correlaciona. Nada explota — solo todo requiere un humano de guardia.

## Puntos clave

- Cada healer **verifica después de actuar** (sondea el puerto, delega en el daemon canónico) — la recuperación a ciegas crea problemas peores (procesos duplicados).
- El circuito abierto convierte "esperar 30s y fallar" en "fallar en 1ms": protege al llamante y al servicio saturado.
- El watchdog tiene presupuesto finito (10) y reset por estabilidad: reiniciar infinito un servidor roto solo genera ruido.
- Los timeouts son la señal primaria: casi todo el auto-healing se dispara por violaciones de tiempo o salud, no por errores de aplicación.`,
    },
    {
      id: 'hooks-y-syncs-automaticos',
      title: 'Hooks y syncs automáticos: la automatización periférica',
      minutes: 10,
      type: 'curso',
      md: `## Qué se automatiza y para qué

Alrededor del ciclo principal vive una capa de automatizaciones pequeñas que mantienen coherente el ecosistema: el grafo de código actualizado tras cada edición, los agentes y skills sincronizados entre herramientas, los gates de calidad en cada commit/push, y la memoria replicada entre Engram y el vault. Ninguna es crítica por sí sola; juntas evitan el "funciona en mi máquina" estructural.

## graphify update tras cada Write/Edit

1. **Trigger.** El hook PostToolUse de ZCode (\`src/zcode-hooks/post-edit-graphify.ts\`) se dispara en cada Write|Edit.
2. **Guards.** Solo actúa si el archivo editado tiene extensión de código (\`.ts/.tsx/.js/.jsx/.mjs/.cjs\`), está dentro del repo, y existe \`graphify-out/graph.json\` (sin índice, no hace nada — el primer build es manual).
3. **Efecto.** Ejecuta \`npm run graphify -- update .\` con timeout de 120s. Si falla, solo loguea diagnóstico — **nunca bloquea** la edición (exit 0 siempre). El grafo queda fresco sin que nadie recuerde actualizarlo.

## zcode-sync multi-tool

1. **Agentes.** Lee los frontmatter de \`.opencode/agents/*.md\` (21 agentes) y los escribe en \`~/.zcode/agents/\` con el mapeo nativo: \`steps → maxTurns\`, \`model → inherit\`, \`permission deny → disallowedTools\`, y \`injectAgentsMd\` true solo para el orquestador (AGENTS.md slim, una vez).
2. **Skills críticas.** Copia **12 skills** (no las ~120: ZCode tiene presupuesto fijo de metadata y excederlo degrada el auto-trigger de *todas*) a tres destinos: \`~/.zcode/skills/\`, \`~/.codex/skills/\` y \`~/.minimax/agents/mavis/skills/\` (filtrable con \`--tools\`).
3. **Regla operativa.** Tras editar \`.opencode/agents/\` hay que re-ejecutar el sync, y los cambios requieren **nueva sesión** en cada herramienta — no hay hot-reload.

## Gates de lefthook

1. **pre-commit** (por tipo de archivo): \`opencode-validation\`, \`json-lint\`, \`workflow-lint\`, \`lockfile-lint\`, \`skill-scan\`, \`secretlint\` y \`secret-scanner\` (80 patrones, con redacción). Un commit con un secreto no llega a existir.
2. **pre-push** (el muro): typecheck, lint, \`siem-audit-bridge\` quick, \`orchestrate-auto-fix --Fix\`, npm-audit (moderate), auditoría de shell-quoting (falla el push si \`runSyncShell\` interpola con comillas — cmd las destruye), perf-baseline, coverage gate rápido (~5s, informativo), container-scan (SBOM con Syft+Grype, bloquea con vuln ≥ high), content-validate (~3s) y ci-static-gates (~35s, los mismos checks que CI — fallar aquí es 100x más barato que fallar en CI).
3. **post-commit / post-merge / commit-msg**: sync de codegraph forzado + snapshot hashline; reinstall tras merge; commitlint + session-track.

## knowledge-base-sync y engram-auto-sync

1. **KB-sync** (\`src/knowledge-base-sync.ts\`, corre lazy): exporta observaciones de Engram al vault de Obsidian (\`knowledge-base/\`), importa el inbox (\`00-inbox\`) deduplicado por hash de contenido (\`.runtime/kb-sync-imported.json\` — una nota no se importa dos veces aunque se edite), y genera resúmenes de sesión en \`04-sessions\`.
2. **Engram-auto-sync** (\`src/engram-auto-sync.ts\`): verifica los checksums (\`.engram/checksums.sha256\`) contra \`engram.db\` en modo \`check\`; los regenera con lock de archivo (\`.runtime/engram-sync.lock\`) en \`sync\`; y en \`monitor\` corre un loop periódico que chequea y auto-corrige. La memoria se mantiene íntegra sin mantenimiento manual.

## En el stack

\`\`\`bash
npx tsx src/zcode-sync.ts --sync          # agentes + skills a 3 herramientas
npx tsx src/knowledge-base-sync.ts --mode full
npx tsx src/engram-auto-sync.ts -Mode check
npm run graphify -- update .
\`\`\`

## Qué pasa si se desactiva

El grafo envejece silenciosamente (y las respuestas basadas en él se desactualizan), las tres herramientas divergen en agentes y skills, los secretos y errores de config llegan al remoto (y a CI), y el vault se desconecta de la memoria operativa. Cada pieza falla de forma silenciosa — su ausencia no da error, da **incoherencia**.

## Puntos clave

- El patrón dominante es **hook con guards + nunca bloquear** (exit 0): la automatización periférica no puede convertirse en el punto de fallo del flujo principal.
- Los gates se ordenan por coste: pre-commit barato y específico, pre-push caro y completo — y ci-static-gates adelanta el fallo de CI al push local.
- La sincronización multi-tool es explícita y con presupuesto (12 skills, no 120) porque el coste de exceder el metadata budget es degradar el auto-trigger global.
- Deduplicar por hash (KB-sync) y verificar por checksums (engram-auto-sync) convierten la sincronización en operación idempotente.`,
    },
  ],
};
