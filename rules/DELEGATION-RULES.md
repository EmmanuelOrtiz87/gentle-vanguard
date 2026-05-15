# Delegation Rules

**Canonical reference for when to delegate vs. work inline.**
These rules are consumed by any AI agent operating in this workspace (opencode, claude-code, cline, cursor, windsurf). Agents MUST follow these rules; they are NOT optional guidelines.

## Principle

Route work through the **smallest safe harness**. "Smallest" means minimal safe coordination, not zero delegation by default. The parent agent maintains one conversation thread and delegates real phase work to subagents when triggers fire.

## Work Routing Ladder

### 1. Inline Direct

Use inline execution when the task is small, mechanical, and the parent already has enough context.

**Examples:**
- Typo, rename, one-file mechanical edit
- Small known bug with clear location
- Focused verification over 1-3 files
- Bash for state (e.g. `git status`, `gh issue view`)

**Do not** add SDD ceremony. **Do not** delegate just to look sophisticated. But **do not** use this exception to avoid delegation after the task stops being small.

### 2. Simple Delegation

Delegate when the work would inflate parent context or requires focused exploration, but does not yet need a full SDD lifecycle.

**Examples:**
- Understand an unfamiliar module
- Inspect 4+ files
- Investigate a failing test
- Implement a bounded multi-file change
- Run tests/builds and summarize results
- Fresh-context review

Use `foundation` subagents (sdd-apply, sdd-design, sdd-verify, etc.) when available.

**Default balanced pattern for bounded implementation:**
```
parent clarifies + checks git
  → scout/context-builder when context-heavy
    → one worker writes
      → fresh reviewer audits diff
        → parent validates + reports
```

### 3. SDD

Use SDD for large, ambiguous, architectural, product-facing, multi-area, or high-review-risk work. See `openspec/config.yaml` for SDD configuration.

**Triggers:**
- Unclear requirements or acceptance criteria
- Architectural/product decisions
- Cross-cutting behavior changes
- Expected large diff or reviewer burden
- Need for specs/design/tasks before safe implementation
- User explicitly says `use sdd`, `/sdd-new`, `/sdd-ff`

## Mandatory Delegation Triggers

These are **stop rules**. Once any trigger fires, the parent MUST either delegate or explicitly tell the user why delegation would be unsafe or wasteful for this exact case.

| # | Rule | Trigger | Action |
|---|------|---------|--------|
| 1 | **4-file rule** | Understanding requires reading 4+ files | Launch `scout` or `context-builder` with fresh context and narrow mapping task |
| 2 | **Multi-file write rule** | Implementation will touch 2+ non-trivial files | Use one `worker` OR keep inline only if a fresh reviewer will audit before completion |
| 3 | **PR rule** | Before commit/push/PR for code changes | Run a fresh-context `reviewer` unless the diff is trivial docs/text-only |
| 4 | **Incident rule** | After wrong cwd, accidental repo/worktree mutation, failed merge, confusing test/env issue | Stop and run a fresh audit `reviewer` before any recovery action |
| 5 | **Long-session rule** | ~20 tool calls, 5 exploratory file reads, or 2 non-mechanical edits without delegation | Pause and choose `scout`, `worker`, or `reviewer` instead of silently continuing |
| 6 | **Fresh review rule** | Adversarial review of diffs, conflicts, PR readiness, incident audits | Use `context: "fresh"` — independence from parent's assumptions is the value |

### Trigger Details

**4-file rule:** If understanding a flow requires reading 4+ files, do NOT load them all into parent context. Delegate to a scout agent that compresses broad repo exploration into a short handoff.

**Multi-file write rule:** If implementation will touch 2+ non-trivial files, use a single worker agent (one writer thread). Do not run parallel writers unless isolated worktrees are explicitly approved.

**PR rule:** Before any commit/push/PR involving code changes, run a fresh-context reviewer agent. The reviewer's value is independence from the parent's assumptions about correctness.

**Incident rule:** After ANY tooling accident (wrong directory, git history damage, merge conflict spiral, environment breakage), stop ALL writes and run a fresh audit reviewer. Do not attempt recovery without independent assessment.

**Long-session rule:** If you've made roughly 20 tool calls, performed 5+ exploratory reads, or made 2+ non-mechanical edits without delegating, pause and reflect. The session has accumulated enough implicit context that the parent is now operating on assumptions rather than fresh analysis.

## Workflow: Delegation Decision Matrix

| Action | Inline | Delegate |
|--------|--------|----------|
| Read to decide/verify 1-3 files | ✅ | ❌ |
| Read to explore/understand 4+ files | ❌ | ✅ |
| Read as preparation for multi-file writing | ❌ | ✅ |
| Write atomic one-file mechanical change | ✅ | ❌ |
| Write with analysis across multiple files | ❌ | ✅ |
| Bash for state (git status, etc.) | ✅ | ❌ |
| Bash for execution (tests, builds) | ❌ | ✅ |
| Commit, push, or open PR after code changes | ❌ | ✅ (fresh review first) |
| Recover from worktree/git/tooling incident | ❌ | ✅ (fresh audit first) |

## Review Workload Guard

**Before any `sdd-apply` phase**, or before writing code for a change that spans multiple files, estimate the review workload:

1. Check estimated changed lines (additions + deletions)
2. If **>400 changed lines**, the PR is too large for a sustainable human review
3. If **>400**, recommend chained PRs (see `skills/chained-pr/SKILL.md`)
4. If the user accepts chained PRs, plan slices where each stays under 400 lines
5. If the user declines chaining, require explicit `size:exception` rationale

**Why 400 lines?** Cognitive research shows review quality drops sharply above 400 changed lines per session. Foundation enforces this as a hard guard, not a soft suggestion.

## Cost and Context Balance

- Use `scout`/`context-builder` to compress broad repo exploration into a short handoff instead of loading many files into the parent
- Use a single `worker` for one writer thread
- Use fresh `reviewer` agents after implementation, conflict resolution, or incidents — their value is independence from the parent's assumptions
- Use `outputMode: "file-only"` for large child reports and summarize only decisions, blockers, and paths in the parent thread
- Avoid delegation for truly local one-file fixes, quick state checks, and already-understood mechanical edits

## Canonical Lightweight Workflows

### Bugfix with unfamiliar flow
```
parent git/status + clarify
  → scout fresh maps flow/files
    → parent decides
      → worker fork implements + tests
        → reviewer fresh audits diff
          → parent validates
```

### Conflict or dependency-marker cleanup
```
parent reproduces/checks conflict
  → parent or worker resolves
    → reviewer fresh checks markers, package/lock consistency, repo cleanliness
      → parent reports/pushes
```

### After tooling/worktree incident
```
stop writes
  → parent captures git status
    → reviewer fresh audits affected repos/worktrees with no edits
      → parent applies only confirmed recovery steps
```

## SDD Workflow

SDD uses a phase chain:
```
init → explore → proposal → spec → design → tasks → apply → verify → archive
```

Dependency graph:
```
proposal → spec ─┬→ tasks → apply → verify → archive
proposal → design ┘
```

Each phase produces an artifact. The parent synthesizes phase results using this contract:
- `status`: pass/fail/blocked
- `executive_summary`: 1-3 lines
- `artifacts`: what files were created/updated
- `next_recommended`: what the agent suggests next
- `risks`: blocking or notable issues
- `skill_resolution`: how project skills were resolved
