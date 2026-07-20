# Core Concepts

## Why Audit Logging Matters

| Need               | Without Audit                              | With Audit                  |
| ------------------ | ------------------------------------------ | --------------------------- |
| **Debugging**      | "The agent did something wrong, but what?" | Full replay of decisions    |
| **Compliance**     | No evidence of rule following              | Verifiable compliance trail |
| **Billing**        | "Why did we spend $5K today?"              | Per-task cost attribution   |
| **Security**       | Can't detect injection or abuse            | Pattern detection on logs   |
| **Improvement**    | Guess what went wrong                      | Data-driven optimization    |
| **Accountability** | "Was this the agent or the user?"          | Clear provenance            |

## What to Log

| Event                   | Details                                  | Priority |
| ----------------------- | ---------------------------------------- | -------- |
| **Invocation**          | Task received, agent, timestamp          | Required |
| **Reasoning**           | Agent's chain-of-thought                 | Required |
| **Tool Calls**          | Tool name, params, result, latency       | Required |
| **Decisions**           | Branch taken, confidence, rationale      | Required |
| **LLM Response**        | Raw model output                         | High     |
| **Errors**              | Error type, stack trace, recovery action | Required |
| **Handoffs**            | Source, target, context summary          | Required |
| **Human Interventions** | Override, confirmation, escalation       | Required |
| **Token Usage**         | Prompt/completion counts                 | High     |
| **User Feedback**       | Rating, correction, follow-up            | Medium   |
