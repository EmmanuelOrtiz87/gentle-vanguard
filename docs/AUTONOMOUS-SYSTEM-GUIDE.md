# AUTONOMOUS SYSTEM GUIDE

## Purpose
This guide explains how to work with the autonomous validation system in the Foundation workspace. It covers daily operations, troubleshooting, and extending the system.

## Quick Start

### Check System Health
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 health
```

### Run Quick Verification
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 verify
```

### Generate Audit
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 audit
```

## Daily Workflow

### 1. Before Starting Work
```powershell
cd C:\Workspace_local\workspace-foundation
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 health
```

### 2. During Development
- Follow documentation governance rules (Spanish accents, emojis, code blocks)
- Run `wf.ps1 verify` before committing
- Check that hooks are working (lefthook)

### 3. Before Commit
```powershell
# Stage changes
git add .

# Run validation (hooks will run automatically)
git commit -m "type(scope): description"

# If hooks fail, check:
.\scripts\utilities\WORKFLOW-ORCHESTRATION\comprehensive-validation.ps1 -Verbose
```

### 4. After Push
- GitHub Actions will run autonomous validation
- Check Actions tab for results
- Fix any issues reported

## Troubleshooting

### Hooks Not Running
```powershell
# Check lefthook installation
lefthook version

# Reinstall hooks
lefthook install

# Check config
cat lefthook.yml
```

### Validation Failures
```powershell
# Run with verbose output
.\scripts\utilities\WORKFLOW-ORCHESTRATION\comprehensive-validation.ps1 -Verbose

# Check specific area
# - PowerShell scripts: Check syntax with PowerShell ISE or VS Code
# - JSON files: Validate at jsonlint.com
# - Markdown: Check accents, code blocks, emojis
```

### Recovery from Incident
See `docs/LESSONS-LEARNED-HOOKS-INCIDENT.md` for recovery procedures.

## Extending the System

### Adding New Validation Checks

1. Edit `scripts/utilities/WORKFLOW-ORCHESTRATION/comprehensive-validation.ps1`
2. Add new check in appropriate section
3. Use `Add-ValidationResult` to record results
4. Test with `-Verbose` flag
5. Update this guide and audit documentation

**Example:**
```powershell
# New check
$newCheck = Test-Path "new-required-file.txt"
if ($newCheck) {
    Add-ValidationResult "New Section" "new-required-file.txt" "PASS" "File exists"
    Write-Log "[OK] new-required-file.txt - Exists" "SUCCESS"
} else {
    Add-ValidationResult "New Section" "new-required-file.txt" "FAIL" "File not found"
    Write-Log "[FAIL] new-required-file.txt - Missing" "ERROR"
}
```

### Adding New Hooks

1. Edit `lefthook.yml`
2. Add new hook under appropriate section (pre-commit, commit-msg, etc.)
3. Run `lefthook install` to activate
4. Test with a dummy commit

**Example:**
```yaml
pre-commit:
  commands:
    new-check:
      glob: "*.md"
      run: echo "Checking {staged_files}..." && exit 0
```

## Governance Integration

The autonomous system enforces governance rules defined in:
- `docs/reference/NORMATIVAS-ORQUESTADOR.md` - Global governance
- `AGENTS.md` / `CLAUDE.md` - Agent-specific rules
- `docs/guides/DOCUMENTATION-GOVERNANCE.md` - Documentation standards

### Override Policy
- **NEVER** use `--no-verify` to skip hooks unless explicitly authorized
- Document any override in commit message
- Report override to orchestrator for review

## Monitoring

### Telemetry Dashboard
```powershell
.\tools\telemetry-dashboard.ps1
```

### Session Reports
```powershell
# List reports
ls .session/reports/

# View latest
cat .session/reports/comprehensive-validation-*.json | ConvertFrom-Json
```

### GitHub Actions
- Check Actions tab in GitHub
- Set up notifications for failed workflows
- Review validation logs in workflow runs

## Best Practices

1. **Run health check daily** - Catch issues early
2. **Fix warnings too** - Not just errors
3. **Update docs on change** - Keep this guide current
4. **Test before commit** - Use `wf.ps1 verify`
5. **Respect the system** - It's here to help, not hinder

## Migration Notes (2026-05-02)

The validation system was updated to:
- Reflect actual workspace structure (not theoretical)
- Check real files that exist (not missing ones)
- Include new governance rules (Spanish accents, emojis)
- Add infrastructure protection (hooks, configs)
- Document lessons learned from hooks incident

**Old system:** Checked non-existent files, 12% pass rate  
**New system:** Checks actual structure, ~85% pass rate expected

---
**Version:** 2.0 (Updated 2026-05-02)  
**Maintained by:** Foundation Orchestrator  
**Emergency Contact:** Create issue in GitHub repo
