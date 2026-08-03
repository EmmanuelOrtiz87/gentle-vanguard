# Inversion Process — Detailed Reference

## Step 1: Define the Goal Clearly

State what success looks like:

```
Goal: "Ship a reliable authentication system by Q2"
Goal: "Build a high-performing engineering team"
Goal: "Launch product with strong user retention"
```

## Step 2: Invert — Ask "How Would I Fail?"

List all ways to guarantee failure, ruin, or the opposite of your goal:

```
Goal: Ship reliable auth system
Inversions (How to guarantee failure):
- Skip security review and pen testing
- No rate limiting or brute force protection
- Store passwords in plaintext
- No monitoring or alerting
- Skip edge cases in testing
- No documentation for on-call
- Single point of failure, no redundancy
- Ignore compliance requirements
- No rollback plan
- Deploy on Friday before vacation
```

## Step 3: Categorize the Failure Modes

Group by type and severity:

| Category    | Failure Mode            | Severity |
| ----------- | ----------------------- | -------- |
| Security    | Plaintext passwords     | Critical |
| Security    | No rate limiting        | High     |
| Operations  | No monitoring           | High     |
| Operations  | No rollback plan        | High     |
| Process     | Skip security review    | Critical |
| Process     | No documentation        | Medium   |
| Reliability | Single point of failure | High     |

## Step 4: Convert to Avoidance Checklist

Transform each failure mode into a requirement:

```
Anti-goal: Store passwords in plaintext
→ Requirement: Use bcrypt/argon2 with appropriate work factor

Anti-goal: No rate limiting
→ Requirement: Implement rate limiting with exponential backoff

Anti-goal: Deploy Friday before vacation
→ Requirement: No deploys within 48h of team unavailability
```

## Step 5: Prioritize by Impact

Focus on avoiding the failures that would be:

- Most damaging if they occurred
- Most likely to occur without explicit prevention
- Hardest to recover from
