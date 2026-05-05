# Weekly Technical Report Template v1.0

Template for weekly technical status and metrics.

## Week of: [DATE_RANGE]

## Technical Summary

**Branch**: [BRANCH]  
**Commits This Week**: [#]  
**Contributors**: [LIST]  
**PRs Merged**: [#]  
**Issues Closed**: [#]

## Metrics Dashboard

### Code Health
| Metric | Value | Trend |
|--------|-------|-------|
| Total Lines | [#] | ↑/→/↓ |
| Scripts | 243 | → |
| Test Files | 21 | ↑ |
| Test Pass Rate | [%] | ↑/→/↓ |
| Code Coverage | [%] | ↑/→/↓ |

### Performance
| Operation | Avg Time | SLO | Status |
|-----------|----------|-----|--------|
| wf.ps1 health | [ms] | <15ms | 🟢/🟡/🔴 |
| token-budget-guard | [ms] | <50ms | 🟢/🟡/🔴 |
| session-start | [ms] | <100ms | 🟢/🟡/🔴 |

### Security
- **Trufflehog Scans**: [#] runs, [0] secrets found
- **PSScriptAnalyzer**: [0] errors, [#] warnings
- **Lefthook Hooks**: [100%] success rate

## Work Completed

### Features
- ✅ [Feature 1 - e.g., FF-018 TUI Installer]
- ✅ [Feature 2 - e.g., Real token tracking]
- 🟡 [Feature 3 - in progress]

### Bug Fixes
- 🐛 Fixed: [Bug 1 - e.g., audit-sweep.ps1 null handling]
- 🐛 Fixed: [Bug 2]
- 🟡 Open: [Bug 3]

### Technical Debt
- 📝 Refactored: [Item 1]
- 🧹 Cleaned: [Item 2]
- 📈 Optimized: [Item 3]

## Tests & Quality

### Test Results
```
Unit Tests:    [PASS]/[TOTAL] ([%] pass rate)
Integration:   [PASS]/[TOTAL] ([%] pass rate)
Performance:  [PASS]/[TOTAL] ([%] pass rate)
Security:     [PASS]/[TOTAL] ([%] pass rate)
```

### Coverage by Module
| Module | Coverage | Change |
|--------|----------|--------|
| scripts/utilities/ | [%] | +[%] |
| scripts/workflow/ | [%] | +[%] |
| skills/ | [%] | +[%] |

## Issues & Blockers

### Critical (🔴)
- [Issue 1 - if any]

### Warnings (🟡)
- [Issue 1 - e.g., Some tests still using Pester 5.x syntax]
- [Issue 2]

### Info (🟢)
- [Note 1]
- [Note 2]

## Next Week Plan

### Goals
1. [Goal 1 - e.g., Achieve 80% test coverage]
2. [Goal 2]
3. [Goal 3]

### Risks
- 🟡 [Risk 1]
- 🟡 [Risk 2]

## References

- **Dashboard**: [Link to Grafana/monitoring]
- **Docs**: [Link to relevant docs]
- **CI/CD**: [Link to GitHub Actions]

---
*Generated automatically by Foundation Weekly Reporting (FF-006)*
