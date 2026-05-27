<p align="center">
  <img src="docs/brand/assets/banner-github.svg" alt="Gentle-Vanguard" width="100%"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-2.23.0-00BFFF?style=flat-square&labelColor=0D1117" alt="Version">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-22C55E?style=flat-square&labelColor=0D1117" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-4DCFFF?style=flat-square&labelColor=0D1117" alt="License">
  <img src="https://img.shields.io/badge/PowerShell-7+-A855F7?style=flat-square&labelColor=0D1117" alt="PowerShell">
  <img src="https://img.shields.io/badge/Agents-18-00BFFF?style=flat-square&labelColor=0D1117" alt="Agents">
  <img src="https://img.shields.io/badge/Skills-135-4DCFFF?style=flat-square&labelColor=0D1117" alt="Skills">
  <img src="https://img.shields.io/badge/Workflows-16-A855F7?style=flat-square&labelColor=0D1117" alt="Workflows">
</p>

<p align="center">
  <a href="docs/AGENTS.md">Bootstrap</a> &nbsp;·&nbsp;
  <a href="docs/AGENTS.md#mandatory-startup-sequence">Startup</a> &nbsp;·&nbsp;
  <a href="docs/QUICK-COMMANDS.md">Quick Commands</a> &nbsp;·&nbsp;
  <a href="rules/DELEGATION-RULES.md">Delegation Rules</a> &nbsp;·&nbsp;
  <a href="rules/NORMATIVES.md">Normatives</a> &nbsp;·&nbsp;
  <a href="CHANGELOG.md">Changelog</a>
</p>

<p align="center">
  <strong>AI-powered development orchestrator · 18 agents · 135 skills · 10 tool-compatible</strong><br>
  <em>Tool-agnostic · SDD Lifecycle · Hashline · Team Mode · Skill MCPs · Persistent memory</em>
</p>

> _"Construyendo el puente definitivo entre la alta ingeniería de software y la estrategia
> corporativa."_ — [Read the Manifesto](MANIFESTO.md)

---

## What is Gentle-Vanguard?

Gentle-Vanguard is an AI orchestration layer built on top of any coding tool (OpenCode, Claude Code,
Cline, Cursor, Windsurf, Codex, Copilot). It gives structure, memory, and governance to what would
otherwise be chaotic AI-assisted development.

- **Routes work** through `pre-process-input.ps1` → trigger matching → agent dispatch (inline,
  delegate, or SDD)
- **18 specialized agents** each with a narrow role, a model profile, and delegation rules
- **135 On-Demand Skills** — Angular, React, Next.js, Go, Django, Python, TypeScript, Docker, K8s,
  Playwright, Security, API Design — zero memory until triggered
- **Persists memory** via Engram — decisions, bugs, and patterns across sessions with hot/warm/cold
  tiers
- **Cost-aware model router** assigns fast/cheap, strong-reasoning, or strong-coding profiles per
  agent
- **Enforces SDD lifecycle** (BA → SAD → DEV → QA) on ambiguous or architectural work
- **Governance-first** — 7D validation, judgment-day adversarial review, pre-commit hooks, 16 CI/CD
  workflows
- **Hashline** — SHA-256 per-line integrity for 400+ tracked files across 15+ extensions. Snapshot
  on post-commit via lefthook + pre-compact via hook. Detect unintended edits before they propagate
- **Team Mode** — Leader-follower orchestration with up to 8 members. Broadcast, assign, report,
  collect cycle. Built on top of the existing dispatch agent system
- **Skill MCPs** — On-demand Model Context Protocol servers launched from SKILL.md frontmatter.
  Register, start, stop, list via dedicated manager. Zero-churn lifecycle

```mermaid
flowchart TB
    YOU[You / CLI / IDE]
    YOU -->|request| PP[pre-process-input.ps1]
    PP --> ORC[Orchestrator]

    ORC -->|small| INLINE[Inline work]
    ORC -->|complex| DELEGATE{Delegation Rules}
    DELEGATE -->|4+ files| SCOUT[scout / context-builder]
    DELEGATE -->|2+ files| WORKER[worker + reviewer]
    DELEGATE -->|architecture/risk| SDD[SDD Lifecycle]

    SDD --> BA[BA - Explore]
    SDD --> SAD[SAD - Design]
    SDD --> DEV[DEV - Apply]
    SDD --> QA[QA - Verify]

    BA --> SKILLS[135 Skills]
    DEV --> SKILLS
    QA --> SKILLS

    SKILLS --> MEM[Engram Memory]
```

---

## Architecture

### Work Routing Ladder

```mermaid
flowchart LR
    T[Task arrives] --> Q1{Small + mechanical?}
    Q1 -->|yes| INLINE[1. Inline Direct]
    Q1 -->|no| Q2{2+ files or context-heavy?}
    Q2 -->|no| INLINE
    Q2 -->|yes| Q3{Ambiguous / architectural?}
    Q3 -->|no| SIMPLE[2. Simple Delegation\nscout → worker → reviewer]
    Q3 -->|yes| SDD3[3. SDD Lifecycle\nBA → SAD → DEV → QA]
```

### Delegation Rules

| #   | Rule                      | Trigger                                     | Action                              |
| --- | ------------------------- | ------------------------------------------- | ----------------------------------- |
| 1   | **4-file rule**           | Understanding requires reading 4+ files     | Launch `scout` with fresh context   |
| 2   | **Multi-file write rule** | Implementation touches 2+ non-trivial files | Use one `worker` + fresh `reviewer` |
| 3   | **PR rule**               | Before commit/push/PR for code changes      | Run fresh-context `reviewer`        |
| 4   | **Incident rule**         | Wrong cwd, git mutation, failed merge       | Stop and run fresh audit `reviewer` |
| 5   | **Long-session rule**     | ~20 tool calls or 5 exploratory reads       | Pause and delegate                  |
| 6   | **Fresh review rule**     | Adversarial review of diffs or PR readiness | Use `context: "fresh"` reviewer     |

### Model Routing per Agent

```mermaid
flowchart LR
    ORCH[Orchestrator\ninherit] --> FAST[fast / cheap\nBA · DOC · OPS · SESSION\nMKT · SALES · HR · BUS-TELE\nSELF-DIAG · GITFLOW]
    ORCH --> REASON[strong-reasoning\nSAD · PREMORTEM · FINANCE]
    ORCH --> CODING[strong-coding\nDEV]
    ORCH --> REVIEW[strong-review\nQA · GOV · LEGAL]
```

### 5-Layer Architecture

| Layer              | Role                  | Components                                                            | Config                                        |
| ------------------ | --------------------- | --------------------------------------------------------------------- | --------------------------------------------- |
| **1. Agents**      | Task delegation       | 1 orchestrator + 17 sub-agents                                        | `config/auto-delegation.json`                 |
| **2. Commands**    | CLI entry points      | `gv.ps1`, `pre-process-input.ps1`                                     | `config/orchestrator.json`                    |
| **3. MCP Servers** | Protocol bridge       | Engram MCP, CodeGraph | `opencode.json#mcp` |
| **4. Skills**      | Specialized execution | 135 skills across 10 categories                                       | `config/skill-dependencies.json`              |
| **5. Memory**      | Persistent context    | Engram (hot/warm/cold tiers)                                          | `config/engram-config.json`                   |

---

## Agent Ecosystem

| Agent            | Role                    | Model Profile    | Delegates to   |
| ---------------- | ----------------------- | ---------------- | -------------- |
| Orchestrator     | Main router             | inherit          | All sub-agents |
| BA (sdd-explore) | Requirements & analysis | fast/cheap       | SAD, skills    |
| SAD (sdd-design) | System design           | strong-reasoning | DEV            |
| DEV (sdd-apply)  | Code generation         | strong-coding    | QA, reviewer   |
| QA (sdd-verify)  | Testing & validation    | strong-review    | DEV (feedback) |
| OPS              | Deployment & CI/CD      | fast/cheap       | —              |
| DOC              | Technical docs          | fast/cheap       | —              |
| GOV              | Compliance & audit      | strong-review    | —              |
| SESSION          | Session management      | fast/cheap       | —              |
| PREMORTEM        | Risk assessment         | strong-reasoning | SAD            |
| FINANCE          | Financial modeling      | strong-reasoning | —              |
| LEGAL            | Regulatory compliance   | strong-review    | —              |
| MKT              | Marketing & SEO         | fast/cheap       | —              |
| SALES            | Pipeline management     | fast/cheap       | —              |
| HR               | Talent acquisition      | fast/cheap       | —              |
| SELF-DIAG        | Self-diagnosis          | fast/cheap       | ORC            |
| BUS-TELE         | Business telemetry      | fast/cheap       | —              |
| CODEGRAPH        | Code analysis           | fast/cheap       | —              |

> All sub-agents are `hidden: true` — only the Orchestrator is user-selectable. Sub-agents are
> managed autonomously via `config/auto-delegation.json`.

---

### Session Context Logging

Every agent response is tracked for token consumption, context size, and cost estimation:

```mermaid
flowchart LR
    AGT[Agent Response] -->|post-response hook| TUA[token-usage-auto.ps1]
    TUA --> TUN[token-usage-notifier.ps1\nDisplay tokens]
    TUA --> SCL[session-context-log.ps1\nLog context]
    SCL --> TEMP[.session/context-log/&lt;sid&gt;/\nTemp .md files per turn]
    SCL -->|-PromoteToPermanent| PERM[.local/session-artifacts/\nPermanent local storage]
```

| Component                 | Location                      | Purpose                                                   |
| ------------------------- | ----------------------------- | --------------------------------------------------------- |
| `session-context-log.ps1` | `scripts/utilities/`          | **Permanent** — Init, log, close, status, reinit          |
| `token-usage-auto.ps1`    | `scripts/utilities/`          | **Permanent** — Integrates notifier + context logger      |
| `context-summary.md`      | `.session/context-log/<sid>/` | **Temp** — Full session log (gitignored)                  |
| `turn-NNN.md`             | `.session/context-log/<sid>/` | **Temp** — Per-turn detail (gitignored)                   |
| `context-log-<sid>/`      | `.local/session-artifacts/`   | **Permanent local** — Promoted with `-PromoteToPermanent` |

**Usage** (called automatically by the agent after every response):

```powershell
pwsh -NoProfile -File scripts/utilities/token-usage-auto.ps1 `
  -InputTokens <N> -OutputTokens <N> -ContextChars <N> `
  -InputSummary "<user intent>" -OutputSummary "<response>" `
  -TurnLabel "<task>"
```

At session close:

```powershell
pwsh -NoProfile -File scripts/utilities/session-context-log.ps1 -Action close
# Or with permanent promotion:
pwsh -NoProfile -File scripts/utilities/session-context-log.ps1 -Action close -PromoteToPermanent
```

Config references: `docs/AGENTS.md#post-response-context-logging-rule`, `CLAUDE.md` rules #14-#15.

---

### Token Notification Auto-Hook (Every Turn)

Automatic token consumption display that fires every turn without agent intervention:

```mermaid
flowchart LR
    TURN[Every turn start] -->|pre-process-input.ps1| AUTO[token-usage-notifier.ps1\n-Action auto]
    AUTO --> ACCUM[Show-AccumulatedMetrics\nSession totals]
    USER[User /notif command] -->|pre-process-input.ps1| TOGGLE[toggle-token-display.ps1]
    TOGGLE --> CFG[.session/token-display-config.json]
    CFG --> AUTO
```

| Command                     | Effect                                        |
| --------------------------- | --------------------------------------------- |
| `/notif on` / `/notif off`  | Master toggle (persists across sessions)      |
| `/notif status`             | Show current state of all notification types  |
| `/notif token on/off`       | Toggle token display (input/output per turn)  |
| `/notif context on/off`     | Toggle context character count display        |
| `/notif cost on/off`        | Toggle cost estimation display                |
| `/notif accumulated on/off` | Toggle session accumulated totals display     |
| `/notif compact on/off`     | Switch between compact box and verbose format |

**Components:**

| Component                   | Location             | Purpose                                                                                                                                               |
| --------------------------- | -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `token-usage-notifier.ps1`  | `scripts/utilities/` | Core display: per-turn metrics, accumulated session totals, status, auto-hook, cost estimation with per-model rates from `config/provider-costs.json` |
| `toggle-token-display.ps1`  | `scripts/utilities/` | Toggle handler: on/off/status per type, persistent state via `.session/token-display-config.json`                                                     |
| `pre-process-input.ps1`     | `scripts/utilities/` | Auto-hook: calls notifier with `-Action auto` at end of every turn                                                                                    |
| `token-usage-auto.ps1`      | `scripts/utilities/` | Post-response bridge: integrates notifier + context logger                                                                                            |
| `token-display-config.json` | `.session/`          | Persisted state: enabled, individualToggles (token/context/cost/accumulated), compactMode                                                             |

Config references: `docs/AGENTS.md#token-notification-auto-hook-–-every-turn`, `CLAUDE.md` rule #6.

---

## Key Capabilities

### SDD / OpenSpec Lifecycle

Spec-Driven Development enforces a 4-phase lifecycle for ambiguous, architectural, or cross-cutting
work.

```mermaid
flowchart LR
    BA[BA\nExplore] -->|openspec| SAD[SAD\nDesign]
    SAD -->|spec approved| DEV[DEV\nApply]
    DEV -->|impl done| QA[QA\nVerify]
    QA -->|gates pass| PR[PR + Review]
```

Config: `openspec/config.yaml` — strict TDD, per-phase gates, testing layers, skip rules.

### SDD Preflight

Run once per session before the first SDD flow:

| Setting        | Options                        | Default       |
| -------------- | ------------------------------ | ------------- |
| Mode           | `interactive` / `auto`         | `interactive` |
| Artifact store | `openspec` / `engram` / `both` | `both`        |
| PR strategy    | `single` / `chained`           | `chained`     |
| Review budget  | lines per PR                   | 400           |

```powershell
.\scripts\utilities\sdd-preflight.ps1 -Interactive
```

### Review Workload Guard

Before any `sdd-apply` phase or multi-file implementation:

```powershell
.\scripts\utilities\review-workload-guard.ps1
```

Blocks PRs exceeding 400 changed lines. Recommends chained PRs (see `skills/chained-pr/SKILL.md`).
Cognitive research shows review quality drops sharply above this threshold.

### Skill Registry

135 skills auto-indexed at session start. Registry is rebuilt on install/removal:

```powershell
.\scripts\utilities\build-skill-registry.ps1
```

Authoritative index: `.atl/skill-registry.md`

### Chain-Delivery Skills

For large features that exceed the 400-line review budget, use chained PR delivery:

- `skills/chained-pr/SKILL.md` — planning and splitting
- `skills/branch-pr/SKILL.md` — branch + PR workflow
- `skills/gitflow-orchestrator-skill/SKILL.md` — full gitflow

### Context Optimization (v2.22.0)

Comprehensive input/token efficiency overhaul:

| Area                         | Before          | After                                                                                               |
| ---------------------------- | --------------- | --------------------------------------------------------------------------------------------------- |
| CLAUDE.md                    | 220 lines       | 47 lines (−79%)                                                                                     |
| AGENTS.md                    | 311 lines       | 78 lines (−75%)                                                                                     |
| NORMATIVES.md                | 1,506 lines     | 120 lines (−92%)                                                                                    |
| INTER-AGENT-COMMUNICATION.md | 167 lines       | 54 lines (−68%)                                                                                     |
| 10 oversized SKILL.md files  | ~5,200 lines    | ~1,420 lines (−73%)                                                                                 |
| auto-delegation.json         | 105 BA keywords | 80 (−24%)                                                                                           |
| pre-process cache            | None            | SHA256 (132 skills, zero rescan)                                                                    |
| Output guard                 | None            | 200 tokens non-code                                                                                 |
| Token notification auto-hook | Manual `/notif` | Automatic every turn via pre-process-input.ps1, persistent toggles, cost from `provider-costs.json` |

Integrated via `opencode.json` sliding window, `pre-compact-hook.ps1` ratio 0.60,
`context-efficiency.json` input guard, and `token-display-config.json` interval display.

### Cross-Tool Compatibility

Compatible with 10 tools via `scripts/utilities/detect-tool.ps1`:

| Tool             | Config File                       | Response Profile |
| ---------------- | --------------------------------- | ---------------- |
| OpenCode         | `opencode.json`                   | ultra            |
| Claude Code      | `.claude/settings.json`           | ultra            |
| Cline            | `.clinerules`                     | ultra            |
| Cursor           | `.cursorrules`                    | ultra            |
| Windsurf         | `.windsurf/`                      | ultra            |
| Codex            | `.codex/`                         | standard         |
| Copilot          | `.github/copilot-instructions.md` | standard         |
| Antigravity      | `.antigravity/`                   | standard         |
| Continue.dev     | `.continue/`                      | standard         |
| Claude (generic) | `CLAUDE.md`                       | ultra            |

---

## Quick Start

```powershell
# 1. Clone
git clone https://github.com/EmmanuelOrtiz87/gentle-vanguard.git
cd gentle-vanguard

# 2. Start session (activates notifications, security, engram, token guard)
.\scripts\utilities\session-autostart.cmd

# 3. Verify workspace
gv health

# 4. SDD preflight (before first SDD flow)
.\scripts\utilities\sdd-preflight.ps1 -Interactive

# 5. Review workload guard (before multi-file work)
.\scripts\utilities\review-workload-guard.ps1
```

---

## Development

| Command                                                  | Purpose                           |
| -------------------------------------------------------- | --------------------------------- |
| `gv verify`                                              | Run all quality gates             |
| `gv judgment-day`                                        | Full adversarial review           |
| `gv dashboard`                                           | Open HTML metrics dashboard       |
| `gv benchmark`                                           | SLO benchmark of key commands     |
| `gv version`                                             | Show stack version + skills count |
| `pwsh -File tests/run-tests.ps1`                         | Run full test suite               |
| `Invoke-Pester -Path tests/ -Output Detailed`            | Run Pester unit tests             |
| `pwsh -File scripts/utilities/build-skill-registry.ps1`  | Rebuild skill registry            |
| `pwsh -File scripts/utilities/security-audit.ps1`        | Run security audit                |
| `pwsh -File scripts/utilities/validate-readme.ps1`       | Validate README structure         |
| `pwsh -File scripts/utilities/review-workload-guard.ps1` | Estimate PR review workload       |
| `pwsh -File scripts/utilities/sdd-preflight.ps1`         | Configure SDD session             |
| `npm run format`                                         | Run Prettier formatting           |
| `Invoke-PSScriptAnalyzer -Path scripts/ -Recurse`        | PSScriptAnalyzer lint             |

---

## CI/CD Pipeline (16 Workflows)

| Workflow                           | Purpose                          | Trigger              |
| ---------------------------------- | -------------------------------- | -------------------- |
| `gentle-vanguard-quality-gate.yml` | Quality gates on PRs             | Every PR             |
| `test-suite.yml`                   | Full test suite                  | Every PR/push        |
| `ps-lint.yml`                      | PSScriptAnalyzer lint            | Every PR             |
| `sdd-gate.yml`                     | Block PRs without SDD            | Every PR             |
| `script-governance.yml`            | Script compliance                | Every PR             |
| `format-check.yml`                 | Prettier formatting              | Every PR             |
| `gitleaks.yml`                     | Secret scanning                  | Every PR             |
| `security-scan.yml`                | OWASP security scanning          | Weekly               |
| `autonomous-validation.yml`        | Full validation suite            | Weekly               |
| `cross-platform-tests.yml`         | Cross-platform tests             | Every PR/push        |
| `dashboard-auto-refresh.yml`       | Metrics dashboard                | Daily                |
| `monthly-management-report.yml`    | Executive report                 | Monthly              |
| `release.yml`                      | Release management               | On tag               |
| `labeler.yml`                      | Auto-label PRs                   | Every PR             |
| `sync-public.yml`                  | Sync to `gentle-vanguard-public` | On push to `main`    |
| `workflow-lint.yml`                | Workflow syntax validation       | On `.github/` change |

---

## Project Status

| Gate          | Status  | Detail                                                                                                  |
| ------------- | ------- | ------------------------------------------------------------------------------------------------------- |
| Configuration | ✅ PASS | `orchestrator.json`, `auto-delegation.json`, `model-routing.json` valid                                 |
| Skills        | ✅ PASS | 135 skills indexed, registry current                                                                    |
| Tests         | ✅ PASS | Full test suite passing                                                                                 |
| Hooks         | ✅ PASS | Pre-commit hooks active (README, secrets, lint)                                                         |
| Context Log   | ✅ PASS | Session context logging active — tokens, cost, input/output per turn                                    |
| Context Opt   | ✅ PASS | SHA256 cache, input guard, output guard, 73% avg file compression                                       |
| Token Notif   | ✅ PASS | Auto-hook every turn, 6 toggle types, persistent config, cost from `provider-costs.json`                |
| Security      | ✅ PASS | 98 tests pass, injection/jailbreak detection active, AES-256 secrets                                    |
| Structure     | ✅ PASS | All mandatory files present                                                                             |
| Engram        | ✅ PASS | Memory store accessible, sessions tracking                                                              |
| SDD           | ✅ PASS | OpenSpec config valid, preflight operational                                                            |
| Hashline      | ✅ PASS | 411 files, 83,214 SHA-256 hashes, post-commit snapshot + pre-compact hook                               |
| Team Mode     | ✅ PASS | Leader-follower with up to 8 members, full cycle (start→assign→report→collect→stop) tested              |
| Skill MCPs    | ✅ PASS | 6 actions (register, start, stop, list, status, deregister), SKILL.md frontmatter parsing, cycle tested |

---

## Key Documentation

| Resource                   | Path                                                                 |
| -------------------------- | -------------------------------------------------------------------- |
| **Agent Bootstrap**        | [docs/AGENTS.md](docs/AGENTS.md)                                     |
| **Context Logging**        | [docs/AGENTS.md#post-response-context-logging-rule](docs/AGENTS.md)  |
| **Architecture Overview**  | [docs/architecture/README.md](docs/architecture/README.md)           |
| **Delegation Rules**       | [rules/DELEGATION-RULES.md](rules/DELEGATION-RULES.md)               |
| **Model Routing**          | [config/model-routing.json](config/model-routing.json)               |
| **SDD Config**             | [openspec/config.yaml](openspec/config.yaml)                         |
| **Skill Registry**         | [.atl/skill-registry.md](.atl/skill-registry.md)                     |
| **README Governance**      | [rules/README-GOVERNANCE.md](rules/README-GOVERNANCE.md)             |
| **Quick Commands**         | [docs/QUICK-COMMANDS.md](docs/QUICK-COMMANDS.md)                     |
| **Security Normative**     | [docs/NORMATIVAS-SEGURIDAD.md](docs/NORMATIVAS-SEGURIDAD.md)         |
| **Architecture Normative** | [rules/NORMATIVAS-ARCHITECTURE.md](rules/NORMATIVAS-ARCHITECTURE.md) |
| **Config Normative**       | [rules/NORMATIVAS-CONFIG.md](rules/NORMATIVAS-CONFIG.md)             |
| **DevOps Normative**       | [rules/NORMATIVAS-DEVOPS.md](rules/NORMATIVAS-DEVOPS.md)             |
| **Docs Normative**         | [rules/NORMATIVAS-DOCS.md](rules/NORMATIVAS-DOCS.md)                 |
| **Enforcement Normative**  | [rules/NORMATIVAS-ENFORCEMENT.md](rules/NORMATIVAS-ENFORCEMENT.md)   |
| **Git Normative**          | [rules/NORMATIVAS-GIT.md](rules/NORMATIVAS-GIT.md)                   |
| **Build Pipeline**         | [docs/build/README.md](build/README.md)                              |
| **Contributing**           | [CONTRIBUTING.md](CONTRIBUTING.md)                                   |
| **Changelog**              | [CHANGELOG.md](CHANGELOG.md)                                         |

---

## Security

| Layer                    | Protection                                                                                                                          | Implementation                                                       |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Prompt Injection**     | 10 detection patterns (instruction-override, jailbreak, leakage, code-exec, role-takeover, encoding-obfuscation, constraint-bypass) | `privacy-gateway.ps1` — blocks CRITICAL before agent processes input |
| **Jailbreak Prevention** | DAN, unrestricted-mode, developer-mode, simulation attacks                                                                          | `security-orchestrator.ps1` — expanded `$CRITICAL_PATTERNS`          |
| **Data Leakage**         | PII redaction, IP masking, home path sanitization                                                                                   | `privacy-sanitizer.ps1` + `security-logger.ps1`                      |
| **Secrets Management**   | AES-256 encryption, DPAPI vault, RBAC, automated rotation                                                                           | `secrets-manager.ps1` v2.0 + `secret-vault.ps1`                      |
| **Supply Chain**         | SBOM CycloneDX generation, npm hardening (ignore-scripts, min-release-age), Trivy scanning                                          | `.npmrc` + `sbom-validate.ps1` + CI/CD                               |
| **Auth & Access**        | Rate-limited auth with lockout, session-based, DPAPI-encrypted                                                                      | `secure-auth.ps1` + `security-orchestrator.ps1`                      |

**98 security tests** — injection detection, PII redaction, secrets vault, SBOM validation,
encryption.

See [SECURITY.md](SECURITY.md), [docs/NORMATIVAS-SEGURIDAD.md](docs/NORMATIVAS-SEGURIDAD.md) (OWASP
LLM Top 10 + OWASP Agentic Top 10).

---

## License

[MIT](LICENSE)

---

<p align="center">
  <strong>Gentle-Vanguard v2.23.0</strong><br>
  <em>Local-First · Total Privacy · Production Ready</em>
</p>
