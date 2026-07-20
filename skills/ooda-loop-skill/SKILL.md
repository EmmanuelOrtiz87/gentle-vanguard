---
name: ooda-loop-skill
description: >
  Imported from cc-thinking-skills. ooda, observe orient decide act, rapid iteration, decision
  cycle.
metadata:
  source: cc-thinking-skills
  original-name: thinking-ooda
---

# OODA Loop

## Overview

The OODA Loop (Observe, Orient, Decide, Act), developed by Colonel John Boyd, is a framework for rapid decision-making in dynamic situations. **Agility beats perfection** — cycle through OODA faster than the situation changes.

## When to Use

- Incident response and outages
- Competitive market situations
- Time-sensitive decisions
- Rapidly changing requirements
- Crisis management
- Debugging under pressure
- Any situation requiring quick adaptation

Decision flow: `Situation changing rapidly? → Need quick decisions? → APPLY OODA LOOP`

## The Four Phases

### 1. OBSERVE — Gather information rapidly

- Current state, changes since last observation, external factors, feedback from previous actions
- Cast wide net initially, narrow as pattern emerges
- Don't filter prematurely
- Time-bound your observation

See `references/examples.md` for an incident walkthrough.

### 2. ORIENT — Make sense of observations

Orientation factors (Boyd's framework): cultural traditions, genetic heritage, previous experience, new information, analysis/synthesis

**This is the CRITICAL phase** — mental models apply here. Misorientation leads to wrong decisions. Challenge your initial framing.

### 3. DECIDE — Select course of action

- Based on current orientation, acknowledges uncertainty
- Identify what to observe next
- Reversible decisions → bias toward action
- Irreversible decisions → gather more info first
- 70% confidence now beats 90% confidence too late

### 4. ACT — Execute the decision

- Execute decisively, then immediately return to OBSERVE
- Don't wait for complete results
- Actions create new observations
- Cycle continues until stable state

## OODA Loop Speed

Operating faster than the situation (or opponent) creates advantage: your actions change the situation before they decide, keeping you ahead. See `references/reference-tables.md` for speed multipliers and killers.

## Application Patterns

See `references/application-patterns.md` for full walkthroughs of:
- Incident Response
- Competitive Response
- Debugging Under Pressure
- OODA for Teams (parallel loops + shared orientation)

## Common Failure Modes

| Failure | Symptom | Fix |
| ------- | ------- | --- |
| Observation overload | Can't process all data | Filter to key indicators |
| Orientation lock | Stuck on one hypothesis | Force alternative framing |
| Decision paralysis | Waiting for certainty | Set decision deadline |
| Action without observation | Blind execution | Mandate observe after act |
| Single loop | Not cycling | Time-box each phase |

## Verification Checklist

- [ ] Observing actual current state, not assumptions
- [ ] Orientation considers multiple hypotheses
- [ ] Decision is actionable and time-bound
- [ ] Action creates observable feedback
- [ ] Loop is actually cycling (not stuck in one phase)
- [ ] Speed is appropriate to situation urgency

## Key Questions

- "What do I observe RIGHT NOW?" (not 5 minutes ago)
- "What does this mean? What pattern does it match?"
- "What's my best action given current understanding?"
- "How will I know if my action worked?"
- "Am I cycling fast enough?"

## Boyd's Insight

"He who can handle the quickest rate of change survives."
