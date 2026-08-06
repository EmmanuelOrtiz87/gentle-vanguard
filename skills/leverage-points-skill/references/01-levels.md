# Leverage Points — Full Reference

## Level 12: Constants and Parameters (LOWEST LEVERAGE)

**What:** Numbers—budgets, rates, thresholds, timeouts

**Examples:** Adjusting cache TTL, changing retry counts, modifying timeout values, tweaking rate
limits

**Why low leverage:** Parameters rarely change behavior fundamentally. The system absorbs parameter
changes and continues its pattern.

```
Intervention: Increase server timeout from 30s to 60s
Result: Slow requests succeed, but root cause remains
Leverage: Very low—masks symptom, doesn't fix system
```

## Level 11: Buffer Sizes

**What:** Stabilizing stocks—queues, caches, inventories

**Examples:** Queue depth limits, connection pool sizes, memory allocations, batch sizes

**Why low leverage:** Buffers absorb fluctuations but don't change system dynamics. Bigger buffer =
slower response to change.

```
Intervention: Increase message queue size
Result: Handles traffic spikes, but processing lag grows
Leverage: Low—buys time but doesn't address throughput
```

## Level 10: Stock-and-Flow Structures

**What:** Physical architecture—how things are connected

**Examples:** Database schema, service topology, network architecture, team structure

**Why medium leverage:** Hard to change once built; design matters but is often locked in.

```
Intervention: Add read replica to reduce DB load
Result: Significant improvement in read performance
Leverage: Medium—structural change, but within existing paradigm
```

## Level 9: Delays

**What:** Time lags in feedback loops

**Examples:** Deployment pipeline duration, feedback cycle time, onboarding time, release frequency

**Why medium leverage:** Shortening delays makes systems more responsive and stable. Many
oscillation problems are actually delay problems.

```
Intervention: Reduce deployment time from 2 hours to 10 minutes
Result: Faster feedback, fewer bugs reaching production
Leverage: Medium-high—changes system responsiveness fundamentally
```

## Level 8: Balancing Feedback Loops

**What:** Negative feedback that counteracts change

**Examples:** Auto-scaling rules, circuit breakers, quality gates, alerting thresholds

**Why medium-high leverage:** Strengthening balancing loops increases stability; weakening them
enables change.

```
Intervention: Implement circuit breaker with automatic recovery
Result: Failures isolated, cascade prevention
Leverage: Medium-high—changes failure dynamics
```

## Level 7: Reinforcing Feedback Loops

**What:** Positive feedback that amplifies change

**Examples:** Growth loops (viral, network effects), technical debt spirals, talent
attraction/attrition cycles, performance improvement loops

**Why high leverage:** Reinforcing loops drive exponential growth or collapse. Controlling gain =
controlling trajectory.

```
Intervention: Create "fix broken windows" culture that reinforces quality
Result: Quality begets quality, technical debt decreases
Leverage: High—self-sustaining improvement
```

## Level 6: Information Flows

**What:** Who has access to what information

**Examples:** Metrics dashboards, error visibility, cost attribution, performance feedback to
developers

**Why high leverage:** Adding information where it was missing changes behavior dramatically. People
respond to what they can see.

```
Intervention: Show cloud costs per team in real-time dashboard
Result: Teams optimize without mandates
Leverage: High—behavior change through visibility
```

## Level 5: System Rules

**What:** Incentives, constraints, permissions

**Examples:** Code review requirements, definition of done, SLA agreements, approval processes,
deployment policies

**Why high leverage:** Rules define what's allowed and rewarded. Change rules, change behavior.

```
Intervention: Require automated tests for all production code
Result: Test coverage increases, bug rate decreases
Leverage: High—changes what's acceptable
```

## Level 4: Self-Organization

**What:** Ability of the system to change its own structure

**Examples:** Team autonomy to change processes, ability to add/remove services, permission to
experiment, organizational learning capacity

**Why very high leverage:** Systems that can evolve survive; rigid systems eventually fail.

```
Intervention: Give teams authority to choose their own tools/practices
Result: Innovation increases, best practices emerge and spread
Leverage: Very high—enables adaptation
```

## Level 3: System Goals

**What:** The purpose or function of the system

**Examples:** Success metrics, OKRs and KPIs, definition of "winning", what's optimized for

**Why very high leverage:** Everything else serves the goal. Change the goal, change everything
downstream.

```
Intervention: Change metric from "features shipped" to "user outcomes achieved"
Result: Teams focus on impact, not output
Leverage: Very high—redirects all effort
```

## Level 2: Paradigm (Mindset)

**What:** The shared assumptions from which goals arise

**Examples:** "Move fast and break things" vs "Boring technology", "Monolith is bad" vs "Right tool
for context", "Engineering is a cost center" vs "Engineering creates value"

**Why transformational:** Paradigms are upstream of goals, rules, and structure. Shift the paradigm,
transform the system.

```
Intervention: Shift from "avoid failure" to "learn from failure"
Result: Experimentation increases, innovation accelerates
Leverage: Transformational—changes what's thinkable
```

## Level 1: Transcending Paradigms (HIGHEST LEVERAGE)

**What:** The ability to change paradigms, recognizing no paradigm is "true"

**Examples:** Recognizing that current best practices are temporary, ability to hold multiple
paradigms simultaneously, knowing when to abandon a paradigm

**Why highest leverage:** Freedom from paradigm lock-in enables choosing the right paradigm for each
context.

```
Mastery: Recognize when "microservices always" became dogma
         Choose monolith when it's right
Result: Optimal architecture for each situation
Leverage: Highest—freedom from ideological constraints
```
