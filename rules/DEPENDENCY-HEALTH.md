# DEPENDENCY-HEALTH — Salud de Dependencias

**Versión:** 1.0 | **Vigente desde:** July 14, 2026 | **Aplica a:** v5.1+

## 1. Propósito

Mantener las dependencias del proyecto actualizadas dentro de ventanas de tiempo definidas,
minimizando la deuda técnica, riesgos de seguridad y breaking changes acumulados.

## 2. Reglas de Actualización

### 2.1 Versiones Máximas

- Ninguna dependencia puede estar más de 1 major version por detrás de la última estable
- Dependencias directas y transitivas están sujetas a la misma regla
- Excepción: dependencias con breaking changes no compatibles con la arquitectura actual

### 2.2 Revisiones Mensuales

- El primer lunes de cada mes se ejecuta una revisión completa de dependencias
- La revisión se registra en `.session/deps/review-YYYY-MM.json`
- El reporte incluye: versión actual, versión disponible, changelog resumen, riesgo estimado

## 3. Herramientas de Automatización

### 3.1 Renovate / Dependabot

- `config/renovate.json` o `.github/dependabot.yml` deben estar presentes y activos
- Configuración mínima: schedule semanal, auto-merge para patches, PR para minors y majors
- Ambos deben reportar a `#deps` channel en Slack

### 3.2 Ventanas de Migración

| Tipo de Cambio | Ventana de Migración | Acción si se Vence  |
| -------------- | -------------------- | ------------------- |
| Patch          | 7 días               | Auto-merge          |
| Minor          | 14 días              | Alerta en dashboard |
| Major          | 14 días              | PR obligatorio      |
| Security       | 7 días               | Hotfix inmediato    |

## 4. Parches de Seguridad

- Vulnerabilidades con CVE asignado tienen prioridad máxima
- Ventana máxima de resolución: 7 días desde la publicación del fix
- Si no hay fix upstream en 7 días, evaluar workaround o fork temporal
- Todas las vulnerabilidades se registran en `.session/audit/vulnerabilities/`

## 5. Excepciones

- Dependencias deprecated oficialmente sin reemplazo directo exentas de la regla de versión
- Dependencias internas del monorepo siguen su propio ciclo de release
- Congelamiento de dependencias en períodos de release freeze (documentado en `config/freeze.json`)

## 6. Penalizaciones

- Dependencia >1 major behind sin exención → alerta quincenal
- Vulnerabilidad sin parche >14 días → escalación a security lead
- Ausencia de revisión mensual por 2 meses consecutivos → post-mortem obligatorio
