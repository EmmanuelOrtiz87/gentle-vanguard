# CI/CD Hardening Standards

**Version:** 1.0.0  
**Last reviewed:** 2026-05-05  
**Enforced by:** `agent-verify.ps1` (`workflow-hardening` domain check)  

---

## 1. Mandatory Fields (every workflow MUST have)

```yaml
name: Descriptive Name

# 1. Least-privilege permissions — declare explicitly at top level
permissions:
  contents: read    # minimum; add others only if required

# 2. Concurrency — prevent redundant runs
concurrency:
  group: <workflow-name>-${{ github.ref }}
  cancel-in-progress: true   # false only for release/deploy workflows

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  job-name:
    name: Human-readable job name
    runs-on: ubuntu-latest   # or windows-latest if pwsh is required
    # 3. Timeout — prevent runaway jobs from consuming minutes
    timeout-minutes: <N>    # see defaults table below
```

---

## 2. Timeout Defaults

| Workflow type | Default `timeout-minutes` |
|---------------|--------------------------|
| Lint / static analysis | 10–15 |
| Unit tests | 15–20 |
| Integration tests | 20–30 |
| Build | 20–30 |
| Security scan | 25 |
| Deploy / release | 30–45 |
| Scheduled cron | 30 |

If a job consistently runs close to its timeout, revisit parallelism or caching before increasing the limit.

---

## 3. Permissions Reference

Use the minimum permissions required:

| Operation | Required scope |
|-----------|---------------|
| Read code | `contents: read` (default) |
| Create releases | `contents: write` |
| Comment on PRs | `pull-requests: write` |
| Upload packages | `packages: write` |
| Write checks/annotations | `checks: write` |
| Read secrets | No special scope — use `secrets.*` in env |

**Never use `permissions: write-all`**.

---

## 4. Action Pinning

```yaml
# CORRECT: pin to major version tag (managed by Dependabot)
- uses: actions/checkout@v4
- uses: softprops/action-gh-release@v2

# WRONG: floating tags or branch refs
- uses: actions/checkout@main   # unpinned — supply-chain risk
- uses: actions/checkout        # no version — defaults to HEAD
```

Dependabot (`dependabot.yml`) keeps action versions updated weekly.  
SHA-pinning is preferred for third-party actions in security-sensitive workflows.

---

## 5. Cron Schedule Format

All `schedule:` entries MUST include a UTC comment AND the local timezone (GMT-3) equivalent:

```yaml
schedule:
  - cron: '30 16 * * 0'  # Weekly Sunday at 13:30 GMT-3 (16:30 UTC)
```

---

## 6. Step Output & Summaries

- Use `$GITHUB_STEP_SUMMARY` to write job summaries for non-trivial analysis workflows.
- Use `::error::`, `::warning::`, `::notice::` annotations for file-level findings.
- Do NOT `echo` sensitive values — use masked secrets: `echo "::add-mask::$VALUE"`.

```bash
# Correct annotation format:
echo "::error file=scripts/foo.ps1,line=42::Description of error"
```

---

## 7. Path Filters (trigger optimization)

Use `paths:` filters on push/PR triggers to avoid running workflows for unrelated changes:

```yaml
on:
  push:
    paths:
      - 'scripts/**'
      - '**/*.ps1'
```

Exception: security scans (OWASP, secret scanning) should run on ALL pushes to protected branches.

---

## 8. Conditional Steps

Prefer `if: github.event_name == 'pull_request'` over separate jobs for PR-only gates.  
Use `continue-on-error: true` only for advisory steps — never for blocking gates.

---

## 9. Secrets Handling

- Access secrets via `${{ secrets.NAME }}` — never embed in code.
- Mask dynamic secrets immediately: `echo "::add-mask::$VALUE"`.
- Never log secrets with `set -x` or PowerShell's `-Verbose` on secret-manipulating steps.
- Store secrets in GitHub Secrets or Environments, not in config files.

---

## 10. Workflow Audit Checklist

Before merging any workflow change, verify:

- [ ] `permissions:` block at top level (not just job level)
- [ ] `timeout-minutes:` on every job
- [ ] `concurrency:` group defined
- [ ] All `uses:` actions pinned to version tag
- [ ] Cron entries have UTC + GMT-3 comment
- [ ] No `write-all` permissions
- [ ] No secrets printed to logs
- [ ] `continue-on-error` only on advisory steps
- [ ] Path filters applied where appropriate
- [ ] `agent-verify.ps1 -Domain config` passes
