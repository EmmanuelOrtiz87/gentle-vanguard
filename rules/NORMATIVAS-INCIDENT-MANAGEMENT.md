# NORMATIVAS-INCIDENT-MANAGEMENT.md — Incident Response & Management

**Version:** 1.0.0 **Last updated:** 2026-06-01

---

## 1. PROPOSITO

Define el proceso de respuesta a incidentes para Gentle-Vanguard. Aplica a todos los componentes: agentes, CI/CD, infraestructura, y seguridad.

---

## 2. SEVERITY MATRIX

| Severidad | Tiempo Respuesta | Tiempo Mitigación | Ejemplos |
|-----------|-----------------|-------------------|----------|
| **P1 - Critical** | 15 min | 1 hora | Data breach, service outage, secrets exposed |
| **P2 - High** | 1 hora | 4 horas | Feature broken, CI/CD down, performance degradation |
| **P3 - Medium** | 4 horas | 24 horas | Bug no crítico, warning en logs |
| **P4 - Low** | 24 horas | 1 semana | Minor issue, cosmetic bug, documentation gap |

---

## 3. INCIDENT LIFECYCLE

```
DETECT → TRIAGE → CONTAIN → MITIGATE → RESOLVE → POST-MORTEM
```

### 3.1 Detection

Canales de detección:
- `health-check.ps1` (cada turno)
- `watchtower.ps1` (proactivo)
- CI/CD failures (GitHub Actions)
- Error budgets (`enforce-error-budget.ps1`)
- Usuario reporta

### 3.2 Triage

```powershell
# Comando de triage rápido
gv incident triage --description "<issue>" --severity P2
```

| Información requerida | Descripción |
|----------------------|-------------|
| ¿Qué pasó? | Descripción del incidente |
| ¿Cuándo? | Timestamp preciso |
| ¿Dónde? | Componente, workflow, archivo |
| ¿Impacto? | Usuarios afectados, datos perdidos |
| ¿Evidencia? | Logs, screenshots, stack traces |

### 3.3 Containment

| Técnica | Descripción | Para incidentes |
|---------|-------------|-----------------|
| Circuit breaker | Abrir circuito para componente afectado | P1, P2 |
| Failover | Cambiar a provider alternativo | P1 (API outage) |
| Rollback | Revertir deploy reciente | P1, P2 |
| Feature flag | Deshabilitar feature problemática | P2, P3 |
| Rate limit | Reducir tráfico al componente | P2 |

### 3.4 Mitigation

```powershell
# Ejecutar mitigación
gv incident mitigate --id INC-2026-001 --action failover

# Verificar mitigación
gv health check --component all
```

### 3.5 Resolution

Criterios para cerrar incidente:
- [ ] Síntoma principal resuelto
- [ ] Health check pasa
- [ ] Tests pasan
- [ ] Usuario confirmó solución
- [ ] Post-mortem creado (P1, P2)

---

## 4. INCIDENT COMMAND STRUCTURE

| Rol | Responsabilidad | Asignado por defecto |
|-----|----------------|---------------------|
| **IC** (Incident Commander) | Coordina respuesta, decisiones | GOV agent |
| **SME** (Subject Matter Expert) | Diagnóstico técnico | DEV/OPS agent |
| **Comms** | Comunicación a stakeholders | MKT agent |
| **Scribe** | Documentación del incidente | DOC agent |

---

## 5. POST-MORTEM

### 5.1 Template

```markdown
# Post-Mortem: INC-2026-XXX

## Resumen
- **Título**: [breve descripción]
- **Severidad**: P1/P2/P3/P4
- **Duración**: [inicio] → [fin]
- **Impacto**: [usuarios/datos afectados]

## Timeline
- [T00:00] Detección: [cómo]
- [T00:15] Triage: [severidad, componentes]
- [T00:30] Containment: [acción tomada]
- [T01:00] Mitigation: [solución aplicada]
- [T02:00] Resolution: [servicio restaurado]

## Root Cause
[Análisis de causa raíz]

## Action Items
- [ ] Fix preventivo: [descripción]
- [ ] Monitoreo: [nueva alerta/métrica]
- [ ] Documentación: [actualizar runbook]

## Lessons Learned
[Qué salió bien, qué salió mal, qué mejorar]
```

### 5.2 SLAs for Post-Mortem

| Severidad | Deadline |
|-----------|----------|
| P1 | 24 horas post-resolución |
| P2 | 72 horas |
| P3 | 1 semana |
| P4 | 2 semanas |

---

## 6. INCIDENT TRACKING

### 6.1 Local Incident Log

```json
// .session/incidents/inc-2026-001.json
{
  "id": "INC-2026-001",
  "severity": "P2",
  "status": "resolved",
  "title": "CI/CD quality gate timeout",
  "detected_at": "2026-06-01T10:00:00Z",
  "resolved_at": "2026-06-01T11:30:00Z",
  "components": ["gentle-vanguard-quality-gate"],
  "root_cause": "Runner resource exhaustion",
  "action_items": [
    {"description": "Add timeout-minutes to all jobs", "done": true},
    {"description": "Add runner health check pre-job", "done": false}
  ]
}
```

### 6.2 Weekly Review

Cada lunes, GOV agent MUST:
1. Revisar incidentes abiertos
2. Verificar action items de post-mortems recientes
3. Actualizar runbooks según lecciones aprendidas
4. Reportar métricas de incidentes al orquestador

---

## 7. NOTIFICATION MATRIX

| Incidente | Notificar a | Canal |
|-----------|-------------|-------|
| P1 - Security breach | GOV + owner | GitHub Security Advisory |
| P1 - Service down | OPS + owner | GitHub Issues (urgent label) |
| P2 - Feature broken | DEV owner | GitHub Issue |
| P3 - Minor bug | Team | GitHub Issue (backlog) |
| CI/CD failure | OPS | GitHub Actions notification |

---

## 8. COMPLIANCE CHECKPOINTS

- [ ] Severity matrix definida y conocida por todos los agentes
- [ ] Incident command structure asignada
- [ ] Post-mortem template disponible
- [ ] Incident log creado (`.session/incidents/`)
- [ ] Notificaciones configuradas por severidad
- [ ] Runbooks actualizados post-incidente
- [ ] Weekly incident review schedule activo

---

## 9. REFERENCES

| Resource | Path |
|----------|------|
| Incident Response | `rules/INCIDENT-RESPONSE.md` |
| SRE Practices | `docs/NORMATIVAS-SRE.md` |
| Health Check | `scripts/health-check/health-check.ps1` |
| Watchtower | `scripts/utilities/watchtower.ps1` |
| Circuit Breaker | `config/circuit-breaker.json` |
| SOC2 Compliance | `rules/NORMATIVAS-SOC2.md` |

---

*Version: 1.0.0 — 2026-06-01 — Status: ACTIVE*
