# NORMATIVAS-SESSION.md — Session Lifecycle Standards

Version: 1.2.0 Last updated: 2026-05-23

---

## 1. PROPOSITO

Define el lifecycle completo de sesiones en Gentle-Vanguard. Aplica a todos los agentes AI que
operan sesiones de desarrollo.

---

## 1.1 DOCUMENTOS LOCAL-ONLY — PROHIBICIÓN DE COMMIT

> **REGLA CRÍTICA**: Los artefactos de sesión son información de trabajo interna. **NUNCA** deben
> ser commiteados al repo ni publicados.

### Documentos que NUNCA van al repo

| Tipo                            | Ejemplos                                                    | Ubicación local                   |
| ------------------------------- | ----------------------------------------------------------- | --------------------------------- |
| Closure reports                 | `PROJECT-CLOSURE-REPORT.md`, `closure-report-*.md`          | `.local/session-artifacts/`       |
| Delivery checklists             | `FINAL-DELIVERY-CHECKLIST.md`                               | `.local/session-artifacts/`       |
| Implementation logs             | `IMPLEMENTATION-LOG.md`, `README-IMPLEMENTATION.md`         | `.local/session-artifacts/`       |
| Session start/context packs     | `*-session-start.md`, `*-context-pack.md`                   | `docs/sessions/` (local-only)     |
| Next session guides             | `NEXT_SESSION_GUIDE.md`                                     | `.local/session-artifacts/`       |
| Strategic/phase plans de sesión | `STRATEGIC-OPTIMIZATION-PLAN.md`, `PHASE-*-ARCHITECTURE.md` | `.local/session-artifacts/`       |
| Lessons learned temporales      | `LESSONS-LEARNED-*.md`                                      | `.local/session-artifacts/`       |
| Session tasks pendientes        | `docs/tasks/*session*.md`                                   | `.local/session-artifacts/`       |
| Telemetry runtime               | `.telemetry/initialization-session-*.json`                  | Local — cubierto por `.gitignore` |
| Session logs                    | `logs/session-*.json`, `session/*.json`                     | Local — cubierto por `.gitignore` |
| Engram session data             | `.engram/session-*.md`, `.engram-data/`                     | Local — cubierto por `.gitignore` |
| Métricas de sesión CSV          | `docs/sessions/metrics/*.csv`                               | Local — cubierto por `.gitignore` |

### Criterio de decisión: ¿Va al repo o no?

```
¿El documento es permanente y útil para CUALQUIER desarrollador futuro?
   → SÍ: Puede ir al repo (normativas, guías de referencia, scripts, skills)
   → NO: Queda en .local/ o en ruta cubierta por .gitignore
```

### Regla de enforcement

1. Todo patrón local-only está declarado en `.gitignore` (sección "Session artifact docs")
2. El directorio `.local/` es local-only: está en `.gitignore`, **nunca** se trackea
3. Si un agente genera estos archivos durante una sesión, **DEBE** guardarlos en
   `.local/session-artifacts/` o en las rutas cubiertas por `.gitignore`
4. No commitear con `git add .` sin revisar — siempre usar `git add <archivo>` explícito o revisar
   `git status` primero

---

## 2. SESSION LIFECYCLE

### 2.1 Estados de Sesión

```
INACTIVE → STARTING → ACTIVE → CLOSING → CLOSED
                        ↓
                     COMPACTED (recoverable)
                        ↓
                     ACTIVE (restored)
```

| State     | Description                     | Transitions            |
| --------- | ------------------------------- | ---------------------- |
| INACTIVE  | No session active               | → STARTING             |
| STARTING  | Session init in progress        | → ACTIVE               |
| ACTIVE    | Session operational             | → CLOSING, → COMPACTED |
| COMPACTED | Context compressed, recoverable | → ACTIVE (restore)     |
| CLOSING   | Shutdown in progress            | → CLOSED               |
| CLOSED    | Session terminated              | → INACTIVE             |

### 2.2 Startup Protocol — Optimized (Contextual)

La Phase A (init) la ejecuta **automáticamente** la autostart pipeline (20 pasos habilitados).
El agente solo ejecuta Phase B (análisis y reporte).

#### Phase A — Init (Automatizado por autostart pipeline)

```
scripts/utilities/session-autostart.ps1
```

La pipeline cubre: tool-detection, session-manager, github-bypass, notifications,
engram-policy, token-budget, engram-optimization, cross-workspace-validation,
security-orchestrator, skill-router, karpathy-guidelines, metrics, adaptive profiles,
codegraph-sync, self-diagnosis, post-autostart-summary.

#### Phase B — Análisis y reporte (agente, 4 pasos)

1. **Leer** `scripts/.session/startup-summary.json` — obtener `isPeakHour`, `sessionId`,
   `workspaceClean`, `engramRunning`, `platform`, `pathSeparator`
2. **Crear** `todowrite` para trackear el trabajo
3. **Reportar** al usuario: bloque compacto (peak hour, session ID, workspace state)
4. **Cargar** `mem_search "lessons learned"` — últimas 5 observaciones al estado de trabajo

#### Post-init opcional (SHOULD)

- `scripts/utilities/agent-verify.ps1` — validar estado del workspace
- Revisar Watchtower/self-diagnosis por issues detectados en autostart

Session ID pattern: `session-YYYY-MM-DD-XX` (e.g., `session-2026-05-10-01`)

### 2.3 Active Session

During active session:

1. **MUST** call `mem_save` after significant work (architecture, bugfix, pattern, config)
2. **MUST** call `mem_search` before starting work that may have been done before
3. **SHOULD** maintain `todowrite` with current progress
4. **SHOULD** validate work with `agent-verify.ps1` periodically
5. **MUST** save lessons to Engram proactively — do NOT wait for user instruction. Triggers for
   automatic `mem_save`:
   - Bug found and fixed (what was wrong, why, how fixed)
   - Non-obvious gotcha discovered (edge case, platform quirk, tool limitation)
   - Architectural decision made (tradeoffs, alternatives considered)
   - Integration pattern that works (what connected, how)
   - Something broke and why (root cause, prevention)
   - Config change with non-obvious implications
   - Performance insight or optimization discovered

### 2.4 Close Protocol — Optimized (Automated Contextual)

The close protocol es contextual: el agente ejecuta UN comando (`gv end-session`) y la pipeline
automatiza todo. No son pasos manuales — son capacidades que la pipeline resuelve según el contexto.

#### Comando Único

```
gv end-session        # Cierre completo automatizado
gv end-session -Force # Omite validaciones no críticas
```

Trigger alternativo por auto-delegación: "cerrar sesion", "close session", "guardar sesion".

#### Lo que la pipeline automatiza

| Capacidad                         | Gatillador contextual                     |
| --------------------------------- | ----------------------------------------- |
| Session summary draft             | `generate-session-summary.ps1` desde git log + actividad |
| Pre-close validation              | Corre automático al inicio del cierre     |
| Git status check                  | Validación automática, advierte si sucio  |
| Config validation (`validate-configs.ps1`) | Automático en pipeline de cierre |
| Session metrics persistence       | `session-metrics-tracker.ps1 -Action end` |
| Self-improving pipeline           | `usage-tracker` → `skill-nudge` → `skill-auto-patch` |
| Self-diagnosis (`self-diagnosis-autonomous.ps1`) | Automático, detecta issues residuales |
| Session learning capture          | `session-learning-capture.ps1 -Trigger close` |
| Artifact rotation                 | Automático si hay más de N artefactos     |
| Norm enforcement/learning         | `auto-norm-enforcer` + `auto-norm-learner` |
| Engram session end                | `engram_mem_session_end.ps1` — actualiza session file + Engram |

#### 0 pasos manuales del agente

Todo es automático. El agente solo **confirma con el usuario** el draft de session summary
que la pipeline ya generó:

1. `gv end-session` → pipeline genera draft, valida, persiste métricas, cierra en Engram
2. Agente muestra draft al usuario: "¿Este resumen está bien? ¿Agregas algo?"
3. Si el usuario confirma o modifica → `mem_session_summary` con el contenido finalizado
4. Si el usuario no dice nada → el draft queda en `.local/session-artifacts/` para la próxima sesión

#### Concurrent Session Safety (automático)

El `session-manager.ps1 -Mode End` ya detecta sesiones concurrentes y requiere
`-TargetSessionId` explícito si hay más de 1 activa. No necesita acción manual del agente
a menos que el script lo advierta.

---

## 3. SESSION CONTINUITY

### 3.1 Cross-Session State

Preserved between sessions:

| Artifact             | Location                                   | Purpose                 |
| -------------------- | ------------------------------------------ | ----------------------- |
| Engram memory        | `.engram-data/`                            | Persistent knowledge    |
| Session files        | `.session/session-*.json`                  | Session state snapshots |
| Orchestrator state   | `.session/orchestrator-state.json`         | Agent dispatch state    |
| Token budget         | `.session/token-autopilot-state.json`      | Token tracking          |
| Token display config | `.session/token-display-config.json`      | Token notification freq |
| Pre-process cache    | `.session/preprocess-trigger-cache.json`  | Trigger cache           |
| Constraint retention | `.session/constraint-retention-state.json` | Earned trust state      |
| NEXT_SESSION_GUIDE   | `docs/NEXT_SESSION_GUIDE.md`               | Session handoff doc     |

### 3.2 Recovery from Compaction

When recovering from context compaction:

1. Read `mem_context` immediately after compaction
2. Restore from `.session/orchestrator-state.json` if exists
3. Continue working ONLY after state restoration confirmed

### 3.3 Crash Recovery

If session terminates unexpectedly:

1. Start new session with `session-autostart.cmd`
2. Check `.session/` for latest state files
3. Read `engram_mem_context` for recent context
4. Read `docs/NEXT_SESSION_GUIDE.md` for handoff notes
5. Run `agent-verify.ps1` to validate workspace integrity

---

## 4. SESSION ROUTING

### 4.1 Auto-Delegation

Session commands are routed via `config/auto-delegation.json`:

| Trigger                           | Agent   | Skill                  |
| --------------------------------- | ------- | ---------------------- |
| "guardar sesion", "close session" | SESSION | session-workflow-skill |
| "continuar", "continue"           | SESSION | session-workflow-skill |
| "estado", "status"                | SESSION | session-workflow-skill |
| "cerrar sesion", "fin de sesion"  | SESSION | session-workflow-skill |

> **Note**: "iniciar sesion" / "start session" is handled directly by the canonical startup protocol
> in `CLAUDE.md` — NOT routed via auto-delegation.

### 4.2 BA/SDD Activation During Session

BA + sdd-lifecycle is **automatically activated** when user triggers project/component creation:

| Trigger                             | Context                          | SDD Phase | Action                                       |
| ----------------------------------- | -------------------------------- | --------- | -------------------------------------------- |
| "create project", "nuevo proyecto"  | User wants new project           | EXPLORE   | Gather requirements, constraints, tech stack |
| "new component", "nueva componente" | User wants new feature/component | EXPLORE   | Understand needs, acceptance criteria        |
| "bootstrap", "scaffold", "template" | User wants project template      | EXPLORE   | Specify project structure and conventions    |

**Important**: These triggers skip directly to BA/SDD EXPLORE. The user is NOT asked "do you want BA
first?" — BA activation is automatic and transparent.

Pre-process-input.ps1 detects these keywords → routes to BA agent + sdd-lifecycle skill → EXPLORE
phase begins.

See: `config/auto-delegation.json#keywordMappings.BA` for complete trigger list.

---

### 4.2 SESSION Agent Profile (unchanged)

```json
{
  "temperature": 0.1,
  "hallucinationGuard": "high",
  "hedgingBlocked": true,
  "maxRetries": 1,
  "escalateOnFailure": "orchestrator",
  "requiredEvidence": ["session state captured", "git status verified"]
}
```

---

## 5. SESSION AUDIT

### 5.1 What Gets Logged

Each session tracks:

- Session ID and start/end timestamps
- Key decisions made
- Files changed
- Tests run and results
- Blockers encountered
- Token consumption (logged every 5 turns per `token-display-config.json`)

### 5.2 Session Summary Structure

```markdown
## Goal

[One sentence: what was built/worked on]

## Accomplished

- ✅ [Completed tasks]
- 🔲 [Pending tasks]

## Discoveries

- [Technical learnings, gotchas, edge cases]

## Relevant Files

- path/to/file — what changed
```

---

## 6. COMPLIANCE CHECKPOINTS

### Inicio (automático, no requiere acción del agente)

| Checkpoint | Responsable |
|---|---|
| `pre-process-input.ps1` antes del primer response | Agente (manual, CRITICAL) |
| Autostart pipeline (20 pasos) ejecutado | Pipeline automático |
| Session ID sigue patrón `session-YYYY-MM-DD-XX` | Pipeline automático |
| `startup-summary.json` generado | Pipeline automático |
| Orphan cleanup ejecutado | Pipeline automático |
| `mem_search` con "lessons learned" | Agente (Phase B step 4) |
| `todowrite` creado | Agente (Phase B step 2) |
| Reporte al usuario generado | Agente (Phase B step 3) |

### Durante la sesión

| Checkpoint | Responsable |
|---|---|
| Decisiones significativas guardadas en Engram (`mem_save`) | Agente (Core Rule #13) |
| `mem_search` antes de trabajo que pudo haberse hecho antes | Agente |
| `todowrite` mantenido con progreso actual | Agente |
| Token notification each 5 turns | Agente (per `token-display-config.json`) |
| Compaction aplicado si contexto > 80% del window | Sistema (opencode.json) |

### Cierre (3 pasos manuales, el resto automático)

| Checkpoint | Responsable |
|---|---|
| Pre-close validation | Pipeline end-session |
| Self-improving pipeline | Pipeline end-session |
| Self-diagnosis | Pipeline end-session |
| Session metrics persistidas | Pipeline end-session |
| `mem_session_summary` preguntado al usuario | Agente (paso manual 1) |
| Decisiones de cierre guardadas (`mem_save`) | Agente (paso manual 2) |
| `engram_mem_session_end` ejecutado | Agente (paso manual 3, built-in tool) |

---

## 7. REFERENCES

| Resource                 | Path                                           |
| ------------------------ | ---------------------------------------------- |
| Session Workflow Skill   | `skills/session-workflow-skill/SKILL.md`       |
| Session Autostart        | `scripts/utilities/session-autostart.cmd`      |
| Pre-Process Input        | `scripts/utilities/pre-process-input.ps1`      |
| Post-Autostart Summary   | `scripts/utilities/post-autostart-summary.ps1` |
| Startup Summary Data     | `scripts/.session/startup-summary.json`        |
| Routing Config           | `config/auto-delegation.json`                  |
| Orchestrator Config      | `config/orchestrator.json`                     |
| AI Normatives            | `rules/AI-NORMATIVES.md`                       |
| Performance & Efficiency | `rules/NORMATIVAS-PERFORMANCE.md`              |
| Code Standards           | `rules/NORMATIVAS-CODIGO.md`                   |
| Error Handling           | `rules/NORMATIVAS-ERROR-HANDLING.md`           |
| Development Standards    | `rules/DEVELOPMENT-STANDARDS.md`               |
| Agent Verify             | `scripts/utilities/agent-verify.ps1`           |
| Validate Configs         | `scripts/utilities/validate-configs.ps1`       |
| Handoff Guide            | `docs/NEXT_SESSION_GUIDE.md`                   |

---

| Token Display Config   | `.session/token-display-config.json`      | Token notification cfg |
| Context Efficiency     | `config/context-efficiency.json`          | Context budgets        |
| Compaction Config      | `opencode.json#compaction`                | Conversation mgmt      |

---

_Version: 1.2.0 — 2026-05-23 — Status: ACTIVE_
