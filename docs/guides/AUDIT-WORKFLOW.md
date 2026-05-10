# Audit Workflow - Foundation v2.1

Unified audit system combining **foundation-audit** (batch validation) and **judgment-day**
(adversarial review).

## Quick Start

### Integrated (with Foundation)

```powershell
# Quick check - 1 second
.\scripts\utilities\wf.ps1 audit sweep --scope quick

# Full batch audit - 5 seconds
.\scripts\utilities\wf.ps1 audit sweep --scope full

# Full + Judgment - 15 minutes
.\scripts\utilities\wf.ps1 audit judgment --mode full
```

### Standalone (without Foundation)

```powershell
# After sync:
~\.foundation-local\audit-workflow.ps1 -Mode quick
~\.foundation-local\audit-workflow.ps1 -Mode full
```

## Architecture

```

                    UNIFIED AUDIT WORKFLOW



     PHASE 1                   PHASE 2
     foundation-audit           judgment-day

      Batch script              Sub-agents
      0 tokens                  ~$0.03
      <5 seconds                10-15 minutes

     Checks:                   Reviewers:
      Duplicates               Judge A (Impl)
      Links                    Judge B (Arch)
      Structure
      Sync                    Dimensions:
                                 Security
           Performance
                                  Architecture
                                  Tests
                        Documentation
      PASS?                      Dependencies
                        Observability
                                 Maintainability
       YESNO


    Proceed        Fix Issues  Re-run Batch  JD



```

## Modes

| Mode       | Phase 1    | Phase 2 | Cost   | Time  | When               |
| ---------- | ---------- | ------- | ------ | ----- | ------------------ |
| `quick`    | (basic)    | -       | $0     | 1s    | Pre-commit         |
| `standard` | (standard) | -       | $0     | 3s    | Pre-commit, CI     |
| `full`     | (all)      | -       | $0     | 5s    | Pre-release, merge |
| `judgment` | (all)      |         | ~$0.03 | 15min | Pre-release        |
| `unified`  | (all)      |         | ~$0.03 | 15min | Major releases     |

## Workflow Integration

### Pre-Commit Hook

```powershell
# Add to .git/hooks/pre-commit
.\scripts\utilities\wf.ps1 audit sweep --scope quick --fail-on-issues
```

### CI/CD Pipeline

```yaml
# GitHub Actions
- name: Foundation Audit
  run: .\scripts\utilities\wf.ps1 audit sweep --scope standard --output json
```

### Pre-Release Checklist

```powershell
# 1. Batch validation
.\scripts\utilities\wf.ps1 audit sweep --scope full

# 2. If pass  Adversarial review
.\scripts\utilities\wf.ps1 audit judgment --mode unified

# 3. If both pass  Safe to release
```

## Standalone Setup

For use in projects without Foundation:

```powershell
# 1. From Foundation directory:
.\skills\foundation-audit-skill\scripts\sync-local.ps1

# 2. Then in any project:
~\.foundation-local\audit-workflow.ps1 -Mode full
```

## Exit Codes

| Code | Meaning                            |
| ---- | ---------------------------------- |
| 0    | No issues found                    |
| 1    | Issues found (non-fatal)           |
| 2    | Fatal error (missing dependencies) |

## Output Formats

```powershell
# Human-readable (default)
.\wf.ps1 audit sweep --output text

# JSON for CI/CD
.\wf.ps1 audit sweep --output json

# Markdown for reports
.\wf.ps1 audit sweep --output markdown
```

## Skills Reference

| Skill                     | Purpose                        |
| ------------------------- | ------------------------------ |
| `foundation-audit-skill`  | Batch validation, zero tokens  |
| `judgment-day-skill`      | Adversarial review, token cost |
| `script-governance-skill` | Script validation              |
| `docs-alignment-skill`    | Documentation synchronization  |

## Related Documentation

- [foundation-audit-skill/SKILL.md](../../skills/foundation-audit-skill/SKILL.md)
- [judgment-day/SKILL.md](../../skills/judgment-day/SKILL.md)
- [SKILL-RESOLVER-PROTOCOL](../reference/SKILL-RESOLVER-PROTOCOL.md)
