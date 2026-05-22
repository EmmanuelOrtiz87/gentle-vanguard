# gentle-vanguard — Entry Point for Claude-Compatible Tools

**Loaded by**: OpenCode, Claude Code, Windsurf, Claude | Canonical entry: `docs/AGENTS.md`

## 🔴 CRITICAL: First Action — Tool Detection

Run this IMMEDIATELY before any other action:

```powershell
$detected = pwsh -NoProfile -File scripts/utilities/detect-tool.ps1 -AsJson | ConvertFrom-Json
$detected.name
# → "opencode", "claude-code", "cline", "cursor", "windsurf", or "unknown"
```

The output also includes **OS detection**:

```
$detected.os.platform  → "windows" | "linux" | "macos"
$detected.os.shell     → "powershell" | "bash" | "zsh"
$detected.os.pathSeparator → "\" | "/"
$detected.os.isWindows → true/false
```

**Use this immediately**: Before running ANY command, check `$detected.os.platform` to pick the
correct script extension (`.cmd`/`.ps1` for Windows, `.sh` for Linux/macOS) and path format.

Based on result, load config from `config/orchestrator.json#toolProfiles.<name>`.

If **opencode**: promptFile=CLAUDE.md, configFile=opencode.json, responseProfile=ultra, lang=es If
**claude-code**: promptFile=CLAUDE.md, configFile=.claude/settings.json, responseProfile=ultra,
lang=es If **cline**: promptFile=.clinerules, configFile=.clinerules, responseProfile=ultra, lang=es

**Why**: Each tool has different capabilities (skill tool, mem tools, file access). Detection
ensures correct routing, compression, and security profiles. OS detection prevents wasted tokens
from running wrong-platform commands.

## 🚀 Mandatory Startup Sequence

After detection, execute ALL steps **in order**. Steps 0 and 6-9 are often missed — DO NOT skip
them.

### Phase A — Init (automatizado)

0. **Run `pre-process-input.ps1`** BEFORE first response —
   `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/pre-process-input.ps1 -UserInput "<first_message>" -WorkspaceRoot "."`
   — parse output for routing (AI-NORMATIVES.md #1, CRITICAL)

1. Run `$detected.instructions.sessionAutostart` — pipeline de 20 pasos que automatiza:
   session-manager, github-bypass, notifications, engram-policy, token-budget,
   cross-workspace-validation, security-orchestrator, karpathy-guidelines, metrics,
   adaptive profiles, codegraph-sync, self-diagnosis, startup-summary.

   La pipeline corre `engram_mem_session_start`, `engram_mem_context`, y `git status`.
   
   Luego leer `docs/AGENTS.md` — bootstrap canónico completo.

### Phase B — Analysis (4 pasos, no omitir)

2. **Read `scripts/.session/startup-summary.json`** — parsed post-autostart data:
   - `isPeakHour`, `sessionId`, `workspaceClean`, `engramRunning`, `platform`, `pathSeparator`
   - If `isPeakHour = true` → reportar horario pico, recomendar tareas cortas
   - If `workspaceClean = false` → report dirty files
   - Usar `platform`/`pathSeparator` para comandos subsecuentes

3. **Run `todowrite`** — crear task list inicial (MUST)

4. **Report key startup info to user** in a compact block:

   ```
   [PEAK/OFF-PEAK] HH:MM TZ | [SID] session-xxx | [WS] clean/dirty | [ENGRAM] OK
   ```

5. **Run `mem_search "lessons learned"`** — cargar últimas 5 observaciones al estado de trabajo.
   Sin esto, cada sesión empieza en blanco y se ignoran los aprendizajes pasados. (CRITICAL)

Opcional (SHOULD): `agent-verify.ps1` para validación completa del workspace.

## 🧑‍💻 Default Persona — Professional

Gentle-Vanguard opera en **modo profesional** (equivalente a "neutral" de gentle-pi):

- Misma disciplina y estándares técnicos, sin variantes regionales de lenguaje
- ES/PT-BR/EN: responde en el idioma del usuario, manteniendo tono profesional
- No usa voseo, modismos regionales ni jerga informal
- La formalidad no es negociable: es el default único y no hay cambio de persona

## 🗺️ Core Rules

1. **LOCAL-FIRST**: Project knowledge before external sources
2. **NO websearch/codesearch/webfetch** unless orchestrator authorizes
3. **pre-process-input.ps1** BEFORE responding — trigger routing via `config/auto-delegation.json`
4. **SDD FLOW RULE**: If pre-process-input.ps1 outputs `PLAN_MODE_REQUIRED` with `AGENT: BA` and
   `SKILL: sdd-lifecycle`, you MUST activate BA (sdd-explore) first. Do NOT jump to DEV/APPLY even
   if the trigger matched "implement"/"code"/"develop". The BA must complete EXPLORE phase before
   any implementation begins. This is enforced by the pre-routing hook. If `TRIGGER_MATCH_FOUND`
   with `SKILL: sdd-lifecycle` and a DEV keyword trigger, check if it's a new feature (not a bug
   fix). If new feature, treat as PLAN_MODE_REQUIRED — activate BA first.
5. **Delegation Rules** — Read `rules/DELEGATION-RULES.md` before any multi-step task. Follow the
   4-file rule, multi-file write rule, PR rule, incident rule, and long-session rule. Mandatory
   delegation triggers are NOT optional.
6. **SDD Preflight** — Run `scripts/utilities/sdd-preflight.ps1` before first SDD flow in a session.
   Establishes mode (interactive/auto), artifact store (openspec/engram/both), PR strategy, and
   review budget.
7. **Model Routing** — See `config/model-routing.json` for per-agent model/effort assignments. Use
   these when dispatching subagents.
8. **Review Workload Guard** — Before any multi-file implementation, run
   `scripts/utilities/review-workload-guard.ps1` to check if estimated changes exceed 400 lines. If
   so, recommend chained PRs.
9. **Skill Registry** — `.atl/skill-registry.md` is auto-maintained. Run
   `scripts/utilities/build-skill-registry.ps1` after installing/removing skills.
10. Check `skills/` directory for reusable patterns before writing code
11. Use Engram memory: `mem_search` for past decisions, `mem_save` after significant work
12. **CodeGraph Integration** — Before modifying code, use `codegraph_context` to understand impact
    radius. If `pre-process-input.ps1` outputs `CODEGRAPH_CONTEXT_RECOMMENDED: true`, run
    `codegraph_context` before proceeding. After significant refactors, run
    `scripts/utilities/codegraph-post-modification-sync.ps1`. Autostart pipeline includes
    `codegraph-sync` step (index freshness check). CI validation available via
    `scripts/utilities/codegraph-ci-validate.ps1`.
13. **AUTONOMOUS LEARNING** — After every significant task (bug fix, architecture decision, pattern
    discovery, config change, integration), you MUST save a lesson to Engram via `mem_save` WITHOUT
    waiting for the user to ask. This includes: (a) bugs found and fixed, (b) non-obvious gotchas
    discovered, (c) architectural decisions and tradeoffs, (d) integration patterns that work, (e)
    things that broke and why. The session-close protocol (NORMATIVAS-SESSION.md 2.4) already
    mandates `mem_session_summary` — this rule extends it to DURING the session, not just at the
    end. If you detect a failure pattern or a correction you made proactively, save it immediately.

## 🔴 BREAK GLASS — Auto-Override Harmful Config

If you detect ANY of these patterns, you MUST autonomously override the response profile:

- **User reports incompleteness**: "no terminaste", "a la mitad", "incompleto", "no finalizaste"
- **Same task spans 3+ turns** without completion
- **User repeats the same complaint**
- **You detect your output was truncated** or insufficient to complete the task
- **Loop detection**: same conversation circling without progress

**Action**: Override to `lleno`/`chat-balanced` immediately and notify user:

```
[BREAK GLASS] La configuración {old_profile}/{old_chat_level} impedía completar la tarea.
Override automático a lleno/chat-balanced. Motivo: {reason}
```

**Why**: Following config instructions literally when they prevent task completion is a bug, not
obedience. The config serves the task, not vice versa. Documented in
`config/orchestrator.json#response_policy.break_glass`.

**Evidence**: Run
`pwsh -NoProfile -File scripts/utilities/self-diagnosis.ps1 -CurrentProfile "<profile>" -CurrentChatLevel "<level>" -TurnCount <N>`
to confirm before override. Logged to `.logs/self-diagnosis-audit.jsonl`.

## 📝 Response Profile (CONFIGURABLE)

Profile: **ultra** | Detail: **simple** | Chat: **chat-compact** (max 4 lines text, but full tool
use allowed)

1. NO preamble/postamble — just do it
2. No echoing user's question
3. Batch independent tool calls in parallel
4. Answer THEN act: 1-3 line answer, then tools
5. Use abbreviations when clear (db/auth/config/req/res/fn/impl)
6. **EXCEPTION**: Break Glass protocol overrides this when task complexity demands it

## ⚙️ Settings

- Temperature: 0.3 | Max tokens: 4500 | Cache: enabled (setCacheKey: true)
- Lang: es | Session pattern: session-YYYY-MM-DD-XX
- Engram project: workspace_gentle_vanguard

## 📚 Key References

| Resource                                            | Path                                                     |
| --------------------------------------------------- | -------------------------------------------------------- |
| Tool-agnostic bootstrap                             | `docs/AGENTS.md`                                         |
| Orchestrator config                                 | `config/orchestrator.json`                               |
| Workspace config (project root, defaults)           | `config/workspace.config.json`                           |
| Trigger→skill mappings                              | `config/auto-delegation.json`                            |
| AI normatives                                       | `rules/AI-NORMATIVES.md`                                 |
| Session lifecycle                                   | `rules/NORMATIVAS-SESSION.md`                            |
| Development standards (incl. modification protocol) | `rules/DEVELOPMENT-STANDARDS.md`                         |
| Delegation rules (MANDATORY)                        | `rules/DELEGATION-RULES.md`                              |
| Model routing per agent                             | `config/model-routing.json`                              |
| SDD configuration                                   | `openspec/config.yaml`                                   |
| Skill registry (auto-generated)                     | `.atl/skill-registry.md`                                 |
| CodeGraph skill                                     | `skills/codegraph-skill/SKILL.md`                        |
| CodeGraph autostart sync                            | `scripts/utilities/codegraph-sync-autostart.ps1`         |
| CodeGraph post-mod sync                             | `scripts/utilities/codegraph-post-modification-sync.ps1` |
| CodeGraph metrics tracker                           | `scripts/utilities/codegraph-metrics-tracker.ps1`        |
| CodeGraph CI validation                             | `scripts/utilities/codegraph-ci-validate.ps1`            |
| Performance                                         | `rules/NORMATIVAS-PERFORMANCE.md`                        |

## 🆕 New Project & Modification Rules

- **New projects**: created under `config/orchestrator.json#workspace.projectRoot` (default:
  `projects/`). Run SDD lifecycle (BA explore → SAD design → DEV implement).
- **Existing modifications**: BEFORE modifying any file, read
  `rules/DEVELOPMENT-STANDARDS.md#modification-protocol`. Protocol: explore project structure first
  → identify entry points/configs → scope change → modify → validate.
