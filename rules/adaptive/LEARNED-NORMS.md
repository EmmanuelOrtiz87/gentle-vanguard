# LEARNED-NORMS - Master Index

> **Auto-Updated**: 2026-04-30 00:24
> **Total Norms**: 3
> **Status**: Active

This file is the master index of all norms learned autonomously by `auto-norm-learner.ps1`.

---

## NORM-001: Documentation saved in project root instead of docs/

- **ID**: DOC-001
- **Type**: Documentation Placement
- **Learned**: 2026-04-29 23:41
- **Source**: Engram memory pattern
- **Confidence**: low
- **Usages**: 1
- **Success Rate**: 100%

**Description**: Documentation files were being saved in project root instead of `docs/` directory.

**Correction**: Auto-Norm-Enforcer now creates `docs/` if missing and validates placement.

**Trigger**: session-start, session-close

---

## NORM-002: Missing directories created manually each session

- **ID**: DOC-002
- **Type**: Documentation Placement
- **Learned**: 2026-04-29 23:41
- **Source**: Engram memory pattern
- **Confidence**: low
- **Usages**: 1
- **Success Rate**: 100%

**Description**: Directories like `docs/`, `rules/adaptive/` were being created manually each session.

**Correction**: Auto-Norm-Enforcer now creates all required directories automatically.

**Trigger**: session-start

---

## NORM-003: PowerShell [OK] parser error at line start

- **ID**: CORR-001
- **Type**: Auto-Correction
- **Learned**: 2026-04-29 23:41
- **Source**: Engram memory pattern (from auto-testing logs)
- **Confidence**: low
- **Usages**: 1
- **Success Rate**: 100%

**Description**: PowerShell outputs `[OK]` or `[ERROR]` at line start which causes parser errors when output is captured.

**Correction**: Use `Write-Host` with `-NoNewline` for status tags, then `Write-Host` for message.

**Pattern**:
```powershell
# WRONG:
"$tag $message"

# RIGHT:
Write-Host "[TAG]" -NoNewline -ForegroundColor Green
Write-Host " $message" -ForegroundColor Gray
```

**Trigger**: Any PowerShell script output

---

## Statistics

| Metric | Value |
|--------|-------|
| Total Norms | 3 |
| Documentation Norms | 2 |
| Correction Norms | 1 |
| Session Norms | 0 |
| High Confidence | 0 |
| Medium Confidence | 0 |
| Low Confidence | 3 |
| Promoted to rules/custom/ | 0 |

---

## Promotion Criteria

A norm is promoted from `LEARNED-NORMS.md` to `rules/custom/` when:
1. Confidence = "high"
2. Usages >= 20
3. Success Rate >= 85%
4. Validated by Judgment Day review

---

## Auto-Update Note

This file is automatically updated by:
- `scripts/adaptive/auto-norm-learner.ps1`

**DO NOT EDIT MANUALLY** - your changes may be overwritten.

To add norms manually, use `rules/custom/` directory instead.
