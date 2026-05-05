# Foundation Development Standards v1.0

Standards and best practices for Foundation project development.

## PowerShell Coding Standards

### Required Patterns
1. **CmdletBinding**: All advanced functions must have `[CmdletBinding()]`
2. **Parameter Validation**: Use `[Parameter()]`, `[ValidateNotNullOrEmpty()]`, etc.
3. **Comment-Based Help**: All public functions must have `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`
4. **Output Type**: Specify `[OutputType([type])` when returning objects
5. **Error Handling**: Use `try/catch` with meaningful error messages

### Naming Conventions
- **Functions**: Verb-Noun (PascalCase) - e.g., `Invoke-TokenBudgetGuard`
- **Variables**: PascalCase for script scope, camelCase for local
- **Files**: PascalCase with hyphens for scripts - e.g., `token-budget-guard.ps1`
- **Tests**: `*.tests.ps1` suffix

### Forbidden Patterns
- ❌ No `Write-Host` in functions (use `Write-Output` or `return`)
- ❌ No hardcoded paths (use relative paths)
- ❌ No empty `catch` blocks
- ❌ No `Should -Be` syntax (use `Should Be` for Pester 3.4.0)

## Testing Standards

### Test Structure
```
tests/
├── unit/           # Fast, isolated tests (<100ms each)
├── integration/    # Tests with real system interaction
├── performance/   # Benchmark and load tests
└── security/       # Security-focused tests
```

### Pester 3.4.0 Syntax (REQUIRED)
```powershell
# ✅ CORRECT:
$result | Should Be $expected
$value | Should Not BeNullOrEmpty
$array | Should Contain 'item'
$string | Should Match 'pattern'

# ❌ WRONG (Pester 5.x syntax):
$result | Should -Be $expected
$value | Should -Not -BeNullOrEmpty
```

### Coverage Requirements
- **Critical scripts**: >80% code coverage
- **Utility scripts**: >70% code coverage
- **All new code**: Must have tests before merge

### Test Tags
- `CI` - Run on every PR
- `Slow` - Tests taking >1 second
- `Feature` - Run daily, not on PR

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

## Git Workflow Standards

### Branch Strategy
- `main` - Production-ready code only
- `develop` - Integration branch
- `feature/*` - Individual features
- `fix/*` - Bug fixes

### Commit Standards
- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`
- Keep commits atomic (one logical change)
- Always run `wf.ps1 health` before commit

## Security Standards

### Mandatory Checks
1. **Lefthook** - Pre-commit hooks must pass
2. **Trufflehog** - No secrets in code
3. **PSScriptAnalyzer** - All scripts must pass
4. **Input Validation** - All user input must be validated

### forbidden Practices
- ❌ No hardcoded secrets/API keys
- ❌ No `password` or `secret` in plain text
- ❌ No disabling security hooks
- ❌ No committing `.env` files

## Performance Standards

### Token Efficiency
- **Context packing**: Use `context-pack.ps1` for large sessions
- **Token budgeting**: All AI interactions must call `token-budget-guard.ps1`
- **Compression**: Apply 0.65 ratio for memory packs

### Script Performance
- Scripts must complete in <2s for interactive use
- Use `-ProgressAction SilentlyContinue` for non-interactive
- Cache results when possible (e.g., skill discovery)

## Review Checklist

Before marking ANY task as complete:
- [ ] All tests pass (`Invoke-Pester`)
- [ ] No broken links in docs (run `audit-sweep.ps1`)
- [ ] PSScriptAnalyzer passes (no errors)
- [ ] Comment-based help present
- [ ] CHANGELOG updated
- [ ] No hardcoded paths
- [ ] Error handling implemented
- [ ] es docs, en code (project rule)

## Tools Configuration

### Required Tools
- **PowerShell** 7.0+
- **Pester** 3.4.0 (NOT 5.x)
- **Git** 2.30+
- **Lefthook** 2.1.6+
- **Trufflehog** latest

### VSCode Settings
- PowerShell extension installed
- Pester snippets enabled
- Format on save: enabled
- Trim trailing whitespace: enabled

## Enforcement

These standards are enforced by:
1. **Pre-commit hooks** (Lefthook)
2. **CI/CD pipeline** (GitHub Actions)
3. **Code review** (mandatory for `develop` → `main`)
4. **Audit sweeps** (weekly)

Violations result in:
- ⚠️ Warning - Minor issues
- ❌ Error - Blocks merge
- 🚫 Critical - Rollback required

---
*Version: 1.0 - 2026-05-05*
*Author: Foundation Team*
*Status: ACTIVE*
