# Multi-Repository Orchestration Normatives — Foundation

Canonical standards for managing multiple repositories, monorepo/polyrepo strategies, and cross-repo workflows.
Last updated: 2026-05-12 | Version: 1.0.0

---

## 1. Multi-Repo Strategies

### Strategy 1: Monorepo (Recommended for v3.0)

**Structure**: Single repository with multiple projects under one version control.

```
foundation/ (monorepo root)
├── apps/
│   ├── web-dashboard/          (React App)
│   ├── cli-tool/               (TypeScript CLI)
│   └── api-server/             (Go/Python backend)
├── packages/
│   ├── core-skills/            (Shared skills)
│   ├── ui-components/          (React components)
│   └── utils/                  (Shared utilities)
├── infrastructure/             (Terraform, Kubernetes)
├── docs/
└── scripts/
```

**Advantages**:
- ✅ Single version control history
- ✅ Atomic commits across projects
- ✅ Shared dependencies, easy to update
- ✅ Easy code sharing
- ✅ Simplified CI/CD

**Disadvantages**:
- ⚠️ Larger repository size
- ⚠️ Requires careful access controls

**Use case**: Foundation should adopt monorepo structure for v3.0 to unify skills, agentsm and frontends.

---

### Strategy 2: Polyrepo (Alternative)

**Structure**: Multiple independent repositories managed by a mono-orchestrator.

```
Repositories:
├── foundation-core/            (Main orchestrator, skills)
├── foundation-web-ui/          (React dashboard)
├── foundation-plugins/         (Community plugins)
└── foundation-docs/            (Documentation)

Orchestrator: foundation-sync (coordinates updates)
```

**Advantages**:
- ✅ Smaller repositories, faster clones
- ✅ Independent versioning per project
- ✅ Team ownership per repo
- ✅ Flexible deployment

**Disadvantages**:
- ⚠️ Complex synchronization
- ⚠️ Version mismatch risks
- ⚠️ Harder to refactor across repos

**Use case**: Later phase (v3.x) for plugin marketplace and community contributions.

---

### Strategy 3: Hybrid (Recommended)

**Structure**: Monorepo for core + polyrepo for community.

```
CORE (Monorepo: foundation)
├── apps/                       [web, cli, api]
├── packages/                   [shared skills, utilities]
└── infrastructure/             [deployment configs]

COMMUNITY (Polyrepo)
├── foundation-plugins/         [community skills, integrations]
└── foundation-marketplace/     [plugin registry, discovery]

Sync: foundation-sync orchestrator (sync core → plugins as needed)
```

---

## 2. Monorepo Organization (v3.0 Target)

### Directory Structure

```
foundation/ (monorepo)
│
├── apps/                       # Deployable applications
│   ├── web-dashboard/         # React 19 frontend
│   │   ├── src/
│   │   ├── tests/
│   │   ├── package.json
│   │   └── Dockerfile
│   ├── api-gateway/           # TypeScript/Go backend
│   │   ├── src/
│   │   ├── tests/
│   │   └── package.json
│   └── cli/                   # Command-line tool
│       ├── src/
│       └── package.json
│
├── packages/                   # Shared libraries
│   ├── core-sdk/              # SDK for agents/skills
│   │   ├── src/
│   │   ├── tests/
│   │   └── package.json
│   ├── ui-components/         # Reusable React components
│   │   ├── src/
│   │   └── package.json
│   ├── types/                 # Shared TypeScript types
│   │   ├── src/
│   │   └── package.json
│   └── utils/                 # Helper utilities
│       ├── src/
│       └── package.json
│
├── skills/                     # MCP skills (127+)
│   ├── sdd-lifecycle/
│   ├── react-19-skill/
│   └── ... (other skills)
│
├── infrastructure/            # Deployment & DevOps
│   ├── terraform/             # Infrastructure as Code
│   ├── kubernetes/            # K8s manifests
│   ├── docker/                # Docker images
│   └── github-actions/        # CI/CD workflows
│
├── docs/                       # Documentation
│   ├── architecture/
│   ├── api/
│   ├── guides/
│   └── ARCHITECTURE.md
│
├── scripts/                    # Shared scripts
│   └── utilities/
│
├── tests/                      # E2E and integration tests
│   ├── e2e/
│   ├── integration/
│   └── performance/
│
├── config/                     # Centralized configuration
│   └── (all config files)
│
├── lerna.json                  # Workspace manager config
├── pnpm-workspace.yaml         # pnpm workspace (recommended)
├── tsconfig.json               # Root TypeScript config
├── package.json                # Root package.json
└── README.md
```

---

## 3. Workspace Manager (pnpm)

### pnpm Workspace Configuration

**REQUIRED**: Use `pnpm-workspace.yaml` instead of npm workspaces (faster, better hoisting).

```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
  - 'skills/*'

catalog:
  react: '19.0.0'
  typescript: '5.3.0'
  zod: '4.0.0'
```

### Root package.json

```json
{
  "name": "foundation-monorepo",
  "version": "3.0.0",
  "type": "module",
  "private": true,
  "packageManager": "pnpm@9.0.0",
  
  "scripts": {
    "setup": "pnpm install",
    "build": "pnpm -r build",
    "test": "pnpm -r test",
    "test:e2e": "pnpm --filter ./tests/e2e test",
    "lint": "pnpm -r lint",
    "format": "pnpm -r format",
    "dev": "pnpm -r --parallel dev",
    "clean": "pnpm -r clean && rm -rf node_modules",
    "workspace:list": "pnpm list -r"
  },
  
  "devDependencies": {
    "pnpm": "^9.0.0",
    "turbo": "^1.12.0",
    "typescript": "^5.3.0",
    "eslint": "^8.55.0",
    "prettier": "^3.1.0"
  }
}
```

### Per-App package.json

```json
{
  "name": "@foundation/web-dashboard",
  "version": "3.0.0",
  "type": "module",
  "private": true,
  
  "dependencies": {
    "react": "^19.0.0",
    "@foundation/core-sdk": "workspace:*",
    "@foundation/ui-components": "workspace:*"
  },
  
  "devDependencies": {
    "typescript": "^5.3.0"
  },
  
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "test": "jest",
    "lint": "eslint src/ --fix"
  }
}
```

---

## 4. Cross-Repo Dependency Management

### Version Pinning

```json
{
  "dependencies": {
    "@foundation/core-sdk": "3.0.0",    // Fixed version
    "@foundation/ui-components": "^3.0.0"  // Semver range
  }
}
```

### Workspace References (Monorepo Only)

```json
{
  "dependencies": {
    "@foundation/core-sdk": "workspace:^3.0.0"
  }
}
```

### Breaking Change Propagation

When core package version changes (v3.0 → v4.0):

```bash
# 1. Update core package
pnpm --filter @foundation/core-sdk version major

# 2. Update all dependents
pnpm -r update @foundation/core-sdk@latest

# 3. Run tests to detect breaking changes
pnpm test

# 4. Update code as needed, create PR with breaking-change note
```

---

## 5. CI/CD for Monorepo

### GitHub Actions Workflow

```yaml
# .github/workflows/monorepo-ci.yml
name: Monorepo CI

on: [push, pull_request]

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      apps: ${{ steps.changes.outputs.apps }}
      packages: ${{ steps.changes.outputs.packages }}
      skills: ${{ steps.changes.outputs.skills }}
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Detect changed packages
        id: changes
        run: |
          # Detect which workspaces changed
          APPS=$(git diff --name-only origin/main...HEAD | grep '^apps/' | cut -d/ -f2 | sort -u | jq -R -s -c 'split("\n")[:-1]')
          PACKAGES=$(git diff --name-only origin/main...HEAD | grep '^packages/' | cut -d/ -f2 | sort -u | jq -R -s -c 'split("\n")[:-1]')
          echo "apps=$APPS" >> $GITHUB_OUTPUT
          echo "packages=$PACKAGES" >> $GITHUB_OUTPUT
  
  build-affected:
    needs: detect-changes
    runs-on: ubuntu-latest
    strategy:
      matrix:
        workspace: ${{ fromJson(needs.detect-changes.outputs.apps) }}
    
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
      
      - run: pnpm install --frozen-lockfile
      - run: pnpm --filter apps/${{ matrix.workspace }} build
      - run: pnpm --filter apps/${{ matrix.workspace }} test
      - run: pnpm --filter apps/${{ matrix.workspace }} lint
```

---

## 6. Multi-Repo Synchronization (Polyrepo Phase)

### Sync Tool: foundation-sync

```powershell
# scripts/utilities/foundation-sync.ps1

[CmdletBinding()]
param(
    [string]$SourceRepo = "https://github.com/EmmanuelOrtiz87/foundation",
    [string]$TargetRepo = "https://github.com/EmmanuelOrtiz87/foundation-plugins",
    [string]$SourcePath = "skills/",
    [string]$TargetPath = "node_modules/@foundation/skills",
    [string]$SyncMode = "mirror"  # mirror, merge, patch
)

function Sync-Repository {
    # Clone source
    git clone --depth 1 $SourceRepo /tmp/foundation-src
    
    # Copy target files
    $source = "/tmp/foundation-src/$SourcePath"
    $target = "/tmp/foundation-target/$TargetPath"
    Copy-Item -Path $source -Destination $target -Recurse -Force
    
    # Commit and push
    git -C /tmp/foundation-target add $TargetPath
    git -C /tmp/foundation-target commit -m "chore(sync): Update from foundation core"
    git -C /tmp/foundation-target push
}

Sync-Repository
```

### Scheduled Sync (GitHub Actions)

```yaml
# .github/workflows/sync-core.yml
name: Sync Foundation Core

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pwsh ./scripts/utilities/foundation-sync.ps1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 7. Version Coordination

### Central Version File

```
VERSION_MANIFEST.json
{
  "foundation": "3.0.0",
  "apps": {
    "web-dashboard": "3.0.0",
    "api-gateway": "3.0.0",
    "cli": "3.0.0"
  },
  "packages": {
    "core-sdk": "3.0.0",
    "ui-components": "3.0.1",
    "types": "3.0.0"
  },
  "skills": "3.0.0",
  "infrastructure": "3.0.0",
  "lastUpdated": "2026-05-12T19:55:00Z",
  "maintenanceWindow": "2026-05-15T02:00:00Z"
}
```

---

## 8. Governance & Access Control

### Code Ownership (CODEOWNERS)

```
# CODEOWNERS
* @team/maintainers

/apps/web-dashboard/ @team/frontend
/apps/api-gateway/ @team/backend
/packages/ @team/maintainers
/infrastructure/ @team/devops
/skills/ @team/maintainers
/docs/ @team/docs
```

### Branch Protection Rules

```yaml
# Default for `main`
- require status checks
- require code reviews (2 approvals)
- require branches to be up to date
- enforce admins

# Protected branch: `main`
- delete branch on merge
- auto-merge: disabled
```

### ⚠️ Critical Safety: `--delete-branch` Guard

**🚫 NEVER use `--delete-branch` when the PR head branch is `main` or `develop`.**

This will **permanently delete the protected branch** from the remote, breaking the repo's branching model.

| Scenario | Safe? | Action |
|----------|-------|--------|
| PR head is a feature branch (`feat/*`, `fix/*`, `chore/*`, `docs/*`) | ✅ Safe | `gh pr merge --merge --delete-branch` |
| PR head is `main` or `develop` | 🚫 **NEVER** | `gh pr merge --merge` (omit `--delete-branch`) |

**GitFlow rule**: Only temporary/feature branches are auto-deleted. Protected branches (`main`, `develop`, `release/*`) must NEVER be passed as `--delete-branch` target.

---

## 9. Testing Multi-Repo Changes

### Integration Tests

```powershell
# tests/integration/monorepo.tests.ps1

Describe "Monorepo Integration" {
    It "all packages can be installed" {
        pnpm install | Should Not Throw
    }

    It "cross-package dependencies resolve" {
        (pnpm list @foundation/core-sdk).version | Should Match "3\.0\."
    }

    It "can build all apps" {
        pnpm -r build | Should Not Throw
    }

    It "no circular dependencies" {
        # Use madge or similar tool
        npx madge --circular --strict packages/ | Should Be ""
    }
}
```

---

## 10. Monorepo Migration Plan (v3.0)

### Phase 1: Planning (Week 1)
- [ ] Define package boundaries
- [ ] Design monorepo structure
- [ ] Select workspace tool (pnpm recommended)
- [ ] Document migration strategy

### Phase 2: Setup (Week 2)
- [ ] Create monorepo root
- [ ] Initialize pnpm-workspace.yaml
- [ ] Create root package.json
- [ ] Set up tsconfig.json paths

### Phase 3: Migration (Weeks 3-4)
- [ ] Move apps/ packages
- [ ] Move packages/ libraries
- [ ] Move skills/
- [ ] Migrate CI/CD workflows

### Phase 4: Validation (Week 5)
- [ ] All tests pass
- [ ] Performance benchmarks OK
- [ ] Documentation complete
- [ ] Stakeholder approval

### Phase 5: Release (Week 6)
- [ ] Merge to main
- [ ] Release v3.0.0
- [ ] Deploy monorepo infrastructure

---

## 8. Lessons Learned & Best Practices (Release Baseline v1.0.0)

### Lessons Learned

- Release history and current version state can diverge between repositories; always validate both.
- Baseline homogenization is safer with non-destructive updates (`VERSION` + branch propagation)
  instead of rewriting existing tag history.
- `main` alignment alone is insufficient; `develop` must also contain the same release baseline.

### Best Practices

1. Validate in both repos before any release action:
  - `VERSION`
  - `git tag --sort=-creatordate`
  - `git branch -vv`
2. Apply baseline changes in this order:
  - update `VERSION` on `main`
  - commit and push
  - merge `main` into `develop`
  - push `develop`
3. Keep tags immutable:
  - if `v1.0.0` already exists, do not move it
  - if `v1.0.0` is missing in one repo, create and push it once
4. Keep mandatory validation gates enabled (pre-push hooks, tests, audit checks) during
  homogenization.

---

## References

- [pnpm Workspaces](https://pnpm.io/workspaces)
- [Monorepo Tools Comparison](https://monorepo.tools/)
- [Lerna.js](https://lerna.js.org/)
- [Turborepo](https://turbo.build/repo)
- Project: `config/multi-repo-orchestration.json` (to be created)
