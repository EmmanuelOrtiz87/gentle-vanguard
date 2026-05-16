# Learned Norms (Autonomous)

This file is **auto-maintained** by the adaptive learning system.

## Active Norms

### Documentation Placement

| ID      | Norm                                             | Confidence | Learned From      | Date       |
| ------- | ------------------------------------------------ | ---------- | ----------------- | ---------- |
| DOC-001 | Documentation in project root instead of docs/   | high       | auto-norm-learner | 2026-05-04 |
| DOC-002 | Scripts README.md must be in English, normalized | high       | manual            | 2026-05-04 |

### Auto-Correction

| ID       | Pattern                                                   | Confidence | Learned From      | Date       |
| -------- | --------------------------------------------------------- | ---------- | ----------------- | ---------- |
| CORR-001 | PowerShell TryParse() must be replaced with regex match   | high       | auto-norm-learner | 2026-05-04 |
| CORR-002 | Path references in gv.ps1 must use triple Split-Path      | high       | auto-norm-learner | 2026-05-04 |
| CORR-003 | repoRoot calculation must use Resolve-Path with Join-Path | high       | auto-norm-learner | 2026-05-04 |

### SESS-### (Session Patterns)

| ID       | Pattern                                     | Confidence | Learned From      | Date       |
| -------- | ------------------------------------------- | ---------- | ----------------- | ---------- |
| SESS-001 | Session files stored in .session/ directory | high       | auto-norm-learner | 2026-05-04 |
| SESS-002 | Session ID pattern: session-YYYY-MM-DD-XX   | high       | auto-norm-learner | 2026-05-04 |

## Normative Rules for New Creations

### Directory Structure Rules

1. **Scripts**: All PowerShell scripts must be in `scripts/utilities/` subdirectories
2. **Skills**: All skills must be in `skills/` with SKILL.md frontmatter
3. **Documentation**: All docs must be in `docs/` or subdirectory with README.md
4. **Config**: All config files must be in `config/` directory
5. **Hooks**: All git hooks must be in `hooks/` directory
6. **Rules**: All rules must be in `rules/` with README.md

### File Naming Rules

1. **PowerShell scripts**: Use kebab-case (e.g., `end-session.ps1`)
2. **Markdown files**: Use UPPER-CASE with hyphens (e.g., `SKILL.md`, `README.md`)
3. **Config files**: Use kebab-case (e.g., `orchestrator.json`)
4. **Session files**: Use pattern `session-YYYY-MM-DD-XXXXXX.json`

### Path Reference Rules

1. **repoRoot**: Always use `Split-Path (Split-Path (Split-Path $scriptDir))` for gv.ps1
2. **scriptDir**: Always use `Split-Path -Parent $MyInvocation.MyCommand.Path`
3. **Cross-references**: Use relative paths from repoRoot (e.g., `skills/`, `scripts/`)
4. **Never hardcode**: Never hardcode absolute paths in scripts

### Documentation Rules

1. **Language**: All documentation must be in English (except user content)
2. **Normalization**: No Spanish text in system files (hooks, scripts, README)
3. **References**: All links must be validated (no broken links)
4. **Frontmatter**: All SKILL.md must have YAML frontmatter

### Auto-Delegation Rules

1. **Orchestrator**: Active when `.orchestrator-active` file exists
2. **Skill loading**: Automatic based on file type (angular, react, go, etc.)
3. **Delegation**: Use `gv.ps1 agent <AGENT> <TASK>` for complex tasks
4. **Fallback**: If orchestrator inactive, use manual skill loading

### Auto-Learning Rules

1. **Memory**: All decisions saved to Engram with `mem_save`
2. **Session**: Session start/end tracked in `.session/` directory
3. **Norms**: New norms added to `rules/adaptive/LEARNED-NORMS.md`
4. **Promotion**: High-confidence norms promoted to `rules/custom/`

### Pester Version

| ID       | Norm                                                          | Confidence | Learned From      | Date       |
| -------- | ------------------------------------------------------------- | ---------- | ----------------- | ---------- |
| PST-001  | Use Pester 5.x syntax (`Should -Be`), NOT 3.4.0 (`Should Be`) | high       | session-2026-05-14-06 | 2026-05-14 |
| PST-002  | `Write-Host` OK in CLI scripts/hooks, forbidden in reusable libs | high    | session-2026-05-14-06 | 2026-05-14 |
| PST-003  | Script max 500 lines (not 400)                                | high       | session-2026-05-14-06 | 2026-05-14 |

### Code Review

| ID       | Norm                                                          | Confidence | Learned From      | Date       |
| -------- | ------------------------------------------------------------- | ---------- | ----------------- | ---------- |
| CRV-001  | Security scan FIRST in code review (before logic/style)       | high       | session-2026-05-14-06 | 2026-05-14 |
| CRV-002  | AI-generated code needs enhanced scrutiny (hallucinated APIs, wrong assumptions) | high | session-2026-05-14-06 | 2026-05-14 |
| CRV-003  | Every review finding classified by severity (CRIT/WARN/SUGGEST) | high     | session-2026-05-14-06 | 2026-05-14 |

### Secrets & Security

| ID       | Norm                                                          | Confidence | Learned From      | Date       |
| -------- | ------------------------------------------------------------- | ---------- | ----------------- | ---------- |
| SEC-001  | Never paste secrets into AI agent prompts                     | critical   | session-2026-05-14-06 | 2026-05-14 |
| SEC-002  | Secret leak response: REVOKE → ROTATE → SCRUB → AUDIT → PREVENT | high     | session-2026-05-14-06 | 2026-05-14 |

### Incident Response

| ID       | Norm                                                          | Confidence | Learned From      | Date       |
| -------- | ------------------------------------------------------------- | ---------- | ----------------- | ---------- |
| INC-001  | SEV1 incidents: 15min response, immediate containment          | high       | session-2026-05-14-06 | 2026-05-14 |
| INC-002  | Post-mortem within 48h for SEV1, 1 week for SEV2              | high       | session-2026-05-14-06 | 2026-05-14 |
| INC-003  | Incident format: Detect → Triage → Contain → Resolve → Verify → Document → Review | high | session-2026-05-14-06 | 2026-05-14 |

## Last Update

- Date: 2026-05-14
- Trigger: manual (session-2026-05-14-06)
- Agent: opencode
- Session: session-2026-05-14-06

## Statistics

- Total norms: 19
- High confidence: 18
- Critical confidence: 1
- Medium confidence: 0
- Low confidence: 0

