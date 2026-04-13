# Foundation Migration & Upgrade Guide

## v1.0.0 - First Stable Release (No Migration Needed)

This is the first stable release of Gentleman Foundation. If you're upgrading from earlier pre-releases (v2.2.0, v2.2.1), follow this guide.

### Upgrading from Pre-Release (v2.2.x) to v1.0.0

#### Overview

v1.0.0 introduces **governance formalization** and **structured release process** but is largely backward-compatible with existing workflows.

**Breaking Changes**: None for end users. All CLI commands, scripts, and skills remain functional.

**New Features**: 
- Global-vs-repository boundary protocol
- Deferred-work registry system
- SDD governance enforcement
- Foundation-Dashboard homologation

#### Step-by-Step Upgrade

##### 1. Update Your Foundation Clone

```bash
cd /path/to/workspace-foundation
git fetch origin
git checkout main  # Switch from develop to main for stable releases
git reset --hard origin/main
git pull --tags origin
```

##### 2. Verify Installation

```powershell
.\scripts\utilities\wf.ps1 health
.\scripts\utilities\wf.ps1 ide-status
```

Expected output: All tools active, no errors.

##### 3. Update Consumer Projects (Dashboard, etc.)

If you're using Foundation as a sync source:

```powershell
# In your consumer project (e.g., bitbucket-dashboard)
.\scripts\utilities\wf.ps1 foundation-sync apply
```

This pulls the latest skills, scripts, and policies from Foundation v1.0.0.

##### 4. Review New Governance Models

Read these docs to understand new protocols:
- `docs/guides/RELEASE-STRATEGY.md` — versioning and release process
- `skills/project-orchestrator-skill/SKILL.md#DEFERRED-WORK-REGISTRY-PROTOCOL` — how to register deferred work
- `skills/project-orchestrator-skill/SKILL.md#GLOBAL-VS-REPOSITORY-BOUNDARY-PROTOCOL` — coordination boundaries

##### 5. No Configuration Changes Required

Pre-release to v1.0.0 is a content update. No config, env vars, or settings to change.

---

## Future Versions

### v1.1.0 (Planned)

Expected when: FF-001 to FF-003 complete (SDD hardening, process metrics, CI noise reduction).

**Expected changes**:
- Tighter SDD enforcement on protected branches
- Process KPI dashboards
- Reduced advisory warnings

**No breaking changes**.

### v2.0.0 (Planned, Far Future)

Potential breaking changes to enable:
- Trunk-based development (removing `develop` branch)
- New architecture for multi-workspace support

**Will include**: Full migration guide.

---

## FAQ

**Q: Can I keep using `develop` branch after upgrading to v1.0.0?**

A: Yes. Foundation continues to support `develop` as integration branch. New consumers cloning Foundation will get the `v1.0.0` tag (snapshot of main), but can create features on `develop` locally. See RELEASE-STRATEGY.md for branch design.

**Q: Will v1.0.0 break my current projects?**

A: No. All CLI commands, scripts, and skill paths remain unchanged. Your existing projects continue to work.

**Q: How do I report a bug in v1.0.0?**

A: Open an issue on GitHub: https://github.com/EmmanuelOrtiz87/workspace-foundation/issues

Include:
- Foundation version: `git describe --tags --abbrev=0`
- OS/PowerShell version: `$PSVersionTable`
- Reproduction steps

**Q: How do I use v1.0.0 for a new project?**

A: Clone and pin to v1.0.0:

```bash
git clone https://github.com/EmmanuelOrtiz87/workspace-foundation.git my-foundation
cd my-foundation
git checkout v1.0.0  # Pin to stable version
```

Or use Foundation as a template:

```bash
# Copy Foundation structure to your new project
cp -r workspace-foundation/* ./my-new-project/
cd my-new-project
git init
git add .
git commit -m "init: scaffold from Foundation v1.0.0"
```

**Q: What's the support window for v1.0.0?**

A: v1.0.0 is supported at least through v1.2.x releases. Once v1.3.0 is released, v1.0.x enters LTS (low-priority fixes only).

**Q: Can I use v1.0.0 in production?**

A: Yes. v1.0.0 is the first stable release and is production-ready. All governance, CI checks, and quality gates pass.

---

**Next**: See [RELEASE-STRATEGY.md](./RELEASE-STRATEGY.md) for versioning and release process details.
