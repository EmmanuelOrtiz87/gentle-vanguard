# LESSONS LEARNED - HOOKS INCIDENT (2026-04-15)

## Incident Summary
During a routine cleanup operation, the pre-commit and commit-msg hooks (lefhooks) were accidentally removed from the repository. This caused validation gaps and inconsistency in the commit process.

## Root Cause
- Overly aggressive cleanup script that didn't exclude `.git/hooks/` and hook configuration files
- Lack of protection for critical infrastructure files
- No validation before executing bulk deletion operations

## Lessons Learned

### 1. Infrastructure Protection
- **NEVER** remove `.git/hooks/` directory or hook config files without explicit user confirmation
- Hook configurations (lefhooks, pre-commit, etc.) are **critical infrastructure**
- Always add exclusions for: `.git/hooks/`, `lefthook.yml`, `.hooks/`, `hooks-config.json`

### 2. Cleanup Operations
- Run cleanup in **dry-run mode first** (`-WhatIf` in PowerShell)
- Validate exclusions before execution
- Log every deleted file for audit trail
- Require explicit confirmation for bulk operations affecting infrastructure

### 3. Validation
- Run `wf.ps1 verify` after any cleanup operation
- Check that hooks are still functional: `git hooks list` or check lefthook status
- Ensure `.gitignore` includes telemetry and temporary files

### 4. Recovery Procedure
If hooks are accidentally removed:
1. Check if lefthook is installed: `lefthook version`
2. Reinstall if needed: `npm install -g lefthook` or appropriate package manager
3. Restore `lefthook.yml` from git history: `git checkout HEAD -- lefthook.yml`
4. Run `lefthook install` to reinstall hooks
5. Validate with `wf.ps1 verify`

## Prevention Measures
- Added protection rules in cleanup scripts
- Documentation governance policy now includes hook protection
- Validation script (`comprehensive-validation.ps1`) now checks hook configuration
- `.gitignore` updated to protect hook-related files

## Applied To
- `fix-all-simple.ps1` - Protected against infrastructure deletion
- `comprehensive-validation.ps1` - Updated to check actual structure
- `AGENTS.md` / `CLAUDE.md` - Added infrastructure protection rules

---
**Date:** 2026-04-15  
**Incident ID:** HOOKS-INCIDENT-2026-04-15  
**Resolution:** Recovered and documented (2026-05-02)
