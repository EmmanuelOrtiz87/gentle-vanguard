# NORMATIVAS-CHAOS-ENGINEERING.md — Chaos Engineering Standards

Version: 1.0.0
Framework: Principles of Chaos Engineering (principlesofchaos.org) + LitmusChaos + Chaos Mesh
Last updated: 2026-05-11

---

## 1. PROPOSITO

Define los estandares de Chaos Engineering para el stack Gentle-Vanguard. Establece la madurez de resiliencia, experimentos controlados de caos, y verificacion de que los sistemas soportan fallos inesperados sin degradacion catastrófica.

---

## 2. PRINCIPIOS DE CHAOS ENGINEERING

| Principio | Descripcion | Implementacion |
|-----------|-------------|----------------|
| Hypothesize | Definir estado estable antes del experimento | SLOs como baseline |
| Vary real-world events | Simular fallos realistas | Network latency, packet loss, process kill |
| Run in production | Experimentar en entorno productivo controlado | Canary deployments + blast radius |
| Automate | Experimentos automaticos y repetibles | CI/CD pipeline chaos jobs |
| Minimize blast radius | Limitar impacto a usuarios reales | Circuit breakers + feature flags |

---

## 3. MADUREZ DE RESILIENCIA

### 3.1 Niveles de Madurez

| Nivel | Nombre | Caracteristicas | Timeline |
|-------|--------|-----------------|----------|
| L0 | Reactive | Sin experimentos, respuesta a incidentes | Current |
| L1 | Observability | Metricas, logs, tracing implementados | Q2 2026 |
| L2 | Static Resilience | Circuit breakers, retries, timeouts implementados | Q2 2026 |
| L3 | Game Days | Experimentos de caos manuales planificados | Q3 2026 |
| L4 | Automated Resilience | Experimentos automaticos en CI/CD | Q4 2026 |
| L5 | Self-Healing | Recuperacion automatica sin intervencion humana | 2027 |

---

## 4. EXPERIMENTOS DE CHAOS

### 4.1 Tipos de Experimentos

| Tipo | Descripcion | Herramienta | Frecuencia |
|------|-------------|-------------|------------|
| Pod kill | Terminar procesos aleatorios | Chaos Mesh | Semanal |
| Network latency | Inyectar latencia en comunicaciones | Toxiproxy | Quincenal |
| Packet loss | Perdida de paquetes simulada | tc (traffic control) | Quincenal |
| Resource exhaustion | CPU/mem/disk al limite | stress-ng | Mensual |
| DNS failure | Fallo de resolucion DNS | iptables / /etc/hosts | Mensual |
| Certificate expiry | Certificado expirado o invalido | Fecha manipulada | Trimestral |
| Dependency outage | Servicio externo caido | Mock / stub | Semanal |

### 4.2 Blast Radius Control

`
Experiment -> Canary instance -> 1% traffic -> 10% -> Production with circuit breakers
`

1. **MUST** empezar en entorno de staging/pre-prod
2. **MUST** tener automatic rollback si SLO se viola
3. **MUST** notificar al equipo antes del experimento
4. **MUST** tener blast radius configurable
5. **SHOULD** usar feature flags para desactivar experimento en cualquier momento

### 4.3 Hypothesize-Experiment-Prove Cycle

`powershell
# Script de experimento de caos
function Invoke-ChaosExperiment {
    param(
        [string],
        [string],
        [hashtable],
        [scriptblock]
    )

    # 1. Verify steady state
     = Measure-ServiceHealth -Service 
    Assert-SteadyState -Baseline  -Expected 

    # 2. Inject fault
    & 

    # 3. Measure impact
    Start-Sleep -Seconds 10
     = Measure-ServiceHealth -Service 

    # 4. Verify hypothesis
    if (.violations -gt .maxViolations) {
        Write-Error "Experiment FAILED:  - system degraded beyond hypothesis"
        Invoke-Rollback -Service 
    } else {
        Write-Host "Experiment PASSED:  - system within expected parameters"
    }

    # 5. Cleanup
    Invoke-FaultCleanup
}
`

---

## 5. AUTOMATION EN CI/CD

`yaml
- name: Chaos Experiment - Network Latency
  shell: pwsh
  run: |
    ./scripts/chaos/inject-network-latency.ps1 -Service mcp-bridge -LatencyMs 500
    # Run integration tests under chaos
    Invoke-Pester tests/integration/ -Tag Chaos
`

---

## 6. COMPLIANCE CHECKPOINTS

TODO implementacion DEBE verificar:

1. [ ] Steady state definido para cada servicio critico
2. [ ] Experimentos automatizados en CI/CD
3. [ ] Circuit breakers implementados en puntos de integracion
4. [ ] Timeouts configurados en todas las llamadas externas
5. [ ] Retry logic con exponential backoff
6. [ ] Bulkheads implementados para aislamiento de fallos
7. [ ] Automatic rollback ante SLO violation
8. [ ] Game days planificados trimestralmente
9. [ ] Post-experimento analysis documentado
10. [ ] Blast radius configurable y limitado

---

## 7. REFERENCIAS

| Resource | Path |
|----------|------|
| Principles of Chaos | principlesofchaos.org |
| Chaos Mesh Docs | chaos-mesh.org |
| LitmusChaos Docs | litmuschaos.io |
| SRE Practices | docs/NORMATIVAS-SRE.md |
| Error Handling | rules/NORMATIVAS-ERROR-HANDLING.md |
| Performance Standards | rules/NORMATIVAS-PERFORMANCE.md |

---

_Version: 1.0.0 - 2026-05-11 - Status: ACTIVE_

