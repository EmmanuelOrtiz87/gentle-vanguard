# NORMATIVA: INTEGRIDAD DEL SISTEMA

**Versión:** 1.0.0 | **Vigencia:** Inmediata | **Stack:** Gentle-Vanguard

## Propósito

Garantizar que todos los componentes del stack estén integrados, funcionales y
verificables. Ningún cambio puede romper la cadena de integración sin ser detectado
y revertido.

## Reglas Obligatorias

| # | Regla | Sanción |
|---|-------|---------|
| 1 | **Health check pasa siempre** — `scripts/health-check/health-check.ps1` debe retornar 0 exit code antes de cualquier commit. | Pre-commit hook lo rechaza |
| 2 | **Optimization stack verificado** — `scripts/validation/verify-optimization-stack.ps1` debe pasar antes de merge a main. | CI/CD gate |
| 3 | **CodeGraph index fresco** — El índice no puede tener más de 7 días de antigüedad. `codegraph-sync-autostart.ps1` verifica en cada sesión. | Health check alerta |
| 4 | **Backup de engram post-sesión** — Toda sesión debe ejecutar `backup-engram.ps1 -Mode backup` al cerrar. | Session-end audit |
| 5 | **Sin errores de parser en scripts** — 0 errores en PSScriptAnalyzer para scripts en `scripts/` y `tests/`. | CI/CD reject |
| 6 | **Integración cross-componente** — Ningún componente puede depender de otro sin declaración explícita en `config/orchestrator.json`. | Review obligatorio |
| 7 | **Dependency graph verificable** — `pnpm-lock.yaml` debe estar actualizado y consistente con `package.json`. | CI/CD reject |
| 8 | **Zero secrets en repo** — Gitleaks y Trivy deben pasar en cada PR. | CI/CD reject automático |

## Pipeline de Verificación Pre-Commit

```powershell
# Ejecutar antes de cada commit:
pwsh -NoProfile -File scripts/health-check/health-check.ps1 -Quiet      # Componentes
pwsh -NoProfile -File scripts/validation/verify-optimization-stack.ps1  # Optimizaciones
```

## Recuperación ante Falla

Si algún check falla:

1. **Leer el reporte** — identificar qué componente falló y por qué
2. **Corregir o revertir** — el cambio que introdujo la falla
3. **Re-ejecutar** — el pipeline completo hasta que todos los checks pasen
4. **Documentar** — en `.exceptions/` si la falla requiere cambio en normativa

## Excepciones

Solo se permiten excepciones a reglas individuales con:

- Issue documentado en `.exceptions/<rule-id>-<date>.md`
- Aprobación de lead técnico
- Plan de re-mediación con fecha límite (< 7 días)

## Referencias

- `scripts/health-check/health-check.ps1` — health check cross-componente
- `scripts/validation/verify-optimization-stack.ps1` — verificación del optimization stack
- `scripts/utilities/BACKUP-RESTORE/backup-engram.ps1` — backup de engram
- `rules/NORMATIVA-OPTIMIZATION-STACK.md` — reglas de optimización
- `rules/NORMATIVA-ENGRAIN-BACKUP.md` — reglas de backup
- `.github/workflows/` — CI/CD gates configurados
