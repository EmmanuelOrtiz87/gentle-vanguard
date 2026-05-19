# Presentation Script: Gentle-Vanguard v2.18.0

This document contains detailed content for the 21 slides covering all aspects of the stack.

---

### Slide 1: Title

**Title:** Gentle-Vanguard v2.18.0 — The Future of Engineering Efficiency **Subtitle:**
Standardization, AI, and Quality as pillars of growth **Notes:** Present the overall vision for
modernizing the development area.

### Slide 2: The Silent Problem

**Key Points:**

- Environment fragmentation (different configurations between developers)
- Slow onboarding (days lost installing tools)
- Lack of up-to-date technical documentation
- Security risks (secret leaks)

### Slide 3: The Solution: Gentle-Vanguard

**Message:** An abstraction layer that unifies development. **Phrase:** "We don't just build code,
we build a platform to scale engineering."

### Slide 4: The 3 Strategic Pillars

**Suggested Graphic:** Value triangle.

1. **Automation:** Repetitive processes eliminated
2. **Quality:** Embedded security and validation (native review engine)
3. **AI-Ready:** Optimized to work with AI Agents (Engram)

### Slide 5: Simplified Architecture

**Flow:** [Base Layer: Gentle-Vanguard] -> [Tools Layer: Engram/Native Review] -> [Business Value:
Projects] **Concept:** Total independence between the technical base and business logic.

### Slide 6: The "Bootstrap Effect"

**Message:** Total configuration in a single command. **Metric:** Estimated 80% reduction in new
workstation setup time.

### Slide 7: AI as Team Member

**Concept:** Integration with MCP Protocol and Workspace-Skills. **Benefit:** AI not only generates
code, it understands our rules and architecture.

### Slide 8: Proactive Security (Guardian Angel)

**Visual:** Data protection shield. **Message:** Automatic validation of secrets and quality before
each release.

### Slide 9: The "Immaculate" Lifecycle

**Steps:**

1. Assisted development
2. Automatic validation
3. AI-generated documentation
4. Traceable release (Tags)

### Slide 10: Competitive Advantages

**Points:**

- Total agnosticism (Windows, Mac, Linux / Bitbucket, GitHub)
- Self-writing documentation (Session Reviews)
- Immaculate history for audits

### Slide 11: ROI Impact

**Comparison:**

- **Before:** 30% of time on technical bureaucracy
- **Now:** 95% of time on customer value delivery

---

### Slide 12: Tool-Agnostic Orchestration (Hidden Layer #1)

**Title:** 10 Tools, 1 Stack **Key Points:**

- Works with OpenCode, Claude Code, Cline, Cursor, Windsurf, Codex, Continue.dev, Copilot,
  Antigravity, Claude Generic
- Each tool has its own adaptive profile that auto-optimizes
- Skill and memory emulation for tools without native support (Cline, Cursor, Copilot, etc.)
- `detect-tool.ps1` auto-detects which tool is running and loads the right config
- No vendor lock-in: switch tools without losing context or skills

### Slide 13: Adaptive Profiles (Hidden Layer #2)

**Title:** Self-Optimizing Configuration **Key Points:**

- 6 adaptive profiles: opencode, claude-cline, cursor, codex-windsurf, continue-copilot, antigravity
- Auto-detect peak hours (9-15h Argentina) and token pressure
- Automatically switches to optimized config during peak, restores when normalized
- Shared DRY module (`adaptive-common.ps1`) — 606 lines of duplication eliminated
- Backup/restore mechanism ensures no config is lost

### Slide 14: SDD Lifecycle (Hidden Layer #3)

**Title:** Spec-Driven Development — Not Just Code **Key Points:**

- 4 phases: BA Explore -> SAD Design -> DEV Implement -> QA Verify
- Each phase has its own specialized agent
- `pre-process-input.ps1` analyzes every message and routes to the right phase
- `PLAN_MODE_REQUIRED` flag prevents jumping to implementation without exploration
- SDD config in `openspec/config.yaml` enforces strict TDD per phase

### Slide 15: Judgment Day (Hidden Layer #4)

**Title:** 7D Validation — No Code Ships Without Passing **Key Points:**

- 7 dimensions: Security, Performance, Readability, Maintainability, Testability, Documentation,
  Architecture
- Pre-commit hooks enforce quality gates before any commit
- `agent-verify.ps1` runs 16 checks: JSON lint, skill structure, workflow validation, security
- 393 unit tests across 40 files
- TruffleHog scanning prevents secret leaks
- Result: ALL CHECKS PASS or the commit is rejected

### Slide 16: Auto-Delegation (Hidden Layer #5)

**Title:** 131 Skills, 15 Agents, Zero Manual Routing **Key Points:**

- `config/auto-delegation.json` maps keywords to skills and agents
- Every user message is pre-processed and routed automatically
- BA agent for exploration, DEV agent for implementation, DOC agent for documentation
- Skills range from SDD lifecycle to code review, from Playwright to pytest
- No manual delegation needed — the system knows what to do

### Slide 17: Session Lifecycle (Hidden Layer #6)

**Title:** Full Session Tracking — Never Lose Context **Key Points:**

- 10-phase autostart: health check, tool detection, orphan cleanup, session init, notifications,
  engram policy, optimization, skill registry, plugins, adaptive profiles
- `startup-summary.json` captures: peak hours, platform, session ID, workspace state
- Orphan detection and cleanup prevents stale sessions
- Token budget tracking with `session-metrics-tracker.ps1`
- Watchtower quick health check at session end

### Slide 18: Security & Governance (Hidden Layer #7)

**Title:** AES-256 Encrypted — Zero Plain-Text Scripts in Public **Key Points:**

- 298 scripts encrypted with AES-256 in `build/protected/`
- Master key required to decrypt and run
- NSIS installer packages everything into single `Gentle-Vanguard.exe`
- Public repo (`gentle-vanguard-public`) contains only: bootstrap scripts, docs, encrypted
  artifacts, skill stubs
- TruffleHog pre-commit hook scans for secrets
- `sync-to-public.ps1` strips all plain-text scripts before syncing

### Slide 19: v2.18.0 — Cross-Tool Nivelación

**Title:** Latest Release Highlights **Key Points:**

- Skill emulation for all 10 tools (Cline, Cursor, Copilot, Windsurf, Codex, Antigravity now have
  skill loading + memory)
- Antigravity dedicated adaptive profile (no longer borrowing Cursor's)
- NSIS detection fix (searches Bin/ subdir + fallback)
- DRY refactor: 6 adaptive profiles share `adaptive-common.ps1` (-606 lines)
- 133 skills validated, 393 tests passing, 16/16 verification gates
- Tool detection now covers `.antigravity/` directory

### Slide 20: Roadmap and Future

**Vision:**

- Expansion of the Workspace-Skills library (community contributions)
- Global project health dashboard
- Integration with corporate CI/CD pipelines
- Auto-update: Launcher checks remote version and prompts for upgrade
- Docker validation: Integration tests in containerized environments
- S3 distribution for global availability

### Slide 21: Conclusion

**Closing:** "Gentle-Vanguard is the gentle-vanguard of our technological agility." **Call to
action:** Standard implementation for all new developments. **Stats:** 15 agents · 133 skills · 10
tools · 393 tests · 16/16 gates · v2.18.0

---

_Document generated for executive presentation support. Updated for v2.18.0._
