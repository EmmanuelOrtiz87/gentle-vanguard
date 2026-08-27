/* Gentle-Vanguard Academy — Track "workflows" (11 lecciones).
   Contenido educativo derivado de: AGENTS.md, docs/stack-manual-full.md,
   rules/NORMATIVAS-*.md, docs/guides/ (TESTING-GUIDE, AUDIT-WORKFLOW,
   OPERATION-GUIDE, TROUBLESHOOTING-RUNBOOK), docs/reference/GLOSSARY.md. */

window.GV_CONTENT = window.GV_CONTENT || {};

window.GV_CONTENT['workflows'] = {
  lessons: [
    {
      id: 'sdd-ciclo-end-to-end',
      title: 'El ciclo SDD end-to-end: BA → SAD → DEV → QA',
      minutes: 14,
      type: 'curso',
      md: `## Qué es y para qué sirve

==Spec-Driven Development (SDD)== es el flujo de trabajo central del stack: antes de escribir código, se escribe y valida una especificación. El objetivo no es burocracia, sino evitar el patrón más caro del desarrollo con IA: generar código sin contrato, descubrir tarde que resuelve el problema equivocado y pagar el re-trabajo en tokens y en tiempo.

El ciclo asigna **roles** y **fases con gates**. Los roles son los cuatro sombreros del pipeline:

- **BA** (Business Analyst): convierte la petición cruda en requisitos explorados y estructurados.
- **SAD** (Software Architecture Designer): convierte requisitos en diseño, decisiones y tareas concretas.
- **DEV**: implementa las tareas (el subagente \`sdd-apply\` tiene el presupuesto de steps más alto del stack, 52, porque escribir código es la fase más costosa).
- **QA**: verifica que lo implementado cumple el contrato (\`sdd-verify\`, 36 steps).

Las fases del pipeline SDD son: \`INIT → EXPLORE → PROPOSE → SPEC → TASKS → DESIGN → APPLY → VERIFY → ARCHIVE\`.

## Cómo funciona

:::diagram sdd-cycle:::

1. **INIT** — se crea el caso SDD con nombre de feature obligatorio (alfanumérico, sin espacios). Sin nombre no hay caso.
2. **EXPLORE / PROPOSE** — el rol BA explora el repositorio y propone alcance; aquí es donde graphify y CodeGraph ahorran la mayor parte del contexto.
3. **SPEC / TASKS** — la propuesta se congela como especificación y se descompone en tareas ejecutables.
4. **DESIGN** — el rol SAD produce el diseño técnico; es fase de ==modelo premium== en el router (diseñar barato sale caro después).
5. **APPLY** — el rol DEV ejecuta las tareas con verificación continua.
6. **VERIFY** — el rol QA valida contratos, corre tests y registra resultados.
7. **ARCHIVE** — el caso se cierra y su aprendizaje queda disponible.

Cada transición de fase produce un artefacto \`gate-<fase>.json\` con estado **PASS/FAIL**. Un FAIL no se ignora: se corrige o se vuelve a la fase anterior. Antes de ejecutar algo con efectos reales existe modo **DryRun**, y el directorio \`.sdd/\` vive en \`.gitignore\`: los artefactos de trabajo no se commitean.

## En el stack

- La normativa que gobierna el pipeline es \`rules/NORMATIVAS-WORKFLOW.md\` (sección SDD Pipeline, fuente NORMATIVA-SDD-PIPELINE).
- En CI, los **PRs a ramas protegidas requieren un SDD validado o done**: es el ==sdd-gate==. Sin gate verde no hay merge.
- Los resultados de validación de contratos SDD se persisten en Nexus, tabla \`contract_results\`.
- Los perfiles de modelo por fase (\`config/model-router.json\`, perfiles \`cheap/balanced/premium\`) definen temperature y \`hallucinationGuard\` distintos para BA/SAD/DEV/QA: explorar tolera más creatividad, verificar exige rigor.
- La skill \`sdd-lifecycle\` expone el ciclo completo (\`sdd init/explore/propose/spec/design/tasks/apply/verify/archive\`).

## En la práctica

Cuando delegues una tarea al stack, deja que el ciclo haga su trabajo: no saltes de la petición directa a APPLY. El gate de SPEC es el punto más barato para detectar un malentendido; el gate de VERIFY es el último. Un cambio de alcance detectado en SPEC cuesta una edición de documento; detectado en VERIFY cuesta re-generar código, re-testear y re-revisar.

## Puntos clave

- SDD = especificación antes de código, con gates automáticos entre fases.
- Cuatro roles (BA → SAD → DEV → QA) mapeados a fases con artefactos \`gate-*.json\` PASS/FAIL.
- DryRun antes de ejecución real; \`.sdd/\` nunca se commitea.
- El sdd-gate bloquea PRs a ramas protegidas sin SDD validado.
- Los perfiles de modelo por fase alinean costo y rigor: premium para diseñar y verificar, económico para rutina.`,
    },
    {
      id: 'rdd-receipts-y-4r',
      title: 'RDD y la revisión 4R: riesgo, recibos y cuatro lentes',
      minutes: 13,
      type: 'curso',
      md: `## Qué es y para qué sirve

==RDD (Receipt-Driven Development)== es el protocolo nativo de revisión y entrega del stack (implementación 100% local en \`src/rdd/\`, sin dependencia de herramientas externas). Su premisa: **cada cambio que se entrega debe estar respaldado por un recibo (receipt) verificable, no por una narración**. La filosofía de los gates lo resume: ==confía en el recibo, no en la narración==.

RDD resuelve dos dolores clásicos del desarrollo con IA:

- **Revisar todo igual** desperdicia tokens en cambios triviales y aun así revisa poco los peligrosos.
- **Aprobar por confianza** ("el agente dijo que pasó los tests") no deja evidencia auditable de qué se revisó y qué se aprobó.

## Cómo funciona: las 4 etapas

1. **Clasificación de riesgo basada en evidencia** (\`src/rdd/risk-classifier.ts\`): el cambio se puntúa 0-100 según lo que TOCA, no según su tamaño. Categorías con evidencia explícita: código de autenticación/seguridad, esquema de base de datos o migraciones, integraciones con APIs externas, y mensajes de commit que indican breaking changes. Regla clave: ==ni líneas ni número de archivos importan; importa qué archivos son==.
2. **Orquestación de revisión por tier**: el tier decide cuántas lentes se aplican.
3. **Emisión de recibo ligado a Git SHA** (\`src/rdd/rdd-core.ts\`): el candidato se ==congela== al iniciar la revisión (anti scope-drift); el recibo referencia ese SHA exacto. Si el contenido cambia, el recibo deja de validar.
4. **Validación en 5 gates de entrega** (\`src/rdd/rdd-gates.ts\`), todos contra el mismo recibo: post-apply, pre-commit, pre-push, pre-pr y release.

## Los tiers de revisión

| Tier | Riesgo | Lentes | Qué significa |
|---|---|---|---|
| 0 | low | 0 | Readback estructural: nadie revisa, el sistema confirma que el cambio es lo que dice ser |
| 1 | standard | 1 | Una lente enfocada en el aspecto que la evidencia señaló |
| 2 | high | 4 | Revisión 4R completa: las cuatro lentes |

## Las 4 R: las cuatro lentes de la revisión de alto riesgo

- **RISK** — Seguridad y comportamiento peligroso: inyecciones, secretos, permisos, datos sensibles, operaciones irreversibles.
- **READABILITY** — Claridad y mantenibilidad: ¿un ingeniero nuevo entiende esto en 6 meses? Nombres, complejidad, comentarios que explican el porqué.
- **RELIABILITY** — Correctitud y casos borde: ¿qué pasa con input vacío, concurrencia, timeout, retry? ¿Los tests cubren el camino que falla, no el que funciona?
- **RESILIENCE** — Modos de fallo y recuperación: si esto falla en producción, ¿degrada o explota? ¿Hay rollback, retry, circuit breaker?

Cada lente produce findings con severidad explícita (\`critical | required | nit | optional | info\`), archivo y línea. Un \`critical\` bloquea la aprobación; un \`nit\` no. La separación de severidades evita la muerte por mil nits.

## Kill switch: la válvula de emergencia

\`src/rdd/rdd-kill-switch.ts\` permite desactivar RDD en una emergencia (hotfix a las 3 AM):

\`\`\`bash
npx tsx src/rdd/rdd-kill-switch.ts disable --reason="Emergency hotfix"
npx tsx src/rdd/rdd-kill-switch.ts status
\`\`\`

Con garantías: requiere ==motivo explícito==, registra un log de auditoría JSONL de cada disable/enable, notifica al dashboard, y el disable ==expira a las 24h== — una válvula de emergencia que se queda abierta deja de ser de emergencia y se vuelve el nuevo default.

## Por qué importa

El recibo convierte la revisión de opinión en ==evidencia verificable y auditable==: qué tier tuvo el cambio, qué lentes se corrieron, qué findings salieron, contra qué SHA se aprobó. Cuando algo rompe en producción, no preguntas "¿quién aprobó esto?" — miras el recibo. Los artefactos viven en \`.session/rdd/\` (no se commitean, como todo estado operativo del stack).

> La lección [Verificación antes de declarar listo](#/lesson/workflows/verificacion-antes-de-listo) muestra cómo el gatekeeper consume estos hallazgos en la práctica, y [Prompts para code review](#/lesson/prompts/prompts-para-code-review) es el complemento manual cuando la revisión la hace un humano.
`,
    },
    {
      id: 'sdd-tdd-bdd-rdd',
      title: 'SDD con TDD, BDD y RDD: cómo se complementan las metodologías',
      minutes: 12,
      type: 'curso',
      md: `## Qué es y para qué sirve

El stack no usa ==una== metodología de desarrollo: usa **cuatro que operan en momentos distintos del mismo pipeline** y se refuerzan entre sí. La confusión habitual ("¿SDD o TDD?") viene de tratarlas como alternativas; en Gentle-Vanguard son capas:

| Metodología | Responde | Momento en el pipeline | Artefacto |
|---|---|---|---|
| **SDD** (Spec-Driven) | ¿QUÉ construir y con qué alcance? | Antes del código | Especificación + tareas (\`.sdd/\`) |
| **BDD** (Behavior-Driven) | ¿QUÉ comportamiento debe cumplir y cómo se demuestra? | Al congelar la spec | Criterios de aceptación tipo Gherkin |
| **TDD** (Test-Driven) | ¿CÓMO sé que el código hace lo que la spec dice? | Durante APPLY | Tests que pasan de rojo a verde |
| **RDD** (Receipt-Driven) | ¿ESTÁ verificada la entrega y su riesgo revisado? | Antes de cada gate de entrega | Recibo ligado a Git SHA |

## BDD: el puente entre requisito y verificación

BDD (Behavior-Driven Development) formula el comportamiento en un formato ejecutable y legible por no-programadores — el clásico es ==Gherkin==: Dado un contexto, Cuando pasa algo, Entonces espero un resultado. En el stack, los criterios de aceptación que el rol **BA** escribe en la fase SPEC son efectivamente escenarios BDD: frases verificables, no adjetivos. "El sistema debe ser rápido" no es verificable; "la respuesta debe llegar en <2s con caché caliente" sí.

- El subagente \`sdd-explore\` genera requisitos con **keywords BDD** (requirement, user story, acceptance, gherkin, specification) — su índice RAG está entrenado para reconocer ese vocabulario.
- En VERIFY, \`sdd-verify\` transforma esos criterios en ==contratos ejecutables==: cada escenario de la spec debe tener un test o una verificación que lo demuestre. Un criterio sin demostración es un FAIL, no un "confía en mí".

## TDD: rojo → verde → refactor dentro de APPLY

TDD (Test-Driven Development) invierte el orden: ==primero el test que falla, después el código que lo hace pasar==. El ciclo red-green-refactor encaja en la fase APPLY del pipeline SDD:

1. **Rojo**: de la tarea SDD se deriva un test concreto (el contrato de esa tarea) — corre y falla.
2. **Verde**: el rol DEV implementa lo mínimo para que pase.
3. **Refactor**: se mejora la forma sin tocar el comportamiento, con el test como red de seguridad.

La ventaja con agentes de IA es doble: el test fallando ==ancla al agente al contrato== (no puede "resolver" otra cosa y declarar victoria), y el test pasando es ==evidencia mecánica== de cumplimiento — no requiere confiar en la narración del agente. La skill \`test-driven-development\` es una de las 12 críticas sincronizadas a todas las herramientas, y el stack la sugiere en tareas de implementación.

## Cómo se encadenan en un caso real

1. **SPEC**: "El budget guard debe alertar al 80% del presupuesto diario" — con su escenario: Dado consumo 4.1M de 5M, Cuando corre el guard, Entonces existe alerta WARN en Nexus.
2. **APPLY (TDD)**: test que crea la condición y afirma la alerta → falla → se implementa → pasa.
3. **VERIFY (BDD)**: \`sdd-verify\` ejecuta el escenario tal cual está escrito en la spec y registra PASS/FAIL como artefacto gate.
4. **RDD**: el cambio tocó \`config/token-budget-guard.json\` + lógica de alertas → evidencia de categoría config/costos → tier standard (1 lente) o high (4R) según score → recibo ligado al SHA.

## Anti-patrón: usarlas como religiones separadas

- TDD sin SDD: tests verdes que implementan ==el requisito equivocado== (el test también lo escribió quien entendió mal).
- SDD sin TDD: specs hermosas y código sin evidencia mecánica — VERIFY se vuelve opinión.
- RDD sin las anteriores: recibos que certifican procesos vacíos.

La regla del stack: ==la spec dice qué, BDD lo hace demostrable, TDD lo hace mecánico, RDD lo hace auditable==.

> Sigue con [RDD y la revisión 4R](#/lesson/workflows/rdd-receipts-y-4r) para el detalle del protocolo de recibos, y [Testing del stack](#/lesson/workflows/testing-del-stack) para las suites reales (config, workflows, research) y cómo correrlas.
`,
    },
    {
      id: 'guardrails-y-gates',
      title: 'Guardrails: qué son y cuáles activa el stack',
      minutes: 10,
      type: 'curso',
      md: `## Qué son y para qué sirven

Un ==guardrail== (barandilla) es un check automático que impide que un cambio malo llegue más lejos de donde puede corregirse barato. La idea es simple: el error más caro es el que se descubre tarde, así que el stack instala barandillas en cada punto de avance — commit, push, PR, merge, release.

Los guardrails no sustituyen al criterio: lo **escalan**. Un humano revisa cuando quiere; los hooks corren siempre, en cada commit, sin días malos.

## Cómo funcionan: las capas activas

### 1. Hooks de pre-commit (lefthook)

Al hacer \`git commit\` corren automáticamente: JSON lint, workflow lint, lockfile lint, **trufflehog** (secrets), skill scan y **secretlint**. Además, el ==secret scanner nativo== del stack (80 patrones) revisa los archivos staged (ts/js/json/yml/md/env, entre otros) con redacción por defecto.

### 2. Hooks de pre-push

Al hacer \`git push\` corren: **TypeScript check** (\`npm run typecheck\`), **ESLint**, audit check, orchestrator auto-fix y \`npm audit\`. Un push con tipos rotos o vulnerabilidades conocidas no sale de la máquina.

### 3. Audit sweep (validación por lotes, cero tokens)

\`\`\`bash
# quick: 1 segundo, pre-commit
npx tsx src/cli/gv.ts audit sweep --scope quick --fail-on-issues
# standard: ~3s, para CI
npx tsx src/cli/gv.ts audit sweep --scope standard --output json
# full: ~5s, pre-release y merges
npx tsx src/cli/gv.ts audit sweep --scope full
\`\`\`

Chequea duplicados, links, estructura y sync del repositorio sin gastar un token.

### 4. sdd-gate en PRs

Todo PR a rama protegida (\`main\`, \`develop\`) requiere un caso SDD en estado validado o done. Sin especificación verificada, el PR no avanza.

### 5. Normativa de calidad

- Cobertura mínima **80%**, objetivo 90%, aplicada en CI/CD.
- Todo PR requiere approval; no hay merge con tests fallando.
- Pipeline obligatorio: commit → build → test → security → deploy → monitor.

## En el stack

- Los hooks viven en \`.lefthook.yml\`; se reinstalan con \`npx lefthook install\` y se prueban con \`npx lefthook run pre-commit --dry-run\`.
- El CI (\`.github/workflows/ci.yml\`) corre 6 jobs: lint-typecheck, test, dashboard-tests, dashboard-build, security-scan y workflow-lint. El workflow \`security.yml\` añade gitleaks, secretlint y trivy.
- Los códigos de salida del audit sweep son contractuales: **0** = sin issues, **1** = issues no fatales, **2** = error fatal.

## En la práctica

El costo también está normado: pre-commit corre en segundos (lints y scanning de staged files), pre-push tarda más (typecheck + suite) — el runbook documenta que si el pre-push supera los 2 minutos conviene investigarlo, no aceptarlo como normal. La barandilla que tarda demasiado invita a saltársela, y un guardrail que se salta no es guardrail.

Si un hook te bloquea, no lo saltees con \`--no-verify\`: leelo. Casi siempre está señalando algo real (un JSON malformado, un secret de prueba, un lockfile desincronizado). Los falsos positivos del scanner de secrets se documentan y se tratan como bug del guardrail, no como molestia a evitar.

## Puntos clave

- Guardrail = check automático en cada punto de avance; el stack los activa en commit, push, PR y release.
- Pre-commit: lint de configs + escaneo de secrets (trufflehog, secretlint, scanner nativo de 80 patrones).
- Pre-push: typecheck, ESLint, audit, npm audit.
- Audit sweep: quick/standard/full por costo creciente; \`judgment\` (revisión adversarial) para releases mayores.
- sdd-gate: sin SDD validado no hay merge a ramas protegidas.`,
    },
    {
      id: 'normativas-del-stack',
      title: 'Normativas del stack: las reglas que le dan dirección',
      minutes: 12,
      type: 'curso',
      md: `## Qué son y para qué sirven

Las ==normativas== son las reglas escritas del repositorio: convenciones obligatorias que hacen que veinte decisiones dispersas se comporten como un solo sistema. Sin normativas, cada sesión (y cada agente) re-decide todo desde cero; con ellas, el stack tiene **dirección estable** y los cambios son revisables contra una regla citable.

Viven en \`rules/\` y se consolidan en cuatro archivos maestros. Cambios en \`rules/\` obligan a actualizar \`AGENTS.md\` — la documentación y la norma nunca se divorcian.

## NORMATIVAS-ARCHITECTURE — cómo se construye

- **Capas estrictas**: Presentation → Application → Domain → Infrastructure, con dirección de dependencia en un solo sentido.
- **Orquestador**: un punto de entrada delega a agentes especializados; el wiring es config (\`config/orchestrator.json\`, \`config/delegation-config.json\` con umbrales de confianza 0.0–1.0).
- **APIs**: SemVer 2.0, versión en la URL (\`/v1/\`), aviso de deprecación una versión completa antes con header \`Sunset\`.
- **Cross-platform**: Windows/Ubuntu/macOS; **TypeScript-First** — todo script operativo es TS corrido con \`npx tsx\`.
- **Repo**: monorepo recomendado (\`apps/\`, \`packages/\`, \`docs/\`); polyrepo solo con razón explícita.
- **Costo**: medir antes de optimizar; modelos económicos para rutina y premium para fases críticas (SDD-design, verify).
- **SLOs**: dispatch de agente <500ms, carga de skill <2s, tarea de agente <30s; circuit breaker con cooldown de 30s.

## NORMATIVAS-CODE-QUALITY — cómo se escribe

- **Single Source of Truth**: configs en JSON, nada hardcodeado en scripts.
- **Idempotencia**: verificar existencia antes de crear; errors explícitos, no silenciosos.
- **Testing First**: todo cambio con tests, **80% mínimo** de cobertura, enforced por CI.
- **Errores con severidad**: CRITICAL bloquea pipeline, HIGH bloquea merge, MEDIUM avisa, LOW loguea; categorías (auth, config, dependency, execution, security, validation).
- **JSON**: comillas y llaves balanceadas verificadas antes de cada tool call; sin trailing commas.
- **Feedback**: toda acción ofrece rating 1–5 persistido en Nexus; patrones con rating <3 generan propuestas de mejora, y un patrón repetido 3+ veces sugiere normativa nueva.

## NORMATIVAS-OPS-DEVOPS — cómo se opera

- **Pipeline**: commit → build → test → security (SAST+DAST+deps) → deploy (staging → approval → producción, artefactos inmutables, blue-green) → monitor.
- **Observabilidad**: logs estructurados JSON, traces OpenTelemetry, métricas; endpoint \`/health\` con estado por componente.
- **Disaster recovery**: RPO 1h (5min para configs/sesiones), RTO 4h; backups de Engram post-sesión con retención 30d/90d; drill de restore trimestral.
- **Resiliencia**: retries con backoff exponencial por dependencia (Engram 3x, Git 2x, APIs 3x); timeout obligatorio en toda operación; circuit breaker 3 fallos → open 30s → half-open.
- **Incidentes**: P1 (15min respuesta) a P4; ciclo DETECT → TRIAGE → CONTAIN → MITIGATE → RESOLVE → POST-MORTEM; post-mortem blameless obligatorio para P1/P2 en 48h.

## NORMATIVAS-WORKFLOW — cómo se trabaja

- **Git**: \`main\` protegida ← \`develop\` ← \`feature/ISSUE-123-desc\`; commits \`type(scope): description\`; sin push directo a main.
- **Release**: automatizada vía \`release-automation\` (valida VERSION/badges/CHANGELOG → build → installer NSIS cifrado AES-256); el tagging manual está prohibido.
- **SDD**: pipeline con gates \`gate-<fase>.json\` (ver lección 1).
- **Sesión**: artefactos de cierre en \`.local/session-artifacts/\`; la autoría del ciclo de vida es \`.session/session-current.json\`.
- **Configs**: validadas contra schema al arranque, inmutables tras init, versionadas en git.
- **Documentación**: niveles README → Getting Started → User Guide → API Reference → Architecture; ADRs en \`docs/adr/\`.
- **Skill factory**: frontmatter YAML obligatorio (name, description, agent, ≥3 triggers) y \`references/detail.md\` con ejemplos.

## En la práctica

Antes de discutir un "deberíamos…", chequea la normativa: si existe, la discusión es "cambiamos la norma o la seguimos", nunca "la ignoramos silenciosamente". Y si te sorprendes repitiendo una corrección tres veces, es candidata a normativa nueva — ese es el mecanismo de aprendizaje del stack.

## Puntos clave

- Cuatro consolidadas: ARCHITECTURE (estructura), CODE-QUALITY (escritura), OPS-DEVOPS (operación), WORKFLOW (proceso).
- Reglas clave transversales: TypeScript-First, 80% cobertura, SLOs medidos, git flow protegido, releases automatizadas.
- Las normativas se citan en review y se actualizan junto a \`AGENTS.md\`.
- El feedback loop convierte patrones repetidos en normas nuevas.`,
    },
    {
      id: 'seguridad-por-capas',
      title: 'Seguridad por capas: del secret scanner a los permisos',
      minutes: 11,
      type: 'curso',
      md: `## Qué es y para qué sirve

La seguridad del stack no es un producto puntual sino ==capas superpuestas==, cada una cubriendo el fallo de la anterior. El modelo asume lo realista: los secrets se filtran por descuido, las dependencias se vulneran, los binarios se distribuyen y los dashboards se exponen. Cada capa tiene un dueño automático — no depende de que alguien se acuerde.

## Capa 1 — Secret scanning (80 patrones)

El scanner nativo (\`src/secret-scanner.ts\`) detecta keys de AWS, GCP, Azure, GitHub, GitLab, OpenAI, Anthropic, Slack, Stripe, JWTs, private keys y más, en 11 categorías:

\`\`\`bash
npm run scan:secrets -- --scan .          # archivo, directorio o URL
npm run scan:secrets -- --dir src         # recursivo
npm run scan:secrets -- --scan . --entropy --json
\`\`\`

- **Entropía Shannon opcional** (≥3.5 bits/char) para filtrar falsos positivos.
- **Redacción automática** por defecto (\`--no-redact\` para desactivar).
- Exit codes: 0 limpio, 1 hallazgos, 2 error.
- Integrado a **pre-commit** (\`.lefthook.yml\`, staged files), **watchtower** (componente \`secret-scanner\`) y tests (\`tests/unit/secret-scanner.test.ts\`).

## Capa 2 — CI de seguridad

El workflow \`.github/workflows/security.yml\` corre tres jobs: **gitleaks** (historia y contenido), **secretlint** (reglas por tipo de secreto) y **trivy** (vulnerabilidades de dependencias e imágenes). Se suma el \`npm audit\` del pre-push y trufflehog del pre-commit: cinco escáneres distintos mirando el mismo repo desde ángulos distintos.

## Capa 3 — Distribución cifrada

El instalador que sale del proceso de release es NSIS cifrado con **AES-256** (\`dist/Gentle-Vanguard.exe\`). Lo que viaja fuera de la máquina viaja cifrado.

## Capa 4 — Permisos en el dashboard (RBAC v1)

- Roles \`viewer < operator < admin\`: leer requiere \`viewer.read\`, mutar requiere \`operator.write\`, \`/api/admin/*\` requiere \`admin\`.
- Sesiones opacas respaldadas en SQLite con **CSRF double-submit**; el primer principal arranca como admin.
- Todo dato de dashboard declara **provenance** (\`database\` tenant-scoped o \`filesystem\` declarado); datos de filesystem sin tenant explícito son rechazados.

## Capa 5 — Promoción externa (opt-in)

Para salir de lo local, los ==promotion gates== exigen evidencia que el stack **nunca fabrica**: digest pinning de imágenes, firma Cosign, evidencia CNI/NetworkPolicy, sandbox de MCP. En modo local son informativos; en modo \`--promotion\` son bloqueantes. Los inputs externos son responsabilidad del operador.

## Capa 6 — Higiene de IA

- **ai-provenance**: inspección de marcas de proveniencia AI por defecto; la remoción (C2PA, Unicode, metadatos) exige petición explícita del usuario sobre contenido propio. Ante duda: inspeccionar y reportar.
- Las 25 skills de ciberseguridad con técnicas ofensivas (red-team) están **restringidas a entornos autorizados**, con notice legal en cada una.

## En la práctica

Si vas a commitear un ejemplo con una key, usa un placeholder obvio y verifica con \`npm run scan:secrets -- --scan .\` antes del commit — el hook lo hará igual, pero duele menos descubrirlo uno. Y si un hallazgo es falso positivo, redáctalo, documéntalo y repórtalo: los guardrails también tienen backlog.

## Puntos clave

- Seis capas: scanner nativo (80 patrones), CI (gitleaks/secretlint/trivy), installer AES-256, RBAC + CSRF, promotion gates opt-in, higiene de IA.
- El scanner redacta por defecto y soporta entropía para bajar falsos positivos.
- RBAC es deployment-scoped: no clama OIDC/LDAP/SSO — eso es input de promoción externa.
- La regla de oro: el stack nunca remueve marcas de proveniencia AI sin petición explícita.`,
    },
    {
      id: 'auditoria-y-trazabilidad',
      title: 'Auditoría y trazabilidad: la cadena hash',
      minutes: 10,
      type: 'curso',
      md: `## Qué es y para qué sirve

Auditar no es solo registrar: es poder **demostrar** que lo registrado no fue alterado. La diferencia entre un log cualquiera y un ==audit trail== es que el segundo detecta manipulación. En un stack donde agentes toman decisiones automáticas, la pregunta "¿por qué hizo esto?" necesita una respuesta verificable, no una reconstrucción de memoria.

El stack responde con tres piezas: event sourcing con cadena hash, pipeline de auditoría y tracing distribuido.

## Event sourcing con hash-chain

Cada evento del event store (\`.session/event-store/\`) guarda \`prevHash\` y \`hash\` (SHA-256): forma una cadena donde modificar un evento histórico rompe todas las verificaciones posteriores.

\`\`\`bash
npx tsx src/event-sourcing.ts -Action append -AggregateId caso-42 \\
  -EventType deployment.done -EventData '{"env":"staging"}'

npx tsx src/event-sourcing.ts -Action verify -AggregateId caso-42
\`\`\`

\`verify\` valida la integridad de la cadena y reporta \`tamper-mismatch\` o \`broken\` si algo fue alterado. Las acciones disponibles son \`append\`, \`project\`, \`snapshot\` y \`prune\`; hay tests de regresión en \`tests/unit/event-sourcing-hashchain.test.ts\`.

## Pipeline de auditoría

\`src/infrastructure/audit-pipeline.ts\` persiste eventos en JSONL diario bajo \`.session/audit/logs/\`:

\`\`\`bash
npx tsx src/infrastructure/audit-pipeline.ts -Action status
npx tsx src/infrastructure/audit-pipeline.ts -Action query -Query "sdd"
npx tsx src/infrastructure/audit-pipeline.ts -Action archive
\`\`\`

Acciones: \`log\`, \`status\`, \`query\`, \`archive\`, \`prune\`. Se inicializa como step lazy al arrancar sesión, así toda sesión nace auditable.

## Tracing distribuido

\`src/tracing-instrument.ts\` (acciones \`start\`, \`end\`, \`error\`) escribe spans en \`.telemetry/spans/\` y \`.telemetry/traces/\` (JSONL) y exporta **OTLP** a \`http://localhost:4318/v1/traces\`. Cada span encadena \`trace_id → span_id\`, lo que permite reconstruir el árbol de una delegación completa: orquestador → subagente → herramienta.

## Revisión adversarial (judgment-day)

Para auditoría de calidad (no solo de integridad), el audit workflow tiene una fase 2: dos jueces (implementación y arquitectura) revisan contra nueve dimensiones — security, performance, architecture, tests, documentation, dependencies, observability, maintainability y compliance. Cuesta ~USD 0.03 en tokens y 10–15 minutos; el barrido de fase 1 es gratis y toma segundos. Para releases mayores: \`gv.ts audit judgment --mode unified\`.

## Trazabilidad causal con witr

La retención también está definida: \`npm run db:prune\` limpia eventos con más de 30 días, caché con más de 7 y \`token_usage\` con más de 90 — auditar no significa acumular para siempre, significa conservar con política explícita. Y la tabla \`events\` de Nexus replica el patrón append-only para el consumo del dashboard y el scoring.

Cuando un componente falla, \`witr\` ("Why Is This Running?") traza procesos, puertos y archivos hasta su cadena causal, redactando secrets del entorno:

\`\`\`bash
npx tsx src/web/witr-cli.ts process <pid>
npx tsx src/web/witr-cli.ts port <port>
\`\`\`

La watchtower lo usa para explicar WARN/FAIL, no solo señalarlos.

## En la práctica

Regla mental: **hecho observado = medición con fecha y comando reproducible**. Si un reporte dice "el sistema funcionó bien", preguntá qué evento, en qué cadena, verificado cuándo. La cadena hash convierte esa pregunta en un comando de un segundo.

## Puntos clave

- Event sourcing append-only con \`prevHash\`+\`hash\` SHA-256; \`verify\` detecta \`tamper-mismatch\`/\`broken\`.
- Audit pipeline JSONL diario en \`.session/audit/logs/\` (log/status/query/archive/prune).
- Tracing OTLP con árbol trace/span; cada delegación es reconstruible.
- Judgment-day añade revisión adversarial de 9 dimensiones cuando la integridad no alcanza.
- witr explica la causa de un proceso/puerto — auditoría con contexto, no solo estado.`,
    },
    {
      id: 'testing-del-stack',
      title: 'Testing del stack: suites y cómo correrlas',
      minutes: 10,
      type: 'curso',
      md: `## Qué es y para qué sirve

El stack se prueba a sí mismo. La suite de tests no es un adorno del CI: es la razón por la que se puede refactorizar 390+ scripts de PowerShell a TypeScript sin congelar el desarrollo. La normativa lo dice claro: ==Testing First== — todo cambio llega con tests, cobertura mínima 80%, enforced en CI/CD.

## El mapa de suites

| Suite | Comando | Alcance |
| --- | --- | --- |
| Unit | \`npm test\` | 463 casos en ~100 archivos de \`tests/unit/\` |
| Config | \`npm run test:config\` | 6 tests de validación de configuraciones |
| Workflows CI | \`npm run test:workflows\` | 2 tests de los workflows de GitHub Actions |
| Research | \`npm run test:research\` | 5 tests (pytest) de \`research/rlhf-dataset-search\` |
| Integration | \`npm run test:integration\` | API health end-to-end |
| E2E dashboard | \`npm run test:e2e\` | flows del dashboard |
| Dashboard build | \`cd apps/web-dashboard && npm run build\` | debe salir 0 sin errores TS |

## Cómo correrlas

\`\`\`bash
npm test                     # suite unit completa
npm run test:quick           # versión rápida del runner
npm run test:parallel -- 4   # paralelismo
npm run test:config          # validación de configs
npm run typecheck            # TypeScript
npm run lint                 # ESLint
\`\`\`

El runner optimizado (\`src/test-runner-optimized.ts\`) soporta \`--quick\` y \`--parallel N\`: en una sesión normal corrés \`--quick\` para feedback inmediato y la suite completa antes del push (el hook lo hace igual).

Existen además los **deterministic tests** (\`npx tsx src/deterministic-test-framework.ts --list\`): tests sin costo de API, útiles para ciclos rápidos de desarrollo.

## Qué cubre la suite unit (ejemplos)

- \`run-command-hidden.test.ts\` — regresión del **process lock**: el PID del hijo debe ser el PID del script (falla si un launcher abre consolas visibles en Windows).
- \`event-sourcing-hashchain.test.ts\` — la cadena hash detecta manipulación.
- \`secret-scanner.test.ts\` — los 80 patrones y la redacción.
- \`web-crawler.test.ts\` — 14 tests incluyendo el decodeo del redirect \`uddg\` de DuckDuckGo.
- \`structural-compression.test.ts\` — las 5 estrategias de compresión y el modo lossless para input.

## En CI

Los 6 jobs de \`ci.yml\`: lint-typecheck, test, dashboard-tests, dashboard-build, security-scan, workflow-lint. Un PR no mergea con la suite roja — no es política de buena voluntad, es gate.

## En la práctica

Cuando arregles un bug, el orden es: **reproducir con un test que falle → arreglar → verlo verde**. Si el fix no tiene test, el bug volverá y no sabrás cuándo. Y cuando un test sea flaky, trátalo como bug de mayor severidad que uno determinista: un suite que llora lobo deja de ser guardrail.

## Puntos clave

- Suite principal: 463 unit tests (~100 archivos), más config (6), workflows (2), research (5), integration y e2e.
- Runner optimizado con \`--quick\` y \`--parallel\`; deterministic tests para ciclos sin costo de API.
- Cobertura mínima 80%, enforced por CI; pre-push corre typecheck + lint + audit.
- Los tests de regresión documentan decisiones de arquitectura (procesos ocultos, cadena hash, scanner).`,
    },
    {
      id: 'watchtower-en-operacion',
      title: 'Watchtower en operación: el runbook mental',
      minutes: 12,
      type: 'curso',
      md: `## Qué es y para qué sirve

La ==Watchtower== es el orquestador de salud y auto-healing del stack: **97 checks sobre 21 componentes** en 6 modos de operación. Su trabajo es detectar drift y degradación *antes* de que se conviertan en una sesión fallida: un índice vencido, un daemon muerto, una base locked, un hook desinstalado.

\`\`\`bash
npm run watchtower:health    # esperado: 97/97 PASS
\`\`\`

## Los 6 modos

| Modo | Comando | Qué hace |
| --- | --- | --- |
| health | \`-Action health\` | 97 checks, 21 componentes |
| rebuild | \`-Action rebuild\` | health + rebuild de índices ML/RAG |
| autoheal | \`-Action autoheal\` | health + restart de procesos caídos |
| report | \`-Action report -OutputFile status.json\` | export JSON |
| continuous | \`-Action continuous -Interval 30\` | loop cada N segundos |
| all | \`-Action all -Force\` | health + autoheal + rebuild |

En el arranque de sesión, el pipeline corre \`autoheal -Quiet\` como step **lazy**: no bloquea, pero deja el stack en su mejor estado conocido antes de que empieces a trabajar.

## Qué vigila (selección)

dashboard-ws (API 200, watchdog vivo), codegraph (índice, nodos, antigüedad), ml-embeddings, engram (integridad DB, reindex, RAG), mcp (configs y bridge), session, hooks de git, configs JSON, tool-configs, security, governance, secret-scanner, cli-guard, y Nexus (archivo, WAL, \`PRAGMA integrity_check\`, tamaño).

## El runbook mental cuando algo falla

1. **Re-corre health.** Un WARN transitorio (DB locked, reindex freshness) desaparece solo; no curas lo que no se reproduce.
2. **Identificá el componente.** La salida agrupa por componente: el diagnóstico ya está a medio hacer.
3. **Buscá la causa, no el síntoma.** Usa \`witr\` para trazar la cadena causal del proceso/puerto involucrado.
4. **Deja que sane solo.** \`-Action autoheal\` restaura procesos caídos; \`-Action rebuild\` regenera índices ML/RAG.
5. **Reinicia daemons por su puerta.** Dashboard: \`npx tsx src/dashboard-stop.ts\` (mata el watchdog **primero**) y luego \`npx tsx src/dashboard-ws-autostart.ts\`.
6. **Hooks rotos:** \`npx lefthook install\` y verifica con \`npx lefthook run pre-commit --dry-run\`.
7. **Leé los logs.** \`.runtime/dashboard-ws.log\`, \`.runtime/autostart-detached-*.log\` — la evidencia vive ahí.
8. **Si persiste, aislá.** El frontend del dashboard tolera caídas del WS vía HTTP polling: una capa degradada no tumba la observabilidad completa.

## Warnings que no son problemas

- \`engram reindex freshness\` — se refresca solo.
- \`cloud-connectors metrics\` — se generan con uso real (son opt-in).
- \`gentle-vanguard-db integrity check\` en WARN — DB locked transitorio.

Aprender a ignorar estos tres con criterio es parte del oficio; ignorarlos todos siempre, no.

## El CLI Guard (caso de estudio)

Dentro de los checks vive una regresión famosa: el patrón roto que compara \`import.meta.url\` contra la ruta de \`process.argv[1]\` prefijada con \`file://\` sin normalizar rutas Windows — hace que \`main()\` nunca se ejecute. El check lo detecta antes de que un "script que no hace nada" te robe una tarde. Es el ejemplo perfecto de por qué los checks son 97 y crecen: cada cicatriz del stack se convierte en guardia.

## En la práctica

Arrancá cada sesión de trabajo serio con \`npm run watchtower:health\`. Si vas a dejar el stack corriendo de fondo (daemons, ingesta de tokens), considerá \`continuous\` con intervalo 30s. Y cuando agregues un componente nuevo al stack, preguntá de inmediato: ¿qué check lo vigila?

## Puntos clave

- 97 checks / 21 componentes / 6 modos; \`autoheal -Quiet\` corre lazy en cada session start.
- Runbook: reproducir → identificar componente → trazar causa (witr) → autoheal/rebuild → reiniciar por la puerta correcta → leer \`.runtime/\`.
- El stop del dashboard mata el watchdog antes que el proceso (evita restart loops).
- Tres warnings transitorios conocidos; el resto se trata.`,
    },
    {
      id: 'verificacion-antes-de-listo',
      title: 'Verificación antes de «listo»: gatekeeper, lenses y ledger',
      minutes: 10,
      type: 'curso',
      md: `## Qué es y para qué sirve

"Listo" es la palabra más peligrosa del desarrollo con agentes. El stack la reemplaza por **evidencia verificada**, con tres componentes del trust-layer que trabajan en secuencia: el ==Result Gatekeeper== decide si un resultado puede avanzar, las ==Review Lenses== lo miran desde ángulos ponderados por riesgo, y el ==Findings Ledger== registra lo encontrado de forma a prueba de manipulación.

Viven en \`src/trust-layer/\` (con espejos en \`src/\`): \`result-gatekeeper.ts\`, \`review-lenses.ts\`, \`findings-ledger.ts\`.

## Result Gatekeeper — contratos entre fases

El gatekeeper implementa ==validación por contrato==: cada fase registra un contrato que describe cómo se validan sus outputs, y el resultado solo avanza si pasa.

\`\`\`bash
# registro un contrato para la fase y valido el output contra él
gatekeeper.registerContract({ phase: 'design', validator: validaNodos });
const ok = gatekeeper.validate('design', outputs); // true/false
\`\`\`

- \`registerContract(contract)\` — declara el validador de una fase.
- Cada validación exitosa queda registrada (fase, inputs, outputs, timestamp).
- Es la misma filosofía de los \`gate-<fase>.json\` del pipeline SDD, aplicada a resultados arbitrarios.

Sin contrato, "terminé" es una opinión; con contrato, es un booleano con timestamp.

## Review Lenses — cuatro lentes ponderados por riesgo

La revisión no es un checklist plano: cada lente tiene un peso de riesgo.

| Lente | id | Peso |
| --- | --- | --- |
| Security Lens | \`security\` | 0.4 |
| Performance Lens | \`performance\` | 0.2 |
| Maintainability Lens | \`maintainability\` | 0.2 |
| Compliance Lens | \`compliance\` | 0.2 |

La selección es **risk-based**: seguridad pesa el doble que cualquier otro lente porque un fallo de seguridad no admite rollback elegante. En review manual, usá la misma tabla: si el tiempo apremia, el lente security se corre siempre; los otros se escalonan.

## Findings Ledger — hallazgos a prueba de manipulación

El ledger registra hallazgos (bugs, deuda, riesgos) como records con \`hash\` y \`previousHash\` — la misma técnica de cadena SHA-256 del event sourcing. Cada finding recibe un id y timestamp, y la cadena completa es verificable: un hallazgo "borrado" o editado rompe la verificación.

El flujo completo queda así:

1. Una fase produce un resultado.
2. El **gatekeeper** lo valida contra el contrato de su fase.
3. Las **lenses** lo revisan con pesos de riesgo.
4. Todo hallazgo entra al **ledger** encadenado, con evidencia.
5. "Listo" = gate PASS + lenses revisadas + findings registrados y triagiados.

## En el stack

Estos componentes se conectan con el resto del sistema de calidad: el gate de VERIFY del SDD usa la misma lógica de contratos, el audit sweep y judgment-day consumen findings, y la cadena hash hace puente con el event sourcing de la lección de auditoría. También encontrará hallazgos el ==auto-code-review== (\`src/auto-code-review.ts\`) y la revisión RDD (\`src/rdd/rdd-4r-review.ts\`), que alimentan el mismo patrón.

## En la práctica

Cuando un agente te diga "terminado", tu respuesta no es "gracias", es la secuencia: ¿qué contrato validó? ¿qué lentes lo miraron? ¿dónde quedaron los findings? Si alguna respuesta es "ninguna", el resultado está sin verificar — y el costo de verificarlo ahora es siempre menor que el de descubrirlo en producción.

## Puntos clave

- Tres piezas: Result Gatekeeper (contratos PASS/FAIL), Review Lenses (4 lentes, security 0.4), Findings Ledger (cadena hash).
- La selección de lentes es risk-based: seguridad primero, siempre.
- Los findings encadenados no se pueden reescribir silenciosamente.
- "Listo" = gate PASS + lenses ejecutadas + findings registrados — nada menos.`,
    },
    {
      id: 'catalogo-capacidades',
      title: 'Capacidades concretas del stack — catálogo honesto',
      minutes: 12,
      type: 'curso',
      md: `## Qué es y para qué sirve

Vender (o usar) una herramienta exige saber exactamente **qué hace, cómo lo hace y dónde se corta**. Esta lección es el catálogo honesto de capacidades del stack: cada capacidad con su mecanismo real, y las limitaciones declaradas sin maquillaje. La regla del kit comercial es explícita: no presentar promesas como hechos — cada afirmación debe poder demostrarse con un comando.

## Catálogo de capacidades

| Capacidad | Mecanismo en el stack |
| --- | --- |
| Leer/analizar código | graphify (\`query\`, \`explain\`) y CodeGraph MCP (callers/callees/impact) sin re-leer archivos |
| Code review | Delegación a agentes de review, audit sweep + judgment-day, review lenses |
| Generar código | Rol DEV del SDD (\`sdd-apply\`, 52 steps) con gates y contratos |
| Generar documentación | \`doc-agent\`, humanizer, diagram-design (27 tipos de diagramas editoriales) |
| Hacer tests | Rol QA (\`sdd-verify\`), suites de regresión, deterministic tests |
| Análisis/diseño/arquitectura | Roles BA/SAD del SDD, ADRs, planning templates |
| Reingeniería e ingeniería inversa | Grafo AST (estructura real, no comentarios), migraciones PS1→TS asistidas |
| Adaptar/optimizar código | Refactor dirigido por grafo + tests de regresión como red de seguridad |
| Reducir deuda técnica | Findings ledger + audits periódicos + normativas anti-regresión |
| Copiar/recrear webs o apps | Skill de replicación front-end (análisis de imagen/layout → código), con permiso del contenido propio o autorizado |
| Investigación web | Web crawler dual-provider (Firecrawl → Jina/DDG/Bing RSS), \`npm run web:select\`, research trends (GitHub/HN/SO/Dev.to/Reddit) |

### Cómo se demostró (ejemplos verificables)

- **Analizar código:** \`npm run graphify -- query "¿quién llama a X?"\` responde sin abrir el editor.
- **Research:** \`npm run web:select -- --query "GDPR breach notification" --limit 5\` busca, gradea con BM25 y persiste el top-N.
- **Reingeniería:** 390+ scripts migrados de PowerShell a TypeScript con tests de regresión en cada wave.
- **Documentación:** este mismo material Academia es contenido generado y verificado con el stack.

## Limitaciones declaradas (sin excusas)

- **Multi-repo orchestration: alpha.** Existe (\`src/cross-workspace-validator.ts\` como candidato), manual y no probado en producción. Para hoy, el modelo soportado es monorepo.
- **Plugin system: experimental.** La arquitectura existe con un ejemplo (\`plugins/example-hello-world\`) pero sin uso real. No construyas negocio encima.
- **Promoción externa: pendiente de inputs.** Cosign, digest pinning, CNI/NetworkPolicy, OIDC/LDAP son **inputs que aporta el operador**, no cosas que el stack genera. El modo local no las exige; el modo \`--promotion\` las bloquea si faltan.
- **Labeling de graphify:** usa Gemini free tier (20 requests/día); un 429 detiene el etiquetado hasta el reset diario.
- **Cloud connectors:** opt-in para promoción externa; las métricas "se generan en uso real" — un environment local sin uso muestra vacío, no mentira.

## El marco mental: hecho, hipótesis o promesa

- **Hecho observado:** medición con fecha y comando reproducible ("la compresión redujo 1.087.295 a 18.418 tokens, medición 2026-08, tabla \`token_savings\`").
- **Hipótesis:** creencia falsable con métrica candidata ("creemos que el routing por costo reduce gasto en análisis").
- **Promesa:** generalización sin medición del contexto del oyente ("tu equipo ahorrará 90%") — el patrón que el stack prohíbe.

El catálogo de arriba está escrito en hechos: cada fila tiene comando. Cuando presentes el stack (a un cliente, en una charla, en la Academia), sostené el mismo estándar.

## Puntos clave

- Once capacidades, cada una con mecanismo y comando demostrable.
- Tres limitaciones grandes declaradas: multi-repo alpha, plugins experimentales, promoción externa pendiente de inputs del operador.
- El test de honestidad: ¿qué comando lo demuestra? Si no hay comando, es promesa.
- Las limitaciones no son vergüenza: son el scope. Lo que no está soportado hoy está documentado como no-soportado.`,
    },
  ],
};
