---
name: gentle-vanguard-manager-skill
description:
  "Trigger: 'update gentle-vanguard', 'check updates', 'sync skills', 'install tools', 'maintenance'.
  Auto-actualización de skills y herramientas nativas reduciendo mantenimiento manual."
---

# Gentle-Vanguard Manager Skill

## Activation Contract

Load when user requests any update/sync/maintenance operation. Triggers on: outdated skills
detected, scheduled maintenance, post-install validation, or explicit update request.

## Hard Rules

- Never auto-update without logging all changes to `.runtime/skill-updates.log`
- Validate integrity after every update via `gv.ps1 health` and `gv.ps1 verify`
- Respect user auto-update preferences in `config/orchestrator.json`

## Decision Gates

| Update Type             | Method                          | Validation                     |
| ----------------------- | ------------------------------- | ------------------------------ |
| Skill with git remote   | `git submodule update --remote` | SKILL.md loads correctly       |
| Skill with package.json | `npm update` in skill dir       | Tests pass                     |
| npm global tools        | `npm outdated -g`               | Lefthook, prettier, commitlint |
| trufflehog              | Chocolatey update               | Version check                  |

## Execution Steps

1. Scan skills/ for SKILL.md files and determine update needs
2. Apply updates per Decision Gates (log each change)
3. Run `gv.ps1 health` then `gv.ps1 verify` for integrity
4. Generate update report

## Output Contract

- `docs/sessions/skill-update-report-YYYY-MM-DD.md` — full report
- `.runtime/skill-updates.log` — incremental log
- Updated skills/ directory with latest versions

## References

- Skill detection: `scripts/utilities/skills-auto-discovery.ps1`
- Gentle-Vanguard sync: `scripts/utilities/gentle-vanguard-sync.ps1`
- User config: `config/orchestrator.json`

