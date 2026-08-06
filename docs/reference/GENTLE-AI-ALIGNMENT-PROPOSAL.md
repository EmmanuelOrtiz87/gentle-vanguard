# Gentle AI Alignment Proposal

## Overview

This document outlines the improvements needed to align Gentle-Vanguard stack with the official
Gentle AI ecosystem and methodologies from:

- **The Amazing Gentleman Programming Book** (vercel.app/en) - Chapter 21: Verifiable Trust
- **Gentle-AI** (github.com/gentleman-programming/gentle-ai)

## Current State Analysis

### ✅ Already Aligned

| Aspect                        | Status     | Evidence                                                                                                                                                                                                                                                                |
| ----------------------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Five-Axis Review              | ✅ ALIGNED | Correctness, Readability, Architecture, Security, Performance                                                                                                                                                                                                           |
| Bounded Review                | ✅ ALIGNED | Content-bound review concept exists                                                                                                                                                                                                                                     |
| Multi-Model Pattern           | ✅ ALIGNED | Model A writes → Model B reviews → Human final call                                                                                                                                                                                                                     |
| Verification Story            | ✅ ALIGNED | Tests, build, manual verification steps                                                                                                                                                                                                                                 |
| SDD (Spec-Driven Development) | ✅ ALIGNED | SDD agents and phases implemented                                                                                                                                                                                                                                       |
| Engram Integration            | ✅ ALIGNED | Persistent memory via engram MCP; official OpenCode plugin installed (`engram setup opencode`); stack session summary persisted via official HTTP API (`POST /sessions/{id}/end`). No custom session-tracking scripts (matches gentle-ai: "Engram works automatically") |
| Skills System                 | ✅ ALIGNED | Skill registry and loading                                                                                                                                                                                                                                              |

### ⚠️ Gaps to Address

| Gap                   | Priority | Description                                  |
| --------------------- | -------- | -------------------------------------------- |
| Receipt Binding       | HIGH     | No content-bound receipts linked to Git hash |
| Staged Index Review   | HIGH     | No support for `git add` staged review       |
| Threat Model Doc      | MEDIUM   | Missing review-authority-threat-model.md     |
| Delegation Triggers   | MEDIUM   | Vague triggers, need explicit rules          |
| gentle-ai Integration | LOW      | No integration with gentle-ai CLI            |

### ✅ Alignment Decision: Engram Session Lifecycle (2026-08-01)

**Context**: The stack previously attempted custom Engram session tracking
(`engram-session-register.ts`

- a pipeline step + the `engram mem session-summary` CLI subcommand). All three were wrong:

* `engram mem session-summary` is NOT a CLI command — `mem_session_summary` is an **MCP tool**
  (verified against Engram v1.20.0 `--help` and the official README/ARCHITECTURE).
* `engram setup opencode` installs the **official OpenCode plugin** that already handles session
  tracking automatically (session.created → `POST /sessions`, chat.message → `POST /prompts`,
  tool.execute.after → passive capture).
* gentle-ai's own philosophy (README): _"Engram works automatically. You don't need to do
  anything."_

**Adopted pattern (native, aligned with gentle-ai)**:

1. **Official plugin** — `engram setup opencode` (installed; session tracking automatic after
   OpenCode restart).
2. **MCP tools** — the agent uses `mem_save`, `mem_search`, `mem_session_summary`, etc. directly
   (already available in this environment).
3. **HTTP API for the pipeline** — the stack's `session-close-orchestrator.ts` persists the session
   summary via the documented endpoint `POST /sessions/{id}/end` (idempotent, graceful SKIP when the
   server is unreachable).
4. **No custom registration scripts** — deleted `src/engram-session-register.ts`; no pipeline step
   added.
5. **Project name** — canonical `gentle-vanguard` (from git remote) fixed in
   `config/engram-policy.json`.

**Guardrail**: do NOT re-introduce custom Engram CLI/session scripts. If something is missing,
extend the official plugin or use the documented HTTP API / MCP tools.

---

## Short-Term Improvements (This Session)

### 1. Add Delegation Triggers to Review Process

**File:** `.opencode/skills/code-review-and-quality/references/review-process.md`

Add explicit triggers based on Gentle AI:

```markdown
## Delegation Triggers

| Trigger                               | Expected Behavior                    |
| ------------------------------------- | ------------------------------------ |
| Reading 4+ files to understand a flow | Delegate to exploration agent        |
| Touching 2+ non-trivial files         | Use focused writer, validate result  |
| Implementation ready for review       | Start bounded native review          |
| Long monolithic session               | Pause, delegate, re-plan, or justify |
```

### 2. Create Review Authority Threat Model

**New File:** `.opencode/skills/code-review-and-quality/references/review-authority-threat-model.md`

Content based on Gentle AI threat model:

```markdown
# Review Authority Threat Model

## Assumptions

- Review protects against accidental scope/identity drift
- Not designed to defend against malicious local actor
- Git candidate is the source of truth

## Trust Boundaries

1. **Author** → Creates change, runs self-review
2. **Reviewer** → Validates against spec, issues receipt
3. **System** → Binds receipt to Git candidate
4. **Delivery** → Validates receipt against live Git state

## Threat Vectors

- Scope drift: Change grows beyond original intent
- Identity drift: Receipt references wrong candidate
- Timing: TOCTOU between review and delivery
```

---

## Medium-Term Improvements (Next Sessions)

### 3. Implement Receipt Binding System

**New Script:** `scripts/utilities/ops/REVIEW/receipt-manager.ts`

```typescript
interface ReviewReceipt {
  id: string;
  candidateHash: string;
  contentHash: string;
  author: string;
  timestamp: string;
  findings: Finding[];
  approved: boolean;
}

function createReceipt(candidate: GitCandidate): ReviewReceipt {
  const contentHash = computeContentHash(candidate.stagedFiles);
  return {
    id: generateId(),
    candidateHash: candidate.sha,
    contentHash,
    author: candidate.author,
    timestamp: new Date().toISOString(),
    findings: [],
    approved: false,
  };
}

function validateReceipt(receipt: ReviewReceipt, currentCandidate: GitCandidate): boolean {
  return (
    receipt.candidateHash === currentCandidate.sha &&
    receipt.contentHash === computeContentHash(currentCandidate.stagedFiles)
  );
}
```

### 4. Add Staged Index Review Command

**New Script:** `scripts/utilities/ops/REVIEW/staged-review.ts`

```bash
# Usage
npx tsx scripts/utilities/ops/REVIEW/staged-review.ts

# Behavior
# 1. Captures complete git index (staged files)
# 2. Freezes review scope to that index
# 3. Excludes worktree untracked/unstaged
# 4. Issues receipt bound to staged snapshot
```

### 5. Integrate gentle-ai CLI

**New Script:** `scripts/utilities/ops/INTEGRATION/gentle-ai-bridge.ts`

```typescript
interface GentleAIIntegration {
  doctor(): Promise<HealthCheck>;
  sync(profile?: string): Promise<SyncResult>;
  upgrade(): Promise<UpgradeResult>;
  reviewStart(projection: 'staged' | 'workspace'): Promise<ReviewSession>;
}
```

---

## Long-Term Improvements (Quarterly)

### 6. Auto-Evolution Pipeline

Create a pipeline that:

1. **Monitors** Gentle AI releases via GitHub API
2. **Compares** our implementation against official patterns
3. **Proposes** alignment changes via PR
4. **Validates** changes maintain compatibility

### 7. Skill Registry Sync

```bash
# Add to pipeline
gentle-ai skill-registry refresh

# Compare with our .opencode/skills/
# Detect drift and propose updates
```

---

## Implementation Roadmap

### Phase 1: This Week

- [ ] Add delegation triggers to review-process.md
- [ ] Create review-authority-threat-model.md
- [ ] Update AGENTS.md with new triggers

### Phase 2: This Month

- [ ] Implement receipt-manager.ts
- [ ] Implement staged-review.ts
- [ ] Add to session-autostart pipeline

### Phase 3: This Quarter

- [ ] gentle-ai bridge implementation
- [ ] Auto-evolution monitoring script
- [ ] Skill registry comparison tool

---

## Success Metrics

| Metric                      | Target            |
| --------------------------- | ----------------- |
| Review alignment score      | 100% vs Gentle AI |
| Delegation trigger coverage | 100%              |
| Receipt binding implemented | Yes               |
| Threat model documented     | Yes               |

---

## References

- [Gentle-AI Official](https://github.com/Gentleman-Programming/gentle-ai)
- [Chapter 21: Verifiable Trust](https://the-amazing-gentleman-programming-book.vercel.app/en/book/Chapter21_Verifiable-Trust)
- [Review Integration Contract](https://github.com/Gentleman-Programming/gentle-ai/blob/main/docs/review-integration.md)
- [Review Authority Threat Model](https://github.com/Gentleman-Programming/gentle-ai/blob/main/docs/review-authority-threat-model.md)
