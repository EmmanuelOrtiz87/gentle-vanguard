---
name: foundation-audit-skill
description: >
  Foundation audit and validation sweep. Detects duplicates, broken links, missing files,
  skill inconsistencies, and documentation issues.
  Trigger: "audit foundation", "validate docs", "sweep project", "check links", "find duplicates",
  "fix references", "homologate", "validation sweep", "wf audit"
---

# Foundation Audit Skill

Comprehensive audit system for validating Foundation and consumer projects. Provides zero-token batch validation and optional deep AI analysis.

## Relationship with Judgment Day

These two skills are **complementary, not duplicates**:

| | foundation-audit-skill | judgment-day |
|---|---|---|
| **What it checks** | Structure, docs, links, duplicates | Logic, security, architecture, correctness |
| **Token cost** | Zero (batch scripts) | ~2k4k (AI sub-agents) |
| **When to use** | Every session, pre-commit, CI/CD | Before merge, after major features |
| **Speed** | 30s  5min | 5min  15min |
| **Output** | Issues list, exit codes | Verdict table, APPROVED/ESCALATED |

**Unified workflow**: Run audit first (free), then judgment-day if code quality review is needed.

## Architecture

```
foundation-audit-skill/
 SKILL.md              # This file
 scripts/
    audit-sweep.ps1   # Batch audit (ZERO agent tokens)
    audit-workflow.ps1 # Unified workflow (audit + judgment)
    sync-local.ps1    # Sync to ~/.foundation-local/ for standalone use
```

## Execution Modes

### Via wf.ps1 (integrated)
```powershell
# Quick sweep - structural check only
wf.ps1 audit quick

# Standard sweep - structure + links + skills
wf.ps1 audit standard

# Full batch sweep
wf.ps1 audit full

# Deep batch sweep (+ orphaned docs)
wf.ps1 audit deep

# Full sweep + adversarial AI review
wf.ps1 audit judgment

# Full sweep then prompt user for judgment
wf.ps1 audit unified
```

### Standalone (any directory, no repo needed)
```powershell
# After running sync-local.ps1:
~/.foundation-local/audit-workflow.ps1 -Mode full
~/.foundation-local/audit-workflow.ps1 -Mode judgment
~/.foundation-local/audit-workflow.ps1 -Mode quick -FailOnIssues
```

### Direct script
```powershell
# From workspace-foundation root:
.\skills\foundation-audit-skill\scripts\audit-sweep.ps1 -Scope quick
.\skills\foundation-audit-skill\scripts\audit-sweep.ps1 -Scope full -Output markdown

# Sync scripts to local for standalone use:
.\skills\foundation-audit-skill\scripts\sync-local.ps1
```

## Audit Scopes

| Scope | Checks | Time | Tokens |
|-------|--------|------|--------|
| `quick` | deprecated refs, skill structure | 30s | 0 |
| `standard` | + markdown links, README links | 2min | 0 |
| `full` | + duplicates, SKILL_INDEX sync | 5min | 0 |
| `deep` | + orphaned docs | 6min | 0 |
| `judgment` | full batch + guidance to run adversarial review | varies | optional |
| `unified` | full batch, then prompts for judgment | varies | optional |

## What Gets Audited

### 1. Duplicate Detection
- Deprecated skills still referenced
- Duplicate file content

### 2. Link Validation
- Markdown links to non-existent files
- README references to missing docs

### 3. Skill Structure
- Missing SKILL.md frontmatter
- Invalid references to non-existent shared folders
- SKILL_INDEX synchronization drift

### 4. Documentation
- Orphaned docs (in `deep` scope)
- Broken markdown links

## Standalone Sync

To use audit scripts in any environment without Foundation repo:

```powershell
# From workspace-foundation:
.\skills\foundation-audit-skill\scripts\sync-local.ps1

# Scripts installed to: ~/.foundation-local/
# Usage from any directory:
~/.foundation-local/audit-workflow.ps1 -Mode full
```

## Exit Codes
- 0: Success (or issues reported without fail-fast)
- 1: Issues found when fail-fast is enabled
- 2: Fatal errors (missing dependencies)

## Output Formats
- Default: Human-readable output
- `-Output json`: JSON for CI/CD
- `-Output markdown`: Markdown report
