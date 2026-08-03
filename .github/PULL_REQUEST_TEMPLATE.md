## Description

<!-- Brief description of what this PR does -->

## Type

<!-- Check one -->

- [ ] Feature — New functionality
- [ ] Bugfix — Fix existing behavior
- [ ] Refactor — Improve without changing behavior
- [ ] Documentation — Docs, comments, README
- [ ] Test — Add or improve tests
- [ ] Security — Security fix or audit
- [ ] Performance — Optimization
- [ ] Infrastructure — CI/CD, tooling, config

## Complexity

<!-- Score 1-5: 1=Trivial, 2=Simple, 3=Medium, 4=Complex, 5=Critical -->

**Score:**

### Complexity Factors (check all that apply)

- [ ] External dependency (API, library, service)
- [ ] Security impact (auth, PII, secrets)
- [ ] Breaking change (public API/interface)
- [ ] Cross-platform (Windows/Linux/Mac)
- [ ] Performance critical (latency/throughput)
- [ ] No tests exist (must create infrastructure)
- [ ] Legacy code (old/untested)

## Estimates

| Metric           | Value               |
| ---------------- | ------------------- |
| Estimated Time   |                     |
| Estimated Tokens |                     |
| Estimated Cost   |                     |
| PR Size          | XS / S / M / L / XL |

## Changes

- [ ] Change 1
- [ ] Change 2
- [ ] Change 3

## Testing

<!-- Check all that apply -->

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] All existing tests pass

## Security

<!-- Check if applicable -->

- [ ] No secrets or credentials exposed
- [ ] Input validation implemented
- [ ] OWASP guidelines followed
- [ ] Security review required

## Rollback Plan

<!-- How to rollback if this causes issues -->

## Related Issues

<!-- Link related issues: Closes #123, Fixes #456 -->

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No breaking changes (or documented above)
- [ ] CI/CD pipeline passes

---

<!-- Experimental activation section (fill when requesting module activation) -->

### Experimental Module Activation Request

- Module name:
- Owners:
- Short description of scope and impact:

#### Activation checklist (must be completed before requesting approval)

- [ ] Confirmed module labeled `experimental` in `config/stack-maturity.json`
- [ ] Ran `pnpm test:config` and `pnpm typecheck` locally
- [ ] Ran security scan (e.g. `pnpm secretlint`)
- [ ] Added tests demonstrating behavior
- [ ] Added migration/rollback notes if applicable

Activation requires at least one approval and will generate an activation record in CI.
