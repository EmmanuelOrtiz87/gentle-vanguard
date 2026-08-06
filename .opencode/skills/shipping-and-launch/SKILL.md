---
name: shipping-and-launch
description: Shipping and Launch
triggers:
  - shipping and launch
---

# Shipping and Launch

## Overview

Ship with confidence. The goal is to deploy safely: monitoring in place, rollback plan ready,
success criteria clear. Every launch should be reversible, observable, and incremental.

## When to Use

- Deploying a feature to production for the first time
- Releasing a significant change to users
- Migrating data or infrastructure
- Opening a beta or early access program
- Any deployment that carries risk

## Key Phases

### 1. Pre-Launch Checklist

See `references/pre-launch-checklist.md` for the full checklist covering:

- **Code Quality** — tests, builds, linting, code review, error handling
- **Security** — secrets, vulnerabilities, input validation, auth, CORS
- **Performance** — Core Web Vitals, N+1 queries, bundles, caching
- **Accessibility** — keyboard nav, screen readers, contrast, focus management
- **Infrastructure** — env vars, DB migrations, DNS/SSL, CDN, health checks
- **Documentation** — README, API docs, ADRs, changelog, user docs

### 2. Feature Flag Strategy

Ship behind feature flags to decouple deployment from release. See
`references/feature-flag-strategy.md` for code examples and lifecycle.

**Rules:** Every flag has an owner + expiration. Clean up within 2 weeks of full rollout. Don't nest
flags. Test both states in CI.

### 3. Staged Rollout

Deploy in stages with monitoring gates at each step. See `references/staged-rollout.md`.

**Progression:** Staging → Production (flag OFF) → Internal team → 5% canary → 25% → 50% → 100%.

**Roll back immediately if:** error rate >2x baseline, P95 latency >50% above baseline, data
integrity issues, or security vulnerabilities.

### 4. Monitoring and Observability

Monitor application, infrastructure, and client metrics. See
`references/monitoring-and-observability.md` for full hierarchy, error reporting code, and
post-launch verification steps.

### 5. Rollback Strategy

Every deployment needs a documented rollback plan. See `references/rollback-plan-template.md` for
the full template.

**Estimated times:** Feature flag (<1 min) → Redeploy (<5 min) → Database rollback (<15 min).

## Common Rationalizations

| Rationalization                 | Reality                                                      |
| ------------------------------- | ------------------------------------------------------------ |
| "It works in staging"           | Different data, traffic, and edge cases in production.       |
| "No feature flags needed"       | Every feature benefits from a kill switch.                   |
| "Monitoring is overhead"        | Without it you get user complaints instead of dashboards.    |
| "We'll add monitoring later"    | Add it before launch. You can't fix what you can't see.      |
| "Rollback is admitting failure" | Rolling back is responsible. Shipping broken is the failure. |

## Red Flags

- Deploying without a rollback plan
- No monitoring or error reporting in production
- Big-bang releases (everything at once, no staging)
- Feature flags with no expiration or owner
- No one monitoring the deploy for the first hour
- Production configuration done by memory, not code
- "It's Friday afternoon, let's ship it"

## Verification

### Before Deploying

- [ ] Pre-launch checklist completed (all sections green)
- [ ] Feature flag configured (if applicable)
- [ ] Rollback plan documented
- [ ] Monitoring dashboards set up
- [ ] Team notified of deployment

### After Deploying

- [ ] Health check returns 200
- [ ] Error rate is normal
- [ ] Latency is normal
- [ ] Critical user flow works
- [ ] Logs are flowing
- [ ] Rollback tested or verified ready

## See Also

- `references/definition-of-done.md` — project-wide DoD
- `references/security-checklist.md` — security pre-launch checks
- `references/performance-checklist.md` — performance pre-launch checks
- `references/accessibility-checklist.md` — accessibility verification before launch
