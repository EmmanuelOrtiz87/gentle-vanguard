---
created: 2026-06-02 11:23:53
tags: [engram, bugfix]
engram_id: 1287
type: bugfix
---

# sync-to-public multi-branch fix + pre-flight health check

**What**: sync-to-public.ps1 solo sincronizaba a la default branch (main), dejando develop 2 semanas stale. Se reescribió section 11 para iterar TODAS las ramas remotas via `git branch -r`. Se extrajeron las operaciones de copia a Sync-FilesToBranch() function, llamada por rama tras `git reset --hard origin/$branch`.

**Why**: El script original usaba `git ls-remote --symref origin HEAD` para detectar "la" branch, ignorando develop. Además, las copy ops corrían una vez antes del loop de branches, pero `git checkout` cambiaba el working tree y los archivos copiados desaparecían al switchear.

**Where**: scripts/utilities/DEPLOYMENT/sync-to-public.ps1, rules/NORMATIVAS-RELEASE.md (section 4.1, 4.2), scripts/utilities/DEPLOYMENT/check-public-repo-health.ps1 (nuevo)

**Learned**:
- `git ls-remote --symref origin HEAD` solo da la default branch. Para todas: `git branch -r`.
- `git reset --hard origin/$branch` antes de sync por rama es más confiable que stash/pop (que falla con branch switching)
- Las operaciones de copia deben ejecutarse DENTRO del loop de branches, no antes
- Pre-flight check debe verificar TODAS las ramas remotas, no solo main

---
*Imported from Engram on 2026-09-06*
