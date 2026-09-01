# Absorción nativa de gentle-ai v2.5.0-rc.3 + v2.4.0 — 2026-08-31

> Fuente: [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai)
> Releases analizadas: `v2.5.0-rc.3` (2026-08-30), `v2.5.0-rc.2`, `v2.5.0-rc.1`, `v2.4.0` (estable,
> 2026-08-17). Nada se copió como dependencia: cada patrón se reimplementó nativo en TypeScript
> dentro de nuestro stack.

## Qué se absorbió (5 módulos nativos)

### 1. `src/core/continuation.ts` — Re-entry ships with the freeze (rc.3)

El headline de rc.3: "The re-entry knowledge lived in prose; the machine refused the prose." Un
START congelaba el candidato y dejaba al operador reconstruir en prosa un comando que el CLI ni
parseaba.

Nativo: `recordContinuation()` publica un `ContinuationEnvelope` con el comando **verbatim** de
re-entrada (`command`), argumentos ordenados, echo byte-identical de selectores
(`selectorArgumentsEcho`) y binding workflow/root/revision. `resolveContinuation()` valida root +
echo y rechaza replays tipados. `nextTransition()` responde "¿qué corro ahora?".

- Contrato: `gentle-vanguard.continuation/v1` (ops: record/get/resolve/next-transition)
- **Un solo dueño durable** (lección rc.2 "One record"): grabar una continuación nueva para el mismo
  workflowId **supersede** toda activa anterior — una transición vieja jamás queda como respuesta de
  `next`. Verificado por test de regresión.
- Escrituras atómicas (temp + rename): un lector nunca ve un registro a medio escribir.

### 2. Ack-before-burn (rc.2) — dentro de `continuation.ts`

Lección rc.2: "approval burned its authority on return; if the host never received the response the
review was over and nothing said so."

Nativo: `stageAck()` deposita un token pendiente SIN quemar nada; `acknowledge()` quema **solo** con
el token exacto (wrong/stale/replay → `TypedRefusal`, crean nada). Un status reiniciado replaya el
mismo token y revision.

- Contrato: `gentle-vanguard.ack/v1` (ops: stage/acknowledge/pending)
- Cableado en RDD: el receipt se emite **staged**; los gates de entrega rehusan tipado
  (`rdd.receipt-not-acknowledged`) hasta el ack exacto; `rdd-core ack --workflow=W --token=T` quema
  y replaya rehusando.

### 3. `src/core/path-identity.ts` — Windows path-identity-correct (#3888)

Lección: comparar paths con `startsWith()` es incorrecto 3 veces en Windows: case-insensitive del
FS, separadores mezclados, y sin boundary check (`C:\repo-evil` pasa como hijo de `C:\repo`).

Nativo: `canonicalPath` / `samePath` / `isWithinRoot` / `safeResolveWithin` — identidad pura de
strings (sin tocar FS), case folding solo en plataformas case-insensitive, preserva raíz de drive,
respeta semántica drive-relativa (`C:` = cwd del drive, `C:\` = raíz).

- **4 correcciones en vivo** (bugs reales preexistentes en nuestro stack):
  - `src/tools/event-sourcing.ts` — safePath del event store
  - `src/resilience/saga-orchestrator.ts` — safePath de sagas
  - `src/cli/serve-presentations.ts` — guard de path traversal HTTP
  - `src/zcode-hooks/session-start.ts` — guard de repo del hook SessionStart (los 4 eran vulnerables
    al hermano-prefijo y a case/separator drift)

### 4. `src/core/typed-refusal.ts` — Refusals que describen qué pasó (rc.2/rc.3)

Lecciones: reason codes que nombran el límite REAL que disparó (v2.4.0: el cap de 32 paths se
reportaba como byte-budget y el consejo era inejecutable); `nothingStarted` para negativas
pre-efecto (jamás auto-filean defect evidence); mensajes sin paths absolutos; remediation = comando
que el receptor PUEDE ejecutar (nunca un retry que se reproduce infinito); evidence JSONL solo para
escalations terminales (#3799).

- Contrato: `gentle-vanguard.typed-refusal/v1`

### 5. `src/core/capabilities.ts` — Capabilities surface (rc.3 "v2.3")

`gentle-ai review capabilities` responde honestamente qué operaciones existen y a qué versión de
protocolo — el caller no descubre por texto de error.

Nativo: registro de los 7 contratos nativos del stack con protocol major.minor, operaciones y
status. `describeContract()` de contrato desconocido → typed refusal nombrando los registrados. CLI:
`npx tsx src/core/capabilities.ts list`.

- Contrato: `gentle-vanguard.capabilities/v1`

## Honestidad fuera de git (#3899/#3885, v2.4.0)

`rdd-core.ts generateWorkflowId()`: fuera de un repo el id es `rdd-nogit-<sha256(cwd)[0:7]>-<ts>` —
truthful, estable, sin crash. Cubre ambos shapes de fallo: git ausente (throw) y git presente pero
sin repo (exit != 0 → stdout vacío).

## Bugs preexistentes propios encontrados y corregidos durante la absorción

1. **receipt huérfano**: `stepReceipt` buscaba archivos `*.json` individuales, pero
   `receipt-manager.ts` persiste en `index.json` (array `receipts[]`) — el workflow quedaba sin
   receipt y los gates morían en "must issue receipt first". Ahora lee el índice y toma el más
   nuevo.
2. **continuación gate sin publicar**: el paso `gate` condicionaba la publicación al cambio de
   `status`, pero un gate pasado cambia `gates[]` sin tocar status — la continuación vieja quedaba
   activa. Ahora publica sobre el mapa de gates.
3. CLI `continuation.ts` no parseaba `--flag=value` (solo espacio).

## Verificación en vivo (todo ejecutado)

| Verificación                                                                  | Resultado                                                                                                              |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Tests nuevos (`path-identity`, `continuation`, `capabilities`)                | 17/17 PASS                                                                                                             |
| Tests relacionados existentes (rdd-retention, sdd-validation, event-sourcing) | 9/9 PASS                                                                                                               |
| `tsc --noEmit`                                                                | 0 errores                                                                                                              |
| eslint (archivos src tocados)                                                 | 0 errores                                                                                                              |
| watchtower health                                                             | 111 PASS / 2 WARN / 0 FAIL (113)                                                                                       |
| graphify update                                                               | 5292 nodos / 10043 edges                                                                                               |
| Ciclo RDD en vivo                                                             | start→classify→review→receipt(staged)→gate REFUSED tipado→ack wrong REFUSED→ack exacto BURNED→replay REFUSED→gate PASS |
| SDD en vivo                                                                   | INIT PASS → publica EXPLORE → `--next` replaya verbatim                                                                |

## Qué NO se absorbió (y por qué)

- **Runtime provider contracts / bundles Go** — gentle-ai es un configurador multi-agente en Go;
  nuestro stack ya tiene su propio modelo de agentes y hooks. El patrón (contracts versionados) sí
  se absorbió vía `capabilities.ts`.
- **Pi/OpenCode relay internals** — dependen del binario gentle-ai.
- **TUI global RDD controls** — no tenemos TUI; el kill-switch ya es CLI nativo.

## Próximos pasos naturales (backlog)

- ~~Panel "what do I run now" en el dashboard~~ — HECHO (ContinuationsPanel +
  `GET /api/continuations`, i18n en/es/pt).
- ~~Ack-before-burn para `session-close`~~ — HECHO (`session-close/close-ack.ts`: el reporte
  terminal se emite staged; el inicio de la siguiente sesión lo recibe — auto-quema PASS intactos,
  escratacha FAIL/WARNINGS/missing-report y los deja pendientes hasta revisión; CLI
  `--pending`/`--ack`/`--receive`; contrato `gentle-vanguard.session-close/v1` registrado).
- ~~Retention de continuations/acks~~ — HECHO (`pruneContinuations()` cableado al prune del RDD,
  lazy en autostart).
- Registrar más contratos nativos en `capabilities.ts` a medida que se estabilicen.
