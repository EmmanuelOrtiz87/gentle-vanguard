            Invoke-Fallback
        } else {
            Write-Warn "Blocked and  unavailable - manual intervention required"
        }
    }
}
```

### In Session Close

```powershell
# Before session end
if (-not (Test-AllTasksComplete)) {
    if (Test-Available) {
         run --ci  # Final review before close
    }
}
```

## Configuration

reads from `.` config or environment:

```bash
# . (project level)
PROVIDER="opencode"
FILE_PATTERNS="*.ps1,*.ts,*.js"
STRICT_MODE="true"
```

## Dependencies

| Tool                         | Required | Purpose                     |
| ---------------------------- | -------- | --------------------------- |
| Gentle-Vanguard Orchestrator | **YES**  | Primary execution           |
| invoke-ai-review.ps1         | **YES**  | Native review (replacement) |
| ()                           | **NO**   | Optional fallback guardian  |

## Coexistence

Gentle-Vanguard operates **fully** without :

- Native AI review via `invoke-ai-review.ps1`
- Pre-commit hooks via Gentle-Vanguard hooks
- Code review via `code-review-orchestrator-skill`

is **enhancement**, not **requirement**.

## Error Handling

```

              FALLBACK decisión TREE


  Orchestrator blocked?


  Self-healing possible?


    YES       NO

  Apply       available?
  healing

            YES   NO

        Invoke   Flag for
             manual
            intervention

  Report result


```

## Commands Reference

```powershell
#  commands (when available)
 run              # Review staged files
 run --ci        # CI mode
 run --pr-mode   # PR review
 config          # Show config
 cache status    # Cache info

# Gentle-Vanguard native (always available)
invoke-ai-review.ps1 run
gv review --scope quick
gv review --scope full
```

## Skill Priority

| Priority | Skill                    | Availability    |
| -------- | ------------------------ | --------------- |
| 1        | project-orchestrator     | Always          |
| 2        | invoke-ai-review         | Always (native) |
| 3        | code-review-orchestrator | Always          |
| **4**    | **guardian-fallback ()** | **Optional**    |

---

**Note:** is a convenience, not a requirement. Gentle-Vanguard works fully without it.