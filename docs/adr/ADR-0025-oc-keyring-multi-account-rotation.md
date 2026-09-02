# ADR-0025: oc-keyring — Multi-account rotation for OpenCode via custom providers

## Status

Accepted

## Date

2026-08-31 (initial); 2026-09-01 (revised after rate-limit incident)

## Context

The owner operates two OpenCode accounts simultaneously (Cuenta A =
primary, Cuenta B = secondary), each subscribed to two OpenCode
products (Zen and Go). The official mechanism for switching between
accounts is manual: deslog in opencode.io, log in with the other
account, copy the API key, paste it in OpenCode Desktop's
Connections panel, restart if needed.

The manual flow costs 3-5 minutes per switch, 15-30 minutes per
day, and ~50-100 hours per year. It is also error-prone (pasting
the wrong key, forgetting which account is active) and exposes the
API key in chat/screenshots.

OpenCode's CLI (`opencode auth login -p <provider>`) only allows
one key per provider ID. There is no native multi-account support
in the official client as of v1.18.21.

## Decision — `oc-keyring` v1.0.x (PowerShell script in user space)

We declare **N custom providers** in `~/.config/opencode/opencode.json`
with unique IDs (`opencode-zen-A`, `opencode-zen-B`, `opencode-go-A`,
`opencode-go-B`), each reading its API key from a corresponding
entry in `~/.local/share/opencode/auth.json` (OpenCode's native
credentials file). A PowerShell script manages a vault file
(`accounts.json`) and synchronizes the credentials file.

Result: the model picker in OpenCode Desktop shows 4 distinct
provider groups, and switching accounts is one command + one click.

### Components

| File | Role | Lives in |
| --- | --- | --- |
| `oc-keyring.ps1` | Main script: list/add/remove/switch/sync/probe/validate | `C:\Users\emman\bin\` |
| `oc-keyring.cmd` | Wrapper for shell invocation | `C:\Users\emman\bin\` |
| `accounts.json` | Vault: source of truth for API keys | `~/.config/opencode/` |
| `opencode.json` | Declares 4 custom providers | `~/.config/opencode/` |
| `auth.json` | Auto-generated credentials | `~/.local/share/opencode/` |
| `backups/<ts>/` | Timestamped snapshots | `~/.local/share/opencode/backups/` |

### Conventions

- **Cuenta A** = primary, **Cuenta B** = secondary
- Same letter = same account across Zen and Go (recommended)
- Provider ID: `opencode-<product>-<letter>`
- A = primary, B = secondary
- Provider ID: `opencode-<product>-<letter>`

### Why PowerShell and not a plugin

| Option | Considered | Decision |
| --- | --- | --- |
| Custom OpenCode plugin | Yes | Rejected — runs in OpenCode process, can't safely edit `auth.json` while running |
| Node.js script | Yes | Rejected — adds a runtime dependency |
| PowerShell script | **Yes** | **Selected** — native to Windows, no install, runs externally to OpenCode |
| Bash script | Yes | Rejected — Windows is the primary platform |

## Decision-Revision (2026-09-01) — Add `probe` command

After the rate-limit incident, we add `oc-keyring probe` to provide
fast, direct API diagnosis. The owner should not have to interpret
generic "Provider error" messages from the OpenCode Desktop client.

`oc-keyring probe` calls the OpenCode API directly with each
configured key, reports per-model status (200 / 401 / 429 / 404),
and shows the underlying error message. This distinguishes:

- **401 CreditsError** — billing issue, needs balance load
- **429 FreeUsageLimitError** — rate limit, wait or switch network
- **429 GoUsageLimitError** — monthly cap, wait or upgrade
- **404 ModelError** — model not available, check config

## Consequences

### Positive

- **95%+ reduction in rotation overhead** (3-5 min → 3 sec)
- **Zero copy/paste** of secrets through chat/UI
- **Atomic, reversible changes** (timestamped backups)
- **Zero tech debt to stack** (lives entirely in user space)
- **Documented and self-contained** (architecture, guide, business
  context, troubleshooting, alternatives, incident post-mortem
  all in `docs/operations/oc-keyring/`)

### Negative

- **Does NOT bypass rate limits** for free models. The 2026-09-01
  incident showed that OpenCode's free model rate limit is per-IP,
  not per-account. Rotating accounts gives no benefit for free
  models. (See
  `docs/operations/oc-keyring/incidents/2026-09-01-zen-free-rate-limit.md`.)
- **Does NOT bypass monthly caps** for Go. Each account has its
  own cap, but both are bounded by the same plan limit.
- **Adds a PowerShell dependency** — fine on Windows, would not
  work on macOS/Linux without porting.

### Neutral

- **Maintains backwards compatibility** with the original
  `opencode auth login` flow. Legacy `opencode` and `opencode-go`
  entries in `auth.json` are preserved.
- **Does not modify the stack's `config/model-router.json`**.
  Agents that reference `opencode/big-pickle` continue to use the
  legacy provider, which happens to point to the same Cuenta A
  key.

## Alternatives considered

| Alternative | Pros | Cons | Decision |
| --- | --- | --- | --- |
| Use environment variables to switch keys | Simple | Requires process restart, not configurable from picker | Rejected |
| Fork OpenCode | Full control | Massive maintenance burden | Rejected |
| Wait for OpenCode to ship native multi-account | Clean | No ETA, blocks productivity now | Rejected as sole path |
| Use a single key and split usage manually | Simplest | Defeats the purpose (isolation, capacity) | Rejected |
| PowerShell script in user space | Minimal surface, no stack impact, atomic, auditable | PowerShell-only | **Selected** |

## Compliance

- **No PII or secrets committed**: vault lives in `~/.config/opencode/`,
  which is outside the repository. Backups are in `~/.local/share/opencode/`,
  also outside the repo.
- **Documented in 7 artifacts** (in `docs/operations/oc-keyring/`):
  README, guide, architecture, changelog, troubleshooting, alternatives,
  business-context, plus incident post-mortem.
- **Registered in engram** (gentle-vanguard project) and nexus
  (events table).
- **Zero modifications** to `config/model-router.json`,
  `openspec/`, `config/auto-delegation.json`, or any other stack file.

## Follow-up

- [ ] Investigate whether the rate limit is truly per-IP or
      per-account+IP. Test by changing IP.
- [ ] Watch OpenCode issue
      [#4318](https://github.com/anomalyco/opencode/issues/4318) for
      system-keyring support. When available, port the vault to
      use the OS keyring.
- [ ] Watch for OpenCode native multi-account support. When
      available, deprecate `oc-keyring` in favor of the native
      solution.
- [ ] If the user adopts a third account or a new OpenCode
      product (e.g. Enterprise), update the script and config.

## References

- `docs/operations/oc-keyring/` — full documentation set
- `docs/operations/oc-keyring/incidents/2026-09-01-zen-free-rate-limit.md` — incident post-mortem
- Engram observations #3558, #3559, #3560, #3572 (gentle-vanguard project)
- Nexus event #1295 (architecture.deployed)
- OpenCode docs: `https://opencode.ai/docs/providers/`,
  `https://opencode.ai/docs/cli/`, `https://opencode.ai/docs/zen/`
