---
name: gentle-vanguard-audit-skill
description:
  "Trigger: 'audit gentle-vanguard', 'validate docs', 'sweep project', 'check links', 'find
  duplicates', 'fix references', 'homologate', 'validation sweep', 'gv audit'. Gentle-Vanguard audit
  and validation sweep detecting duplicates, broken links, missing files, skill inconsistencies, and
  documentation issues."
metadata:
  source: GV-native
---

# Gentle-Vanguard Audit Skill

## Activation Contract

Load when user requests any audit/validation/deduplication/sweep operation for Gentle-Vanguard
workspace. Use before judgment-day when structural integrity check is needed first.

## Hard Rules

- Run audit before judgment-day (zero-token batch scripts before AI review)
- Never modify files during audit — only report issues
- Exit code must reflect outcome: 0=success, 1=issues-found, 2=fatal

## Decision Gates

| Scope    | When                        | Checks                               |
| -------- | --------------------------- | ------------------------------------ |
| quick    | Pre-commit or session start | Deprecated refs, skill structure     |
| standard | Pre-commit or CI            | + markdown links, README links       |
| full     | Pre-merge or weekly         | + duplicates, SKILL_INDEX sync       |
| deep     | Monthly deep-clean          | + orphaned docs                      |
| judgment | Before release              | Full batch + AI adversarial review   |
| unified  | Interactive                 | Full batch, then prompt for judgment |

## Execution Steps

1. Resolve audit scope: quick → standard → full → deep → judgment (ascending)
2. Run `src/infrastructure/audit-pipeline.ts -Scope <resolved>` via `C:/Workspace_local/gentle-vanguard/src/cli/gv.ts audit <scope>`
3. Parse exit code and output
4. If judgment scope: prompt user for adversarial AI review
5. Report results in requested format

## Output Contract

- Exit 0: success; Exit 1: issues found; Exit 2: fatal error
- Output formats: human-readable text, JSON (`-Output json`), or markdown (`-Output markdown`)
- Each issue includes file path, severity, description

## References

- Scripts: [scripts/](scripts/) — src/infrastructure/audit-pipeline.ts, src/infrastructure/audit-pipeline.ts, src/infrastructure/audit-pipeline.ts
- Details (JD comparison, scopes, commands): [references/details.md](references/details.md)
