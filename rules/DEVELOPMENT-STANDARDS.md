# Foundation Development Standards v2.0

Standards and best practices for Foundation project development.
Last updated: 2026-05-10

---

## PowerShell Coding Standards

### Required Patterns

1. **CmdletBinding**: All advanced functions must have `[CmdletBinding()]`
2. **Parameter Validation**: Use `[Parameter()]`, `[ValidateNotNullOrEmpty()]`, etc.
3. **Comment-Based Help**: All public functions must have `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`
4. **Output Type**: Specify `[OutputType([type])` when returning objects
5. **Error Handling**: Use `try/catch` with meaningful error messages (see `rules/NORMATIVAS-ERROR-HANDLING.md`)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Functions | Verb-Noun (PascalCase) | `Invoke-TokenBudgetGuard` |
| Variables | PascalCase (script), camelCase (local) | `$ConfigPath`, `$localVar` |
| Files | PascalCase with hyphens | `token-budget-guard.ps1` |
| Tests | `*.tests.ps1` suffix | `auth.tests.ps1` |
| JSON keys | camelCase | `confidenceThreshold` |
| Branch names | type/description | `feat/auth-flow` |
| Skill directories | kebab-case | `auto-delegation-router` |

### Forbidden Patterns

- No `Write-Host` in functions (use `Write-Output` or `return`)
- No hardcoded paths (use relative or config-driven paths)
- No empty `catch` blocks
- No `Should -Be` syntax (use `Should Be` for Pester 3.4.0)
- No circular dependencies between modules
- No hardcoded secrets or API keys

---

## Testing Standards

### Test Structure

```
tests/
├── unit/           # Fast, isolated tests (<100ms each)
├── integration/    # Tests with real system interaction
├── e2e/            # Golden dataset evaluations
├── performance/    # Benchmark and load tests
└── security/       # Security-focused tests
```

### Pester 3.4.0 Syntax (REQUIRED)

```powershell
# CORRECT:
$result | Should Be $expected
$value | Should Not BeNullOrEmpty
$array | Should Contain 'item'
$string | Should Match 'pattern'

# WRONG (Pester 5.x syntax):
$result | Should -Be $expected
```

### Coverage Requirements

- **Critical scripts**: >80% code coverage
- **Utility scripts**: >70% code coverage
- **All new code**: Must have tests before merge

### Test Tags

- `CI` - Run on every PR
- `Slow` - Tests taking >1 second
- `Feature` - Run daily, not on PR

### Testing Policy Source

Canonical testing configuration: `config/testing-policy.json`
Detailed testing norms: `docs/NORMATIVAS-TESTING.md`

---

## Documentation Standards

### Required Documentation

1. **README.md** - Every directory needs one
2. **SKILL.md** - Every skill must have frontmatter YAML
3. **Comment-Based Help** - All public functions
4. **CHANGELOG.md** - Track all changes

### Markdown Rules

- Use ATX headers (`# H1`, `## H2`)
- Links must be validated (no broken links)
- Use tables for structured data
- All docs in English, user communication in Spanish
- Max 3 heading levels deep for readability

### SKILL.md Frontmatter Standard

```yaml
---
name: skill-name
description: 'Trigger: keyword1, keyword2. Short description.'
---
```

---

## Code Quality Standards

### File Organization

- One logical concept per file (Single Responsibility)
- Max 400 lines per script/file (split if exceeded)
- Max 3 nesting levels (refactor to functions if exceeded)
- No circular dependencies between modules
- Max 3 parameters per function (use splatting/hashtable for more)

### Config JSON Standards

Every config JSON MUST include:
- `version` field
- `description` field
- Comments via `_comment` field (JSON5 not supported)

---

## Git Workflow Standards

### Branch Strategy

- `main` - Production-ready code only
- `develop` - Integration branch
- `feature/*` - Individual features
- `fix/*` - Bug fixes
- `docs/*` - Documentation changes

### Commit Standards

- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:`, `refactor:`, `perf:`
- Keep commits atomic (one logical change)
- Always run `agent-verify.ps1` before commit
- Never use `--no-verify` without GOV authorization

---

## Security Standards

### Mandatory Checks

1. **Lefthook** - Pre-commit hooks must pass
2. **Gitleaks** - No secrets in code (CI)
3. **PSScriptAnalyzer** - All scripts must pass
4. **Input Validation** - All user input must be validated
5. **OWASP LLM Top 10** - Follow `docs/NORMATIVAS-SEGURIDAD.md`

### Forbidden Practices

- No hardcoded secrets/API keys
- No `password` or `secret` in plain text
- No disabling security hooks
- No committing `.env` files
- No path disclosure (redact home/user paths)
- No prompt injection vulnerable patterns

---

## Performance Standards

### Token Efficiency

- **Context packing**: Use `scripts/utilities/handoff-compress.ps1` for large sessions
- **Token budgeting**: All AI interactions must call `scripts/utilities/token-guard.ps1`
- **Compression**: Apply 0.90 ratio for memory packs

### Script Performance

- Scripts must complete in <2s for interactive use
- Use `-ProgressAction SilentlyContinue` for non-interactive
- Cache results when possible (e.g., skill discovery)
- Profile before optimizing (measure, don't guess)

---

## Review Checklist

Before marking ANY task as complete:

- [ ] All tests pass (`Invoke-Pester`)
- [ ] No broken links in docs (run `audit-sweep.ps1`)
- [ ] Agent self-verification passed (`agent-verify.ps1`)
- [ ] PSScriptAnalyzer passes (no errors)
- [ ] Comment-based help present
- [ ] CHANGELOG updated
- [ ] No hardcoded paths
- [ ] Error handling implemented per NORMATIVAS-ERROR-HANDLING.md
- [ ] Engram persisted (`mem_save` for significant work)
- [ ] es docs, en code (project rule)

---

## AI Agent Standards

- All agents MUST follow routing defined in `config/auto-delegation.json`
- Temperature configured per agent profile (DEV=0.15, QA=0.1, GOV=0.1, OPS=0.1)
- Hedging language blocked for DEV, QA, OPS, GOV agents
- Hallucination guard levels enforced per profile (CRITICAL for QA/OPS/GOV)
- Evidence collection required before task completion
- Escalation path: agent -> escalateOnFailure -> orchestrator
- Session lifecycle: autostart -> work -> verify -> persist -> close

---

## Tools Configuration

### Required Tools

- **PowerShell** 7.0+
- **Pester** 3.4.0 (NOT 5.x)
- **Git** 2.30+
- **Lefthook** 2.1.6+
- **Node.js** 18+ (for Prettier)

### VSCode Settings

- PowerShell extension installed
- Pester snippets enabled
- Format on save: enabled
- Trim trailing whitespace: enabled
- Prettier as default formatter for MD/JSON/YAML

---

## Enforcement

These standards are enforced by:

1. **Pre-commit hooks** (Lefthook) - `hooks/pre-commit-opencode-validation.ps1`
2. **CI/CD pipeline** (GitHub Actions) - `foundation-quality-gate.yml`
3. **Code review** (mandatory for `develop` -> `main`)
4. **Audit sweeps** (weekly) - `foundation-audit-skill`
5. **Agent self-verification** (`agent-verify.ps1`)

Violations result in:

- Warning - Minor issues (documented but non-blocking)
- Error - Blocks merge (MUST fix before proceeding)
- Critical - Rollback required (security/compliance)

---

## References

| Resource | Path |
|----------|------|
| AI Normatives | `rules/AI-NORMATIVES.md` |
| Code Normatives | `rules/NORMATIVAS-CODIGO.md` |
| Error Handling | `rules/NORMATIVAS-ERROR-HANDLING.md` |
| Testing Normatives | `docs/NORMATIVAS-TESTING.md` |
| Security Normatives | `docs/NORMATIVAS-SEGURIDAD.md` |
| **Accessibility (WCAG 2.2)** | `docs/NORMATIVAS-ACCESIBILIDAD.md` |
| **I18n/L10n Standards** | `docs/NORMATIVAS-I18N-L10N.md` |
| **ISO/IEC 25010 Quality** | `docs/NORMATIVAS-ISO25010.md` |
| **ISO/IEC 27001 Controls** | `docs/NORMATIVAS-ISO27001.md` |
| **SRE Practices** | `docs/NORMATIVAS-SRE.md` |
| **Chaos Engineering** | `docs/NORMATIVAS-CHAOS-ENGINEERING.md` |
| **API Design Standards** | `docs/NORMATIVAS-API-DESIGN.md` |
| **SBOM Validation** | `docs/NORMATIVAS-SBOM.md` |
| C# Hardening | `rules/CI-HARDENING-STANDARDS.md` |
| Skill Style Guide | `rules/SKILL-STYLE-GUIDE.md` |
| Orchestrator Config | `config/orchestrator.json` |
| Quality Gates | `config/quality-gates.json` |
| Structure Policy | `config/structure-policy.json` |
| Testing Policy | `config/testing-policy.json` |
| PSScriptAnalyzer Config | `config/PSScriptAnalyzerSettings.psd1` |
| ESLint Config | `.eslintrc.json` |
| TypeScript Config | `tsconfig.json` |

---

_Version: 2.0 - 2026-05-10_ _Author: Foundation Team_ _Status: ACTIVE_
