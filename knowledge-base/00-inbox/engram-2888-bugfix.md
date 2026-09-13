---
created: 2026-08-19 03:29:08
tags: [engram, bugfix]
engram_id: 2888
type: bugfix
---

# Limpieza .git-rewrite (920 archivos) + verificación final stack 95/95

**What**: Limpieza completa de .git-rewrite/ (920 archivos trackeados accidentalmente de un filter-branch/replace) + verificación final del stack.
**Why**: Housekeeping de higiene de repo — .git-rewrite/ es un artefacto temporal de git que nunca debió versionarse; el secret-scanner lo marcaba con falsos positivos.
**Where**: .gitignore, git rm -r --cached .git-rewrite, commits 552e7e1b + 0eea9b27
**Learned**:
- .git-rewrite/ contenía 920 archivos trackeados (backup-refs, parse, revs, map/) que generaban 17 falsos positivos en el secret-scanner (hashes de commits interpretados como "Facebook Client ID").
- Fix: añadir `.git-rewrite/` al .gitignore + `git rm -r --cached .git-rewrite`. El commit grande (920 archivos) puede colgar el hook post-commit (hashline-snapshot) — el commit se crea igualmente, verificar con `git log`.
- Los 42 matches del secret-scanner son TODOS falsos positivos/placeholders: .git-rewrite (hashes), TROUBLESHOOTING-RUNBOOK (AKIA...MPLE), public/skills (bucket-S3-redacted, TARGET.com), tests (fixtures sintéticos ghp_...AAAA, eyJh...sw5c). No hay secretos reales en el repo.
- Estado final verificado: watchtower 95/95 PASS, typecheck OK, lint OK, tests 5/5 (3 ejecuciones consecutivas — un fallo inicial fue flaky por contención durante el push).
- Todos los cambios pusheados a main + develop + sync public (2026-08-19 03:24).

---
*Imported from Engram on 2026-09-06*
