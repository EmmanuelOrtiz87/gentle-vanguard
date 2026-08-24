---
name: delegate
description: Recommend the best stack agent for a task and delegate with model tiering
argument-hint: <task description>
---

Delegate "$ARGUMENTS" through the stack's multi-domain router:

1. `npx tsx src/recommend-agent.ts --task "$ARGUMENTS" --topn 3` to see the recommended agents.
2. Delegate: `npm run delegate:run -- --task "$ARGUMENTS"` (applies AGENT_TEMPERATURE tiering).
3. Report which agent was chosen, why (routing domain match), and the result.

If the agent hits maximum steps, re-assign with
`npx tsx src/adaptive-steps.ts --resume <agent> --task_id <id>` (+20 steps, max 80).
