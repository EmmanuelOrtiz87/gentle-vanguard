# Foundation Audit — Supporting Details

## Relationship with Judgment Day

| | foundation-audit-skill | judgment-day |
|---|---|---|
| **What it checks** | Structure, docs, links, duplicates | Logic, security, architecture, correctness |
| **Token cost** | Zero (batch scripts) | ~2k-4k (AI sub-agents) |
| **When to use** | Every session, pre-commit, CI/CD | Before merge, after major features |
| **Speed** | 30s–5min | 5min–15min |
| **Output** | Issues list, exit codes | Verdict table, APPROVED/ESCALATED |

**Unified workflow**: Run audit first (free), then judgment-day if code quality review is needed.

## Audit Scopes

| Scope | Checks | Time |
|-------|--------|------|
| `quick` | deprecated refs, skill structure | 30s |
| `standard` | + markdown links, README links | 2min |
| `full` | + duplicates, SKILL_INDEX sync | 5min |
| `deep` | + orphaned docs | 6min |
| `judgment` | full batch + guidance to run adversarial review | varies |
| `unified` | full batch, then prompts for judgment | varies |

## Execution Commands

### Via wf.ps1
```powershell
wf.ps1 audit quick
wf.ps1 audit standard
wf.ps1 audit full
wf.ps1 audit deep
wf.ps1 audit judgment
wf.ps1 audit unified
```

### Standalone (any directory)
```powershell
~/.foundation-local/audit-workflow.ps1 -Mode full
~/.foundation-local/audit-workflow.ps1 -Mode judgment
~/.foundation-local/audit-workflow.ps1 -Mode quick -FailOnIssues
```

### Direct script
```powershell
.\skills\foundation-audit-skill\scripts\audit-sweep.ps1 -Scope quick
.\skills\foundation-audit-skill\scripts\audit-sweep.ps1 -Scope full -Output markdown
.\skills\foundation-audit-skill\scripts\sync-local.ps1
```

## What Gets Audited

1. **Duplicate Detection**: Deprecated skills still referenced, duplicate file content
2. **Link Validation**: Markdown links to non-existent files, README references to missing docs
3. **Skill Structure**: Missing SKILL.md frontmatter, invalid references, SKILL_INDEX drift
4. **Documentation**: Orphaned docs (deep scope), broken markdown links

## Standalone Sync
```powershell
.\skills\foundation-audit-skill\scripts\sync-local.ps1
# Scripts installed to: ~/.foundation-local/
```
