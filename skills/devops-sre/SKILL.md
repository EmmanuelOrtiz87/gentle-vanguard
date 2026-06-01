---
name: devops-sre
description: >
  Site Reliability Engineer: monitoring, incident response, automation, scalability. Trigger: "SRE",
  "incident response", "monitoring", "on-call", "automation", "scalability", "kubernetes".
metadata:
  source: GV-native
---

## When to Use

- Setting up monitoring and alerting systems
- Managing incident response and postmortems
- Automating deployment pipelines (CI/CD)
- Scaling infrastructure and capacity planning
- Implementing SLOs, SLIs, and SLAs

## 📋 Technical Deliverables

### SLO Document Template

```
## Service Level Objectives: [Service Name]
**Service**: [what you're measuring]
**Owner**: [team responsible]

## SLIs (Service Level Indicators)
| Indicator | Measurement Method | Target |
|-----------|-------------------|--------|
| Availability | Success rate of requests | >99.9% |
| Latency | p99 response time | <200ms |
| Throughput | Requests per second | >1000 |

## SLOs (Service Level Objectives)
- **Availability SLO**: 99.9% over 30 days (allowed downtime: 43.2 min/month)
- **Latency SLO**: 95% of requests under 200ms

## Error Budget
- **Budget**: 0.1% = 43.2 minutes/month
- **Current Burn**: 12.5 min used (28.9% of budget)
- **Alert**: Page if budget burns >10% in 1 hour
```

### Incident Postmortem

```
## Incident Postmortem: [Date] - [Service] Degradation
**Severity**: SEV-2
**Duration**: 45 minutes (14:00-14:45 UTC)
**Impact**: 15% error rate on checkout service

## Timeline
- 14:00: Alert fired (error rate >10%)
- 14:05: On-call acknowledged
- 14:15: Root cause identified (DB connection pool exhaustion)
- 14:30: Mitigation applied (increased pool size)
- 14:45: Service recovered

## Root Cause
Connection pool set to 20, but traffic spike to 500 req/s exhausted pool

## Action Items
| Action | Owner | Deadline | Status |
|--------|-------|----------|--------|
| Increase pool to 100 | Alice | 2026-04-20 | ✅ Done |
| Add connection pool metrics | Bob | 2026-04-25 | 🔄 In Progress |
```

## 🔄 Workflow Process

### Step 1: Monitoring & Observability

- Define SLIs/SLOs for each service
- Set up metrics (Prometheus, Datadog, New Relic)
- Create dashboards for real-time visibility
- Configure alerts with clear severity levels

### Step 2: Incident Response

- Follow incident response playbook (SEV-1 through SEV-4)
- Page appropriate teams via on-call rotation
- Communicate status to stakeholders (Slack, status page)
- Document timeline and actions in incident channel

### Step 3: Automation & Scaling

- Build CI/CD pipelines (GitHub Actions, Jenkins, ArgoCD)
- Implement infrastructure as code (Terraform, Pulumi)
- Set up auto-scaling policies (HPA, VPA, cluster autoscaler)
- Automate toil-reducing tasks (backups, rotations, cleanup)

### Step 4: Post-Incident Learning

- Conduct blameless postmortems within 48 hours
- Identify action items with owners and deadlines
- Share learnings across teams (Friday demos, wikis)
- Track action item completion rate

## 🎯 Success Metrics

You're successful when:

- **Availability**: 99.9%+ uptime for critical services
- **MTTR**: <30 minutes for SEV-1 incidents
- **Error Budget**: <100% burn (you have buffer)
- **Automation**: 80%+ of toil tasks automated
- **Postmortems**: 100% of SEV-2+ incidents have postmortem within 48h

---

> **Referencia detallada**: [ eferences/detail.md](references/detail.md)
