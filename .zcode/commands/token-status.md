---
name: token-status
description: Show real token budget usage (used / budget / %) from Nexus
---

Run the stack's real token accounting (tool-agnostic, ingests opencode + zcode):

1. `npm run token:ingest` (one ingestion pass)
2. `npm run token:status` (budget: used / budget / %)
3. If the user wants traceability detail, also run `npm run token:trace`.

Report the numbers plainly: tokens used today, per-session, % of budget, top consumers by agent, and
savings from cache/compression.
