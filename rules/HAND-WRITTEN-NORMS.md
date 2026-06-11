# Hand-Written Norms

Norms documentadas manualmente, no generadas por auto-norm-learner. Mantenidas a pulso.

## NORM-001: ESLint strict-boolean-expressions debe desactivarse en proyectos React/Node legacy

**Context:** El dashboard de web-dashboard tiene 200+ warnings de `strict-boolean-expressions`. Es
una regla de estilo que no detecta bugs. **Rule:** En proyectos con base de código existente, se
puede desactivar esta regla a nivel de subproyecto mediante `.eslintrc.json` local. **File:**
`apps/web-dashboard/.eslintrc.json`

## NORM-002: Los archivos .session/ y .runtime/ deben excluirse de secretlint

**Context:** secretlint encontró un GitHub token real en `.session/engram-rag/_export-tmp.json`.
`.session/` ya estaba en `.gitignore` pero no en secretlint. **Rule:** Todo directorio de runtime
(`.session/`, `.runtime/`) debe estar en `.secretlintignore` para evitar falsos positivos y
exposición. **Files:** `.secretlintignore`, `.secretlintrc.json`

## NORM-003: Las promesas no manejadas deben prefixearse con `void`

**Context:** Se encontraron 7 floating promises en el dashboard que causaban errores de lint. La
regla `no-floating-promises` está en `error`. **Rule:** Toda llamada a función async cuyo resultado
no se necesita debe prefixearse con `void` (ej: `void loadListings()`). Nunca ignorar promesas sin
`void` o `.catch()`.

## NORM-004: Non-null assertions (!) deben reemplazarse con type guards

**Context:** Se reemplazaron 10 non-null assertions en el dashboard con type guards y optional
chaining. **Rule:** Prohibido usar `!` en TypeScript (regla `no-non-null-assertion: error`). Usar en
su lugar: optional chaining (`?.`), nullish coalescing (`??`), o type guards explícitos
(`if (x !== null && x !== undefined)`).

## NORM-005: Dashboard TS requiere CI propio separado del dashboard PowerShell

**Context:** El dashboard TypeScript (`apps/web-dashboard/`) no tenía cobertura en CI. El workflow
`dashboard-ci.yml` solo cubre el dashboard PowerShell (métricas). **Rule:** Todo subproyecto con
`package.json` propio debe tener su propio workflow de CI que ejecute lint + typecheck + build ante
cambios en sus archivos. **File:** `.github/workflows/dashboard-ts-ci.yml`

## NORM-006: Las variables no usadas en TypeScript deben prefixearse con `_`

**Context:** Se encontraron 8 variables/parámetros no usados en el dashboard. `noUnusedLocals` y
`noUnusedParameters` están en `error` en tsconfig. **Rule:** Toda variable o parámetro declarado
pero no usado debe prefixearse con `_` (ej: `_req`, `_eventType`) para indicar omisión intencional.

## NORM-007: Runtime files (.event-bus/, .engram/chunks/) no deben trackearse en git

**Context:** `.event-bus/history.json` y `.event-bus/sessions-history.json` estaban siendo
trackeados por git. El gitignore no los cubría. **Rule:** Todo archivo de runtime state
(`.event-bus/*.json`, `.engram/chunks/*`) debe estar en `.gitignore`. Verificar con `git ls-files`
después de agregar nuevos patrones. **Action:** Usar `git rm --cached` para untrackear archivos que
ya se commitearon pero deberían estar ignorados.

## NORM-008: Engram data integrity — backup con integrity-check + SHA256 + scheduling

**Context:** Stack de backup de Engram auditado. Existen 4 scripts con roles distintos: (1)
`backup-engram.ps1` — backup/restore/verify de DB + sessions + SHA256 + Git rollback. NO duplicar
con scripts de backup adicionales. (2) `auto-backup-orchestrator.ps1` — orquestador que DELEGA
backup real a (1) y agrega AES-256 encryption de metadata (norms, session state). Sin placeholders.
(3) `engram-integrity-check.ps1` — SHA256 checksums + SQLite validation + auto-repair. (4)
`backup-resilience-test.ps1` — tests de resiliencia (tamper, fallback). **Rule:** (1)
backup-engram.ps1 es el único script que debe copiar engram.db. (2) auto-backup-orchestrator.ps1
debe delegar a backup-engram.ps1, nunca duplicar. (3) backup-engram.ps1 corre pre-integrity-check +
SHA256 + post-backup verification. (4) Scheduling automático via session-autostart.config.json (step
`engram-backup` lazy). **Files:** `scripts/utilities/ops/BACKUP-RESTORE/backup-engram.ps1`,
`scripts/adaptive/auto-backup-orchestrator.ps1`,
`scripts/utilities/memory/ENGRAM/engram-integrity-check.ps1`, `config/session-autostart.config.json`

## NORM-009: Critical changes require explicit consent

**Context:** No había guardia contra cambios críticos no autorizados en Engram. Un agente podría
sobrescribir memoria sin que el usuario lo sepa. **Rule:** (1) Toda operación de riesgo _high_ o
_critical_ sobre Engram requiere autorización explícita del usuario vía `engram-change-guard.ps1`.
(2) Fingerprint SHA256 previo y posterior para detectar modificaciones no autorizadas. (3) El agente
debe notificar al usuario _antes_ de modificar observaciones existentes. **File:**
`scripts/utilities/memory/ENGRAM/engram-change-guard.ps1`
