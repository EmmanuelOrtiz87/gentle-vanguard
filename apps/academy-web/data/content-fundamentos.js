/* Gentle-Vanguard Academy — Track "fundamentos" (10 lecciones, ES).
   Formato: window.GV_CONTENT["<track>"] = { lessons: [...] }. Markdown subset soportado por app.js. */
window.GV_CONTENT = window.GV_CONTENT || {};
window.GV_CONTENT['fundamentos'] = {
  lessons: [
    {
      id: 'que-es-gentle-vanguard',
      title: '¿Qué es Gentle-Vanguard?',
      minutes: 8,
      type: 'curso',
      md: `## Qué es

==Gentle-Vanguard== es una **capa de orquestación e ingeniería** que se instala encima de tus herramientas de IA para programar. No es un modelo de lenguaje ni un chat: es un stack local de scripts TypeScript, configuraciones versionadas, una base de datos SQLite operacional, servidores MCP, agentes especializados y un dashboard de observabilidad, todo coordinado para que trabajar con agentes de IA sea un proceso **medible, repetible y auditable**.

Puedes imaginarlo como el "sistema operativo" de tu flujo de trabajo con IA: cuando abres una sesión, el stack arranca memoria persistente, índices de código, presupuesto de tokens, health checks y telemetría de forma automática, y cuando cierras, consolida métricas y aprendizajes.

### Qué NO es

Es tan importante saber lo que no es como lo que es:

- **No es un LLM ni un proveedor de modelos**: usa los modelos que ya tienes en OpenCode, ZCode, Codex, MiniMax, Cursor o Claude Code.
- **No es un SaaS ni una nube obligatoria**: el modelo operativo oficial es ==LOCAL-FIRST / SERVER-OPTIONAL== (ADR-0017). Todo el núcleo corre en tu máquina; servidor, Kubernetes y SaaS son rutas opt-in de evolución.
- **No es un IDE nuevo**: no reemplaza tu editor; lo complementa con orquestación, memoria y verificación.
- **No es magia**: cada número que muestra (tokens, costos, salud) proviene de datos reales persistidos por las herramientas, sin mock data.

## Para qué sirve

:::diagram stack-layers:::

El problema de fondo: las herramientas de IA te dan potencia pero no disciplina. Cada sesión empieza de cero, la calidad depende de la suerte del prompt, y nadie sabe cuánto cuesta ni qué riesgos se corrieron. Gentle-Vanguard convierte eso en un proceso de ingeniería con:

- **Memoria** entre sesiones (Engram) para no repetir decisiones.
- **Índices de código** (graphify/CodeGraph) para responder "¿dónde vive X?" sin releer el repo.
- **Observabilidad** real: tokens, trazas, alertas y salud en un dashboard local.
- **Verificación** continua: 97 checks de salud, scanner de secrets, auditoría con hash-chain.

## En el stack

El punto de entrada diario es el arranque de sesión, que inicializa todo el pipeline de forma idempotente:

\`\`\`bash
npm run session:autostart:detached   # fire-and-forget, ~1.3s, pipeline completo en background
npx tsx src/session-autostart.ts     # alternativa bloqueante
\`\`\`

Documentación de referencia: \`AGENTS.md\` (versión slim de bajo contexto) y \`docs/stack-manual-full.md\` (manual completo con arquitectura, checks, migraciones y ADRs). El glosario canónico de terminología vive en \`docs/reference/GLOSSARY.md\`.

> Regla práctica: si una tarea solo necesita el día a día, inyecta el manual slim; carga el completo solo cuando la tarea lo requiera (migraciones, ADRs, detalle de checks).

## Cómo se organiza el repositorio

Orientación rápida para no perderse el primer día:

- \`src/\` — la orquestación: pipeline de sesión, watchtower, tokens, web, compresión, agentes.
- \`apps/web-dashboard/\` — el dashboard React/TS/Vite y el DatabaseManager de Nexus.
- \`config/\` — configuración versionada y validada por tests.
- \`docs/\` — manuales, ADRs, referencias, glosario y estado canónico.
- \`graphify-out/\`, \`.session/\`, \`.runtime/\`, \`.engram-data/\` — índice del grafo y estado/datos generados en operación.

## Puntos clave

- Gentle-Vanguard es una ==capa de orquestación== sobre herramientas de IA, no otra herramienta de IA.
- El stack completo vive en tu máquina: SQLite local, filesystem \`.session/\`, MCP local y dashboard en loopback.
- Todo lo que muestra está derivado de trazas y datos reales, nunca de datos inventados.
- El arranque de sesión es obligatorio e idempotente: inicializa memoria, grafo, presupuesto, salud y dashboard sin intervención manual.`,
    },
    {
      id: 'por-que-existe-cinco-dolores',
      title: 'Por qué existe: los 5 dolores que resuelve',
      minutes: 9,
      type: 'curso',
      md: `## El diagnóstico

Gentle-Vanguard no nació como producto de laboratorio: nació de cinco dolores concretos que sufre cualquier developer que usa agentes de IA a diario. Entenderlos es entender el diseño de todo el stack, porque **cada componente responde a uno de ellos**.

### 1. Sesiones desde cero

Cada conversación con un agente empieza amnésica: olvidó las decisiones de arquitectura, los bugs ya corregidos, las preferencias del proyecto. Resultado: tokens quemados en re-explicarlo todo.

- **Respuesta del stack**: ==Engram==, memoria semántica persistente. Observaciones con tipo y procedencia (\`bugfix\`, \`decision\`, \`architecture\`, \`pattern\`...), veredictos explícitos ante conflictos y resúmenes de sesión que la siguiente sesión puede consultar.

### 2. Calidad por suerte

Un día el agente produce código excelente, al siguiente rompe todo. Sin proceso, la calidad es una lotería del prompt.

- **Respuesta del stack**: ciclo ==SDD== (Spec-Driven Development: BA → SAD → DEV → QA) con gates en CI, normativas del orquestador, verificación con tests, y guardrails (temperatura y hallucination guard por fase, definidos en \`config/model-router.json\`).

### 3. Prompts gigantes

Pegar medio repo en el prompt "para que entienda contexto" es carísimo y frágil.

- **Respuesta del stack**: ==graphify / CodeGraph==, el índice de código construido con AST determinista. En vez de releer archivos, se consulta el grafo (\`npm run graphify -- query\`) y llega solo el contexto relevante: el mayor ahorro de tokens de la operación diaria. Lo complementa la compresión estructural con modo \`input\` lossless-only.

### 4. Costos invisibles

Nadie sabe cuántos tokens consumió ayer el orquestador vs los subagentes, ni cuánto ahorró la caché.

- **Respuesta del stack**: ==token tracking real y agnóstico==. El daemon \`src/tokens/token-ingest.ts\` lee el uso persistido por cada herramienta (opencode, zcode, codex, minimax) y lo consolida en Nexus (\`token_usage\`, \`token_transactions\`, \`token_savings\`) con presupuestos configurables.

### 5. Secretos y riesgos

Un agente con acceso a shell y archivos puede cometer una API key a git o ejecutar algo peligroso.

- **Respuesta del stack**: ==secret scanner== nativo con 80 patrones y entropy check, integrado a pre-commit (lefthook) y a la watchtower; RBAC v1 en el dashboard; auditoría con cadena de hashes; skills ofensivas restringidas a entornos autorizados.

## La tabla resumen

:::stats 97~checks de salud automáticos | 463~tests sin fallos | 21~agentes especializados | -94%~tokens con índice local:::

| Dolor | Componente que lo resuelve | Dónde vive |
| --- | --- | --- |
| Sesiones desde cero | Engram (memoria persistente) | \`.engram-data/\` + MCP |
| Calidad por suerte | SDD + guardrails + verificación | \`docs/sdd/\`, \`config/model-router.json\` |
| Prompts gigantes | graphify / CodeGraph | \`graphify-out/\` |
| Costos invisibles | Token tracking + Nexus | \`src/tokens/\`, \`.runtime/gentle-vanguard.db\` |
| Secretos y riesgos | Secret scanner + RBAC + audit | \`src/secret-scanner.ts\` |

## En el stack

Puedes verificar cada solución con un comando:

\`\`\`bash
npm run token:status        # presupuesto real usado
npm run graphify -- query "autostart"   # contexto sin leer archivos
npm run scan:secrets -- --scan .
npm run watchtower:health   # 97/97 PASS esperado
\`\`\`

> Estos cinco dolores son también el hilo conductor del resto de la Academy: cada track profundiza en un conjunto de respuestas del stack.

## Puntos clave

- Cada componente del stack existe para responder a un ==dolor concreto==, no por moda arquitectónica.
- Memoria, proceso, índices, contabilidad y seguridad son las cinco líneas maestras.
- La solución siempre es local primero: ninguno de estos dolores exige una nube para curarse.`,
    },
    {
      id: 'modelo-local-first-server-optional',
      title: 'El modelo LOCAL-FIRST / SERVER-OPTIONAL (ADR-0017)',
      minutes: 8,
      type: 'curso',
      md: `## La decisión

El 2026-08-25 se aceptó el ADR-0017: Gentle-Vanguard es oficialmente ==LOCAL-FIRST / SERVER-OPTIONAL==. La operación local es el alcance soportado por defecto y el scope primario del producto; servidor, Kubernetes, cloud y SaaS son **rutas de evolución opt-in**, nunca prerrequisitos presentados como tales.

¿Por qué importa? Porque el repositorio contiene contratos cloud, manifests de Kubernetes y gates de promoción de imágenes. Sin un ADR que ordene el relato, sería fácil creer que necesitas un cluster para operar. No lo necesitas.

## Qué funciona 100% en local

- CLI y orquestación completa (\`src/\`).
- SQLite/Nexus en \`.runtime/gentle-vanguard.db\`.
- El filesystem de sesión \`.session/\` (checkpoints, snapshots, event store, audit logs).
- Engram (memoria), CodeGraph/graphify (índices), integraciones MCP locales.
- El dashboard en ==loopback==, con sesiones deployment-scoped, principales, membresías y RBAC v1.

## Los perfiles operativos

| Perfil | Alcance | Default | Frontera de identidad y datos |
| --- | --- | --- | --- |
| local-default | Un workspace local y Nexus/SQLite local | Sí | Scope deployment-local; dashboard loopback; sin identidad empresarial |
| local-multi-tenant | Varios tenants lógicos en un deployment local | Opt-in | Registros tenant-scoped y RBAC deployment-local |
| server-promotion | Servidor o Kubernetes operado | Opt-in/futuro | Requiere inputs externos y promotion gates |
| saas-federated | Servicio hospedado/federado | Opt-in/futuro | Requiere federación explícita e identidad empresarial |

### Reglas de autenticación que derivan del modelo

1. La autenticación local es ==deployment-scoped==: sesiones, principales, roles, CSRF y eventos de auditoría pertenecen al deployment local.
2. RBAC v1 (\`viewer < operator < admin\`) se aplica a requests protegidos y mutaciones administrativas.
3. El bypass de localhost solo se permite si se habilita explícitamente y host y remote address son loopback. Nunca es un mecanismo de identidad productiva.
4. OIDC, LDAP y SSO son federación futura opt-in; la autenticación local no los implica.
5. Promoción o SaaS deben mantener autenticación fail-closed y documentar contrato externo de identidad, secrets, tenancy y auditoría antes de llamarse empresarial o federado.

## Promoción externa: gates, no prerrequisitos

Cuando un operador apunta a deployment externo, aparecen los gates: digests de imagen fijados, evidencia de firma Cosign, evidencia CNI/NetworkPolicy, evidencia de sandbox para MCP. Si faltan, son **bloqueantes de promoción**, no de operación local. En modo local los mismos checks son informativos (exit 0).

> Consecuencia práctica: la documentación separa siempre "estado verificado localmente" de "inputs operador-externos", sin inventar métricas, digests ni evidencia de seguridad.

### Consecuencias documentadas del ADR

- **Positivas**: el usuario local tiene un camino soportado sin dependencia de Kubernetes, cuenta cloud, registry, CNI, Cosign ni identidad empresarial; y las implementaciones server/cloud/SaaS existentes quedan disponibles para evolución deliberada.
- **Negativas**: manejar varios perfiles exige fronteras de documentación explícitas, y la promoción externa sigue siendo operator-led hasta que sus inputs de infraestructura e identidad existan.
- **Mitigación**: los documentos de prerrequisitos de deployment se marcan como gates externos, y el estado local se reporta en secciones separadas del estado de promoción.

## En el stack

- ADR completo: \`docs/adr/ADR-0017-local-first-operating-model.md\`.
- Estado canónico vigente: \`docs/status/CANONICAL-STATUS.md\` (versión de paquete y modelo operativo oficial).
- Glosario: entrada "Local-First / Server-Optional" en \`docs/reference/GLOSSARY.md\`.

\`\`\`bash
npm run watchtower:health   # todo verde sin nube, sin registry, sin identidad empresarial
\`\`\`

## Puntos clave

- Local es el default soportado; ==server/cloud/SaaS son opt-in== y no se eliminan ni se activan silenciosamente.
- Cuatro perfiles con fronteras distintas de identidad y datos.
- Los gates de promoción bloquean solo el deployment externo, jamás el uso local.
- La autenticación local es honesta: RBAC v1 deployment-scoped, sin reclamar OIDC/LDAP/SSO.`,
    },
    {
      id: 'conceptos-base-ia',
      title: 'Conceptos base de IA que necesitas',
      minutes: 10,
      type: 'curso',
      md: `## El vocabulario mínimo

Para operar el stack con criterio no necesitas un doctorado en ML: necesitas dominar seis conceptos que aparecen en cada comando, alerta y reporte.

### LLM (Large Language Model)

Un modelo de lenguaje que predice texto token a token. No "sabe" tu repo: solo ve lo que entra en su contexto. Toda la ingeniería del stack gira en torno a **qué** le entra y **cuánto** cuesta que le entre.

### Tokens

La unidad de facturación y de contexto. Un token es aproximadamente un fragmento de palabra. El stack contabiliza tokens reales en tres niveles:

- \`token_usage\`: por sesión.
- \`token_transactions\`: por mensaje, con agente orquestador o subagente, modelo, costo y detalles como cache y reasoning.
- \`token_savings\`: ahorros por cache reads y compresión.

### Contexto y ventana

La ==ventana de contexto== es el máximo de tokens que el modelo puede "ver" a la vez. El contexto es un recurso escaso y caro: si lo llenas con archivos completos, no cabe el razonamiento. De ahí graphify (dar contexto quirúrgico) y la compresión estructural (mandar menos).

### Temperatura

Parámetro que controla la aleatoriedad de la salida. Temperatura baja: salidas más deterministas, adecuadas para generar código y especificaciones. Temperatura alta: más creatividad, más riesgo de alucinación. En el stack, los perfiles de \`config/model-router.json\` definen temperature y ==hallucinationGuard== **por fase SDD** (BA/SAD/DEV/QA), porque no se necesita la misma disciplina para explorar requisitos que para escribir código.

### Prompting

El arte de construir la entrada. Aquí el stack lo convierte en ingeniería: \`AGENTS.md\` slim para inyección diaria de contexto, skills con triggers declarativos, y normativas del orquestador. El prompt deja de ser un texto artesanal y pasa a ser un activo versionado.

### Reasoning y caché

Dos matices que aparecen en los reportes: los modelos de razonamiento gastan ==reasoning tokens== (pensamiento intermedio facturado), y la caché de prompts hace que repetir contexto cueste menos. Por eso \`token_transactions\` desglosa reasoning y cache por mensaje, y \`token_savings\` acumula el ahorro por cache reads y compresión: sin ese desglose, comparar dos sesiones es comparar peras con manzanas.

### Agentes vs chat

| Aspecto | Chat | Agente |
| --- | --- | --- |
| Ciclo | Pregunta → respuesta | Objetivo → plan → herramientas → verificación |
| Herramientas | Ninguna o pocas | Shell, archivos, web, MCP, delegación |
| Autonomía | Turno único | Multi-paso con contexto persistente |
| Riesgo | Bajo | Requiere guardrails y auditoría |

Un ==agente de código== puede leer tu repo, ejecutar comandos y escribir archivos. Por eso el stack le pone límites: presupuestos de tokens, steps adaptativos con máximo, RBAC, scanner de secrets y trazas de cada acción.

## Cómo se conecta con el stack

Cada concepto tiene reflejo operativo:

\`\`\`bash
npm run token:status   # ventana y presupuesto: usado / presupuesto / %
npm run profile:list   # perfiles con temperature por fase
npx tsx src/adaptive-steps.ts --status   # límites de autonomía por agente
\`\`\`

> Regla mental: el modelo es el motor; el contexto es el combustible; el token es la moneda. El trabajo del stack es gastar menos moneda por el mismo kilometraje.

## Puntos clave

- Token = unidad de costo y de contexto; se contabiliza real, no estimado.
- La ventana de contexto es el recurso escaso que todo el stack optimiza.
- La temperatura se gestiona por fase SDD, no a mano por prompt.
- Agente ≠ chat: autonomía multi-paso que exige guardrails, presupuesto y auditoría.`,
    },
    {
      id: 'agentes-y-orquestadores',
      title: 'Qué es un agente de código y un orquestador',
      minutes: 9,
      type: 'curso',
      md: `## Agente de código

Un ==agente de código== es un programa con un LLM en su núcleo que persigue un objetivo usando **herramientas**: ejecutar comandos, leer y escribir archivos, buscar en la web, invocar servidores MCP. A diferencia de un chat, mantiene estado entre pasos y decide el siguiente movimiento según el resultado del anterior.

Un agente típico del stack tiene: una identidad (nombre, rol), un presupuesto de ==steps== (pasos máximos), un conjunto de herramientas permitidas y reglas (normativas, skills) que acotan su comportamiento.

## Orquestador y multi-agente

Cuando la tarea es grande, un solo agente se queda corto. La solución es el patrón **orquestador + subagentes**: un agente principal descompone el trabajo y delega piezas a especialistas.

El stack define **21 subagentes** sincronizados a las herramientas vía \`npx tsx src/zcode-sync.ts --sync\`. Algunos representativos:

| Agente | Rol | Steps base |
| --- | --- | --- |
| orchestrator | Coordinación del flujo SDD | 24 |
| sdd-explore | Investigación | 38 |
| sdd-design | Diseño | 30 |
| sdd-apply | Implementación (código) | 52 |
| sdd-verify | Testing/verificación | 36 |
| gov-agent | Seguridad y compliance | 38 |
| doc-agent | Documentación | 34 |

### Herramientas y MCP

==MCP== (Model Context Protocol) es el protocolo estándar con el que los modelos se conectan a herramientas y servicios externos. En el stack, los servidores MCP locales exponen capacidades críticas: **engram** (memoria), **codegraph** (grafo de código), **filesystem**, **memory**, **chrome-devtools**. La configuración vive en \`.zcode/config.json\` bajo \`mcp.servers\`.

### Delegación con aprendizaje

La delegación no es estática: \`src/route-and-delegate.ts\` recomienda el agente adecuado para una petición y delega aplicando el tiering de \`config/model-router.json\`:

\`\`\`bash
npm run delegate:run -- --task "audit gdpr compliance"
npx tsx src/recommend-agent.ts --task "code review" --topn 3
\`\`\`

La tabla de routing (\`.session/routing/routing-table.json\`, 17 dominios + overrides) aprende de cada ejecución registrando éxito/fracaso, y en su versión actual registra outcomes por tenant en Nexus (\`routing_rules\` con \`success_count\` y \`success_rate\`).

### Steps adaptativos

Cada agente tiene un presupuesto de pasos que el sistema auto-escala por complejidad (señales del texto, cantidad de archivos, historial). Si un agente reporta "maximum steps reached", el orquestador lo **re-asigna automáticamente con +20 steps** (máximo 80) preservando contexto:

\`\`\`bash
npx tsx src/adaptive-steps.ts --estimate "refactor 20 files"
npx tsx src/adaptive-steps.ts --resume sdd-apply --task_id ses_xxx
\`\`\`

## Guardrails

Autonomía sin límites es riesgo. Los guardrails del stack:

- **Presupuestos**: steps máximos y budget guard de tokens (daily 5M, perSession 3M).
- **Normativas**: reglas del orquestador y autorizaciones globales versionadas en \`docs/governance/\`.
- **Verificación**: cada fase SDD termina en gates; los PRs a ramas protegidas requieren SDD validado (\`sdd-gate\`).
- **Trazabilidad**: cada delegación y tool call queda en trazas y transacciones de tokens.

## En el stack

- Agentes y skills se sincronizan a las 3 herramientas con \`npx tsx src/zcode-sync.ts --sync\` (re-ejecutar tras editar \`.opencode/agents/\`).
- La topología completa (memoria → skills → MCP → comandos → agentes) está en \`docs/architecture/layer-topology.md\`.
- Arquitectura de subagentes: \`docs/reference/SUBAGENT-ARCHITECTURE.md\`.

## Puntos clave

- Agente = LLM + herramientas + presupuesto; orquestador = el que descompone y delega.
- ==MCP== es el pegamento estándar entre modelos y herramientas.
- Los steps adaptativos y el auto-reassignment evitan agentes agotados a mitad de tarea.
- La autonomía siempre está acotada por guardrails: budgets, normativas, verificación y trazabilidad.`,
    },
    {
      id: 'mision-vision-alcance',
      title: 'Misión, visión y alcance del stack y del microemprendimiento',
      minutes: 7,
      type: 'curso',
      md: `## Misión del stack

La misión de Gentle-Vanguard se resume en una frase: **hacer que trabajar con IA sea ingeniería, no suerte**. Eso significa convertir la relación con los agentes de código en un proceso con memoria, medición, verificación y seguridad, operable por una sola persona en su propia máquina.

Todo el diseño sirve a esa misión:

- ==Memoria== para no repetir decisiones (Engram).
- ==Medición== honesta de uso y costo (token tracking sobre Nexus).
- ==Verificación== continua de salud y calidad (watchtower, SDD, tests).
- ==Seguridad== por defecto (scanner, RBAC, auditoría hash-chain).

## Visión

La visión es un stack **agnóstico por capas**: poder cambiar de agente, de SO, de herramienta o de lenguaje sin reescribir la orquestación. La topología de 5 capas (memoria, skills, MCP, comandos, agentes) formaliza esa promesa: cada capa define una interfaz, no una implementación. A futuro, las rutas de promoción externa (servidor, Kubernetes, SaaS federado) permiten crecer hacia operación multi-equipo **sin traicionar el default local**, tal como fija el ADR-0017.

## Alcance del stack

Lo que el stack **es** hoy:

- Una capa de orquestación local-first con pipeline de sesión automático.
- Un ecosistema de agentes, skills y comandos sincronizado entre herramientas.
- Un sistema de observabilidad y datos operacionales real (Nexus + dashboard).

Lo que **no pretende** ser:

- Un reemplazo de las herramientas de IA, sino su capa de gobierno.
- Un servicio hospedado obligatorio (server/SaaS son opt-in).
- Una solución mágica: cada afirmación del stack debe estar respaldada por datos verificados.

## El microemprendimiento

Gentle-Vanguard también es un ==microemprendimiento== con dos piernas, y la Academy tiene un track completo dedicado al negocio (\`negocio\`). El modelo:

- **Producto propio**: el stack mismo — la capa de orquestación, sus agentes y skills, empaquetados y documentados para reutilización y evolución continua.
- **Servicios**: la aplicación del stack a casos reales — auditorías, reviews, implementación asistida, optimización de costos de IA, compliance. El stack actúa como multiplicador: convierte experiencia manual en proceso repetible y auditable.

### Por qué este modelo encaja

1. El stack local-first elimina la fricción de infraestructura: no hay hosting que mantener para operar.
2. Cada servicio prestado retroalimenta al producto (nuevas skills, normativas, checks).
3. La documentación canónica (ADRs, glosario, manuales) hace el trabajo presentable y defendible ante clientes.

> Honestidad de posicionamiento: el repositorio distingue siempre lo verificado localmente de los inputs externos de promoción. Esa misma honestidad es la promesa comercial: sin cifras inventadas, sin seguridad de papel.

### Cómo se mide el éxito

Nada de métricas de vanidad: el éxito operativo del stack se verifica con comandos concretos — salud 97/97 en la watchtower, presupuesto de tokens dentro de los límites configurados, ahorro acumulado por caché y compresión visible en \`token_savings\`, gates SDD en verde en CI. Si una métrica no se puede ejecutar, no cuenta.

## En el stack

- Modelo operativo: ADR-0017 y \`docs/status/CANONICAL-STATUS.md\`.
- Mapa de documentación (por dónde empezar a leer): \`docs/README.md\` y \`docs/getting-started/README.md\`.
- Visión de producto y rutas: \`docs/stack-manual-full.md\`.

## Puntos clave

- Misión: que la IA trabaje **con ingeniería** — memoria, medición, verificación, seguridad.
- Visión: agnosticismo por capas + evolución opt-in hacia servidor/SaaS.
- El negocio combina ==producto propio== (el stack) y ==servicios== (aplicarlo a casos reales).
- La honestidad técnica (nada inventado, todo verificado) es también la propuesta de valor.`,
    },
    {
      id: 'compatibilidad-herramientas',
      title: 'Compatibilidad y herramientas soportadas',
      minutes: 8,
      type: 'curso',
      md: `## Filosofía: agnóstico por diseño

Gentle-Vanguard no te pide abandonar tu herramienta favorita. El stack se **sincroniza hacia** las herramientas: los mismos agentes, skills y comandos se replican donde ya trabajas. La topología de capas (\`docs/architecture/layer-topology.md\`) lo garantiza: memoria, skills, MCP, comandos y agentes definen interfaces, no implementaciones atadas a un vendor.

## Las herramientas

| Herramienta | Qué recibe del stack | Mecanismo |
| --- | --- | --- |
| OpenCode | Agentes + skills + normativas | Config nativa \`.opencode/\` |
| ZCode | Agentes + skills críticas + comandos + hooks | \`zcode-sync.ts --sync\`, \`.zcode/\` |
| Codex | Skills críticas + AGENTS.md | \`~/.codex/skills/\`, lectura nativa de AGENTS.md |
| MiniMax | Skills críticas (pi-agent) | \`~/.minimax/agents/mavis/skills/\` |
| Cursor | Rules y configs de herramienta | \`cursorrules\` (checks de tool-configs) |
| Claude Code | Skills compatibles | Estructura \`.claude/skills/\` |

### El sincronizador

\`\`\`bash
npx tsx src/zcode-sync.ts --sync              # sincroniza 21 agentes + skills críticas
npx tsx src/zcode-sync.ts --sync --tools zcode,codex,minimax   # filtrar destinos
\`\`\`

Dos reglas importantes:

- Re-ejecutar el sync **tras editar** \`.opencode/agents/\` o skills compartidas.
- ==NO copiar todas las skills== (~120): solo las 12 críticas. ZCode degrada el auto-trigger de skills si se excede su presupuesto de metadata.

### AGENTS.md como estándar

Codex y MiniMax leen \`AGENTS.md\` nativamente (es el estándar emergente de instrucciones de agentes). Por eso el manual slim existe: bajo contexto para inyección diaria, con el manual completo (\`docs/stack-manual-full.md\`) reservado para tareas que lo requieran.

### Tokens: las 4 fuentes

El tracking es agnóstico porque lee lo que **cada herramienta ya persiste** en disco:

- **opencode**: SQLite en \`~/.local/share/opencode/opencode.db\` (tablas \`session\`, \`message\`).
- **zcode**: rollouts JSONL bajo \`~/.zcode/\`.
- **codex**: sesciones bajo \`~/.codex/sessions/\`.
- **minimax**: \`~/.minimax/v2/sqlite/runtime-state.sqlite\` (tabla \`local_runtime_token_usage\`).

### Cambios requieren nueva sesión

No hay hot-reload: un cambio de agentes, skills, comandos o hooks solo aplica tras abrir una nueva sesión en cada herramienta.

### MCP y hooks compartidos

Más allá de archivos, el stack comparte **infraestructura viva** entre herramientas:

- Los servidores ==MCP== (codegraph, engram, chrome-devtools, filesystem, memory) se configuran en \`.zcode/config.json\` bajo \`mcp.servers\` y sirven a cualquier cliente MCP.
- Los ==hooks de ZCode== viven en \`~/.zcode/cli/config.json\`: SessionStart ejecuta el autostart (con guard por repo) y PostToolUse sobre Write/Edit ejecuta la actualización del grafo; los scripts están en \`src/zcode-hooks/\`.
- Los comandos de barra (\`/graphify\`, \`/token-status\`, \`/db-health\`, \`/watchtower\`, \`/delegate\`, \`/web-research\`) empaquetan los flujos frecuentes.

## En el stack

La watchtower verifica la compatibilidad en su ciclo de salud con el componente **tool-configs** (clinerules, cursorrules, continue config) entre los 21 componentes monitoreados:

\`\`\`bash
npm run watchtower:health   # incluye tool-configs y MCP bridge
\`\`\`

La sincronización es verificable, no un acto de fe: la watchtower chequea tool-configs y la salud del bridge MCP en cada ciclo, y el comando de sync reporta qué se copió a cada destino. Si una herramienta dejó de ver un agente o una skill, la primera sospecha es siempre la misma: ==¿se re-ejecutó el sync después del último cambio en \`.opencode/\`?==

Comandos ZCode propios (\`.zcode/commands/\`): \`/graphify\`, \`/token-status\`, \`/db-health\`, \`/watchtower\`, \`/delegate\`, \`/web-research\`.

## Puntos clave

- El stack se ==sincroniza hacia las herramientas==, no las reemplaza.
- 21 agentes y 12 skills críticas via \`zcode-sync.ts --sync\`; menos es más (presupuesto de metadata).
- \`AGENTS.md\` es el contrato de instrucciones multi-tool; las 4 fuentes de tokens hacen el tracking agnóstico.
- Los cambios de configuración requieren nueva sesión: planifica tus ediciones.`,
    },
    {
      id: 'primer-contacto-comandos',
      title: 'Primer contacto: comandos esenciales',
      minutes: 9,
      type: 'curso',
      md: `## Tu primer cuarto de hora

Esta lección es un recorrido guiado por los comandos que usarás todas las semanas. Ejecútalo en orden sobre un clon del repositorio y habrás tocado cada subsystem clave del stack.

### Paso 1 — Arrancar la sesión

\`\`\`bash
npm run session:autostart:detached
\`\`\`

Inicializa el pipeline completo en background (~1.3s de espera): session ID, engram, security orchestrator, codegraph, token budget, watchtower auto-heal, dashboard WS y Nexus (lazy steps). Es ==idempotente==: puedes correrlo mil veces. El log queda en \`.runtime/autostart-detached-*.log\`.

### Paso 2 — Verificar la salud

\`\`\`bash
npm run watchtower:health
\`\`\`

Resultado esperado: ==97/97 PASS== sobre 21 componentes (dashboard-ws, codegraph, engram, mcp, session, hooks, configs, security, secret-scanner, cli-guard...). Si algo falla, el modo autoheal intenta restaurarlo:

\`\`\`bash
npx tsx src/core/maintenance-watchtower.ts -Action autoheal
\`\`\`

### Paso 3 — Preguntarle al grafo

Antes de leer archivos a mano, pregunta al índice de código:

\`\`\`bash
npm run graphify -- query "cómo se calcula el presupuesto de tokens"
npm run graphify -- explain <node_id>
\`\`\`

Si es la primera vez y falta \`graphify-out/graph.json\`, construye primero con \`npm run graphify -- build\` (segundos, nativo, sin LLM).

### Paso 4 — Ver los números

\`\`\`bash
npm run token:status    # presupuesto real: usado / presupuesto / %
npm run db:health       # integridad de Nexus, WAL, tablas, filas
\`\`\`

### Paso 5 — Abrir el dashboard

\`\`\`bash
npx tsx src/dashboard-start.ts    # WS + Vite + Chrome
npx tsx src/dashboard-stop.ts     # parada limpia (mata watchdog primero)
\`\`\`

Puerto dinámico asignado por \`Get-FreePort()\` y persistido en \`.runtime/dashboard-ports.json\`.

### Paso 6 — Buscar riesgos

\`\`\`bash
npm run scan:secrets -- --scan .
\`\`\`

80 patrones (AWS, GCP, Azure, GitHub, OpenAI, Slack, Stripe, JWT, private keys...), entropy opcional y redacción por defecto. Exit code 1 = secrets encontrados.

### Paso 7 — Respalda antes de experimentar

\`\`\`bash
npm run db:backup     # backup online de Nexus a .runtime/backups/
npm run db:list       # ver qué backups tienes
\`\`\`

Los checkpoints y snapshots del pipeline (\`.session/checkpoints/\`, \`.session/snapshots/\`) cumplen el mismo rol para el estado de sesión: antes de un cambio grande, hay a qué volver.

## Mapa de comandos de la semana

| Necesidad | Comando |
| --- | --- |
| Estado de agentes/steps | \`npx tsx src/adaptive-steps.ts --status\` |
| Recomendar agente | \`npx tsx src/recommend-agent.ts --task "..." --topn 3\` |
| Delegar tarea | \`npm run delegate:run -- --task "..." \` |
| Research web curada | \`npm run web:select -- --query "..."\` |
| Perfiles de modelo | \`npm run profile:list\` / \`profile:apply\` |
| Backup de Nexus | \`npm run db:backup\` |

Un último mapa útil: el directorio \`.runtime/\` es tu panel trasero — ahí viven los logs del autostart detached (con poda automática a 7 días), \`dashboard-ports.json\` con los puertos elegidos, \`dashboard-ws.log\` con el heartbeat del watchdog y \`backups/\` con los respaldos de Nexus. Cuando algo no arranca, la respuesta casi siempre ya está escrita en un log de \`.runtime/\`.

## Errores de novato frecuentes

- Correr el autostart bloqueante cuando un hook/CI no debe colgarse: usa siempre el ==detached== en shells de agente.
- Instalar el paquete npm \`graphify@1.0.0\`: no tiene relación; el CLI local es \`npm run graphify --\`.
- Editar \`config/model-routing.json\`: fue consolidado en \`config/model-router.json\`.
- Esperar hot-reload tras cambiar agentes/skills: abre nueva sesión.

## Puntos clave

- El flujo diario mínimo es: ==autostart → watchtower → graphify query → dashboard==.
- Todo comando crítico tiene versión TS nativa; los \`npm run\` apuntan solo a esas versiones.
- La salud 97/97 es la línea base de "todo funciona"; cualquier WARN merece autoheal.
- Los gotchas documentados (graphify npm, config consolidada, detached) te ahorrarán horas.`,
    },
    {
      id: 'configuraciones-y-perfiles',
      title: 'Configuraciones y perfiles',
      minutes: 8,
      type: 'curso',
      md: `## Una fuente de verdad por dominio

El stack evita la configuración dispersa: cada dominio tiene su archivo canónico en \`config/\`, validado por tests (\`npm run test:config\`) y monitoreado por la watchtower (componente **configs**, con validación de esquemas JSON).

| Archivo | Domina |
| --- | --- |
| \`config/model-router.json\` | Routing policy, cost tracking, model levels y ==perfiles== |
| \`config/token-budget-guard.json\` | Presupuestos de tokens (daily 5M, perSession 3M) |
| \`config/session-autostart.config.json\` | Steps del pipeline de sesión (lazy incluidos) |
| \`config/dashboard-alerts.json\` | 8 reglas de alertas del dashboard |
| \`config/subagent-mapping.json\` | Mapeo de skills absorbidas por rol de agente |
| \`config/secret-scanner.json\` | Patrones y opciones del scanner |
| \`config/structural-compression.json\` | Estrategias de compresión |
| \`config/web-crawler.json\` | Proveedores y fallback del crawler |

> Historia que evita errores: \`config/model-routing.json\` fue **eliminado** y consolidado en \`model-router.json\`; 15 referencias fueron actualizadas en la codebase. Si ves la ruta vieja en un doc antiguo, desconfía.

## Perfiles cheap / balanced / premium

La convención absorbida de gentle-ai define tres perfiles en la sección \`profiles\` de \`config/model-router.json\`. Cada perfil asigna **temperature + hallucinationGuard por fase SDD** (BA/SAD/DEV/QA): explorar requisitos no exige la misma disciplina que emitir código.

\`\`\`bash
npm run profile:list            # listar perfiles
npm run profile:status          # perfil activo
npm run profile:set -- premium  # dry-run
npm run profile:apply -- premium # aplicar y persistir
\`\`\`

Cuándo usar cada uno:

- ==cheap==: tareas mecánicas o de bajo riesgo donde el costo manda.
- ==balanced==: default del día a día.
- ==premium==: fases donde el error es caro (diseño, código crítico).

## config-loader

La carga de configuración no se duplica en cada script: \`src/core/config-loader.ts\` centraliza la lectura y resolución. El patrón del workspace histórico (\`workspace.config.json\` con placeholders como \`{workspaceRoot}\` resueltos en runtime) evolucionó hacia este loader central; los scripts importan configuración validada, no parsean JSON a mano.

### Jerarquía de decisión efectiva

Cuando el orquestador asigna steps a una delegación, la prioridad es:

1. Routing table aprendida (\`.session/routing/routing-table.json\`) si hay historial.
2. Estimación por tarea (\`adaptive-steps.ts --auto\`).
3. Defaults de \`opencode.json\` (fallback).

Y la temperatura que se inyecta al delegar (\`AGENT_TEMPERATURE\`) viene del **tier del dominio** en \`model-router.json\`.

### Resolución de placeholders

El modelo histórico del workspace ilustra el patrón que sobrevive en el loader: \`workspace.config.json\` define raíces con placeholders como \`{workspaceRoot}\`, y en runtime se resuelven contra un contexto (\`dataRoot\`, \`toolsRoot\`, \`projectsRoot\`) antes de aplicar las configs de cada skill. Resultado: la misma configuración funciona en cualquier máquina sin rutas absolutas quemadas — el mismo principio agnóstico de la topología de capas, aplicado a la configuración.

## En el stack

- Validación: \`npm run test:config\` (6 tests) corre en CI junto a workflows y research.
- La watchtower valida los esquemas JSON de 5 configs críticas en cada ciclo.
- Cambiar presupuesto: edita \`config/token-budget-guard.json\`; verificar con \`npm run token:status\`.

\`\`\`bash
npm run test:config      # valida configuraciones
npm run profile:status   # qué perfil está activo ahora
\`\`\`

## Puntos clave

- Un archivo canónico por dominio; la configuración está ==versionada, testeada y monitoreada==.
- Los perfiles cheap/balanced/premium ajustan temperature y guard por ==fase SDD==, no a mano.
- \`config/model-router.json\` es la fuente consolidada (la ruta \`model-routing.json\` está muerta).
- Cambios de config se verifican con \`test:config\` y watchtower antes de confiar en ellos.`,
    },
    {
      id: 'capacidades-y-limitaciones',
      title: 'Capacidades y limitaciones honestas',
      minutes: 8,
      type: 'curso',
      md: `## Por qué esta lección existe

Un stack que solo promete es una demo. Gentle-Vanguard mantiene una disciplina de honestidad: distinguir siempre lo ==verificado localmente== de lo experimental, y jamás presentar inputs externos de promoción como logros locales. Esta lección es el mapa realista de qué puedes esperar.

## Lo que hace bien hoy

- **Pipeline de sesión robusto**: arranque idempotente, steps lazy no bloqueantes (\`onStepFailure: continue\`), logs con retención de 7 días. La operación diaria no depende de que todo esté perfecto.
- **Salud verificada**: la watchtower ejecuta ==97 checks sobre 21 componentes== en 6 modos, con auto-healing integrado al inicio de sesión.
- **Datos reales, cero mock**: el dashboard y Nexus derivan todo de trazas y uso persistido por las herramientas. Cada cifra es reproducible.
- **Índice de código determinista**: graphify construye el grafo con AST puro (sin LLM, sin red), en segundos; los mismos archivos producen el mismo grafo.
- **Seguridad práctica**: scanner de 80 patrones en pre-commit y watchtower, RBAC v1 en el dashboard, auditoría con cadena SHA-256 verificable.
- **CI disciplinada**: 6 jobs en \`ci.yml\` (lint-typecheck, test, dashboard-tests, dashboard-build, security-scan, workflow-lint) más security con gitleaks, secretlint y trivy.

## Lo que es alpha, opt-in o futuro

- **Cloud connectors**: routing por costo/latencia, circuit breaker y hybrid executor existen, pero son ==opt-in para promoción externa==, no parte del path local soportado (ADR-0017).
- **Promoción server/SaaS**: los gates (digests, Cosign, CNI, sandbox evidence, identidad empresarial) esperan inputs del operador. No hay deployment externo verificado por defecto.
- **Labeling de comunidades**: el etiquetado del grafo usa el free tier de Gemini (20 requests/día); un 429 obliga a esperar reset o configurar API key paga.
- **Sagas y rollback**: implementados (\`src/saga-orchestrator.ts\`, \`src/rollback-orchestrator.ts\`) pero de activación manual, no automáticos.
- **Paths limitados en graphify**: \`path\`/\`affected\` solo siguen edges \`contains\`/\`calls\`; rutas cross-file raras sin extracción semántica de pago.
- **Tests**: las suites principales son las de config, workflows y research; la cobertura unitaria es creciente pero no exhaustiva.

## Lo que NO hace

- No reemplaza tu juicio: el orquestador propone, el humano decide en las fases donde las normativas lo exigen.
- No garantiza calidad solo por correr: el ciclo SDD requiere que los gates se respeten.
- No reclama identidad empresarial: la autenticación local es deployment-scoped, sin OIDC/LDAP/SSO.

## En el stack

\`\`\`bash
npm run watchtower:health   # estado verificado ahora mismo
cd apps/web-dashboard && npm run build   # debe salir 0 sin errores TS
node -e "console.log('verifica siempre antes de creer')"
\`\`\`

Fuentes de estado: \`docs/status/CANONICAL-STATUS.md\` (versión vigente del paquete) y los reportes fechados que el propio stack genera — recuerda que un reporte histórico describe el estado del día en que se escribió.

> La regla de oro documental: los documentos fechados no se reescriben; si el presente cambió, se emite uno nuevo. Por eso el estado canónico vive en un archivo aparte.

## Puntos clave

- Capacidades nucleares ==verificadas==: pipeline, salud 97/97, datos reales, grafo determinista, seguridad base, CI.
- Capacidades ==opt-in/experimentales==: cloud, promoción externa, labeling con quota, sagas manuales.
- La honestidad no es modestia: es el requisito para que las cifras del stack signifiquen algo.
- Antes de asumir que algo funciona, ejecuta el comando que lo verifica.`,
    },
  ],
};
