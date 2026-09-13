---
created: 2026-05-18 03:08:49
tags: [engram, architecture]
engram_id: 932
type: architecture
---

# Cursor Agent Best Practices integration complete

**What**: Implementacion completa de las 12 practicas del articulo Cursor Agent Best Practices (cursor.com/es/blog/agent-best-practices) en nuestro stack
**Why**: Optimizar integracion con Cursor y alinearla con las mejores practicas del equipo de Cursor
**Where**:
- .cursor/rules/ (core-workflow.md, commands.md, code-style.md) - reglas modulares
- .cursor/commands/ (pr.md, review.md, status.md, test.md, fix-issue.md, update-deps.md) - 6 comandos reutilizables
- .cursor/plans/ - directorio para Plan Mode saves
- .cursor/hooks.json + .cursor/hooks/grind.ts - stop hook para long-running agents
- .cursorrules - reescrito para referenciar .cursor/rules/
- .cursor/config.json - v2.0 con rules/commands/plans config
- adaptive-cursor-profile.ps1 - actualizado para backup/restore de nueva estructura
**Learned**: Cursor ahora recomienda .cursor/rules/*.md en vez del unico .cursorrules. Los comandos /command se activan con .cursor/commands/*.md. Los stop hooks requieren Cursor Nightly + Bun. Nuestro stack cubre las 12 practicas del articulo.

---
*Imported from Engram on 2026-09-06*
