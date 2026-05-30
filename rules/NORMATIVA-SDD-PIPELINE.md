# NORMATIVA: SDD Pipeline

**Versión:** 1.0.0 | **Vigencia:** Inmediata | **Stack:** Gentle-Vanguard

## Propósito

Estandarizar la ejecución del SDD Lifecycle automatizado, asegurando que cada fase
produzca artefactos válidos, gates aprobados, y que el pipeline completo sea
repetible y auditable.

## Reglas Obligatorias

| # | Regla | Sanción |
|---|-------|---------|
| 1 | **Feature name obligatorio** — Toda invocación debe incluir `-Feature <name>` alfanumérico sin espacios | Script reject |
| 2 | **Artefactos en .sdd/** — Cada feature produce artefactos en `.sdd/<feature>/<phase>/artifact.md` con gates en `.sdd/<feature>/gate-<phase>.json` | CI/CD verify |
| 3 | **Gates entre fases** — Cada fase debe producir un gate PASS antes de avanzar a la siguiente | Pipeline reject |
| 4 | **DryRun antes de real** — Toda feature nueva debe ejecutarse primero con `-DryRun` | Code review |
| 5 | **Sin commits de artefactos** — `.sdd/` está en `.gitignore`; nunca commitearte los artefactos | Pre-commit reject |

## Phases

```
INIT → EXPLORE → PROPOSE → SPEC → TASKS → DESIGN → APPLY → VERIFY → ARCHIVE
```

Cada fase genera:
- `.sdd/<feature>/<phase>/artifact.md` — artefacto de la fase
- `.sdd/<feature>/gate-<phase>.json` — gate con status PASS/FAIL + timestamp

## Commands

| Operación | Comando |
|-----------|---------|
| Pipeline completo | `pwsh scripts/sdd-pipeline/sdd-pipeline.ps1 -Feature "<name>" -Description "<desc>"` |
| Fase específica | `pwsh scripts/sdd-pipeline/sdd-pipeline.ps1 -Feature "<name>" -Description "<desc>" -Phase INIT` |
| Dry run | `pwsh scripts/sdd-pipeline/sdd-pipeline.ps1 -Feature "<name>" -Description "<desc>" -DryRun` |
| Health check | `pwsh scripts/health-check/health-check.ps1 -Component sdd` |

## Output Structure

```
.sdd/<feature>/
  INIT/artifact.md
  gate-INIT.json
  EXPLORE/artifact.md
  gate-EXPLORE.json
  ...
  ARCHIVE/artifact.md
  gate-ARCHIVE.json
```

## Referencias

- `scripts/sdd-pipeline/sdd-pipeline.ps1` — implementación
- `.gitignore` — entrada `.sdd/`
- `scripts/health-check/health-check.ps1` — verificación cross-component
