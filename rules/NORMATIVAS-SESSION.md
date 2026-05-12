# NORMATIVAS-SESSION.md — Session Lifecycle Standards

Version: 1.0.0
Last updated: 2026-05-10

---

## 1. PROPOSITO

Define el lifecycle completo de sesiones en el workspace Foundation. Aplica a todos los agentes AI que operan sesiones de desarrollo.

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

| State | Description | Transitions |
|-------|-------------|-------------|
| INACTIVE | No session active | → STARTING |
| STARTING | Session init in progress | → ACTIVE |
| ACTIVE | Session operational | → CLOSING, → COMPACTED |
| COMPACTED | Context compressed, recoverable | → ACTIVE (restore) |
| CLOSING | Shutdown in progress | → CLOSED |
| CLOSED | Session terminated | → INACTIVE |

### 2.2 Startup Protocol

When starting a session, execute ALL steps in order:

#### Phase A — Init

1. **MUST** run `scripts/utilities/pre-process-input.ps1 -UserInput "<message>" -WorkspaceRoot "."` BEFORE first response (AI-NORMATIVES.md #1, CRITICAL)
2. **MUST** run `scripts/utilities/session-autostart.cmd` (Windows) or equivalent
3. **MUST** call `engram_mem_session_start` with unique session ID
4. **MUST** call `engram_mem_context` to restore previous context
5. **MUST** check `git status` for dirty workspace

Session ID pattern: `session-YYYY-MM-DD-XX` (e.g., `session-2026-05-10-01`)

#### Phase B — Analysis & Reporting

6. **MUST** read `scripts/.session/startup-summary.json` — parse `isPeakHour`, `sessionId`, `workspaceClean`, `engramRunning`
7. **MUST** create `todowrite` for tracking work
8. **SHOULD** run `scripts/utilities/agent-verify.ps1` to validate state
9. **MUST** report startup summary to user in compact block (peak hour, session ID, workspace state)

### 2.3 Active Session

During active session:

1. **MUST** call `mem_save` after significant work (architecture, bugfix, pattern, config)
2. **MUST** call `mem_search` before starting work that may have been done before
3. **SHOULD** maintain `todowrite` with current progress
4. **SHOULD** validate work with `agent-verify.ps1` periodically

### 2.4 Close Protocol

When closing a session:

1. **MUST** run `mem_session_summary` with structured summary
2. **MUST** save key decisions to Engram via `mem_save`
3. **MUST** update `NEXT_SESSION_GUIDE.md` with current state
4. **SHOULD** run `git status` to verify clean state
5. **SHOULD** validate configs with `validate-configs.ps1`
6. **MUST** call `engram_mem_session_end` to mark session complete

---

## 3. SESSION CONTINUITY

### 3.1 Cross-Session State

Preserved between sessions:

| Artifact | Location | Purpose |
|----------|----------|---------|
| Engram memory | `.engram-data/` | Persistent knowledge |
| Session files | `.session/session-*.json` | Session state snapshots |
| Orchestrator state | `.session/orchestrator-state.json` | Agent dispatch state |
| Token budget | `.session/token-autopilot-state.json` | Token tracking |
| Constraint retention | `.session/constraint-retention-state.json` | Earned trust state |
| NEXT_SESSION_GUIDE | `docs/NEXT_SESSION_GUIDE.md` | Session handoff doc |

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

| Trigger | Agent | Skill |
|---------|-------|-------|
| "iniciar sesion", "start session" | SESSION | session-workflow-skill |
| "guardar sesion", "close session" | SESSION | session-workflow-skill |
| "continuar", "continue" | SESSION | session-workflow-skill |
| "estado", "status" | SESSION | session-workflow-skill |
| "cerrar sesion", "fin de sesion" | SESSION | session-workflow-skill |

### 4.2 SESSION Agent Profile

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
- Token consumption

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

TODO sesión DEBE verificar:

1. `pre-process-input.ps1` executed BEFORE first response
2. Session ID follows `session-YYYY-MM-DD-XX` pattern
3. `startup-summary.json` read and peak hour reported to user
4. `mem_session_start` called before work
5. `todowrite` created at session start
6. `agent-verify.ps1` run at session start (SHOULD)
7. Significant decisions saved to Engram
8. Session state recoverable after compaction
9. `mem_session_summary` called before close
10. NEXT_SESSION_GUIDE.md updated
11. Git workspace in clean/reported state before close

---

## 7. REFERENCES

| Resource | Path |
|----------|------|
| Session Workflow Skill | `skills/session-workflow-skill/SKILL.md` |
| Session Autostart | `scripts/utilities/session-autostart.cmd` |
| Pre-Process Input | `scripts/utilities/pre-process-input.ps1` |
| Post-Autostart Summary | `scripts/utilities/post-autostart-summary.ps1` |
| Startup Summary Data | `scripts/.session/startup-summary.json` |
| Routing Config | `config/auto-delegation.json` |
| Orchestrator Config | `config/orchestrator.json` |
| AI Normatives | `rules/AI-NORMATIVES.md` |
| Performance & Efficiency | `rules/NORMATIVAS-PERFORMANCE.md` |
| Code Standards | `rules/NORMATIVAS-CODIGO.md` |
| Error Handling | `rules/NORMATIVAS-ERROR-HANDLING.md` |
| Development Standards | `rules/DEVELOPMENT-STANDARDS.md` |
| Agent Verify | `scripts/utilities/agent-verify.ps1` |
| Validate Configs | `scripts/utilities/validate-configs.ps1` |
| Handoff Guide | `docs/NEXT_SESSION_GUIDE.md` |

---

_Version: 1.0.0 — 2026-05-10 — Status: ACTIVE_
