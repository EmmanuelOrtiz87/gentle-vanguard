# Module Activation Workflow

Formal process to activate **experimental** modules in the Gentle-Vanguard stack. Core modules are
the default daily path and do **not** require this workflow. Deprecated modules cannot be activated.

- Registry: [`config/module-maturity.json`](../../config/module-maturity.json)
- Enforcer: [`src/module-maturity.ts`](../../src/module-maturity.ts)
- Policy summary: [`docs/status/STACK-MATURITY-GUIDE.md`](../status/STACK-MATURITY-GUIDE.md)

## Roles

| Role             | Responsibility                                                         |
| ---------------- | ---------------------------------------------------------------------- |
| **Owner**        | Module owner (see `owner` field in the registry). Drives the proposal. |
| **gov-agent**    | Governance review, security gates, approval gate keeper.               |
| **orchestrator** | Final approval + rollout coordination.                                 |

## Minimum gates (no exceptions)

Every experimental module must satisfy, at minimum:

1. `tests` — `npm run test` passes.
2. `typecheck` — `npm run typecheck` passes with 0 errors.
3. `lint` — `npm run lint` passes with 0 warnings.
4. `security-scan` — `npm run secretlint` passes (SAST/secret scanning).
5. `governance-approval` — recorded decision in
   `docs/governance/activation-decisions/<module-id>.md`.
6. `owner-signoff` — explicit owner approval recorded in the same file.

Gates 1-4 are enforced by `src/module-maturity.ts` (the CLI can execute them with `--run-checks`).
Gates 5-6 are human/agent decisions recorded as files.

## Workflow (proposal → rollout)

### Step 1 — Proposal

The **owner** writes a proposal covering:

- Scope and public interface (what runs, what it touches).
- Impact: files, services, pipeline steps, resource consumption.
- Risk classification (`low | medium | high`) and mitigation.
- Success criteria for the pilot.

Store the proposal under `docs/governance/activation-decisions/<module-id>.md` (see
[decision template](#decision-file-template)).

### Step 2 — Governance review

The **gov-agent** reviews the proposal against:

- `config/module-maturity.json` policy (`policy.minimumGates`, `policy.approvalRoles`).
- Security impact (secrets, network, data privacy).
- Conflict with core modules or existing experimental modules.
- Alignment with the stack's local-first principle.

Verdict: `approved` / `changes-required` / `rejected`. `rejected` is final unless a new proposal is
written. `changes-required` returns to Step 1 with the required changes attached.

### Step 3 — Minimum gates

Run the automated gates and confirm they pass:

```bash
npx tsx src/module-maturity.ts --validate <module-id> --run-checks
npx tsx src/module-maturity.ts --gate <module-id> --run-checks
```

`--gate` must report `"gate": "open"` with an empty `missingRequired` list. If any required gate
fails, the module stays blocked.

### Step 4 — Approval

- **gov-agent** approves the security/governance outcome.
- **orchestrator** gives final approval.
- Both sign the decision file `docs/governance/activation-decisions/<module-id>.md` (section
  `## Approvals`), including the rollout date.

### Step 5 — Activation + rollout

1. Edit `config/module-maturity.json`:
   - set `"activated": true` for the module, and
   - keep `"optIn": true` during the pilot (so it is still an explicit opt-in) OR set
     `"optIn": false` only after the module is promoted.
2. Promote to **core** only after a soak period (see [maturation route](#maturation-route)).
3. Update `docs/product/ROADMAP.md` to reflect the state.
4. Mark the decision file `status: activated` with the rollout date.

## Rollback

An experimental module can be deactivated at any time:

- `gov-agent` or the owner sets `"activated": false` in the registry.
- Record the rollback reason and date in the decision file.
- No cleanup of accumulated `.session/` data is required beyond normal pruning.

## Maturation route (experimental → core)

1. `experimental` → runs under `optIn: true`.
2. After a soak period with no regressions and full gate coverage, the owner proposes promotion.
3. A second governance review runs the same gates plus a soak report.
4. On approval, the module becomes `core` (`optIn: false`, `activated: true`).

## Decision file template

```markdown
# Module: <module-id>

- Status: proposed | approved | activated | rejected | rolled-back
- Owner: <owner>
- Risk: <low | medium | high>
- Proposed: <date>

## Proposal

<scope, impact, risk, success criteria>

## Gates

- [ ] tests (npm run test)
- [ ] typecheck (npm run typecheck)
- [ ] lint (npm run lint)
- [ ] security-scan (npm run secretlint)

## Approvals

| Role         | Verdict  | Date   | Signature |
| ------------ | -------- | ------ | --------- |
| gov-agent    | approved | <date> | <name>    |
| orchestrator | approved | <date> | <name>    |

## Rollout

- Activation date:
- Notes:
```

## Automation

The session pipeline can enforce readiness via the lazy step `module-maturity-validate`
(`npx tsx src/module-maturity.ts --status`), which surfaces experimental modules that are gated or
deprecated modules that should be removed. It never activates anything automatically — activation
always requires this workflow.
