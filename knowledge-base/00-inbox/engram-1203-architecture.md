---
created: 2026-05-29 02:10:49
tags: [engram, architecture]
engram_id: 1203
type: architecture
---

# Fase 3 completa: hardened tool configs + multi-tool validator

**What**: Completada Fase 3 de hardening de tool configs. Se limpiaron 3 tool configs, se creó validador multi-tool, se agregó al pipeline de autostart, se documentaron normas.

**Why**: Las tools ignoran silenciosamente props no estándar, dando falsa sensación de que la config funciona. Esto es deuda técnica.

**Where**:
- `.windsurf/config.json` — reducido a solo `name`, `version`, `description`, `rules`. Custom props movidas a `config/windsurf-project-settings.json`
- `.continue/config.json` — reducido a solo `name`, `version`, `description`, `mcpServers`, `experimental`. Custom props movidas a `config/continue-project-settings.json`
- `.clinerules` — eliminada sección `system_prompt` (Cline la ignora), reemplazada con nota referenciando `config/system-prompt-optimization.json`
- `scripts/utilities/CONFIG/validate-tool-configs.ps1` — nuevo validador multi-schema
- `config/session-autostart.config.json` — agregado step `validate-tool-configs`
- `rules/NORMATIVAS-CONFIG-SAFETY.md` — 8 normas de configuración segura

**Learned**: Windsurf schema oficial solo acepta 6 props; Continue schema oficial ~12 props. El patrón "triple guard" (validar tool configs + CI + pre-commit) previene regresiones. 308/308 tests pasando post-hardening.

---
*Imported from Engram on 2026-09-06*
