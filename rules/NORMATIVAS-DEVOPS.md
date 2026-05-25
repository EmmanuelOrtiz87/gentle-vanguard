# DevOps Normatives

**Version:** 1.0.0 **Last updated:** 2026-05-23

---

## DevOps Normatives

### 1. CI/CD Pipeline Standards

#### 1.1 Pipeline Stages

```
Commit → Build → Test → Security → Deploy → Monitor
```

#### 1.2 Stage Requirements

**Commit Stage**:

- Code checkout
- Dependency resolution
- Compilation/build
- Artifact creation

**Test Stage**:

- Unit tests
- Integration tests
- Code coverage
- Quality gates

**Security Stage**:

- SAST scanning
- Dependency scanning
- Secret scanning
- Compliance checks

**Deploy Stage**:

- Environment preparation
- Deployment
- Smoke tests
- Health checks

**Monitor Stage**:

- Metrics collection
- Log aggregation
- Alert configuration
- Trend analysis

### 2. Deployment Procedures

#### 2.1 Deployment Strategies

- Blue-green deployment
- Canary deployment
- Rolling deployment
- Feature flags
- Rollback procedures

#### 2.2 Deployment Checklist

- [ ] All tests passing
- [ ] Security scan passed
- [ ] Performance validated
- [ ] Documentation updated
- [ ] Stakeholders notified
- [ ] Rollback plan ready
- [ ] Monitoring configured

### 3. Monitoring Requirements

#### 3.1 Monitoring Metrics

- Application metrics
- Infrastructure metrics
- Business metrics
- User experience metrics
- Security metrics

#### 3.2 Monitoring Tools

- Metrics collection (Prometheus)
- Log aggregation (ELK)
- Distributed tracing (Jaeger)
- Alerting (AlertManager)
- Dashboards (Grafana)

### 4. Incident Response

#### 4.1 Incident Management

- Detection and alerting
- Incident creation
- Escalation
- Response
- Resolution
- Post-mortem

#### 4.2 Incident Communication

- Stakeholder notification
- Status updates
- Resolution communication
- Post-incident report

### 5. Disaster Recovery

#### 5.1 DR Planning

- RTO (Recovery Time Objective): <1 hour
- RPO (Recovery Point Objective): <15 minutes
- Backup frequency: Every 15 minutes
- Backup retention: 30 days
- Disaster testing: Monthly

#### 5.2 DR Procedures

- Backup procedures
- Recovery procedures
- Testing procedures
- Documentation
- Training

### 6. Development Tooling

#### 6.1 CodeGraph Index Auto-Sync

El índice semántico de CodeGraph se mantiene fresco automáticamente mediante hooks de Lefthook:

| Evento        | Hook                | Script                                                             |
| ------------- | ------------------- | ------------------------------------------------------------------ |
| `post-commit` | `.lefthook.yml`     | `codegraph-post-modification-sync.ps1 -Trigger post-commit -Force` |
| `post-merge`  | `.lefthook.yml`     | `codegraph-post-modification-sync.ps1 -Trigger post-merge -Force`  |
| Session start | `session-autostart` | `codegraph-sync-autostart.ps1` (si índice >30min)                  |

**Propósito**: Evitar que el índice de CodeGraph quede obsoleto (>30min de antigüedad), lo que
genera warnings en toda herramienta que dependa de él para exploración del codebase.

**Verificación**: `codegraph status` — revisar `LastWriteTime` del archivo
`.codegraph/codegraph.db`.

---

_Version: 1.0.1 — 2026-05-24 — Status: ACTIVE_
