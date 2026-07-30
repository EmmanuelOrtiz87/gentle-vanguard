# STALE-FILE-CLEANUP — Limpieza de Archivos Obsoletos

**Versión:** 1.0 | **Vigente desde:** July 14, 2026 | **Aplica a:** v5.1+

## 1. Propósito

Mantener el repositorio libre de archivos huérfanos, scripts migrados, configuraciones obsoletas y
código muerto. La limpieza es trimestral, controlada y siempre preserva el historial moviendo a
`.archive/` en lugar de eliminar definitivamente.

## 2. Política de Archivado

### 2.1 Ubicación

- Los archivos obsoletos se mueven a `.archive/<año>/<mes>/` conservando la estructura original
- Ejemplo: `scripts/health-check/old-script.ps1` →
  `.archive/2026/07/scripts/health-check/old-script.ps1`
- No se permite `git rm` como primera acción; siempre mover primero y luego commit del movimiento

### 2.2 Qué se Archiva

- Scripts TypeScript reemplazados por versiones TypeScript (ver checklist §3)
- Configuraciones sin referencias activas después de 90 días
- Archivos de documentación duplicados o fusionados
- Plantillas de skill o agent que ya no están en uso
- Reportes y artefactos generados manualmente (no los del pipeline automático)

## 3. Checklist de Migración PS1 → TS

- [ ] La versión TS cubre toda la funcionalidad del PS1 original
- [ ] Todos los callers del PS1 han sido actualizados para apuntar al TS
- [ ] Los `npm run` scripts apuntan a la versión TS
- [ ] No hay referencias al PS1 en `session-autostart.config.json` ni en workflows
- [ ] El PS1 original existe y es funcional (como respaldo antes de archivar)
- [ ] Se ejecutaron las pruebas de la versión TS con éxito
- [ ] Se notifica al equipo del archivado

## 4. Detección de Archivos Obsoletos

### 4.1 Por Antigüedad

- Archivos sin modificar en >180 días se marcan como candidatos
- La detección usa `git log --diff-filter=M -1 --format="%ct" <file>` para última modificación
- Archivos con `ctime` >180 días y sin commits en >180 días entran en la lista

### 4.2 Por Huérfanos

- Archivos `*.ps1` sin correspondencia en `src/` después de migración completa
- Archivos de configuración en `config/` no referenciados por ningún script activo
- Archivos de prueba para código que ya no existe

## 5. Ejecución

- La limpieza se realiza el primer viernes de cada trimestre (enero, abril, julio, octubre)
- Se genera un reporte preview antes de ejecutar: `scripts/utilities/stale-file-report.ps1`
- El reporte lista candidatos con: ruta, última modificación, último commit, referencias activas
- Se requiere aprobación humana antes de proceder al archivado

## 6. Excepciones

- Archivos en `.gitignore` (generados, cachés, dependencias) no se archivan
- `.env` y archivos de secretos se eliminan de forma segura, no se archivan
- Archivos marcados como `@preserve` en el header del archivo exentos de limpieza
