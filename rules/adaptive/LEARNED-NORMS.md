# Learned Norms (Autonomous)

Auto-maintained by auto-norm-learner.ps1 — last run: 2026-06-04 00:30

## DOC Norms

| ID      | Norm                                                             | Confidence | Source        | Date       |
| ------- | ---------------------------------------------------------------- | ---------- | ------------- | ---------- |
| DOC-001 | README público y privado deben ser diferentes                    | high       | session-audit | 2026-06-04 |
| DOC-002 | Presentación debe tener mínimo 10 slides con contenido completo  | high       | session-audit | 2026-06-04 |
| DOC-003 | STACK-STATUS-REPORT.md debe reflejar versión actual del proyecto | medium     | session-audit | 2026-06-04 |

## CORR Norms

| ID       | Norm                                                                  | Confidence | Source        | Date       |
| -------- | --------------------------------------------------------------------- | ---------- | ------------- | ---------- |
| CORR-001 | auto-norm-enforcer silenciado con Out-Null — no ocultar su salida     | high       | session-fix   | 2026-06-04 |
| CORR-002 | auto-norm-learner no produce normas sin Engram — proveer seed inicial | high       | session-fix   | 2026-06-04 |
| CORR-003 | sync-to-public.ps1 no debe copiar docs/sdd/ ni docs/README.md         | high       | session-audit | 2026-06-04 |

## LEARN Norms

| ID        | Norm                                                                    | Confidence | Source          | Date       |
| --------- | ----------------------------------------------------------------------- | ---------- | --------------- | ---------- |
| LEARN-001 | Archivos huérfanos en raíz deben moverse a directorios correspondientes | high       | session-audit   | 2026-06-04 |
| LEARN-002 | Archivos residuales (0 bytes, JSON response) deben eliminarse           | high       | session-cleanup | 2026-06-04 |
| LEARN-003 | El enforcement de normativas debe ser automático (pre-commit) no manual | medium     | session-audit   | 2026-06-04 |

## GEN Norms

| ID      | Norm                                                            | Confidence | Source               | Date       |
| ------- | --------------------------------------------------------------- | ---------- | -------------------- | ---------- |
| GEN-001 | Preferir pwsh sobre powershell para scripts nuevos              | high       | learned              | 2026-06-04 |
| GEN-002 | Usar env:GV_BASE_DIR como path base en vez de hardcode          | high       | learned              | 2026-06-04 |
| GEN-003 | Usar Write-Output en vez de Write-Host en scripts reutilizables | high       | NORMATIVAS-CODIGO.md | 2026-06-04 |

## Statistics

- Total norms: 10
- New norms: 10
- Updated norms: 0
- Promoted norms: 0
- Pruned stale norms: 0
- Last trigger: manual
