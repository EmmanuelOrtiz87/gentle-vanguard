Run a code review on the current changes.

1. Run `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/utilities/agent-verify.ps1` — full stack check
2. If critical, also run `gv judgment-day` — adversarial dual-review
3. Summarize findings: security, quality, architecture, testing, docs
4. Do NOT modify code during review — only report issues
