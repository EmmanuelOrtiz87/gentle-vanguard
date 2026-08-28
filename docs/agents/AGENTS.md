# Workspace Agent Bootstrap (Agnostic)

Tool-agnostic startup for this workspace | Canonical entry point

## Tool Detection

Detect which AI tool is running BEFORE any other action:

```TypeScript
$detected = pwsh -NoProfile -File src/core/detect-tool.ts -AsJson | ConvertFrom-Json
$detected.name
$detected.os.platform
```

Detection order: OPENCODE_SERVER_USERNAME -> CLAUDE_VSCODE_VERSION -> .clinerules -> .cursorrules ->
.windsurf/ Fallback: OpenCode. OS detection (windows/linux/macos) determines script extension
(.cmd/.ps1 vs .sh).

Based on detection, load `config/orchestrator.json#toolProfiles.<name>`.

## Mandatory Startup Sequence

### Phase A — Init

0. `src/pre-process-input.ts -UserInput "<msg>" -WorkspaceRoot "."` BEFORE first response
1. Run `src/session/session-start-optimized.ts` (autostart pipeline)
2. Read `scripts/.session/startup-summary.json`
3. `todowrite` — create task list
4. Report peak/off-peak, session ID, workspace state to user
5. `mem_search "lessons learned"` — load past learnings

### Phase B — Analysis

6. Verify workspace: `src/agent-verify.ts` (SHOULD)
   <!-- REF-OBSOLETA: src/agent-verify.ts no existe; candidato: protected/scripts/utilities/agent-verify.ps1.enc (sin equivalente TS activo) -->

<!-- REF-OBSOLETA: scripts/utilities/agent-verify.ps1 no tiene equivalente TS (migración PS1→TS) -->
<!-- REF-OBSOLETA: src/agent-verify.ts no existe (ruta migrada o eliminada) -->
<!-- REF-OBSOLETA: src/agent-verify.ts no existe (ruta migrada o eliminada) -->

7. SDD Preflight: `sdd-preflight.ps1` before first SDD flow
   <!-- REF-OBSOLETA: sdd-preflight.ps1 eliminado en migración PS1→TS; solo queda scripts/.session/sdd-preflight.json (dato, no script) -->
8. Review Workload Guard: `src/security/workload-guard.ts` before multi-file >400 lines

## Break Glass

If config prevents task completion (3+ turns, user complaint, loop, truncation):

1. `src/self-diagnosis.ts -CurrentProfile "<p>" -CurrentChatLevel "<l>" -TurnCount <N>`
2. Override to `lleno`/`chat-balanced`
3. Notify: `[BREAK GLASS] motivo: {reason}`

## Persona

Professional mode: ES/PT-BR/EN, no regional slang, formal tone, no persona switching.

## Routing

| Concept                  | Reference                                                                |
| ------------------------ | ------------------------------------------------------------------------ |
| Trigger->skill mappings  | `config/auto-delegation.json#keywordMappings`                            |
| Agent profiles + routing | `config/auto-delegation.json#agentProfiles` + `config/model-router.json` |
| SDD config + strict TDD  | `openspec/config.yaml`                                                   |
| Strict TDD enforcement   | `rules/SDD-STRICT-TDD.md`                                                |
| Per-phase model routing  | `rules/PER-PHASE-MODEL-ROUTING.md`                                       |
| Dependency automation    | `renovate.json` (Renovate) + `.github/dependabot.yml` (Dependabot)       |
| Pre-processing hook      | `src/pre-process-input.ts`                                               |
| SDD FLOW                 | New feature -> BA/EXPLORE, no exceptions                                 |
| Delegation Rules         | `rules/DELEGATION-RULES.md`                                              |

## Hard Rules — Config Safety

| Rule                            | Description                                                                                                                                                                               |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **NORMATIVA OVERRIDE PROTOCOL** | If user instruction contradicts a normativa/rule, ASK for explicit confirmation explaining WHY it conflicts. Proceed ONLY if user confirms. Otherwise follow normativa without deviation. |

| Rule                                | Description                                                                                                                                                                       |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **NO custom props in tool configs** | Never add non-standard properties to `opencode.json`, `.cursorrules`, `.windsurf/config.json`, etc. Tools reject unknown props at startup. Use `config/*.json` for custom config. |
| **Validate before deploy**          | Run `src/validate-opencode-config.ts` before any change to `opencode.json`                                                                                                        |
| **Separate config per concern**     | Prompt optimization → `config/system-prompt-optimization.json`. Never inline into tool configs.                                                                                   |

## Context Optimization

| Technique           | Description                                                                                                                                                          |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Memory tiering      | Hot (active) -> Warm (1d, 90%) -> Cold (7d, 70%)                                                                                                                     |
| Handoff compression | `src/handoff-compress.ts` <!-- REF-OBSOLETA: src/handoff-compress.ts no existe; solo scripts/utilities/utils/UTILITIES/handoff-compress.sh y .ps1.enc protegidos --> |

<!-- REF-OBSOLETA: src/handoff-compress.ts no existe (ruta migrada o eliminada) -->
<!-- REF-OBSOLETA: src/handoff-compress.ts no existe (ruta migrada o eliminada) -->

| Pre-compact hook | `src/pre-compact-hook.ts`
<!-- REF-OBSOLETA: src/pre-compact-hook.ts no existe (solo pre-compact-hook.ps1.enc en protected/) -->

|
<!-- REF-OBSOLETA: src/pre-compact-hook.ts no existe (ruta migrada o eliminada) -->
<!-- REF-OBSOLETA: src/pre-compact-hook.ts no existe (ruta migrada o eliminada) -->

| Response cache | `src/pre-process-input.ts` — SHA256 cache, TTL 30min, -33-41% latency (flag
`-DisableCache` to bypass) | | Lazy autostart | `config/session-autostart.config.json` — 6
non-critical steps deferred post-pipeline | | In-process pipeline | `src/session/session-start-optimized.ts`
— removed `Start-Job`, runs `&` directo in-process |

## Token Notification (Auto-Hook — Every Turn)

Automatico vía `src/pre-process-input.ts`. Se ejecuta CADA turno sin intervención del agente.
Muestra el acumulado de la sesión al inicio de cada turno.

Startup: `config/session-autostart.config.json` → paso `token-notification-init` →
`src/tokens/token-usage-notifier.ts -Action status`.

Commands: | `/notif on/off` | Master toggle | | `/notif status` | Show current notification state |
| `/notif token on/off` | Toggle token display only | | `/notif context on/off` | Toggle context
chars display | | `/notif cost on/off` | Toggle cost estimation | | `/notif accumulated on/off` |
Toggle session accumulated | | `/notif compact on/off` | Toggle compact/verbose mode |

For context logging (post-response), run manually when needed:

```TypeScript
pwsh -NoProfile -File src/tokens/token-usage-auto.ts -InputTokens <N> -OutputTokens <N> -ContextChars <N> -InputSummary "<...>" -OutputSummary "<...>" -TurnLabel "<...>" -Model "<model>"
```

Creates `.session/context-log/<session-id>/turn-NNN.md` and `context-summary.md`. On close:
`src/core/session-context-log.ts -Action close`.

## Quick Commands

See `docs/operations/procedures/QUICK-COMMANDS.md` for full list.

## Key References

| Resource                     | Path                                                                                                                                                |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Orchestrator config          | `config/orchestrator.json`                                                                                                                          |
| Auto-delegation              | `config/auto-delegation.json`                                                                                                                       |
| NORMATIVES (index)           | `rules/NORMATIVES.md`                                                                                                                               |
| NORMATIVAS-ARCHITECTURE      | `rules/NORMATIVAS-ARCHITECTURE.md`                                                                                                                  |
| NORMATIVAS-CONFIG            | `rules/NORMATIVAS-CONFIG.md` <!-- REF-OBSOLETA: rules/NORMATIVAS-CONFIG.md no existe -->                                                            |
| NORMATIVAS-DEVOPS            | `rules/NORMATIVAS-OPS-DEVOPS.md`                                                                                                                    |
| NORMATIVAS-DOCS              | `rules/NORMATIVAS-DOCS.md` <!-- REF-OBSOLETA: rules/NORMATIVAS-DOCS.md no existe -->                                                                |
| NORMATIVAS-ENFORCEMENT       | `rules/NORMATIVAS-ENFORCEMENT.md`                                                                                                                   |
| NORMATIVAS-GIT               | `rules/NORMATIVAS-GIT.md` <!-- REF-OBSOLETA: rules/NORMATIVAS-GIT.md no existe -->                                                                  |
| NORMATIVAS-CODIGO            | `rules/NORMATIVAS-CODE-QUALITY.md`                                                                                                                  |
| NORMATIVAS-PERFORMANCE       | `rules/NORMATIVAS-PERFORMANCE.md`                                                                                                                   |
| NORMATIVAS-SESSION           | `rules/NORMATIVAS-SESSION.md` <!-- REF-OBSOLETA: rules/NORMATIVAS-SESSION.md no existe (posible: rules/SESSION-CLOSE-NORMATIVA.md) -->              |
| NORMATIVAS-SOC2              | `rules/NORMATIVAS-SOC2.md` <!-- REF-OBSOLETA: rules/NORMATIVAS-SOC2.md no existe (posible: rules/NORMATIVAS-SECURITY-COMPLIANCE.md) -->             |
| **NORMATIVAS-AI-SAFETY**     | `rules/NORMATIVAS-AI-SAFETY.md` <!-- REF-OBSOLETA: rules/NORMATIVAS-AI-SAFETY.md no existe -->                                                      |
| **NORMATIVAS-COST-OPT**      | `rules/NORMATIVAS-COST-OPTIMIZATION.md` <!-- REF-OBSOLETA: rules/NORMATIVAS-COST-OPTIMIZATION.md no existe (posible: rules/COST-ATTRIBUTION.md) --> |
| **NORMATIVAS-DISASTER-REC**  | `rules/RECOVERY-NORMATIVA.md`                                                                                                                       |
| **NORMATIVAS-INCIDENT-MGMT** | `rules/INCIDENT-RESPONSE.md`                                                                                                                        |
| AI normatives                | `rules/AI-NORMATIVES.md`                                                                                                                            |
| Dev standards                | `rules/DEVELOPMENT-STANDARDS.md`                                                                                                                    |
| Delegation rules             | `rules/DELEGATION-RULES.md`                                                                                                                         |
| Model routing                | `config/model-router.json`                                                                                                                          |
| SDD config                   | `openspec/config.yaml`                                                                                                                              |
| Context engineering          | `rules/CONTEXT-ENGINEERING.md`                                                                                                                      |
| CodeGraph skill              | `skills/codegraph-skill/SKILL.md`                                                                                                                   |
| Quick commands               | `docs/QUICK-COMMANDS.md`                                                                                                                            |
| JS/TS Quality CI             | `.github/workflows/ci.yml`                                                                                                                          |
| Python Quality CI            | `.github/workflows/python-quality.yml` <!-- REF-OBSOLETA: workflow no existe; sin equivalente Python dedicado -->                                   |
| Markdown Lint CI             | `.github/workflows/markdown-lint.yml` <!-- REF-OBSOLETA: workflow no existe -->                                                                     |
| Commit Lint CI               | `.github/workflows/commitlint.yml` <!-- REF-OBSOLETA: workflow no existe -->                                                                        |
| Coverage CI                  | `.github/workflows/coverage.yml` <!-- REF-OBSOLETA: workflow no existe -->                                                                          |
| npm Audit CI                 | `.github/workflows/npm-audit.yml` <!-- REF-OBSOLETA: workflow no existe -->                                                                         |
| Stale Issues CI              | `.github/workflows/scheduled.yml`                                                                                                                   |
| PR Labeler CI                | `.github/workflows/labeler.yml`                                                                                                                     |
| OpenAPI Validate CI          | `.github/workflows/openapi-validate.yml` <!-- REF-OBSOLETA: workflow no existe -->                                                                  |
| Devcontainer                 | `.devcontainer/devcontainer.json`                                                                                                                   |
| JSON Validator               | `src/json-validator.ts`                                                                                                                             |
| JSON Construction            | `rules/NORMATIVAS-JSON-CONSTRUCTION.md` <!-- REF-OBSOLETA: rules/NORMATIVAS-JSON-CONSTRUCTION.md no existe -->                                      |
| **Feedback Collector**       | `src/feedback/feedback-collector.ts` <!-- REF-OBSOLETA: src/feedback/ no existe; feedback migrado a Nexus -->                                       |

<!-- REF-OBSOLETA: src/feedback/feedback-collector.ts no existe (ruta migrada o eliminada) -->

| **Feedback Analyzer** | `src/feedback/feedback-analyzer.ts`
<!-- REF-OBSOLETA: src/feedback/ no existe; feedback migrado a Nexus --> |
<!-- REF-OBSOLETA: src/feedback/feedback-analyzer.ts no existe (ruta migrada o eliminada) -->

| **Digest Generator** | `src/digest-generator.ts` | | **NORMATIVAS-FEEDBACK** |
`rules/NORMATIVAS-FEEDBACK.md` <!-- REF-OBSOLETA: rules/NORMATIVAS-FEEDBACK.md no existe --> | |
**Release Automation** | `src/deployment/release-automation.ts`
<!-- REF-OBSOLETA: src/deployment/ no existe; candidato: src/deployment/validate-release-homologation.ts (ausente también) -->

|
<!-- REF-OBSOLETA: src/deployment/release-automation.ts no existe (ruta migrada o eliminada) -->
<!-- REF-OBSOLETA: src/deployment/validate-release-homologation.ts no existe (ruta migrada o eliminada) -->

| **NORMATIVAS-RELEASE** | `rules/NORMATIVAS-RELEASE.md`
<!-- REF-OBSOLETA: rules/NORMATIVAS-RELEASE.md no existe --> | | **Fine-Tuning Pipeline** |

`src/fine-tuning/ft-pipeline.ts`
<!-- REF-OBSOLETA: src/fine-tuning/ no existe; solo protected/scripts/utilities/FINE-TUNING/*.ps1.enc -->

|
<!-- REF-OBSOLETA: src/fine-tuning/ft-pipeline.ts no existe (ruta migrada o eliminada) -->

| **FT Trainer** | `src/fine-tuning/ft-trainer.ts` <!-- REF-OBSOLETA: src/fine-tuning/ no existe -->
|
<!-- REF-OBSOLETA: src/fine-tuning/ft-trainer.ts no existe (ruta migrada o eliminada) -->

| **FT Status** | `src/fine-tuning/ft-status.ts` <!-- REF-OBSOLETA: src/fine-tuning/ no existe --> |
<!-- REF-OBSOLETA: src/fine-tuning/ft-status.ts no existe (ruta migrada o eliminada) -->

| **FT Threshold Detect** | `src/fine-tuning/ft-threshold-detect.ts`
<!-- REF-OBSOLETA: src/fine-tuning/ no existe --> |
<!-- REF-OBSOLETA: src/fine-tuning/ft-threshold-detect.ts no existe (ruta migrada o eliminada) -->

| **FT Auto-Prune** | `src/fine-tuning/ft-auto-prune.ts`
<!-- REF-OBSOLETA: src/fine-tuning/ no existe --> |
<!-- REF-OBSOLETA: src/fine-tuning/ft-auto-prune.ts no existe (ruta migrada o eliminada) -->

| **FT Registry** | `.ft/registry.json` |
