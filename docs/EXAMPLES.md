# 🏗️ Foundation AI Development Stack — Real-World Examples

> **29 agents · 132 skills · CLI `wf` · auto-delegation · Engram memory · 7D pre-commit hooks**

---

## 1. Build a REST API in Go (Spec → Deployed API)

**User input:**
```
wf start-session && wf task-brief "Build a Go REST API for user management with JWT auth"
```

**What happens:**

| Step | Agent | Skill | Action |
|------|-------|-------|--------|
| 1 | ORCHESTRATOR | `project-orchestrator-skill` | Pre-processes input, routes to BA (confidence < 60%) |
| 2 | BA | `sdd-lifecycle` (EXPLORE) | Asks: CRUD ops? DB? Auth? Deploy target? |
| 3 | SAD | `api-design-skill`, `database-relational-skill` | Produces OpenAPI spec + DB schema + ADR in `docs/sdd/` |
| 4 | DEV | `golang-api-skill`, `typescript-skill` | Generates handlers, models, middleware, tests |
| 5 | QA | `testing-skill`, `go-testing` | Runs `go test ./...`, validates coverage ≥ 80% |
| 6 | GOV | `security-skill` | Scans for secrets, JWT hardcoding, SQL injection |
| 7 | OPS | `docker-devops-skill` | Creates Dockerfile, docker-compose, CI pipeline |
| 8 | SESSION-CLOSE | `project-orchestrator-skill` | Persists architecture decisions to Engram |

**🔄 Auto:** Agent routing, skill loading, spec generation, basic CRUD scaffold, test execution  
**👤 Manual:** Answer BA exploration questions (3–5), review ADR tradeoffs, set env vars  
**✅ Output:** `main.go`, `go.mod`, OpenAPI `docs/specs/user-api.yaml`, Dockerfile, CI workflow, passing tests

---

## 2. Add Authentication to a React App

**User input:**
```
Add JWT auth with login/signup to the React frontend
```

**What happens:**

| Step | Agent | Skill | Action |
|------|-------|-------|--------|
| 1 | ORCHESTRATOR | `project-orchestrator-skill` | Detects React project, routes to DEV |
| 2 | BA | `sdd-lifecycle` (EXPLORE) | Quick 2-question: auth provider? token storage? |
| 3 | SAD | `api-design-skill` | Documents auth flow: login → JWT → protected routes |
| 4 | DEV | `react-19-skill`, `zod-4-skill` | Creates `AuthContext`, `useAuth` hook, login/signup pages, form validation |
| 5 | QA | `playwright-skill` | E2E: login flow, token expiry, protected route redirect |
| 6 | GOV | `security-skill` | Checks: httpOnly flag, CSP headers, no token in localStorage |
| 7 | QAt-GITFLOW | `git-workflow-skill` | Creates `feature/auth-jwt` branch, conventional commits |

**🔄 Auto:** Auth context scaffold, form validation schemas, E2E test skeleton, branch creation  
**👤 Manual:** Configure JWT secret via env, set auth provider URL, review route protection list  
**✅ Output:** `AuthContext.tsx`, `useAuth.ts`, `LoginPage.tsx`, `SignupPage.tsx`, `auth.e2e.ts`, protected route wrappers

---

## 3. Run a Security Audit on the Codebase

**User input:**
```
wf judgment-day --security
```

**What happens:**

| Step | Agent | Skill | Action |
|------|-------|-------|--------|
| 1 | ORCHESTRATOR | `project-orchestrator-skill` | Triggers full judgment-day workflow |
| 2 | GOV | `judgment-day`, `security-skill` | Launches 7D quality gates: secrets, gitflow, architecture, API, docs, testing, quality |
| 3 | QA | `security-pentester` | Scans for OWASP Top 10, dependency CVEs, SQL injection patterns |
| 4 | SAD | `context-engineering-skill` | Reviews architecture for security anti-patterns |
| 5 | DEV (SCRIPT-GOV) | `script-governance-skill` | Validates all `.ps1`/`.sh` scripts for shell injection risks |
| 6 | GOV | `quality-skill` | Generates `docs/audits/security-audit-YYYY-MM-DD.md` with findings |
| 7 | REPORT | `reporting-skill` | Produces executive summary: severity counts, fix recommendations |

**🔄 Auto:** All 14 quality gates, secret scanning, dependency audit, script validation, report generation  
**👤 Manual:** Review findings for false positives, prioritize fixes, apply patches  
**✅ Output:** `docs/audits/security-audit-*.md` with `CRITICAL/HIGH/MEDIUM/LOW` breakdown, CVE list, remediation steps

---

## 4. Release a New Version (v2.7.0)

**User input:**
```
wf release v2.7.0
```

**What happens:**

| Step | Agent | Skill | Action |
|------|-------|-------|--------|
| 1 | ORCHESTRATOR | `project-orchestrator-skill` | Detects `release` keyword, routes to OPS |
| 2 | OPS | `release-management-skill` | Validates semver impact since v2.6.5 |
| 3 | GOV | `quality-gates.json` | Runs all 5 required checks (script-governance, workflow-lint, quality-gate, ps-lint, sdd-gate) |
| 4 | QA | `testing-skill` | Runs full test suite, validates coverage |
| 5 | DOC | `documentation-governance` | Checks CHANGELOG.md is updated, `VERSION` file bumped |
| 6 | OPS | `release-management-skill` | Cuts `release/v2.7.0` branch, tags, generates release notes |
| 7 | GOV | `judgment-day` | Blocks if: rollback plan missing, CHANGELOG stale, QA gates failing |

**🔄 Auto:** Semver validation, CHANGELOG check, branch creation, tag, GitHub Release draft  
**👤 Manual:** Review release notes, approve PR, push tag, confirm deployment  
**✅ Output:** Git tag `v2.7.0`, GitHub Release, `CHANGELOG.md` updated, `docs/operations/release-v2.7.0.md`

---

## 5. Premortem a New Architecture Design

**User input:**
```
premortem my architecture in docs/sdd/payment-service-v2.md
```

**What happens:**

| Step | Agent | Skill | Action |
|------|-------|-------|--------|
| 1 | ORCHESTRATOR | `project-orchestrator-skill` | Detects `premortem` keyword, routes to PREMORTEM |
| 2 | PREMORTEM | `premortem-skill` | Reads the design doc, generates 8–12 failure scenarios |
| 3 | SAD | `context-engineering-skill` | Cross-references failure modes against actual architecture decisions |
| 4 | PREMORTEM | `premortem-skill` | Produces `docs/premortems/payment-service-v2-premortem.md` |
| 5 | GOV | `quality-skill` | Validates: each scenario has likelihood + impact + mitigation |
| 6 | SESSION | `session-workflow-skill` | Saves findings to Engram for future reference |

**📋 Failure scenario example:**
> **Scenario:** Payment provider API changes contract without notice  
> **Likelihood:** Medium · **Impact:** Critical  
> **Mitigation:** Add adapter layer with circuit breaker, integration test with mock provider  
> **Blind spot detected:** No retry strategy documented for 5xx responses

**🔄 Auto:** Full premortem report with scored scenarios, blind spot detection  
**👤 Manual:** Review and accept/adapt mitigations, update design doc  
**✅ Output:** `docs/premortems/payment-service-v2-premortem.md` with 10+ scenarios, risk matrix, action items

---

## 6. Weekly Project Health Dashboard

**User input:**
```
wf dashboard --weekly
```

**What happens:**

| Step | Agent | Skill | Action |
|------|-------|-------|--------|
| 1 | ORCHESTRATOR | `project-orchestrator-skill` | Routes to DOC + BUS-TELE |
| 2 | BUS-TELE | `business-telemetry-skill` | Aggregates: sessions logged, tokens consumed, commands run, agents used |
| 3 | GOV | `quality-skill` | Pulls quality gate pass/fail rates, judgment-day outcomes |
| 4 | REPORT | `reporting-skill` | Generates HTML dashboard with charts (session count, token trend, top agents) |
| 5 | DOC | `documentation-governance` | Writes `docs/reports/weekly-YYYY-MM-DD.md` |
| 6 | GOV | `project-orchestrator-skill` | Signs off: all metrics have source citations, no fabricated data |

**📊 Dashboard sections:**
| Section | Data |
|---------|------|
| Session activity | Sessions started, avg duration, most active agents |
| Token usage | Total consumed, trend vs previous week, budget health |
| Quality | Judgment-day pass rate, open findings, coverage delta |
| Git health | Branches created, PRs merged, merge conflict count |

**🔄 Auto:** Metric aggregation, HTML/PDF dashboard, executive summary  
**👤 Manual:** Interpret trends, decide actions for flagged items  
**✅ Output:** `docs/reports/weekly-YYYY-MM-DD.md`, `docs/reports/dashboard-weekly.html`

---

## 7. Resolve a Merge Conflict

**User input:**
```
resolve merge conflict in src/handlers/user.go
```

**What happens:**

| Step | Agent | Skill | Action |
|------|-------|-------|--------|
| 1 | ORCHESTRATOR | `project-orchestrator-skill` | Detects `conflict` keyword, routes to GITFLOW-CONFLICT |
| 2 | GITFLOW-CONFLICT | `git-workflow-skill` | Runs `git diff HEAD...develop -- src/handlers/user.go`, identifies conflict regions |
| 3 | DEV | — | Analyzes both versions, preserves meaning from both branches |
| 4 | QA | `testing-skill` | Runs `go test ./src/handlers/` after resolution |
| 5 | GOV | `script-governance-skill` | Validates no accidentally reverted changes or duplicated code |
| 6 | GITFLOW-MERGE | `sync-after-merge.ps1` | Post-merge sync: rebase downstream branches |

**🔄 Auto:** Conflict analysis, test execution, post-merge sync  
**👤 Manual:** Verify merged logic, accept/reject conflict resolution choices  
**✅ Output:** Clean merge commit, passing tests, synced downstream branches

---

## 8. Create a New Skill for the Stack

**User input:**
```
Create a skill for FastAPI patterns — trigger word "fastapi"
```

**What happens:**

| Step | Agent | Skill | Action |
|------|-------|-------|--------|
| 1 | ORCHESTRATOR | `project-orchestrator-skill` | Detects `create skill`, routes to GOV |
| 2 | GOV | `foundation-manager-skill` | Loads `skill-creator-skill` from `skills/skill-creator-skill/` |
| 3 | GOV | `skill-creator-skill` | Scaffolds `skills/fastapi-patterns/` with SKILL.md, example files |
| 4 | GOV | `skill-factory-skill` | Registers skill in `config/auto-delegation.json`: adds keyword mapping → `fastapi-patterns` |
| 5 | GOV | `sync-skills.ps1` | Runs skill registry sync, validates no duplicate triggers |
| 6 | DEV | — | Asks if you want to also create a DEV agent entry for the skill |

**📁 `skills/fastapi-patterns/SKILL.md`:**
```markdown
# FastAPI Patterns
**Trigger:** "fastapi", "fast api", "uvicorn"
**Stack:** Python 3.11+, Pydantic v2, SQLAlchemy 2.0
**Patterns:** Dependency injection, routers, background tasks, WebSocket
```

**🔄 Auto:** SKILL.md scaffold, `auto-delegation.json` registration, duplicate detection  
**👤 Manual:** Fill in detailed patterns and examples in SKILL.md, add agent profile if needed  
**✅ Output:** `skills/fastapi-patterns/SKILL.md`, updated `config/auto-delegation.json`, skill registry entry

---

## 9. Multi-Agent: Design, Build & Test a Microservice (Full SDD)

**User input:**
```
Build a notification microservice — sends email/SMS, tracks delivery status
```

**What happens:**

| Step | Agent | Skill | Action |
|------|-------|-------|--------|
| 1 | ORCHESTRATOR | `project-orchestrator-skill` | Pre-processes, detects complexity (multi-agent, multi-phase), activates adaptive mode |
| 2 | BA | `sdd-lifecycle` (EXPLORE) | 5-question drill: providers? retry? template engine? rate limits? observability? |
| 3 | SAD | `sdd-lifecycle` (DESIGN) | Produces: `docs/sdd/notification-service-v1/` with ADR, API spec, DB schema, sequence diagrams |
| 4 | SAD | `database-relational-skill` | Designs `notifications`, `templates`, `delivery_logs` tables |
| 5 | BA | `bdd-scenarios-skill` | Writes Gherkin: `Feature: Send notification`, `Feature: Retry failed delivery` |
| 6 | DEV | `golang-api-skill`, `mcp-skill` | Implements: HTTP handler, SMTP provider, SMS provider, retry worker |
| 7 | QA | `pytest-skill`, `testing-skill` | Unit tests + integration tests with MailHog + Twilio sandbox |
| 8 | GOV | `judgment-day` | Full 7D validation: architecture, API, gitflow, testing, docs, security, quality |
| 9 | OPS | `docker-devops-skill` | Dockerfile, docker-compose with MailHog, CI workflow |
| 10 | DOC | `documentation-governance` | README, API reference, runbook |
| 11 | SESSION-CLOSE | `project-orchestrator-skill` | Engram summary: architecture decisions, provider choices, failure modes |

**🔄 Auto:** Full SDD lifecycle, adaptive multi-agent orchestration, spec → code → test → docs  
**👤 Manual:** Choose email/SMS providers, set API keys, review retry policy tuning  
**✅ Output:** `docs/sdd/notification-service-v1/`, `internal/handler/`, `internal/provider/`, `docker-compose.yml`, `README.md`, passing test suite, CI pipeline

---

## 10. Daily Morning Check

**User input:**
```
wf daily
```

**What happens:**

| Step | Agent | Skill | Action |
|------|-------|-------|--------|
| 1 | ORCHESTRATOR | `project-orchestrator-skill` | Detects `daily` keyword, routes to DAILY agent |
| 2 | DAILY | `daily-workflow` | Runs `scripts/utilities/WORKFLOW-ORCHESTRATION/daily-check.ps1` |
| 3 | DAILY | `session-workflow-skill` | Checks: git status, branch hygiene, stale checkpoints (>7d), CI status |
| 4 | DAILY | `project-orchestrator-skill` | Validates: config integrity, skill registry health, foundation version |
| 5 | GOV | `quality-skill` | Context efficiency: prompt adoption %, avg chars, trend vs last week |
| 6 | SESSION | `session-workflow-skill` | Starts session `session-YYYY-MM-DD-NN` in Engram |
| 7 | DAILY | `daily-workflow` | Prints morning report: 5 sections with status indicators |

**📋 Morning report output:**
```
╔══════════════════════════════════════════════╗
║  ☀️ Daily Check — 2026-05-11                 ║
╠══════════════════════════════════════════════╣
║ ✅ Git: clean, branch feature/auth-jwt       ║
║ ✅ CI: last build passed (12m ago)            ║
║ ⚠ Checkpoints: 1 stale (>7d), consider drop  ║
║ ✅ Context: GREEN — 78% adoption, avg 890ch   ║
║ ✅ Skills: 132 registered, 0 conflicts         ║
║ ✅ Session started: session-2026-05-11-02     ║
╚══════════════════════════════════════════════╝
```

**🔄 Auto:** Git status, CI check, checkpoint age, context metrics, session start, version check  
**👤 Manual:** Review stale checkpoints, plan today's objective  
**✅ Output:** Console dashboard, Engram session initialized, `.session/` state files updated

---

## 📋 Quick Reference: Agent Activation by Keyword

| You type... | Agent activates | Skill loads |
|-------------|-----------------|-------------|
| "build an API" | SAD + DEV | `api-design-skill`, `golang-api-skill` |
| "add auth" | DEV + GOV | `react-19-skill`, `security-skill` |
| "security audit" | GOV + QA | `judgment-day`, `security-pentester` |
| "release vX.Y.Z" | OPS + GOV | `release-management-skill` |
| "premortem this" | PREMORTEM | `premortem-skill` |
| "dashboard / report" | BUS-TELE + REPORT | `business-telemetry-skill`, `reporting-skill` |
| "resolve conflict" | GITFLOW-CONFLICT | `git-workflow-skill` |
| "create skill" | GOV | `skill-creator-skill` |
| "daily / morning" | DAILY | `daily-workflow` |
| "close session" | SESSION-CLOSE + GOV | `project-orchestrator-skill` |
| "design microservice" | BA → SAD → DEV → QA → OPS | `sdd-lifecycle` (full chain) |

---

> **Prerequisite:** Always start with `wf start-session` (or `.\scripts\utilities\session-autostart.cmd`) to initialize Engram memory and routing context.
