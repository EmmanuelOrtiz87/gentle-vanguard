# CONFIGURATION VALIDATION CHECKLIST

Use this checklist before any commit that modifies configuration files.

## Pre-Commit Validation

### 1. JSON Configuration Files
- [ ] Valid JSON syntax (no trailing commas, proper quotes)
- [ ] Required fields present
- [ ] No sensitive data (API keys, passwords)
- [ ] UTF-8 encoding without BOM
- [ ] Proper file extension (.json)

**Files to check:**
- `config/hooks-config.json`
- `config/workspace.config.json`
- `tools/session-autostart.config.json`
- `tools/context-efficiency-config.json`
- `tools/token-guard-config.json`
- `opencode.json` (if present)

### 2. PowerShell Scripts
- [ ] Valid syntax (use `$ast = [System.Management.Automation.Language.Parser]::ParseFile()`)
- [ ] No emojis in script files (CLI compatibility)
- [ ] Consistent indentation (spaces, not tabs)
- [ ] UTF-8 encoding without BOM
- [ ] Proper file extension (.ps1)

**Critical scripts:**
- `tools/pre-process-input.ps1`
- `tools/pre-compact-hook.ps1`
- `tools/session-manager.ps1`
- `scripts/utilities/WORKFLOW-ORCHESTRATION/wf.ps1`

### 3. Markdown Documentation
- [ ] Proper Spanish accents (automatización, configuración, revisión, activación)
- [ ] Code blocks specify language (```powershell, ```bash, ```json)
- [ ] UTF-8 encoding without BOM
- [ ] Blank lines before/after headers and code blocks
- [ ] Emojis used for visual scanning (🚀, ⚙️, 🤖, 💡, 🚨, ✅)
- [ ] Tables used for structured data
- [ ] Visual callouts used (`> 💡 **TIP:**`)

**Critical docs:**
- `README.md`
- `AGENTS.md`
- `CLAUDE.md`
- `docs/README.md`

### 4. Git Configuration
- [ ] `.gitignore` includes: `.telemetry/`, `.engram-data/`, `node_modules/`
- [ ] No sensitive files staged
- [ ] Commit message follows convention: `type(scope): description`
- [ ] Hooks are functional (lefthook installed and active)

### 5. Infrastructure Protection
- [ ] `.git/hooks/` directory intact
- [ ] `lefthook.yml` present and valid
- [ ] `config/hooks-config.json` present
- [ ] No cleanup scripts targeting infrastructure files

## Automated Validation

Run before commit:
```powershell
.\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1 verify
.\scripts\utilities\WORKFLOW-ORCHESTRATION\comprehensive-validation.ps1
```

## Post-Commit Validation

- [ ] `git status` shows clean working tree
- [ ] `git log --oneline -1` shows correct commit message
- [ ] Hooks executed successfully (check output)
- [ ] Pushed to remote without errors

---
**Version:** 1.0  
**Last Updated:** 2026-05-02  
**Maintained by:** Foundation Orchestrator
