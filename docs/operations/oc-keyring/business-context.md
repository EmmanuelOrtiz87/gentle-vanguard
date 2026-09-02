# oc-keyring — Business Context

Why this feature exists, what it costs, what it saves, and what it doesn't fix.

## The business problem

The owner operates **two OpenCode accounts simultaneously** in daily
work:

- **Cuenta A** (primary): the main account used for production work,
  client deliverables, and any task that should be billed to the
  primary billing relationship.
- **Cuenta B** (secondary): a separate account with its own quota,
  used as a fallback, for testing, or for tasks that should be
  isolated from the primary billing.

Both accounts are subscribed to **two OpenCode products**:

- **OpenCode Zen**: curated list of models, including free models
  (Big Pickle, MiMo Free, etc.) and paid models (Claude, GPT-5,
  DeepSeek, etc.) billed per-token.
- **OpenCode Go**: subscription plan with access to popular models
  at a flat monthly rate, plus a per-account monthly cap.

The two accounts give the owner:

- **Isolation**: testing/experimental work doesn't pollute the
  primary billing.
- **Capacity**: 2x the monthly cap of OpenCode Go.
- **Redundancy**: if Cuenta A hits a rate limit, Cuenta B is
  available.
- **Resilience**: if one account is compromised or its billing
  fails, the other continues to work.

## The pre-oc-keyring problem

OpenCode's official mechanism for switching accounts requires
manual intervention every time:

1. Open browser, go to opencode.io
2. Log out of the current account
3. Log in with the other account
4. Navigate to the API key section for the right product
5. Copy the key
6. Open OpenCode Desktop, navigate to Connections
7. Delete the old credential, paste the new one
8. Re-authenticate (sometimes a restart is needed)

**Cost per rotation**: ~3-5 minutes of focused human work.
**Cost per day** (assuming 4-6 rotations): 15-30 minutes of
context-switching and manual error-prone work.
**Cost per year**: ~50-100 hours of pure overhead.

The 2026-08-31 motivation for building `oc-keyring` was: "I rotated
accounts manually 4 times today and lost focus each time. This
needs to be solved."

## The post-oc-keyring reality

After deployment:

- **Time per rotation**: ~3 seconds (`oc-keyring switch zen B` + 1
  click in the model picker)
- **Time per day**: ~15-20 seconds total
- **Time per year**: ~1 hour (mostly just to remember the command)
- **Reduction**: 95%+

Other benefits:

- **Zero copy/paste** of API keys through chat/UI/screenshots
- **Zero risk of pasting the wrong key** (eliminates a class of
  human errors)
- **Atomic and reversible** (each change creates a backup)
- **Auditable** (the script logs what changed and when)

## What oc-keyring does NOT solve

This is important to set expectations correctly. `oc-keyring` is a
**rotation mechanism**, not a **capacity multiplier**.

For **paid models**, it does multiply effective capacity: Cuenta A
and Cuenta B each have their own balance, so rotating spreads load
and effectively doubles the budget.

For **free models**, it does NOT multiply capacity. OpenCode's rate
limit on free models is global (per-IP, not per-account). See the
2026-09-01 incident post-mortem
([incidents/2026-09-01-zen-free-rate-limit.md](./incidents/2026-09-01-zen-free-rate-limit.md))
for the full analysis. The 6 free models on Zen all share one
quota; rotating between accounts does not help.

This was a real surprise and a real disappointment on 2026-09-01
when both accounts hit the same 429 within minutes of each other.
The owner reasonably expected "free models are per-account like paid
models are", but the platform does not work that way.

## What this means in practice

When OpenCode quotas are exhausted, the alternatives are:

1. **Wait** for the quota to reset (rate limits, monthly caps)
2. **Use other providers** in the stack (Dify, littellmott,
   lm-studio, tokenrouter) — these are not affected by OpenCode's
   limits
3. **Load balance** on opencode.io for paid models
4. **Switch network** (VPN, hotspot) to attempt a per-IP rate
   limit reset (unverified)

The full decision tree is in [alternatives.md](./alternatives.md).

## Operational metrics

| Metric | Before | After | Delta |
| --- | --- | --- | --- |
| Time per account switch | 3-5 min | 3 sec | -98% |
| Daily overhead | 15-30 min | 15-20 sec | -98% |
| Annual overhead | 50-100 hours | ~1 hour | -98% |
| Manual error rate | ~5% (wrong key paste) | 0% | -100% |
| API key in screenshots/chat | Yes | No | -100% |
| Backup before change | No | Always | +∞ |

## Security posture

The feature does NOT change the security posture vs. the baseline
(using `opencode auth login` directly):

- API keys are still stored in plaintext in
  `~/.local/share/opencode/auth.json` (OpenCode's native format).
- The vault (`accounts.json`) is in user space, never committed.
- Backups are in user space, never committed.
- No new attack surface introduced.

For stronger protection, watch OpenCode issue
[#4318](https://github.com/anomalyco/opencode/issues/4318) for
system-keyring support. When that ships, `oc-keyring` can be
extended to write credentials to the OS keyring instead of the
plaintext file.

## Cost of maintenance

**Ongoing maintenance cost**: ~0 hours per month.

- The script is self-contained.
- No updates required unless OpenCode changes its config format.
- The `models.dev` registry is the source of truth for model
  availability; if OpenCode adds a new free model, a one-line edit
  to `opencode.json` adds it.
- Backups accumulate but are not auto-pruned (intentional).

## When to sunset this feature

`oc-keyring` is obsolete when:

- OpenCode ships native multi-account support (planned, no ETA).
- OpenCode moves to system keyring (issue #4318), making the
  vault approach less relevant.
- The owner reduces to one account (unlikely, but possible).

Until any of these, `oc-keyring` is the lowest-friction path to
multi-account rotation. It's also a defensive design: if OpenCode
ever changes its config format in a breaking way, the script can
be ported in a few hours, not days.
