# Code Review Standards

**Version:** 1.0.0
**Last updated:** 2026-05-14
**Applies to:** All PRs targeting `develop` and `main`
**Enforced by:** GitHub branch protection + `code-review-orchestrator-skill`

---

## 1. Purpose

Define a consistent, severity-based framework for reviewing ALL code changes — human-written and AI-generated. Every review MUST produce structured, actionable output.

---

## 2. Review Levels

| Level | Required For | Reviewers | Blocks Merge |
|-------|-------------|-----------|-------------|
| **L1 — Self Review** | Every commit | Author | No |
| **L2 — Light Review** | `fix/*`, `docs/*`, `chore/*` | 1 peer | Yes |
| **L3 — Full Review** | `feature/*`, `refactor/*` | 2 peers | Yes |
| **L4 — Security Review** | Auth, crypto, secrets, payment | 1 security + 1 peer | Yes |
| **L5 — Architecture Review** | Cross-cutting, new modules, breaking changes | 1 senior + 1 peer | Yes |

---

## 3. Review Checklist (L3+)

### 3.1 Security (scan FIRST — block on any critical)

- [ ] No hardcoded secrets, tokens, API keys
- [ ] No prompt injection vulnerabilities
- [ ] Input validation on ALL user-facing parameters
- [ ] Authentication/authorization checks in place
- [ ] No path traversal (use `Join-Path`, never concatenation)
- [ ] No `Invoke-Expression` on untrusted data
- [ ] No sensitive data in logs or error messages
- [ ] Dependencies checked for known CVEs

### 3.2 Correctness

- [ ] Logic matches the intended behavior (verify against requirements)
- [ ] Edge cases handled (empty input, null, boundary values)
- [ ] Error handling follows `rules/NORMATIVAS-ERROR-HANDLING.md`
- [ ] No silent failures (empty catch blocks)
- [ ] Idempotent — safe to run multiple times

### 3.3 Architecture & Design

- [ ] Follows Single Responsibility (one logical change per file)
- [ ] No circular dependencies
- [ ] Follows established patterns in the codebase (not introducing new styles)
- [ ] Changes are proportionate to the problem (no scope creep)
- [ ] Modification Protocol followed for existing code (`rules/DEVELOPMENT-STANDARDS.md#modification-protocol`)

### 3.4 Code Quality

- [ ] File size within limits (max 500 lines)
- [ ] Nesting ≤ 3 levels
- [ ] Function parameters ≤ 3 (or uses splatting)
- [ ] Naming follows conventions (PascalCase functions, camelCase locals)
- [ ] No dead code, commented-out blocks, or debugging artifacts
- [ ] No TODO/FIXME without an associated issue

### 3.5 Testing

- [ ] New code has tests (unit minimum)
- [ ] Existing tests still pass
- [ ] Coverage meets thresholds (80% critical, 70% utilities)
- [ ] Tests are deterministic (no flaky assertions)
- [ ] Edge cases covered in tests

### 3.6 Documentation

- [ ] Comment-based help on all public functions
- [ ] CHANGELOG updated (if user-facing change)
- [ ] README updated if behavior changes
- [ ] AI-generated code annotated with `# AI-generated` comment
- [ ] Breaking changes documented with migration notes

---

## 4. Severity Classification

Every finding MUST be classified:

| Severity | Label | Meaning | Action |
|----------|-------|---------|--------|
| 🔴 **Critical** | `[CRIT]` | Bug, security hole, data loss | Block merge — MUST fix |
| 🟡 **Warning** | `[WARN]` | Style violation, missing docs, minor perf | SHOULD fix before merge |
| 🔵 **Suggestion** | `[SUGGEST]` | Optional improvement, alternative approach | MAY fix, no block |

### Critical findings that ALWAYS block merge:
- Security vulnerability (any OWASP Top 10)
- Broken functionality (logic error, wrong behavior)
- Data loss risk
- Hardcoded secrets
- PII exposure
- Test suite broken

---

## 5. AI-Generated Code Rules

### 5.1 Annotations
Every AI-generated code block MUST be annotated:
```powershell
# AI-generated — reviewed by <reviewer> on <date>
```

### 5.2 Enhanced Scrutiny
AI-generated code requires additional review focus on:
- **Hallucinated APIs** — verify every function/class/method actually exists
- **Wrong assumptions** — AI often guesses intent; verify logic matches spec
- **Security defaults** — AI picks insecure defaults (e.g., permissive CORS, weak crypto)
- **Glue code** — AI excels at stitching APIs but misses auth/error boundary checks
- **Dead code** — AI generates unused variables, imports, helper functions

### 5.3 Always Check in AI Code
- [ ] Dependencies exist and are correct versions
- [ ] Error paths are handled (not just happy path)
- [ ] No mock data or test fixtures leaked to production
- [ ] No synthetic examples or placeholder text
- [ ] Configuration is environment-aware (not hardcoded)

---

## 6. Review Output Format

Every code review MUST be structured:

```markdown
## Review Summary
**Files reviewed**: <count>
**Severity**: <critical/warning/suggestion count>
**Verdict**: Approve / Changes Requested / Blocked

### 🔴 Critical
| File | Line | Issue | Recommendation |
|------|------|-------|---------------|
| path/file.ps1 | 42 | ... | ... |

### 🟡 Warnings
| File | Line | Issue | Recommendation |
|------|------|-------|---------------|

### 🔵 Suggestions
| File | Line | Issue | Recommendation |
|------|------|-------|---------------|
```

---

## 7. Reviewer Responsibilities

- Review the **intent and logic**, not just formatting
- Verify the change solves the stated problem
- Ensure tests accompany new functionality
- Check that AI-generated code hasn't introduced subtle bugs
- Leave actionable feedback (what AND why, not just what)
- Respond to PR updates within 4 business hours

---

## 8. References

| Resource | Path |
|----------|------|
| Dev Standards | `rules/DEVELOPMENT-STANDARDS.md` |
| Error Handling | `rules/NORMATIVAS-ERROR-HANDLING.md` |
| Testing Standards | `rules/TESTING-STANDARDS.md` |
| Security Normatives | `docs/NORMATIVAS-SEGURIDAD.md` |
| PR Workflow | `rules/PR-WORKFLOW.md` |
| Code Review Skill | `skills/code-review-orchestrator-skill/` |

---

_Version: 1.0.0 — 2026-05-14 — Status: ACTIVE_
