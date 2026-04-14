# Demo 01 - Developer Onboarding

Audience: Development Team

## Goal

Show how a developer starts with the stack in a clean and repeatable way.

## Scope

1. Environment activation.
2. Foundation sync behavior.
3. Session start and status checks.
4. First project context setup.

## Components Demonstrated

1. `stack-on-demand.ps1`
2. `foundation-sync.ps1`
3. `wf.ps1`
4. `start-session.ps1`
5. Base documentation entry points

## Run Steps

1. `./scripts/utilities/wf.ps1 health`
2. `./scripts/utilities/stack-on-demand.ps1 -Action activate`
3. `./scripts/utilities/wf.ps1 start-session demo-onboarding`
4. `./scripts/utilities/wf.ps1 status`
5. `./scripts/utilities/orchestrator-status.ps1`

## Expected Outcome

1. Tooling is active and validated.
2. Session artifact is created.
3. Developer sees the recommended next steps.
