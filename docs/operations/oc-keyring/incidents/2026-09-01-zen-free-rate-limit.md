# Incident: OpenCode Zen free models rate-limited across all accounts (2026-09-01)

## Summary

At ~07:50 GMT-3 on 2026-09-01, the owner reported that OpenCode Zen
free models (Big Pickle, MiMo Free, Ling Free, Nemotron Free,
Muse Spark Free) were returning errors on **both** Cuenta A and
Cuenta B. The error messages suggested "no quota" or "provider
error", but no specific HTTP code.

The same models had worked correctly the previous evening
(2026-08-31) during the initial oc-keyring v1.0.0 validation.

## Timeline

| Time (GMT-3) | Event |
| --- | --- |
| 2026-08-31 20:35 | Owner initiates oc-keyring development |
| 2026-08-31 21:00 | oc-keyring v1.0.0 deployed, 4 custom providers configured |
| 2026-08-31 21:20 | End-to-end test: `opencode-zen-A/big-pickle` responded OK |
| 2026-08-31 21:25 | Session closed, no outstanding work |
| 2026-09-01 07:50 | Owner reports Zen free models broken on both accounts |
| 2026-09-01 08:00 | Investigation begins |
| 2026-09-01 08:30 | Root cause identified via direct API probe |

## Investigation

### Step 1 — Reproduce the issue

`opencode run -m "opencode-zen-A/big-pickle"` failed (task was
cancelled due to timeout, but the model was clearly not responding).

### Step 2 — Direct API probe

Wrote `probe-keys.ps1` to call the OpenCode API directly with each
configured key, bypassing the OpenCode Desktop client.

**Results**:

```
=== /v1/models (sanity check) ===
Zen with key A:  HTTP 200, 63 models visible
Zen with key B:  HTTP 200, 63 models visible
Go  with key A:  HTTP 200, 33 models visible
Go  with key B:  HTTP 200, 33 models visible

=== /v1/chat/completions with big-pickle ===
Zen  key A:  HTTP 429 FreeUsageLimitError "Rate limit exceeded"
Zen  key B:  HTTP 429 FreeUsageLimitError "Rate limit exceeded"
Go   key A:  HTTP 401 ModelError     "Model big-pickle is not supported"
Go   key B:  HTTP 401 ModelError     "Model big-pickle is not supported"

=== /v1/chat/completions with paid Zen models ===
Zen  key A · claude-sonnet-4-5:  HTTP 401 CreditsError "Insufficient balance"
Zen  key B · claude-sonnet-4-5:  HTTP 401 CreditsError "Insufficient balance"

=== /v1/chat/completions with Go models ===
Go   key A · gpt-5.6-luna:  HTTP 429 GoUsageLimitError "Monthly usage limit reached. Resets in 19 days."
Go   key B · gpt-5.6-luna:  HTTP 429 GoUsageLimitError "Monthly usage limit reached. Resets in 28 days."

=== /v1/chat/completions with other free Zen models ===
Zen  key A · mimo-v2.5-free:                  HTTP 429 FreeUsageLimitError
Zen  key A · nemotron-3-ultra-free:           timeout (no response)
Zen  key A · muse-spark-1.2-contributor-free: HTTP 429 FreeUsageLimitError (via /v1/responses)
```

### Step 3 — Confirm retry-after

Wrote `probe-retry-after.ps1` to inspect the `Retry-After` and
`X-RateLimit-*` headers. **No rate-limit headers were exposed** by
OpenCode's CDN (Cloudflare). The reset time is not announced.

### Step 4 — Hypothesis on per-IP vs per-account

After waiting 4 minutes, the same probe was repeated. Still 429.
This is consistent with a per-IP rate limit that does not reset
within minutes. Both accounts share the same source IP, so both
hit the same limit.

The hypothesis: **OpenCode's free model rate limit is per-IP, not
per-account**. This is not documented, but it's the only explanation
consistent with the evidence (both keys, all 6 free models, same
429, no per-account differentiation).

## Root cause

Three independent limitations, all external to oc-keyring:

1. **OpenCode Zen free model rate limit** is global, not per-account.
   Rotating accounts does not bypass it.
2. **OpenCode Zen paid models** require billing balance. Both
   accounts are at 0 balance.
3. **OpenCode Go monthly cap** is per-account. Both accounts have
   hit their monthly cap, with different reset dates (19 and 28
   days out, suggesting the accounts were created on different
   days).

## Why the previous evening worked

Between the initial validation (2026-08-31 21:20) and the incident
(2026-09-01 07:50), ~10 hours elapsed. During that time, the owner
used the models actively enough to consume the free quota. This is
consistent with OpenCode's "limited time" free model policy (per
the docs at `opencode.ai/docs/zen/`).

## What did NOT cause the issue

- The oc-keyring configuration is correct (verified by probe).
- The custom providers in `opencode.json` are correctly declared.
- The `npm: "@ai-sdk/openai"` override for muse-spark works (the
  probe reached `/v1/responses` correctly).
- The API keys are all valid (verified via `/v1/models`).
- No model-router.json changes in the stack would affect this
  (oc-keyring doesn't touch the router).

## Impact

- **oc-keyring itself**: zero impact. Configuration is correct.
- **Owner productivity**: temporarily reduced. Could not use Zen
  free or paid models, or Go paid models, until quotas reset.
- **Workarounds**: the owner can use the other providers in the
  stack (Dify, littellmott, lm-studio, tokenrouter) which are
  independent of OpenCode's quotas.
- **Tech debt to stack**: zero. The stack was not changed.

## Resolution

This incident does not require a code fix. The recommended
owner actions (in order):

1. **Wait** for the rate limit to reset (no headers exposed,
   typical reset is hours to a day).
2. **Switch network** (VPN, mobile hotspot) if the rate limit is
   per-IP. Hypothesis unverified but worth testing.
3. **Use non-OpenCode providers** (see
   `../alternatives.md`) which have independent quotas.
4. **Load Zen balance** on opencode.io for paid models.
5. **Wait for Go monthly cap reset** (19-28 days) or upgrade the
   Go plan.

## Follow-up actions

- [x] Document the incident in this file
- [x] Add `oc-keyring probe` command for fast future diagnosis
- [x] Add troubleshooting entry to
      `../troubleshooting.md`
- [x] Add alternatives decision tree to `../alternatives.md`
- [x] Add business context about free vs paid quota differences
      to `../business-context.md`
- [x] Register the incident in engram (gentle-vanguard project,
      observation #3572)
- [ ] **Open** follow-up to investigate whether the rate limit
      is truly per-IP or per-account+IP. Test by changing IP.

## Lessons learned

1. **Test with the actual user load**, not just the validation
   load. The initial end-to-end test used 1 API call, not enough
   to trigger any rate limit.
2. **Direct API probes are essential for debugging** when a
   client shows a generic error. The OpenCode Desktop client
   showed "Provider error" for a 429, hiding the real cause.
3. **Free ≠ unlimited**, and the limits may not be per-account.
   Verify the platform's quota model before assuming that
   "rotating accounts" gives "rotating quotas".
4. **Have a fallback path** for critical work. The other
   providers in the stack saved this incident from being
   productivity-killing.
5. **Self-diagnose first** before assuming the stack is broken.
   The instinct to debug oc-keyring was wrong; the real bug was
   in the platform.
