# Demo 03 - Engram Memory and Continuity

Audience: Development Team

## Goal

Show cross-session continuity using Engram memory and session history.

## Scope

1. Start and continue sessions.
2. Recover prior context.
3. Avoid repeated onboarding and repeated prompts.

## Components Demonstrated

1. `run-engram.ps1`
2. `compact-start.ps1`
3. `detect-ide-session.ps1`
4. Session artifacts and continuity flow

## Run Steps

1. `./scripts/utilities/run-engram.ps1 --help`
2. `./scripts/utilities/wf.ps1 compact-start`
3. `./scripts/utilities/wf.ps1 start-session demo-memory`
4. `./scripts/utilities/wf.ps1 status`

## Expected Outcome

1. Memory tools are reachable and session-aware.
2. Context is resumed quickly.
3. Team sees tangible AI collaboration continuity.
