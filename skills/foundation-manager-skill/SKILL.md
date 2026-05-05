---
name: foundation-manager-skill
description: FF-017 Auto-Actualización Skills/Tools. Implementa mecanismos de auto-actualización para skills y herramientas.
---

# foundation-manager-skill
# FF-017: Auto-Actualización Skills/Tools

## Trigger
for: "update foundation", "check updates", "sync skills", "install tools", "maintenance"

## Description
Implementa mecanismos de auto-actualización para skills y herramientas nativas, reduciendo mantenimiento manual y asegurando mejoras continuas.

## When to use
- Cuando se detecten skills/herramientas desactualizadas
- Próxima release o mantenimiento programado
- Después de instalar nuevas skills

## Execution Steps

1. **Check for updates**
   - Scan skills/ directory for SKILL.md files
   - Compare version/fecha in SKILL.md vs current date
   - Identify tools in package.json, go.mod, requirements.txt

2. **Auto-update skills**
   - If skill has git remote: `git submodule update --remote`
   - If skill has package.json: `npm update` in skill directory
   - Log updates to `.runtime/skill-updates.log`

3. **Auto-update tools**
   - Check npm global packages: `npm outdated -g`
   - Update lefthook, prettier, commitlint if needed
   - Update trufflehog via chocolatey if available

4. **Validate after update**
   - Run `wf.ps1 health` to verify Foundation integrity
   - Run `wf.ps1 verify` to check all skills load correctly
   - Generate update report in `docs/sessions/`

## Expected Deliverables
- `docs/sessions/skill-update-report-YYYY-MM-DD.md`
- `.runtime/skill-updates.log`
- Updated skills/ directory with latest versions

## Notes
- Uses `scripts/utilities/skills-auto-discovery.ps1` for skill detection
- Integrates with `scripts/utilities/foundation-sync.ps1` for sync
- Respects user preferences for auto-updates (config in `config/orchestrator.json`)
