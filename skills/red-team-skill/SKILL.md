---
name: red-team-skill
description: >
  Imported from cc-thinking-skills. red team, adversarial review, attack simulation, penetration
  thinking.
metadata:
  source: cc-thinking-skills
  original-name: thinking-red-team
---

# Red Team Thinking

## Overview

Red teaming means deliberately attacking your own plans, systems, or ideas to find weaknesses. A
dedicated "red team" assumes an adversarial role against the "blue team's" defenses.

**Core Principle:** Attack yourself before others do.

## When to Use

- Security architecture review / Pre-launch preparation
- Validating critical decisions / Stress-testing plans
- Disaster preparedness / Competitive strategy / Code review

**Decision flow:** Building something important? → Tried to break it? → RED TEAM IT. Confident in
defenses? → RED TEAM YOUR CONFIDENCE. No adversary tested you? → BE YOUR OWN ADVERSARY.

## Red Team Process (6 Steps)

### Step 1: Define the Target

What are you attacking? Scope (in/out), goal (e.g. unauthorized access, session hijacking).

### Step 2: Adopt Adversary Mindset

Profile likely attackers (script kiddies, sophisticated, insiders, competitors) and their
motivations.

### Step 3: Enumerate Attack Surfaces

Map entry points (login, API, admin panel, DB), exposure, attacker access, and trust boundaries.

### Step 4: Execute Attack Scenarios

Systematically try attacks (credential stuffing, session hijacking, token prediction, XSS, etc.).
Document each attempt with execution steps and findings.

### Step 5: Attempt Bypass

For each defense, try to bypass it — distribute across IPs, vary inputs, target weaker endpoints.

### Step 6: Document Findings

Produce an actionable report with severity ratings (Critical/High/Medium/Low) and remediation
timelines.

## Verification Checklist

- [ ] Defined clear scope and adversary model
- [ ] Adopted genuine adversary mindset
- [ ] Enumerated attack surfaces
- [ ] Executed multiple attack scenarios
- [ ] Attempted to bypass defenses
- [ ] Documented findings with severity
- [ ] Provided actionable remediation
- [ ] Updated defenses based on findings

## Key Questions

- "How would an attacker approach this?"
- "What assumptions am I making that an attacker wouldn't?"
- "What's the weakest point in this system?"
- "If I wanted to cause maximum damage, how would I?"
- "What am I confident about that I haven't actually tested?"

## Sun Tzu's Wisdom (Applied)

"If you know the enemy and know yourself, you need not fear the result of a hundred battles."

Red teaming is knowing yourself as the enemy would. The purpose isn't pessimism — it's preparation.
