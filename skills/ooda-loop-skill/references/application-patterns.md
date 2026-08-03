# OODA Loop — Application Patterns

## Incident Response

```
OBSERVE: Metrics, logs, alerts, user reports
ORIENT:  Match pattern, form hypothesis, assess blast radius
DECIDE:  Mitigation action (rollback, scale, disable)
ACT:     Execute mitigation, immediately observe results
LOOP:    Continue until stable
```

## Competitive Response

```
OBSERVE: Competitor announcement, market reaction, customer feedback
ORIENT:  Assess threat level, identify our advantages, gaps
DECIDE:  Response strategy (match, differentiate, ignore)
ACT:     Execute response, observe market reaction
LOOP:    Adjust based on effectiveness
```

## Debugging Under Pressure

```
OBSERVE: Error messages, stack traces, recent changes
ORIENT:  Form hypothesis about cause
DECIDE:  Test most likely hypothesis first
ACT:     Add logging, try fix, or eliminate possibility
LOOP:    Update hypothesis based on results
```

## OODA for Teams

### Parallel Loops

Different team members run loops simultaneously:

```
SRE:     Infrastructure OODA (scaling, failover)
Dev:     Code OODA (debugging, fixes)
Support: Communication OODA (users, stakeholders)
Lead:    Strategy OODA (coordination, escalation)
```

### Shared Orientation

Teams need synchronized mental models:

- Runbooks create shared orientation
- Incident channels share observations
- Clear roles enable parallel action
- Post-incident updates orientation for next time
