# NORMATIVA: BACKUP DE MEMORIA PERSISTENTE (ENGRAM)

**Versión:** 1.0.0 | **Vigencia:** Inmediata | **Stack:** Gentle-Vanguard

## Propósito

Proteger la memoria persistente del proyecto (observaciones, relaciones, sesiones,
decisiones arquitectónicas) contra pérdida de datos por corrupción, borrado accidental,
migración de entorno, o fallo de disco.

## Reglas Obligatorias

| # | Regla | Sanción |
|---|-------|---------|
| 1 | **Backup automático post-sesión** — Al cerrar sesión, `backup-engram.ps1` debe ejecutarse automáticamente vía session-manager. | Session-end audit lo detecta |
| 2 | **Formato append-only NDJSON** — El backup primario debe usar NDJSON (Newline-Delimited JSON) para observaciones, relaciones y sesiones. | Review rechaza formato diferente |
| 3 | **Git-based rollback** — El directorio `.engram-data/` debe tener un repositorio git interno para versionado y rollback granular. | Health check verifica git log |
| 4 | **Verificación semanal de integridad** — `backup-engram.ps1 -Verify` debe ejecutarse semanalmente (GitHub Action o scheduled task). | Dashboard alerta si no se ejecuta |
| 5 | **Retención mínima de 30 días** — Backups anteriores a 30 días pueden comprimirse (gzip) pero no eliminarse hasta 90 días. | Auditoría trimestral |

## Formato de Backup

```
.backups/engram/
├── observations-YYYYMMDD.ndjson   → Backup diario de observaciones
├── relations-YYYYMMDD.ndjson      → Backup diario de relaciones
├── sessions-YYYYMMDD.ndjson       → Backup diario de sesiones
└── manifest.json                  → Checksum SHA256 de todos los archivos
```

## Verificación de Integridad

El comando `backup-engram.ps1 -Verify` ejecuta:
1. Parsear cada línea NDJSON con `ConvertFrom-Json` — fallo en cualquier línea = backup corrupto
2. Verificar integridad referencial (todo ID de relación existe como observación válida)
3. Comparar conteo contra manifest checksum
4. Verificar timestamps en orden ascendente
5. Simular 3 consultas: exact match, búsqueda, replay de sesión

## Restauración

```powershell
# Restaurar desde backup más reciente
.\backup-engram.ps1 -Restore -Date 20260530

# Restaurar a un commit específico de git
cd .engram-data && git checkout <commit-hash>
```

## Excepciones

No se permiten excepciones a la regla #1 (backup post-sesión). Las demás reglas
pueden tener excepciones temporales (< 48h) con aprobación documentada.

## Referencias

- `scripts/utilities/BACKUP-RESTORE/backup-engram.ps1` — script de backup/restore/verify
- `.engram-data/` — repositorio git de memoria persistente
- `.backups/engram/` — backups NDJSON exportados
- `scripts/health-check/health-check.ps1` — health check integrado
