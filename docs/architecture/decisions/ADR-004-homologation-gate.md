# ADR-004: Mandatory Homologation Gate in Release Workflow

**Status**: Accepted (Implemented)  
**Date**: May 13, 2026  
**Author**: Foundation Security Team  
**Context**: Preventing release-time repository misalignment issues  

---

## Context

foundation maintains **two synchronized repositories**:
- `foundation` (private) — full codebase + internal docs
- `foundation-public` (public) — sanitized for GitHub

Before implementing the homologation gate, release process risked:
- **Misaligned versions**: foundation v1.0.1 but foundation-public still v1.0.0
- **Misaligned branches**: main branches out of sync, preventing merge
- **Dirty working trees**: unstaged changes blocking publish
- **Human error**: Releasing from wrong branch without noticing

### Risk Assessment

- **Likelihood**: Medium (manual steps, easy to forget)
- **Impact**: High (bad releases, broken public repo, customer confusion)
- **Current Prevention**: Manual checklist (error-prone)
- **Acceptable Risk**: None (repeatable release process required)

---

## Decision

**Implement mandatory homologation gate that blocks publish if repos are misaligned.**

Gate runs BEFORE any other validation (first thing in `wf.ps1 publish`).

If gate fails, publish is blocked with clear remediation steps.

### Rationale

1. **Shift-Left Philosophy**
   - Catch misalignment early (before test, secrets scan, etc.)
   - Fail fast with clear error message
   - Reduce release time by preventing false starts

2. **Repository Consistency**
   - Ensures version sync (VERSION file matches in both repos)
   - Ensures branch sync (main/develop aligned before merge)
   - Ensures clean state (no uncommitted changes)

3. **Automation Over Manual Checklists**
   - Humans forget items on checklists
   - Automated checks cannot be bypassed (except with flags)
   - Repeatable, deterministic validation

4. **Dual-Repo Integrity**
   - Public repo cannot fall behind private repo
   - Prevents customer confusion ("why doesn't public have v1.0.1?")
   - Maintains trust in GitHub public releases

---

## Implementation

### Gate Location

```
wf.ps1 publish
  ↓
1. ✓ Mandatory Homologation Gate  ← FIRST CHECK
  ├─ Check: VERSION file matches
  ├─ Check: main/develop branches aligned
  ├─ Check: working tree clean
  └─ Check: (optional) tag consistency
  ↓
2. ✓ Secrets Scan
3. ✓ Tests
4. ✓ Build
5. ✓ Publish
```

### Validations Performed

**In `scripts/utilities/DEPLOYMENT/validate-release-homologation.ps1`**:

```powershell
# 1. VERSION alignment (REQUIRED)
Foundation\VERSION = "1.0.0"
Foundation-Public\VERSION = "1.0.0"
✓ MATCH

# 2. Branch alignment (REQUIRED)
Foundation\main = commit abc123
Foundation-Public\main = commit abc123
✓ ALIGNED

# 3. Working tree (REQUIRED)
git status --porcelain = (empty)
✓ CLEAN

# 4. Tag consistency (OPTIONAL)
v1.0.0 exists in both repos
✓ CONSISTENT
```

### Failure Scenarios

**Scenario 1: VERSION Mismatch**

```powershell
❌ [BLOCKED] Homologation gate failed

  VERSION Mismatch:
    Foundation:       1.0.1
    Foundation-Public: 1.0.0

Resolution:
  1. Update foundation-public/VERSION to 1.0.1
  2. git add VERSION && git commit -m "chore: align VERSION for vX.Y.Z"
  3. Push: git push origin main
  4. Retry: wf.ps1 publish
```

**Scenario 2: Branch Misalignment**

```powershell
❌ [BLOCKED] Homologation gate failed

  Branch Misalignment:
    Foundation main:       abc123 (behind by 3 commits)
    Foundation-Public main: def456

Resolution:
  1. Fetch latest: git fetch origin
  2. Pull: git pull origin main
  3. Verify alignment: git log --oneline main | head -5
  4. Retry: wf.ps1 publish
```

**Scenario 3: Dirty Working Tree**

```powershell
❌ [BLOCKED] Homologation gate failed

  Working tree not clean:
    Modified: config/mcp-servers.json
    Untracked: test.tmp

Resolution:
  1. Commit changes: git add . && git commit
  2. OR revert changes: git checkout -- config/mcp-servers.json
  3. Remove untracked: rm test.tmp
  4. Verify: git status (should be "clean")
  5. Retry: wf.ps1 publish
```

### Bypass (Emergency Only)

```powershell
# Skip gate (NOT RECOMMENDED)
wf.ps1 publish -SkipHomologationGate

# This requires explicit flag, flags responsibility
```

---

## Consequences

### Positive

- ✅ **Prevents Bad Releases**: Catches misalignment before publish fails halfway
- ✅ **Dual-Repo Consistency**: Public GitHub always matches private master
- ✅ **Clear Errors**: Developers see exactly what's wrong and how to fix it
- ✅ **Repeatable Process**: Same validation every time, no surprises
- ✅ **Audit Trail**: Gate execution logged in CI/CD
- ✅ **Fast Feedback**: ~1 second to validate (no delay)

### Negative

- ❌ **One More Check**: Adds validation step (minor slowdown)
- ❌ **Manual Sync Required**: Developer must keep repos in sync
- ❌ **Discipline Required**: Developers must follow git flow conventions
- ❌ **Possible Blocker**: If repos truly misaligned, blocks release (not a bug)

### Mitigation

- ✅ [RELEASE-PROCESS.md](../../guides/RELEASE-PROCESS.md#25-homologation-gate-mandatory--auto-runs-on-publish) documents the gate
- ✅ [TROUBLESHOOTING-RUNBOOK.md](../../guides/TROUBLESHOOTING-RUNBOOK.md#problem-homologation-gate-failed) has remediation steps
- ✅ Clear error messages guide developers to fixes
- ✅ `-SkipHomologationGate` escape hatch for emergencies

---

## Example Workflow

**Happy Path: Everything Aligned**

```powershell
cd foundation
git status
# On branch develop, everything committed

wf.ps1 publish
# [✓] Homologation Gate: PASSED
# [✓] VERSION files aligned: 1.0.1
# [✓] Branches aligned: main/develop
# [✓] Working tree clean
# → Proceeds to secrets scan, tests, publish
```

**Recovery Path: VERSION Mismatch**

```powershell
wf.ps1 publish
# ❌ Homologation Gate: FAILED
#    VERSION mismatch: foundation=1.0.1, foundation-public=1.0.0

cd ../foundation-public
echo "1.0.1" > VERSION
git add VERSION
git commit -m "chore: align VERSION for v1.0.1 release"
git push origin main

cd ../foundation
git push origin main  # Sync the commit
git push origin develop

wf.ps1 publish
# [✓] Homologation Gate: PASSED
# → Continues with publish
```

---

## Related Gates

| Gate | Purpose | Timing |
|------|---------|--------|
| **Homologation** | Repo alignment | First (1 sec) |
| Secrets Scan | No hardcoded secrets | After homologation |
| Tests | Code quality | Before build |
| Build | Compilation | Final check |
| Publish | Deploy | If all pass |

---

## Future Enhancements

**Potential additions to gate** (not currently implemented):

- [ ] **Changelog validation**: CHANGELOG.md updated for new version
- [ ] **Tag pre-validation**: Verify tag doesn't already exist
- [ ] **Documentation sync**: Verify docs/ folder is identical
- [ ] **Git signature verification**: Commits are GPG-signed (if policy changes)
- [ ] **Artifact availability**: Docker images pre-built and staged

---

## Related Decisions

- [ADR-001](ADR-001-powershell-language-choice.md) — Why gate is written in PowerShell
- [RELEASE-PROCESS.md](../../guides/RELEASE-PROCESS.md) — Full release workflow

---

## Testing the Gate

**Manual verification** (safe to run anytime):

```powershell
cd foundation

# Run gate manually
.\scripts\utilities\wf.ps1 release-homologation

# Check result
$LASTEXITCODE
# 0 = PASSED
# 1 = FAILED
```

---

## References

- [RELEASE-PROCESS.md §2.5](../../guides/RELEASE-PROCESS.md#25-homologation-gate-mandatory--auto-runs-on-publish)
- [validate-release-homologation.ps1](../../../scripts/utilities/DEPLOYMENT/validate-release-homologation.ps1)
- [TROUBLESHOOTING-RUNBOOK.md §Release Workflow Issues](../../guides/TROUBLESHOOTING-RUNBOOK.md#release-workflow-issues)

---

**Implemented**: May 13, 2026 (commit 449363e)  
**Review Date**: Q1 2027  
**Status**: Stable, working as designed
