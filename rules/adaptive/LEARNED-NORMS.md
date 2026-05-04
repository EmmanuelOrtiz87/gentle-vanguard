# Learned Norms (Autonomous)

This file is **auto-maintained** by the adaptive learning system.

## Active Norms

### Documentation Placement

| ID | Norm | Confidence | Learned From | Date |
|----|------|-------------|--------------|------|
| DOC-001 | Documentation in project root instead of docs/ | high | auto-norm-learner | 2026-05-04 |
| DOC-002 | Scripts README.md must be in English, normalized | high | manual | 2026-05-04 |

### Auto-Correction

| ID | Pattern | Confidence | Learned From | Date |
|----|---------|-------------|--------------|------|
| CORR-001 | PowerShell TryParse() must be replaced with regex match | high | auto-norm-learner | 2026-05-04 |
| CORR-002 | Path references in wf.ps1 must use triple Split-Path | high | auto-norm-learner | 2026-05-04 |
| CORR-003 | repoRoot calculation must use Resolve-Path with Join-Path | high | auto-norm-learner | 2026-05-04 |

### SESS-### (Session Patterns)

| ID | Pattern | Confidence | Learned From | Date |
|----|---------|-------------|--------------|------|
| SESS-001 | Session files stored in .session/ directory | high | auto-norm-learner | 2026-05-04 |
| SESS-002 | Session ID pattern: session-YYYY-MM-DD-XX | high | auto-norm-learner | 2026-05-04 |

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

1. **repoRoot**: Always use `Split-Path (Split-Path (Split-Path $scriptDir))` for wf.ps1
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
3. **Delegation**: Use `wf.ps1 agent <AGENT> <TASK>` for complex tasks
4. **Fallback**: If orchestrator inactive, use manual skill loading

### Auto-Learning Rules

1. **Memory**: All decisions saved to Engram with `mem_save`
2. **Session**: Session start/end tracked in `.session/` directory
3. **Norms**: New norms added to `rules/adaptive/LEARNED-NORMS.md`
4. **Promotion**: High-confidence norms promoted to `rules/custom/`

## Last Update

- Date: 2026-05-04
- Trigger: manual
- Script: auto-norm-learner-simple.ps1
- Session: session-2026-05-04-074718

## Statistics

- Total norms: 8
- High confidence: 8
- Medium confidence: 0
- Low confidence: 0
- Success rate: 100%
