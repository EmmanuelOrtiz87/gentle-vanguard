# OODA Loop — Phase Examples

These examples walk through an incident scenario applied to each phase of the OODA loop.

## Observe — Incident Context

```
Error rates:    Spiking 10x normal
Affected services:  API gateway, user service
Timeline:       Started 5 minutes ago
Recent changes: Deploy 15 minutes ago
User reports:   "Can't log in"
```

## Orient — Pattern Matching

```
Pattern matches:    Similar to DB connection pool exhaustion last month
But different:      No DB metrics anomaly this time
Recent deploy touched:  Auth service rate limiting
Hypothesis:         Rate limit config too aggressive
```

## Decide — Course of Action

```
Decision:       Roll back auth service deploy
Hypothesis:     This will restore normal error rates
Observation plan:   Watch error rates for 2 minutes post-rollback
Fallback:       If no improvement, investigate DB connections
```

## Act — Execute and Observe

```
Action:         kubectl rollback deployment/auth-service
Immediate observe:  Error rates, response times
Time limit:     2 minutes to see effect
```
