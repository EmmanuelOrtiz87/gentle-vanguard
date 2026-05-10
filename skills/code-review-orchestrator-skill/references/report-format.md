## Console Output

```
[REVIEW] Code Review Orchestrator
======================================

[--------------------] 0% Starting review...
[REVIEW] Security Review
[======--------------] 30% Security reviewed
[REVIEW] Quality Review
[========------------] 40% Quality reviewed
[REVIEW] Architecture Review
[===========---------] 55% Architecture reviewed
[REVIEW] Testing Review
[==============------] 70% Testing reviewed
[REVIEW] Documentation Review
[================----] 80% Documentation reviewed
[REVIEW] API Design Review
[==================--] 90% API reviewed
[REVIEW] Git Workflow Review
[====================] 100% Complete

======================================
 Review Complete
======================================

 Found: 24 issues
   - 2 critical
   - 5 high
   - 10 medium
   - 7 low

 Report saved to: docs/code-reviews/2026-04-08-all-review.md
```

## Report File Structure

```markdown
# Code Review Report

**Date:** 2026-04-08 14:30
**Scope:** all
**Total Issues:** 24 (2 critical, 5 high, 10 medium, 7 low)

## Summary

### Issues by Severity
| Severity | Count | Action Required |
|----------|-------|----------------|
| CRITICAL | 2     | Block deployment |
| HIGH     | 5     | Fix before merge |
| MEDIUM   | 10    | Review and fix |
| LOW      | 7     | Consider fixing |

### Issues by Category
| Category | Total | Critical | High | Medium | Low |
|----------|-------|----------|------|--------|-----|
| Security | 8     | 2        | 3    | 2      | 1   |
| Quality  | 6     | 0        | 2    | 2      | 2   |
| ... | | | | | |

## Critical Issues (Action Required)

### 1. [SECURITY] API Key Exposed
**File:** src/config/api.ts:15
**Category:** Security
**Issue:** Hardcoded API key detected.
**Recommendation:** Use environment variables.
```
