## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, invoke the `skill` tool with `skill: "graphify"` before doing anything else.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. For label-based searches, always use `graphify query` instead of `path`/`explain`.
- Use `graphify explain "<node_id>"` for focused explanations by exact node ID (e.g., `adaptive_auto_delegate_orchestrator_start_orchestrator`). Node IDs use underscore-separated paths — run `graphify query` first to find the correct ID.
- `graphify path "<A>" "<B>"` and `graphify affected "X"` are limited — the graph only has `contains`/`calls` edges (AST-only, no `references`/`imports` edges without LLM semantic extraction). Cross-file paths are rare without a paid API key.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost). Use `--force` when refactors delete code (node count decreases).
- Community labeling uses Gemini free tier (20 requests/day limit). If labeling fails with 429, wait for daily reset or set a paid API key. Re-run `graphify label .` to retry.
- For graph.html visualization: set `$env:GRAPHIFY_VIZ_NODE_LIMIT=40000` before `cluster-only` or `label` to handle graphs larger than the 5000-node default.
