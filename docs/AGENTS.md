# Workspace Agent Bootstrap (Agnostic)

Tool-agnostic startup for this workspace | Canonical entry point

## Tool Detection

Detect which AI tool is running BEFORE any other action:
```powershell
$detected = pwsh -NoProfile -File scripts/utilities/detect-tool.ps1 -AsJson | ConvertFrom-Json
$detected.name
$detected.os.platform
```
Detection order: OPENCODE_SERVER_USERNAME -> CLAUDE_VSCODE_VERSION -> .clinerules -> .cursorrules -> .windsurf/
Fallback: OpenCode. OS detection (windows/linux/macos) determines script extension (.cmd/.ps1 vs .sh).

Based on detection, load `config/orchestrator.json#toolProfiles.<name>`.

## Mandatory Startup Sequence

### Phase A — Init
0. `pre-process-input.ps1 -UserInput "<msg>" -WorkspaceRoot "."` BEFORE first response
1. Run `scripts/utilities/session-start-optimized.ps1` (autostart pipeline)
2. Read `scripts/.session/startup-summary.json`
3. `todowrite` — create task list
4. Report peak/off-peak, session ID, workspace state to user
5. `mem_search "lessons learned"` — load past learnings

### Phase B — Analysis
6. Verify workspace: `agent-verify.ps1` (SHOULD)
7. SDD Preflight: `sdd-preflight.ps1` before first SDD flow
8. Review Workload Guard: `review-workload-guard.ps1` before multi-file >400 lines

## Break Glass

If config prevents task completion (3+ turns, user complaint, loop, truncation):
1. `self-diagnosis.ps1 -CurrentProfile "<p>" -CurrentChatLevel "<l>" -TurnCount <N>`
2. Override to `lleno`/`chat-balanced`
3. Notify: `[BREAK GLASS] motivo: {reason}`

## Persona

Professional mode: ES/PT-BR/EN, no regional slang, formal tone, no persona switching.

## Routing

| Concept | Reference |
|---------|-----------|
| Trigger->skill mappings | `config/auto-delegation.json#keywordMappings` |
| Agent profiles + routing | `config/auto-delegation.json#agentProfiles` + `config/model-routing.json` |
| SDD config + strict TDD | `openspec/config.yaml` |
| Strict TDD enforcement | `rules/SDD-STRICT-TDD.md` |
| Per-phase model routing | `rules/PER-PHASE-MODEL-ROUTING.md` |
| Dependency automation | `renovate.json` (Renovate) + `.github/dependabot.yml` (Dependabot) |
| Pre-processing hook | `scripts/utilities/pre-process-input.ps1` |
| SDD FLOW | New feature -> BA/EXPLORE, no exceptions |
| Delegation Rules | `rules/DELEGATION-RULES.md` |

## Context Optimization

| Technique | Description |
|-----------|-------------|
| Memory tiering | Hot (active) -> Warm (1d, 90%) -> Cold (7d, 70%) |
| Handoff compression | `scripts/utilities/handoff-compress.ps1` |
| Pre-compact hook | `scripts/utilities/pre-compact-hook.ps1` |
| Response cache | `pre-process-input.ps1` — SHA256 cache, TTL 30min, -33-41% latency (flag `-DisableCache` to bypass) |
| Lazy autostart | `session-autostart.config.json` — 6 non-critical steps deferred post-pipeline |
| In-process pipeline | `session-start-optimized.ps1` — removed `Start-Job`, runs `&` directo in-process |

## Context Logging

Periodically (every 5 turns, per `token-display-config.json`), run:
```powershell
pwsh -NoProfile -File scripts/utilities/token-usage-auto.ps1 -InputTokens <N> -OutputTokens <N> -ContextChars <N> -InputSummary "<..." -OutputSummary "<...>" -TurnLabel "<...>"
```
Creates `.session/context-log/<session-id>/turn-NNN.md` and `context-summary.md`.
On close: `session-context-log.ps1 -Action close`.

## Quick Commands

See `docs/QUICK-COMMANDS.md` for full list.

## Key References

| Resource | Path |
|----------|------|
| Orchestrator config | `config/orchestrator.json` |
| Auto-delegation | `config/auto-delegation.json` |
| NORMATIVES (index) | `rules/NORMATIVES.md` (120 lines) |
| NORMATIVAS-ARCHITECTURE | `rules/NORMATIVAS-ARCHITECTURE.md` |
| NORMATIVAS-CONFIG | `rules/NORMATIVAS-CONFIG.md` |
| NORMATIVAS-DEVOPS | `rules/NORMATIVAS-DEVOPS.md` |
| NORMATIVAS-DOCS | `rules/NORMATIVAS-DOCS.md` |
| NORMATIVAS-ENFORCEMENT | `rules/NORMATIVAS-ENFORCEMENT.md` |
| NORMATIVAS-GIT | `rules/NORMATIVAS-GIT.md` |
| NORMATIVAS-CODIGO | `rules/NORMATIVAS-CODIGO.md` |
| NORMATIVAS-PERFORMANCE | `rules/NORMATIVAS-PERFORMANCE.md` |
| NORMATIVAS-SESSION | `rules/NORMATIVAS-SESSION.md` |
| NORMATIVAS-SOC2 | `rules/NORMATIVAS-SOC2.md` |
| AI normatives | `rules/AI-NORMATIVES.md` |
| Dev standards | `rules/DEVELOPMENT-STANDARDS.md` |
| Delegation rules | `rules/DELEGATION-RULES.md` |
| Model routing | `config/model-routing.json` |
| SDD config | `openspec/config.yaml` |
| Context engineering | `rules/CONTEXT-ENGINEERING.md` |
| CodeGraph skill | `skills/codegraph-skill/SKILL.md` |
| Quick commands | `docs/QUICK-COMMANDS.md` |
