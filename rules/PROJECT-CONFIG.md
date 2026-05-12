# Foundation Project Configuration v1.0

Centralized configuration for project standards and enforcement.

## Development Standards

### PowerShell Standards

- **Version**: PowerShell 7.0+ required
- **Pester Version**: 3.4.0 (NOT 5.x - syntax compatibility)
- **Coding Style**: PascalCase for functions, camelCase for locals
- **Required Attributes**: `[CmdletBinding()]` for all advanced functions
- **Comment-Based Help**: All public functions must have .SYNOPSIS, .DESCRIPTION, .EXAMPLE

### Testing Standards

- **Framework**: Pester 3.4.0
- **Syntax**: `Should Be`, `Should Match`, `Should Contain` (NO `Should -Be`)
- **Coverage Target**: 80% for critical scripts, 70% for utilities
- **Test Tags**: `CI` (PR runs), `Slow` (>1s), `Feature` (daily runs)
- **Structure**: `tests/unit/`, `tests/integration/`, `tests/performance/`

### Documentation Standards

- **Language**: Code/docs in English, user communication in Spanish
- **Required Docs**: README.md in every directory, SKILL.md in every skill
- **Frontmatter**: YAML in SKILL.md files (name, description)
- **No Broken Links**: All markdown links must be validated

### Security Standards

- **Hooks**: Lefthook + Trufflehog mandatory
- **No Secrets**: No API keys, passwords in code
- **Input Validation**: All user input validated
- **Error Handling**: No empty catch blocks

## Enforcement

### Automated Checks

1. **Pre-commit**: Lefthook runs PSScriptAnalyzer, Trufflehog, syntax check
2. **CI/CD**: GitHub Actions runs Pester tests, link validation
3. **Audit**: `audit-sweep.ps1 -Scope full` weekly
4. **Code Review**: Mandatory for develop → main

### Manual Checks

1. **Documentation**: Verify all new functions have comment-based help
2. **Links**: Run `audit-sweep.ps1 -Scope standard` before release
3. **Standards**: Review DEVELOPMENT-STANDARDS.md compliance

## Version Strategy

### Semantic Versioning

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, documentation updates

### Release Process

1. Update version in all relevant files
2. Run full test suite
3. Create GitHub release with notes
4. Merge develop → main
5. Tag release

## Project Structure

```
workspace-foundation/
├── scripts/           # All workflow/utility scripts
├── skills/            # 127 AI agent skills
├── config/            # Configuration files
├── docs/              # Documentation
├── tests/             # Test suites (unit/integration/perf/security)
├── plugins/           # Plugin ecosystem
├── templates/         # Project templates
└── rules/             # Development standards
```

## Quality Gates

### Before Merge to develop

- [ ] All Pester tests pass
- [ ] No broken markdown links
- [ ] PSScriptAnalyzer no errors
- [ ] Trufflehog no secrets detected
- [ ] Documentation updated

### Before Release

- [ ] 80%+ test coverage on critical scripts
- [ ] Performance benchmarks within SLO
- [ ] Audit sweep shows 0 issues
- [ ] CHANGELOG updated
- [ ] Version tags applied

---

_Version: 1.0 - 2026-05-05_ _Status: ACTIVE_
