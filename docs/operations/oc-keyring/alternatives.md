# Alternatives & Workarounds for OpenCode Quotas

When OpenCode rate limits, monthly caps, or credit shortages prevent use of
the custom providers managed by `oc-keyring`, the workarounds below can keep
you productive. None require changes to oc-keyring or to the stack.

## TL;DR decision tree

```
Need a model RIGHT NOW?
│
├── Has billing on Zen? ──YES──> Use Zen paid models (claude-sonnet, gpt-5, etc.)
│
├── Has Go monthly cap left? ──YES──> Use Go models (gpt-5.6-luna, minimax-m3, etc.)
│
├── Free models needed?
│   │
│   ├── Same IP, can switch network? ──YES──> Use VPN or mobile hotspot
│   │   (rate limit appears to be per IP, not per account)
│   │
│   └── Stuck on this IP? ──> Wait or use non-OpenCode providers
│
└── Willing to use other providers?
    ├── Dify         → gpt-4
    ├── littellmott  → qwen3-coder, kimi, deepseek, claude-haiku
    ├── lm-studio    → qwen2.5-coder-7b (local, 192.168.1.2:1234)
    ├── tokenrouter  → openai/gpt-5.6-luna and 6 others (needs its own key)
    └── ollama       → model-router.json has it as fallback
```

## Why this matters

The 2026-09-01 incident (see [incidents/2026-09-01-zen-free-rate-limit.md](./incidents/2026-09-01-zen-free-rate-limit.md))
showed that:

1. **OpenCode Zen free models share a single rate limit** across accounts.
   Both Cuenta A and Cuenta B hit the same `429 FreeUsageLimitError` from
   the same IP. Rotating accounts does not bypass it.
2. **OpenCode Go has a hard monthly cap per account** that resets in
   19-28 days. Rotating accounts does extend total capacity (because
   each account has its own cap), but only if the other account has
   unused quota.
3. **Paid Zen models** require billing balance. Both accounts are
   currently at 0 balance and return 401 `CreditsError`.

`oc-keyring` is correctly configured; the limitations are external to it.

## Workaround 1 — VPN or alternate network

**Hypothesis (unverified)**: the rate limit is per IP address, not per
account. If true, switching to a different IP (VPN, mobile hotspot,
different WiFi network) should release the limit.

**How to test**: enable a VPN, then call a free Zen model from a
PowerShell terminal:

```powershell
oc-keyring probe
```

If `big-pickle` returns 200 instead of 429, the hypothesis is confirmed.

**Caveat**: a VPN with a public/shared IP may already be rate-limited
if other OpenCode users are on the same egress. Mobile hotspot from a
phone is usually a clean IP.

## Workaround 2 — Use other providers in the stack

The `opencode.json` already declares several non-OpenCode providers.
These are independent of OpenCode's quotas and have their own billing.

| Provider ID         | Models                                       | Notes |
| ------------------- | -------------------------------------------- | ----- |
| `Dify`              | gpt-4                                        | Already configured; uses API Gateway |
| `littellmott-nuevo` | qwen3-coder-30b, kimi-2-5, deepseek-v3-2, claude-haiku-4-5, minimax-m2-5 | API Gateway, cost-optimized |
| `lm-studio`         | qwen2.5-coder-7b-instruct                    | Local on 192.168.1.2:1234, no internet needed |
| `tokenrouter`       | openai/gpt-5.6-luna, MiniMax-M3, moonshotai/kimi-k3, qwen/qwen3.8-max-free, qwen/qwen3.8-max, z-ai/glm-5.3, deepseek/deepseek-v4-flash-0731 | **Requires its own tokenrouter key** (different from OpenCode keys) |

To use them in OpenCode Desktop, just pick the model from the picker.
The model-router in `config/model-router.json` also references `ollama`
and `lm-studio2` as fallbacks.

**Probe each provider to verify it still works**:

```powershell
oc-keyring probe
```

shows results for OpenCode providers; non-OpenCode providers need
manual verification.

## Workaround 3 — Load balance on opencode.io

For paid Zen models (claude-sonnet, gpt-5, etc.):

1. Go to `https://opencode.io/auth`
2. Add billing details (auto-reload $20 by default, can disable)
3. Set monthly limit per workspace
4. Wait ~5 minutes for the new balance to propagate

Then the paid Zen models will work, and `oc-keyring` will distribute
the load between Cuenta A and Cuenta B (each consuming its own
balance).

## Workaround 4 — Run a second OpenCode instance

If the rate limit is per IP per process, running a second OpenCode
process might not help. But running OpenCode on a different machine
(different IP) would.

**Not recommended** because:
- Same account logged in on two machines may violate OpenCode's TOS
- Different accounts on two machines defeats the purpose of `oc-keyring`
  (which is single-machine rotation)

## Workaround 5 — Time-based rotation

OpenCode's monthly caps reset on a fixed schedule. If Go caps reset on
the 1st and 15th of the month, the calendar itself becomes the
rotation mechanism:

```powershell
# Days 1-14: use Cuenta A for Go (cap fresh)
oc-keyring switch go A

# Days 15-end: use Cuenta B for Go
oc-keyring switch go B
```

This requires neither `oc-keyring` automation nor any code change —
just a calendar reminder.

## Decision matrix

| Situation | Best workaround | Effort |
| --- | --- | --- |
| Need to work right now, on this IP | Other providers (Dify, lm-studio) | Low — just pick from picker |
| Can switch to mobile hotspot | VPN / hotspot | Low |
| Can wait a few hours | Do nothing | Zero |
| Can spend $5-20 | Load Zen balance | Low — 5 min on opencode.io |
| Have tokenrouter credentials | Switch to tokenrouter models | Low — pick from picker |
| Need a free model right now, no other options | Wait for rate-limit reset | Zero |

## What oc-keyring v1.x does NOT do (intentional)

- It does not retry on 429. (OpenCode client handles this natively.)
- It does not auto-failover between accounts. (User decides.)
- It does not monitor quotas. (OpenCode's dashboard does.)
- It does not bypass rate limits. (Impossible without violating TOS.)

Adding any of those would require deeper integration with OpenCode's
client, which is out of scope for the user-space script.
