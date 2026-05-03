# Configuration Validation Checklist

## Purpose
Use this checklist to validate workspace configuration before starting work.

## Checklist

### Core Configuration
- [ ] `tools/context-efficiency-config.json` exists and `targetPercentage` is 100
- [ ] `tools/session-autostart.config.json` exists and synced with foundation
- [ ] `config/hooks-config.json` exists and valid JSON
- [ ] `opencode.json` exists with provider configuration

### Directory Structure
- [ ] `docs/` directory exists
- [ ] `config/` directory exists
- [ ] `.github/workflows/` directory exists
- [ ] `.session/logs/` directory exists
- [ ] `.session/reports/` directory exists

### Scripts
- [ ] All hooks scripts are present and executable
- [ ] `pre-process-input.ps1` exists
- [ ] `validate-system-health.ps1` exists
- [ ] `intelligent-validator.ps1` exists

### Validation
- [ ] Run `comprehensive-validation.ps1` and verify 100% pass rate
- [ ] Run `cross-workspace-validator.ps1` with no issues
- [ ] Engram version is up to date

## Notes
Update this checklist when adding new configuration or scripts.
