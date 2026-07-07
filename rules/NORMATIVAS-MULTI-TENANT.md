# NORMATIVA: Multi-Tenant Isolation (v5.1)

**Versión:** 1.0 | **Vigente desde:** July 6, 2026 | **Aplica a:** v5.1+

## 1. Propósito

Garantizar que múltiples proyectos/equipos compartan el mismo orquestador sin fuga de datos,
contención de recursos ni interferencia cruzada entre tenants.

## 2. Reglas

### 2.1 Identificación de Tenant

- El Tenant ID se resuelve en este orden: `$env:GENTLE_TENANT_ID` → `tenant-config.json` → nombre
  del workspace folder
- Si no se encuentra ninguno → modo single-tenant (backward compatible)
- El Tenant ID debe ser alphanumérico (guiones permitidos): `^[a-zA-Z0-9\-]+$`

### 2.2 Aislamiento de Paths

- `.session/<tenant_id>/` — sesiones, config, cachés
- `.codegraph/<tenant_id>/` — índices CodeGraph
- `.telemetry/<tenant_id>/` — telemetría y tracing
- `.runtime/<tenant_id>/` — archivos runtime (PIDs, logs)
- Todos los paths deben pasar por `Get-TenantContext` — NUNCA hardcodear `.session/`

### 2.3 Aislamiento de Datos

- Engram: usar `-Project "gentle-vanguard:<tenant_id>"` para scoping
- Dashboard: filtro `?tenant=<id>` en endpoints de API
- Auditoría: logs separados por tenant en `.session/<tenant>/audit/`
- Watchtower: health checks independientes por tenant

### 2.4 Seguridad

- Cross-tenant data access: PROHIBIDO sin autorización explícita
- Tenant context validation en cada gate del SDD pipeline
- `Test-TenantIsolation` debe ejecutarse en cada sesión multi-tenant

## 3. Excepciones

- Recursos compartidos de solo lectura (templates, normativas raíz) no requieren aislamiento
- Dashboard puede mostrar vista consolidada si `GENTLE_MULTI_TENANT=true`

## 4. Penalizaciones

- Violación de aislamiento → rollback automático + incidente de seguridad
- Hardcodeo de paths sin tenant → revisión de código obligatoria
