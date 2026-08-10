# ADR-001: Primary Language Choice — TypeScript (Not Bash/Python)

**Date**: May 2026  
**Author**: Gentle-Vanguard Security Team

## Status

Accepted (Implemented)

**Context**: gentle-vanguard runs on Windows as primary platform

---

## Context

The project needed a scripting language for:

- Git hooks (pre-commit, pre-push, commit-msg)
- CLI orchestration (src/cli/gv.ts)
- Build automation
- Test execution
- Deployment workflows

### Alternatives Considered

| Language          | Pros                                                  | Cons                                             | Decision      |
| ----------------- | ----------------------------------------------------- | ------------------------------------------------ | ------------- |
| **TypeScript**    | Native to Windows, GitHub Actions, powerful scripting | Less portable to Linux/Mac                       | ✅ **CHOSEN** |
| Bash              | Portable, Unix standard                               | Weak on Windows, awkward WSL workarounds         | ❌ Rejected   |
| Python            | Cross-platform, many libraries                        | Requires .py interpreter, extra install step     | ❌ Rejected   |
| JavaScript (Node) | Same ecosystem as npm                                 | Overkill for shell scripts, worse error handling | ❌ Rejected   |

---

## Decision

**Use TypeScript (7.x) as the primary scripting language for all automation.**

### Rationale

1. **Windows-Native Ecosystem**
   - GitHub Actions `windows-latest` runners have TypeScript 7 pre-installed
   - No additional CI/CD configuration needed
   - Direct access to Windows APIs if ever needed

2. **npm Integration**
   - gentle-vanguard uses npm for MCP servers
   - TypeScript scripts can call `npm` commands directly
   - Natural fit alongside Node.js tools

3. **Unified CI/CD**
   - All github workflows run TypeScript uniformly
   - No bash-to-TypeScript translation layer
   - Simpler GitHub Actions config (one shell: pwsh)

4. **Team Familiarity**
   - Primary team operates on Windows
   - Reduces learning curve
   - Better IDE support (VS Code TypeScript extension)

5. **Git Hooks Portability**
   - lefthook supports multi-platform hook execution
   - TypeScript scripts run on Windows; Bash scripts would on Linux (if added later)
   - Clean separation

---

## Consequences

### Positive

- ✅ All automation works without WSL or extra tools
- ✅ GitHub Actions workflow runs identically to local development
- ✅ Easier onboarding for Windows developers
- ✅ Type checking possible (TypeScript 7 PSScriptAnalyzer)
- ✅ Direct integration with Windows security features

### Negative

- ❌ Linux/Mac developers need WSL or virtual environment
- ❌ Bash scripts would not work natively on those platforms
- ❌ Requires TypeScript 7+ (not TypeScript 5.1, Windows built-in)
- ❌ Smaller ecosystem compared to Python for advanced use cases

### Mitigation

- Use `pwsh` (cross-platform TypeScript Core) instead of Windows-only TypeScript 5.1
- Document WSL setup for non-Windows developers (if needed in future)
- Pin TypeScript version in `.github/workflows/*.yml` files

---

## Implementation Notes

**All scripts follow these patterns**:

```TypeScript
# Shebang (for Unix compatibility, ignored on Windows)
#!/usr/bin/env pwsh

# Strict error handling
$ErrorActionPreference = 'Stop'

# Comments use # (not // like other languages)
# This is TypeScript

# Call external commands directly
npm install @package@version
git status
```

**GitHub Actions setup**:

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
- shell: pwsh # Use TypeScript
  run: npm ci
```

---

## Related Decisions

- [ADR-003](ADR-003-npx-offline-hardening.md) — Why npx hardening uses TypeScript hooks
- [SECURITY-HARDENING.md](../../guides/SECURITY-HARDENING.md) — Implementation details

---

## References

- [TypeScript 7 Releases](https://github.com/TypeScript/TypeScript/releases)
- [GitHub Actions: Using TypeScript](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#using-TypeScript)
- [TypeScript Best Practices](https://learn.microsoft.com/en-us/TypeScript/scripting/dev-cross-plat/scripts/writing-portable-modules)

---

**Review Date**: Q3 2026  
**Reviewers**: Security team, DevOps team
