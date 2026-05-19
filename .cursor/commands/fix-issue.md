Fix an issue from GitHub or a bug report.

1. Get issue details: `gh issue view <number>` (if GitHub issue URL/number provided)
2. Find relevant code using grep and semantic search
3. Understand the bug: check current behavior vs expected
4. Implement fix following existing code patterns
5. Run tests to verify:
   `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validation/run-tests.ps1`
6. Run agent-verify:
   `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/agent-verify.ps1`
7. Open PR with `/pr` command
