---
name: ci-cd-and-automation
description: Automate CI/CD pipelines. Configure build processes, test runners, deployment strategies, and quality gates.
triggers:
  - ci/cd
  - pipeline
  - automation
  - build
  - deploy
  - github actions
---

# CI/CD and Automation

## Overview

Automate quality gates so that no change reaches production without passing tests, lint, type
checking, and build. CI/CD is the enforcement mechanism for every other skill — it catches what
humans and agents miss, and it does so consistently on every single change.

**Shift Left:** Catch problems as early in the pipeline as possible. A bug caught in linting costs
minutes; the same bug caught in production costs hours. Move checks upstream — static analysis
before tests, tests before staging, staging before production.

**Faster is Safer:** Smaller batches and more frequent releases reduce risk, not increase it. A
deployment with 3 changes is easier to debug than one with 30. Frequent releases build confidence in
the release process itself.

## When to Use

- Setting up a new project's CI pipeline
- Adding or modifying automated checks
- Configuring deployment pipelines
- When a change should trigger automated verification
- Debugging CI failures

## Feeding CI Failures Back to Agents

When CI fails, feed the output directly to an agent:

> "The CI pipeline failed with this error: [paste error]. Fix and verify locally."

| Failure        | Fix                                   |
|----------------|---------------------------------------|
| Lint failure   | Run `npm run lint --fix` and commit   |
| Type error     | Read the error location, fix the type |
| Test failure   | Follow the debugging skill            |
| Build error    | Check config and dependencies         |

## Common Rationalizations

| Rationalization                   | Reality                                                                            |
|-----------------------------------|------------------------------------------------------------------------------------|
| "CI is too slow"                  | Optimize the pipeline (see references), don't skip it.                             |
| "This change is trivial"          | Trivial changes break builds. CI is fast for trivial changes anyway.               |
| "The test is flaky, just re-run"  | Flaky tests mask real bugs. Fix the flakiness.                                     |
| "We'll add CI later"              | Projects without CI accumulate broken states. Set it up on day one.                |
| "Manual testing is enough"        | Manual testing doesn't scale and isn't repeatable. Automate what you can.          |

## Red Flags

- No CI pipeline in the project
- CI failures ignored or silenced
- Tests disabled in CI to make the pipeline pass
- Production deploys without staging verification
- No rollback mechanism
- Secrets stored in code or CI config files
- Long CI times with no optimization effort

## Verification

- [ ] All quality gates are present (lint, types, tests, build, audit)
- [ ] Pipeline runs on every PR and push to main
- [ ] Failures block merge (branch protection configured)
- [ ] CI results feed back into the development loop
- [ ] Secrets are stored in the secrets manager, not in code
- [ ] Deployment has a rollback mechanism
- [ ] Pipeline runs in under 10 minutes for the test suite

## Reference Files

Detailed YAML configurations, deployment strategies, and optimization guides:

- [pipeline-setup.md](references/pipeline-setup.md) — CI pipeline YAML examples, environment setup
- [workflow-patterns.md](references/workflow-patterns.md) — deployment strategies, feature flags, automation
- [quality-gates.md](references/quality-gates.md) — CI optimization, parallelism, caching, gate pipeline