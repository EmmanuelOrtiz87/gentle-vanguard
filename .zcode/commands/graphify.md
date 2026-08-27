---
name: graphify
description: Query the native knowledge graph (AST-built, no LLM) about the codebase
argument-hint: <question>
---

Run the stack-local graphify CLI against the codebase knowledge graph.

- If `graphify-out/graph.json` is missing, first run `npm run graphify -- build`.
- For the user question "$ARGUMENTS", run: `npm run graphify -- query "$ARGUMENTS"`.
- If the query surfaces a specific node ID, follow up with
  `npm run graphify -- explain "<node_id>"`.
- Do NOT install the npm package `graphify@1.0.0` (unrelated random graph generator).
- After code modifications in this task, run `npm run graphify -- update .` to validate the
  snapshot.
