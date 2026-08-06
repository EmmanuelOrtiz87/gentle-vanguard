# token-budget-tracking-skill

> Gentle-Vanguard Skill

## Description
>

## Triggers


## Instructions
# Token Budget Tracking & Optimization

## Overview

A single runaway agent (50K tokens/loop × 100 iters) can cost $50-$150 in minutes. This skill covers budgets, tracking, cost attribution, and optimization.

## Core Concepts

| Dimension        | What It Tracks                    | Why It Matters               |
| ---------------- | --------------------------------- | ---------------------------- |
| Per Agent        | Tokens consumed by each agent     | Identify expensive agents    |
| Per Task         | Cost per completed task           | Measure ROI per task type    |
| Per User         | Cost attributed to a user/session | Bill-back, abuse detection   |
| Per Model        | Cost by LLM provider/model        | Model selection decisions    |
| Daily/Weekly     | Aggregate burn rate               | Budget forecasting           |
| Per Step         | Tokens per reasoning step         | Detect inefficient reasoning |

## Implementation Steps

Code and detailed examples in `references/`.

1. **[Token Counter](references/step-1-token-counter.md)** — Thread-safe counter with per-agent-task tracking and cost calculation.
2. **[Budget Enforcement](references/step-2-budget-enforcement.md)** — Per-agent and global period budgets with pre-flight checks.
3. **[Token Optimization](references/step-3-token-optimization.md)** — Context compression, summarization, and truncation.
4. **[Real-Time Dashboard](references/step-4-budget-dashboard.md)** — Live status with percent-used and alerts.
5. **[Proactive Cost Controls](references/step-5-cost-controls.md)** — Usage-ratio-driven compression and model selection.
6. **[Budget Alerting Rules](references/step-6-alerting-rules.md)** — YAML rules for daily budget, spikes, runaway detection.

## Budget Planning

| Agent Type       | Suggested Daily Limit | Monthly Cost Cap |
| ---------------- | --------------------- | ---------------- |
| Customer Support | 500K tokens           | ~$150            |
| Research Agent   | 2M tokens             | ~$600            |
| Code Generation  | 3M tokens             | ~$900            |
| Data Analysis    | 1M tokens             | ~$300            |
| Internal Tooling | 200K tokens           | ~$60             |

[Pricing table & optimization impact](references/budget-planning.md)

## Trigger Phrases

| Phrase                       | Action                                |
| ---------------------------- | ------------------------------------- |
| "Show token usage"           | Display current consumption by agent  |
| "What's the budget status?"  | Show budget vs. actual for all agents |
| "Set budget for agent X"     | Configure per-agent token limit       |
| "What's costing the most?"   | Show top spenders and cost breakdown  |
| "Optimize this request"      | Compress context to reduce tokens     |
| "Alert on budget thresholds" | Set up budget alerting rules          |

## Anti-Patterns

| Anti-Pattern             | Why It Fails                         | Fix                           |
| ------------------------ | ------------------------------------ | ----------------------------- |
| No budget tracking       | Bills are a surprise each month      | Real-time per-agent tracking  |
| Same model for all tasks | Overpaying for simple tasks          | Model tiering by difficulty   |
| No per-agent limits      | One runaway agent costs everything   | Hard per-agent budgets        |
| Ignoring output tokens   | Output costs more than input (2-4x)  | Track input/output separately |
| No proactive alerts      | Find out about spikes at billing     | Real-time budget alerts       |
| Caching nothing          | Pay for identical prompts repeatedly | Implement response caching    |
