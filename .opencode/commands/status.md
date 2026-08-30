---
description: Display current stack status and session metrics
agent: session-agent
---

Display the current stack status:

1. Session pipeline: last autostart summary
2. Watchtower health: `npx tsx src/maintenance-watchtower.ts --action health --quiet`
3. Token budget: check `.session/token-budget.json`
4. CodeGraph index: `.codegraph/codegraph.db` size and freshness
5. Engram memory: `engram doctor --json`
6. Git status: branch, last commit, dirty files
7. Dashboard: WebSocket server status
8. Active checkpoints: `npx tsx src/ops/checkpoint-manager.ts list`

Display as a structured status dashboard with component health indicators.

$ARGUMENTS
