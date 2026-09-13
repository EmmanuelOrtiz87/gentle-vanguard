---
created: 2026-09-07 18:06:07
tags: [engram, decision]
engram_id: 3777
type: decision
---

# Homologación v4.0.0 completa — repo público 100% limpio (0 apps, 0 .ps1, allowlist)

**What**: Homologación completa del stack Gentle-Vanguard a v4.0.0 con repo público 100% limpio y homologado. El repo público gentle-vanguard-public ahora contiene SOLO el allowlist de distribución: protected/ (1679 .enc), src/ (605), docs/ (198), tests/ (162), public/ (111), demos/ (44), adapters/ (23), .github/ (12), scripts/gentle-vanguard/ (bootstrap TS), config/ (9 .example + 3 runtime). CERO .ps1, CERO apps, README 4.0.0, installer nuevo (Gentle-Vanguard.exe 17.2 MB + .sha256).

**Why**: El usuario pidió que el stack completo esté actualizado en el repo privado, homologado al público y con el .exe instalador subido para que la gente pueda instalar el stack desde cero. Además: "no deberiamos tener ps1 en el repo", "no deberiamos tener ninguna app", "debemos dejar todo homologado, actualizado y documentado".

**Where**:
- src/infrastructure/sync-to-public.ts (4 mejoras: elimina apps, limpia .ps1, limpia directorios stale, limpia archivos root stale)
- docs/guides/HOMOLOGATION-GUIDE.md (reglas actualizadas: 0 .ps1, 0 apps, allowlist)
- README-PUBLIC.md (4.0.0)
- C:\Workspace_local\gentle-vanguard-public (repo público local, develop/main sync + tag v4.0.0 + GitHub Release)
- dist/Gentle-Vanguard-Setup-4.0.0.exe + .sha256

**Learned**:
1. **Bug NSIS real**: makensis rechaza .nsi con em-dash (—, U+2014) en UTF-8 sin BOM — NSIS lee como ACP. Fix: ASCII puro en template (3 líneas cabecera + 1 DetailPrint).
2. **sync-to-public.ts copiaba .exe legacy**: buscaba dist/Gentle-Vanguard.exe (31 MB) pero build genera dist/Gentle-Vanguard-Setup-<ver>.exe. Fix: regex para installer versionado más reciente + copia .sha256.
3. **commitlint exige conventional commits**: git merge --no-edit falla; usar git commit -m "chore(merge): ..." explícito.
4. **120 .ps1 + 4 bootstrap .ps1 + 179 apps/web-dashboard** en el público eran deuda histórica pre-existente (no introducida por mi sync). El sync ahora los elimina automáticamente.
5. **Directorios/archivos root stale** (26 dirs + 25 archivos) no copiados por el sync pero que sobrevivían de syncs anteriores. Fix: allowlist explícito + limpieza automática en sync-to-public.ts.
6. **Code signing no configurado** (GV_SIGNTOOL_PATH/GV_SIGNING_CERT ausentes) → SmartScreen warning. Opción práctica: Azure Trusted Signing (~$10/mes) o certificado anual (~$200-400/año). Stack ya tiene soporte en create-installer.ts.
7. **Commits clave**: 0f561554 (fix NSI), 6d0d141e (fix sync installer), 257831e5 (fix sync limpieza total), 109a929e (docs HOMOLOGATION-GUIDE), tag v4.0.0 en público, Release https://github.com/EmmanuelOrtiz87/gentle-vanguard-public/releases/tag/v4.0.0

---
*Imported from Engram on 2026-09-08*
