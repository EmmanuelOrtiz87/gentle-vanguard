---
created: 2026-06-04 02:42:29
tags: [engram, architecture]
engram_id: 1327
type: architecture
---

# Auditoría integral y reingeniería de governance

**What**: Auditoría completa del stack Gentle-Vanguard: READMEs, archivos huérfanos, presentación, normativas, enforcement. Se diferenciaron README público vs privado, se reorganizaron 11 archivos de raíz a directorios, se restauró presentación de 4 a 12 slides, se creó normative-audit-pipeline.ps1 con 6 checks automáticos + hook pre-commit, y se corrigió sync-to-public.ps1.

**Why**: El usuario reportó múltiples incumplimientos: READMEs idénticos, archivos huérfanos, presentación con solo 4 slides (eran 21), normativas no respetadas, enforcement manual, warnings y archivos residuales.

**Where**: README.md, README-PUBLIC.md, gentle-vanguard-presentation.html, scripts/utilities/normative-audit-pipeline.ps1, .lefthook.yml, scripts/utilities/DEPLOYMENT/sync-to-public.ps1, docs/MANIFESTO.md (moved), docs/SECURITY.md (moved), etc.

**Learned**:
- La normativa NORMATIVAS-CODIGO.md §4.3 prohíbe Write-Host y Select-String pero ~300+ scripts los usan → el enforcement debe ser gradual o la normativa debe relajarse para scripts de utilería
- auto-norm-enforcer estaba silenciado con Out-Null → violaciones nunca reportadas al usuario
- El sync-to-public.ps1 copiaba docs/README.md (419 líneas de datos internos) al repo público
- LEARNED-NORMS.md vacío → el ciclo de aprendizaje autónomo no funciona

---
*Imported from Engram on 2026-09-06*
