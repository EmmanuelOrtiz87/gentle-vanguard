# NORMATIVA: CI/CD Self-Healing (v5.1)

**Versión:** 1.0 | **Vigente desde:** July 6, 2026 | **Aplica a:** v5.1+

## 1. Propósito

Implementar auto-recuperación en el pipeline CI/CD para manejar fallos transitorios sin intervención
humana, y fallos permanentes con rollback automático.

## 2. Reglas

### 2.1 Retry con Backoff

- Todo job CI/CD debe usar `ci-retry-engine.ps1` para ejecución
- Fallos TRANSIENT: retry con exponential backoff (base 5s, max 60s, jitter 2s)
- Fallos PERMANENT: NO retry, trigger rollback inmediato
- Fallos SECURITY: halt + alerta + notificación inmediata
- Clasificación de fallos según patrones en `config/ci-self-heal.json`

### 2.2 Rollback Automático

- `ci-rollback-engine.ps1` revierte el último commit via `git revert`
- Solo aplica en branches seguras: `main`, `master`, `develop`
- Rollback requiere aprobación en branches no seguras
- Máximo 2 intentos de rollback consecutivos

### 2.3 Incident Logging

- Todo incidente se registra en `.session/audit/incidents/` con timestamp
- Incidentes PERMANENT y SECURITY → alerta en dashboard
- Formato: `{ failureType, job, attempts, resolution, duration }`

### 2.4 GitHub Actions Integration

- `.github/actions/self-heal/action.yml` wrapper para steps críticos
- Workflows de deploy, release y quality deben usar self-heal action
- Configuración vía `with: max-retries`

## 3. Excepciones

- Rollback deshabilitado si `autoRollback: false` en config
- Branches feature/hotfix exentos de rollback automático

## 4. Penalizaciones

- CI/CD sin self-heal wrapper → revisión obligatoria
- Rollback manual cuando automático estaba disponible → post-mortem
