# Implementation Directive — Content Operations

## Objective
Integrate Content Operations into Gentle-Vanguard without creating a parallel framework.

## Inspect and reuse first

Before coding, inspect:
- `src/marketing-agent.ts`
- `src/social-poster.ts`
- `docs/presentations/resources-index.html`
- `src/cli/gv.ts`
- health/watchtower
- audit/security
- dashboard
- database/Nexus
- existing schedulers/event buses/agent orchestration

## Required outcome

Create one coherent workflow:

`ContentJob → validate → package → review → approve → adapter → publish → audit → metrics`

## Requirements

- Content manifest is the source of truth.
- Approval gate is mandatory for remote publication.
- Local packet generation must work offline.
- Platform adapters are isolated behind a common contract.
- Never store credentials in Git.
- Publishing must be idempotent.
- Every state transition is auditable.
- Remote API failures leave a recoverable local packet.
- Existing marketing-agent remains the generation layer.
- Existing social-poster capabilities should be refactored/reused rather than duplicated.
- Existing CMS should become the human control surface.
- Existing `gv` CLI should expose the feature when stable.

## Suggested commands

```text
gv content list
gv content validate
gv content prepare
gv content preview
gv content approve
gv content publish
gv content status
gv content report
gv content export
```

## Platform order

1. Local/manual
2. LinkedIn
3. X
4. YouTube
5. TikTok
6. Meta/Instagram
7. WhatsApp Business
8. Community platforms

Implement only through current official APIs and permissions.

## Acceptance criteria

- Existing tests remain green.
- New domain tests cover validation and state transitions.
- Offline preparation works with no network.
- CMS can inspect prepared jobs.
- No duplicate posting path exists between `marketing-agent`, `social-poster` and COE.
- A single manifest can generate platform-specific variants.
- Export script can produce an offline ZIP on Windows.
