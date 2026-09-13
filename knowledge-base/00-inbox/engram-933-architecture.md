---
created: 2026-05-18 03:14:42
tags: [engram, architecture]
engram_id: 933
type: architecture
---

# Continue.dev checks + Cursor command integration complete

**What**: Implementacion completa de Continue.dev Best Practices con 5 checks modulares + comando Cursor para ejecutarlos
**Why**: Alinear nuestro stack con docs.continue.dev/checks/best-practices (scope narrow, be specific, checks vs tests vs lint)
**Where**:
- .continue/checks/ (security-review.md, test-coverage.md, documentation-freshness.md, dependency-audit.md, migration-safety.md)
- .continue/config.json v2.0.0 (checks.paths + autoRunOnPR)
- adaptive-continue-copilot-profile.ps1 (backup/restore de checks)
- .cursor/commands/continue-check.md (/continue-check para ejecutar checks desde Cursor)
**Learned**: Continue.dev checks son markdown con frontmatter YAML, se ejecutan automaticamente en PR review via autoRunOnPR. Los 5 checks cubren los casos del articulo oficial mas adaptaciones a nuestro stack (PowerShell env vars, skills SKILL.md, config JSON schema).

---
*Imported from Engram on 2026-09-06*
