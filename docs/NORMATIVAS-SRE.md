# NORMATIVAS-SRE.md — Site Reliability Engineering Standards

Version: 1.0.0
Framework: Google SRE Book principles + SLI/SLO/SLA taxonomy
Last updated: 2026-05-11

---

## 1. PROPOSITO

Define los estandares de Site Reliability Engineering (SRE) para el stack Gentle-Vanguard. Aplica a todos los servicios, scripts, workflows, y agentes. Establece SLIs, SLOs, y error budgets para garantizar confiabilidad medible.

---

## 2. JERARQUIA DE CONFIABILIDAD

### 2.1 Definiciones

| Termino | Significado | Ejemplo |
|---------|-------------|---------|
| SLI | Metrica cuantitativa de un aspecto del servicio | Latencia de dispatch de agente |
| SLO | Valor objetivo para un SLI | Dispatch < 500ms el 99% del tiempo |
| SLA | Compromiso contractual (externo) | 99.5% uptime mensual |
| Error Budget | Tolerancia a fallos = 100% - SLO | 1% de fallos permitido (8.76h/mes) |

### 2.2 SLO Hierarchy

Service SLO (global) -> Component SLOs (por agente, script, workflow) -> SLIs (metricas individuales) -> Raw metrics (logs, traces, counters)

---

## 3. SLIs DEL STACK Gentle-Vanguard

### 3.1 Agent Performance SLIs

| SLI | Metrica | Fuente |
|-----|---------|--------|
| Agent dispatch latency | Tiempo entre trigger y skill loaded | metrics-config.json |
| Agent task completion rate | % de tareas completadas sin error | agent-usage.csv |
| Agent retry rate | % de tareas que requirieron retry | failure-learning-system.ps1 |
| Agent hallucination rate | % de outputs marcados como hallucination | Hallucination guard logs |

### 3.2 Script Performance SLIs

| SLI | Metrica | SLO |
|-----|---------|-----|
| Interactive script latency | < 2s p95 | >= 99% |
| Pre-commit hook latency | < 5s p95 | >= 95% |
| CI step duration | < 30s p95 | >= 95% |
| Audit sweep (quick) | < 30s p95 | >= 90% |

### 3.3 CI/CD SLIs

| SLI | Metrica | SLO |
|-----|---------|-----|
| Pipeline success rate | % de pipelines verdes | >= 95% sobre ventana de 7 dias |
| Pipeline duration | Tiempo total de pipeline | < 15min p95 |
| Deployment frequency | Despliegues a main/semana | >= 2 (meta: daily) |
| Change failure rate | % de cambios que causan incidentes | < 10% |

### 3.4 Security SLIs

| SLI | Metrica | SLO |
|-----|---------|-----|
| Vulnerability fix time (CRITICAL) | Tiempo desde deteccion a fix | < 48h |
| Vulnerability fix time (HIGH) | Tiempo desde deteccion a fix | < 7 dias |
| Secret detection latency | Tiempo entre commit y alerta | < 5min |
| Policy compliance rate | % de configs que pasan validacion | >= 99% |

### 3.5 Quality SLIs

| SLI | Metrica | SLO |
|-----|---------|-----|
| Test pass rate | % de tests pasando | >= 99% |
| Code coverage (critical) | Coverage en scripts criticos | >= 80% |
| WCAG violation rate | Violaciones criticas por release | 0 |
| ISO 25010 compliance | Caracteristicas sobre threshold | 8/8 |

---

## 4. ERROR BUDGETS

### 4.1 Budget Definition

| Componente | SLO | Periodo | Budget |
|-----------|-----|---------|--------|
| Agent dispatch | 99% | 30d | 25920s (1%) |
| Script performance | 95% | 7d | 30240s (5%) |
| Pipeline success | 95% | 7d | ~3 fallos/semana |

### 4.2 Budget Consumption

| Consumo | Accion |
|---------|--------|
| < 50% | Normal, deploy continua |
| 50-75% | Warning: revisar cambios recientes |
| 75-90% | Freeze deploys no criticos |
| > 90% | Full freeze, solo hotfixes |

---

## 5. TOIL REDUCTION

### 5.1 Definicion de Toil

| Caracteristica | Ejemplo Gentle-Vanguard | Accion |
|----------------|-------------------|--------|
| Manual | Validacion manual de configs | Automatizar con validate-configs.ps1 |
| Repetitivo | Revision semanal de logs | Dashboard automatico |
| Sin valor duradero | Limpieza manual de sessions | post-task-cleanup.ps1 |
| Escala lineal | Revision de N skills manual | check-skills.ps1 automatico |

### 5.2 Toil Budget

- **Maximo 50%** del tiempo del equipo/agente en toil
- Cualquier tarea manual ejecutada > 3 veces en un mes DEBE ser automatizada

---

## 6. INCIDENT MANAGEMENT

### 6.1 Severity Levels

| Severity | Nombre | Response Time | SLO Impact |
|----------|--------|---------------|------------|
| SEV1 | Critical outage | < 15min | SLO breach |
| SEV2 | Major feature broken | < 1h | Near SLO breach |
| SEV3 | Minor feature degraded | < 4h | No SLO impact |
| SEV4 | Cosmetic / low impact | < 24h | No SLO impact |

### 6.2 Incident Response Flow

Detection -> Triage (severity classification) -> Mitigation (rollback / fix-forward) -> Root cause analysis -> Blameless postmortem -> Action items -> Verify fix in production

### 6.3 Postmortem Requirements

1. **MUST** escribirse dentro de 48h del SEV1/SEV2
2. **MUST** incluir timeline, root cause, action items
3. **MUST** ser blameless (no culpar personas)
4. **MUST** generar al menos 1 action item automatizable
5. **SHOULD** incluir metricas de impacto (duracion, usuarios afectados, SLO consumption)

---

## 7. COMPLIANCE CHECKPOINTS

TODO implementacion DEBE verificar:

1. [ ] SLIs definidos para cada componente critico
2. [ ] SLOs con objetivos medibles y alcanzables
3. [ ] Error budgets definidos y monitoreados
4. [ ] Toil tracking implementado
5. [ ] Incident response flow documentado
6. [ ] Postmortem template disponible
7. [ ] Dashboard de SLOs accesible
8. [ ] Alertas configuradas para SLO breaches
9. [ ] CI gate bloquea si error budget excedido
10. [ ] Revision trimestral de SLOs

---

## 8. REFERENCIAS

| Resource | Path |
|----------|------|
| Google SRE Book | sre.google/books |
| Performance Standards | rules/NORMATIVAS-PERFORMANCE.md |
| Error Handling | rules/NORMATIVAS-ERROR-HANDLING.md |
| Quality Gates | config/quality-gates.json |
| Monitoring Dashboard | scripts/monitoring/executive-dashboard.ps1 |

---

_Version: 1.0.0 - 2026-05-11 - Status: ACTIVE_


