# Systems Debugging Process

## Step 1: Map the System

Draw components, connections, and data/control flows:

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│ Client  │────▶│   API   │────▶│   DB    │
└─────────┘     └────┬────┘     └─────────┘
                     │
                     ▼
               ┌─────────┐
               │  Cache  │
               └─────────┘
```

## Step 2: Identify Feedback Loops

For each loop, determine:

- Is it reinforcing or balancing?
- What's the delay in the loop?
- What could make it unstable?

```
Retry Storm Loop (Reinforcing - Dangerous):
Service slow → Clients retry → More load → Service slower → More retries
```

## Step 3: Trace Upstream

Follow the symptom backward to find originating cause:

```
Symptom: High latency in Service C
→ Service C waiting on Service B
  → Service B waiting on Service A
    → Service A doing full table scan (ROOT CAUSE)
```

## Step 4: Look for Interactions

What happens when components interact under stress?

- Circuit breakers tripping
- Cascading timeouts
- Resource contention
- Thundering herd

## Step 5: Consider Time Dynamics

- When did this start?
- What changed recently (deploys, config, traffic)?
- Is it periodic? (Cron jobs, cache expiration, batch processes)
- Is it growing or stabilizing?
