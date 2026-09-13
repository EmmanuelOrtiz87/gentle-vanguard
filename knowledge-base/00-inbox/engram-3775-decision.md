---
created: 2026-09-07 13:25:24
tags: [engram, decision]
engram_id: 3775
type: decision
---

# Homologación v4.0.0 completa — installer NSIS + sync-to-public mejorado

**What**: Homologación completa del stack a v4.0.0: protect (716 scripts encriptados, 1755 .enc en build/protected, 111 skill stubs en build/public), installer NSIS construido (dist/Gentle-Vanguard-Setup-4.0.0.exe, 17.2 MB, SHA256 aa5a1ded...b02d), sync al repo público gentle-vanguard-public con tag v4.0.0 y GitHub Release publicado (https://github.com/EmmanuelOrtiz87/gentle-vanguard-public/releases/tag/v4.0.0).

**Why**: El usuario pidió que el stack completo esté actualizado en el repo privado (main/develop), homologado al público y con el .exe instalador subido para que la gente pueda instalar el stack desde cero.

**Where**: src/cli/create-installer.ts (fix NSI), src/infrastructure/sync-to-public.ts (fix installer versionado), src/cli/protect.ts, dist/Gentle-Vanguard-Setup-4.0.0.exe, docs/guides/HOMOLOGATION-GUIDE.md, C:\Workspace_local\gentle-vanguard-public (repo público local).

**Learned**:
1. **Bug NSIS real**: makensis rechaza el template .nsi con "Bad text encoding" si contiene em-dash (—, U+2014) en UTF-8 sin BOM — NSIS lee el .nsi como ACP. Fix: ASCII puro en el template (3 líneas cabecera + 1 DetailPrint). Los em-dash en comentarios TS no llegan al NSI.
2. **sync-to-public.ts copiaba el .exe legacy equivocado**: buscaba dist/Gentle-Vanguard.exe (viejo, 31 MB) pero el build genera dist/Gentle-Vanguard-Setup-<ver>.exe. Fix: buscar el installer versionado más reciente con regex /^Gentle-Vanguard-Setup-\d+\.\d+\.\d+\.exe$/ y copiarlo como Gentle-Vanguard.exe + .sha256.
3. **commitlint hook exige conventional commits**: git merge --no-edit falla; hay que usar git commit -m "chore(merge): ..." explícito.
4. **120 .ps1 en el repo público fuera de scripts/gentle-vanguard/** son deuda histórica pre-existente (ya estaban en f52c6e30), no los introduce el sync. No se borraron sin confirmación porque algunos son hooks/CI necesarios.
5. **Code signing no configurado** (GV_SIGNTOOL_PATH/GV_SIGNING_CERT ausentes) → el installer muestra advertencia SmartScreen. Pendiente para futuros releases.
6. Commits clave: 0f561554 (fix NSI), 6d0d141e (fix sync), f82a9217 (merge a main), tag v4.0.0 en público.

---
*Imported from Engram on 2026-09-08*
