# Gentle-Vanguard Audit — Supporting Details

## Relationship with Judgment Day

|                    | gentle-vanguard-audit-skill        | judgment-day                               |
| ------------------ | ---------------------------------- | ------------------------------------------ |
| **What it checks** | Structure, docs, links, duplicates | Logic, security, architecture, correctness |
| **Token cost**     | Zero (batch scripts)               | ~2k-4k (AI sub-agents)                     |
| **When to use**    | Every session, pre-commit, CI/CD   | Before merge, after major features         |
| **Speed**          | 30s–5min                           | 5min–15min                                 |
| **Output**         | Issues list, exit codes            | Verdict table, APPROVED/ESCALATED          |

**Unified workflow**: Run audit first (free), then judgment-day if code quality review is needed.

## Audit Scopes

| Scope      | Checks                                          | Time   |
| ---------- | ----------------------------------------------- | ------ |
| `quick`    | deprecated refs, skill structure                | 30s    |
| `standard` | + markdown links, README links                  | 2min   |
| `full`     | + duplicates, SKILL_INDEX sync                  | 5min   |
| `deep`     | + orphaned docs                                 | 6min   |
| `judgment` | full batch + guidance to run adversarial review | varies |
| `unified`  | full batch, then prompts for judgment           | varies |

## Execution Commands

### Via gv.ps1

```powershell
gv.ps1 audit quick
gv.ps1 audit standard
gv.ps1 audit full
gv.ps1 audit deep
gv.ps1 audit judgment
gv.ps1 audit unified
```

### Standalone (any directory)

```powershell
~/.gentle-vanguard-local/audit-workflow.ps1 -Mode full
~/.gentle-vanguard-local/audit-workflow.ps1 -Mode judgment
~/.gentle-vanguard-local/audit-workflow.ps1 -Mode quick -FailOnIssues
```

### Direct script

```powershell
.\skills\gentle-vanguard-audit-skill\scripts\audit-sweep.ps1 -Scope quick
.\skills\gentle-vanguard-audit-skill\scripts\audit-sweep.ps1 -Scope full -Output markdown
.\skills\gentle-vanguard-audit-skill\scripts\sync-local.ps1
```

## What Gets Audited

1. **Duplicate Detection**: Deprecated skills still referenced, duplicate file content
2. **Link Validation**: Markdown links to non-existent files, README references to missing docs
3. **Skill Structure**: Missing SKILL.md frontmatter, invalid references, SKILL_INDEX drift
4. **Documentation**: Orphaned docs (deep scope), broken markdown links

## Standalone Sync

```powershell
.\skills\gentle-vanguard-audit-skill\scripts\sync-local.ps1
# Scripts installed to: ~/.gentle-vanguard-local/
```
