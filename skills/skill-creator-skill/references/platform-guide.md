# Platform-Specific Instructions

## Claude.ai

Core workflow is the same (draft → test → review → improve → repeat), but without subagents:

- **Running test cases**: No parallel execution. Read SKILL.md, follow instructions to accomplish
  each test prompt yourself, one at a time. Skip baseline runs.
- **Reviewing results**: If no browser available, present results directly in the conversation. Show
  prompt and output for each test case. Save files to filesystem and tell user where they are.
- **Benchmarking**: Skip quantitative benchmarking — no meaningful baseline without subagents.
- **Iteration loop**: Same as before without the browser reviewer. Organize results into iteration
  directories.
- **Description optimization**: Requires `claude -p` CLI (Claude Code only). Skip on Claude.ai.
- **Blind comparison**: Requires subagents. Skip it.
- **Updating an existing skill**: Preserve original name. Copy to writeable location before editing.
  If packaging manually, stage in `/tmp/` first.

## Cowork

- Subagents available — main workflow works. If severe timeout problems, run test prompts in series.
- No browser/display: use `--static <output_path>` with `generate_review.py` to write standalone
  HTML, then proffer a link.
- **Always generate the eval viewer** after running tests, before evaluating inputs yourself. Use
  `generate_review.py`, not custom HTML.
- Feedback: "Submit All Reviews" downloads `feedback.json`. Read it from there.
- Packaging works with `package_skill.py`.
- Description optimization should work (uses `claude -p` via subprocess). Save until skill is in
  good shape.
- **Updating an existing skill**: Follow the update guidance from the Claude.ai section.
