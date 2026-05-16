# ADR-006: Automated Dependency Updates Policy

**Status**: Accepted (Partially Implemented)  
**Date**: May 13, 2026  
**Author**: Gentle-Vanguard DevOps Team  
**Context**: Supply-chain security posture after npx hardening sprint  

---

## Context

gentle-vanguard has strong supply-chain security controls (ADR-003: npx offline hardening,
`.npmrc` global policy, `lockfile-lint` pre-commit hook). However, **keeping
dependencies up-to-date** requires ongoing manual attention. Without automation:

- Security patches are applied days/weeks late
- Developers must manually track CVE advisories
- `npm audit` findings accumulate silently
- Renovate/Dependabot is not configured (repository has no auto-update tooling)

### Current Dependency Profile (May 2026)

| Scope | Package Manager | Dependencies | Lock File |
|-------|----------------|--------------|-----------|
| Root | npm | devDependencies only | package-lock.json ✅ |
| mcp-bridge | npm | runtime + dev | package-lock.json ✅ |

### Risk Profile

- **Severity**: Medium — all dependencies are dev/tooling only (no runtime user-facing npm deps)
- **Attack surface**: Build tools and CLI utilities (lefthook, commitlint, lockfile-lint)
- **npx mitigation**: Offline workspace already pins exact tool versions

---

## Decision

**Adopt a two-layer dependency update policy: automated audit alerting + quarterly
manual dependency review. Defer Renovate/Dependabot automation until Q3 2026.**

### Layer 1: Automated Audit (Implemented)

`npm audit` runs in the pre-push hook (`scripts/hooks/check-npm-audit.ps1`):

```powershell
npm audit --audit-level=moderate
if ($LASTEXITCODE -ne 0) { exit 1 }   # blocks push
```

- **Trigger**: every `git push` (via lefthook)
- **Level**: blocks on `moderate` or higher severity
- **Scope**: root `package.json` + `adapters/mcp-bridge/package.json`

### Layer 2: Lockfile Integrity (Implemented)

`lockfile-lint` pre-commit hook validates that `package-lock.json` was not manually
edited and only contains entries from the approved registry:

```yaml
# config/lefthook.yml
pre-commit:
  lockfile-lint:
    run: npx --offline lockfile-lint ...
```

### Layer 3: Quarterly Manual Review (Policy)

Every quarter, run:

```powershell
npm outdated                   # list stale packages
npm audit                      # current vulnerabilities
npm update --save-dev          # bump patch/minor
npm audit fix                  # auto-fix fixable CVEs
```

Review schedule: first Monday of March, June, September, December.

### Layer 4: Renovate Automation (Q3 2026)

Evaluate and configure Renovate Bot for:
- Auto-PRs for patch updates (auto-merge if CI passes)
- Manual review for minor/major updates
- Group lockfile updates in single PR

**Deferred to Q3 2026** because:
1. Current dependency surface is small (devDependencies only)
2. Renovate config requires tested PR merge automation (in progress)
3. GitHub Actions PR auto-merge policies need review first

---

## Consequences

### Positive

- ✅ `npm audit` in pre-push catches CVEs before they reach main
- ✅ `lockfile-lint` prevents lockfile tampering
- ✅ Quarterly cadence ensures stale deps don't accumulate
- ✅ Clear ownership: whoever runs `gv.ps1 publish` is accountable for audit check
- ✅ Zero new tooling required for Layers 1-3

### Negative

- ⚠️ Quarterly review is manual — relies on calendar discipline
- ⚠️ No auto-PR for upstream security patches (until Renovate in Q3)
- ⚠️ `npm audit` can produce false positives for devDependencies with no runtime impact

---

## Alternatives Considered

1. **Dependabot (GitHub native)** — Simple to enable, but generates noisy PRs without
   grouped updates; auto-merge not available without branch protection bypass; deferred
   in favour of Renovate's richer grouping support.

2. **Renovate now (Q2 2026)** — Preferred long-term but requires tuning time gentle-vanguard
   doesn't have mid-sprint; deferred to Q3 with a hard deadline.

3. **Manual-only (current)** — Rejected: humans miss advisories; `npm audit` finds
   moderate+ CVEs that developers would not notice otherwise.

4. **Block publish on any outdated package** — Rejected: overly aggressive; outdated
   ≠ vulnerable; would break workflow for cosmetic version bumps.

---

## Implementation Checklist

- [x] `npm audit` in pre-push hook (`check-npm-audit.ps1`)
- [x] `lockfile-lint` in pre-commit (`config/lefthook.yml`)
- [x] `npm ci` in CI/CD (`test-suite.yml` mcp-bridge step)
- [ ] Quarterly review calendar event (team calendar — manual action)
- [ ] Renovate configuration (`renovate.json`) — **Q3 2026**
- [ ] SBOM generation per release (`generate-sbom.ps1`) — **Implemented May 2026**

---

## References

- ADR-003 — npx offline hardening (supply-chain gentle-vanguard)
- `config/lefthook.yml` — hook configuration
- `scripts/hooks/check-npm-audit.ps1` — audit hook implementation
- `scripts/utilities/DEPLOYMENT/generate-sbom.ps1` — SBOM generation
- OWASP A06:2021 — Vulnerable and Outdated Components

