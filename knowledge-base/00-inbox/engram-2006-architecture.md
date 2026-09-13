---
created: 2026-07-26 05:21:46
tags: [engram, architecture]
engram_id: 2006
type: architecture
---

# Final PS1 → TS migration (12 files) - complete stack migration

**What**: Migrated the last 12 PS1 files to TypeScript, completing the full PS1→TS migration of Gentle-Vanguard
**Why**: Eliminate PowerShell dependency from the core stack — all operations now run via npx tsx
**Where**:
- src/cli/gentle-vanguard.ts (replaces root gentle-vanguard.ps1) — main entry point
- src/cli/protect.ts (replaces build/protect-gentle-vanguard.ps1) — AES-256-GCM encryption
- src/cli/create-installer.ts (replaces build/create-installer.ps1) — NSIS installer builder
- build/Gentle-Vanguard-Launcher.ts (replaces build/Gentle-Vanguard-Launcher.ps1) — 478→380 lines, setup wizard
- demos/07-mixed-cookbook-real-request/preflight.ts + reset-demo.ts
- 6 templates/project-root/scripts/*.ts
- .gitignore: added !build/*.ts negation
- package.json: 4 new npm scripts (gv:main, gv:protect, gv:installer, gv:launcher)
**Learned**: build/ directory was gitignored via build/* — had to add !build/*.ts like we did for bin/*.ps1. Some PS1 commands (secret vault, cache) still need native Windows APIs but are isolated in bin/gv.ps1 wrapper.

---
*Imported from Engram on 2026-09-06*
