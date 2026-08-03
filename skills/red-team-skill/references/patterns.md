# Red Team Patterns — Reference

## Security Red Team Checklist

**Authentication:**
- [ ] Credential stuffing / Brute force attacks / Session hijacking
- [ ] Token prediction / Password reset flaws

**Authorization:**
- [ ] Privilege escalation / IDOR (insecure direct object reference)
- [ ] Missing function-level access control / JWT manipulation

**Input validation:**
- [ ] SQL injection / XSS (stored, reflected, DOM)
- [ ] Command injection / Path traversal

**Business logic:**
- [ ] Race conditions / State manipulation / Price manipulation / Workflow bypass

## Plan Red Team

Red-team a launch plan by challenging failure modes and assumptions:

| Failure Mode | Attack Vector | Mitigation |
|--------------|---------------|------------|
| Traffic spike | Product goes viral | Auto-scaling, load test |
| PR disaster | Journalist finds bug | Bug bash before launch |
| Payment failure | Provider outage | Backup payment provider |
| Support overwhelmed | Many questions | FAQ, chatbot, staff up |

| Assumption | What if wrong? | How to verify? |
|------------|----------------|----------------|
| Users understand new UI | Confusion, tickets | User testing |
| Infrastructure handles 10x | Crashes | Load testing |
| Marketing drives traffic | No signups | Organic channel backup |

## Architecture Red Team

Attack architecture for:
- **Single points of failure** — API Gateway, Auth service, Message queue
- **Cascade failures** — timeouts → retries → overwhelm → cascade
- **Data consistency** — eventual consistency window exploits, distributed tx rollbacks, cache invalidation races

**Common findings:** No circuit breakers, shared DB = coupled failure domains, no chaos engineering.

## Decision Red Team

Red-team any major decision by listing arguments AGAINST and counter-arguments. Example:

> Decision: Adopt Kubernetes.
> AGAINST: Ops complexity, learning curve (3-6mo delay), simpler alternatives exist, over-engineering.
> Counter: Scale projections justify it, team wants K8s, platform investment pays off.
> Verdict: Learning curve is strongest counter. Consider managed K8s to reduce ops burden.
