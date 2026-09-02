# oc-keyring

Multi-account rotation for **OpenCode Zen** and **OpenCode Go**.

Solves the problem of having to re-login in opencode.io every time you want to
switch between two or more OpenCode accounts. Once configured, switching is
one command + one click in the OpenCode Desktop model picker.

## Quick start

```powershell
# Add a second account (Cuenta B is the conventional name)
oc-keyring add zen B sk-Vw71cfP9uRFVwNRj3mj1t3u6dHjjSIRUXMD5ice00Z28hLBTBQKyRIaKp9q1XZSb
oc-keyring add go  B sk-Vw71cfP9uRFVwNRj3mj1t3u6dHjjSIRUXMD5ice00Z28hLBTBQKyRIaKp9q1XZSb

# List / status
oc-keyring list
oc-keyring status

# Switch active account
oc-keyring switch zen B

# In OpenCode Desktop: open the model picker, choose any model under
# "OpenCode Zen - Cuenta B". Done.
```

## Documentation

| File | Purpose |
| --- | --- |
| [`guide.md`](./guide.md) | Full user manual: commands, paths, examples, troubleshooting |
| [`architecture.md`](./architecture.md) | Technical decisions, alternatives considered, risks, roadmap |
| [`changelog.md`](./changelog.md) | Version history, audit trail, what was changed and why |
| [`alternatives.md`](./alternatives.md) | Workarounds for external limitations (rate limits, quotas) |
| [`troubleshooting.md`](./troubleshooting.md) | Common issues and their solutions |
| [`business-context.md`](./business-context.md) | Business case, operational impact, security posture |
| [`incidents/2026-09-01-zen-free-rate-limit.md`](./incidents/2026-09-01-zen-free-rate-limit.md) | Post-mortem of the 2026-09-01 rate-limit incident |

## Installation paths

| Component | Path |
| --- | --- |
| Script | `C:\Users\emman\bin\oc-keyring.ps1` |
| Wrapper | `C:\Users\emman\bin\oc-keyring.cmd` |
| Validator | `C:\Users\emman\bin\oc-keyring-validate.ps1` |
| Probe | `C:\Users\emman\bin\probe-keys.ps1` (see troubleshooting) |
| Vault | `%USERPROFILE%\.config\opencode\accounts.json` |
| Config | `%USERPROFILE%\.config\opencode\opencode.json` |
| Auth (auto) | `%USERPROFILE%\.local\share\opencode\auth.json` |
| Backups | `%USERPROFILE%\.local\share\opencode\backups\<timestamp>\` |

## Conventions

- **Cuenta A** = primary account
- **Cuenta B** = secondary account
- Same letter = same account across Zen and Go (recommended, not required)
- Provider ID format: `opencode-<product>-<letter>` (e.g. `opencode-zen-A`)

## Tech debt to stack

**Zero.** This feature lives entirely in user space. No files added to the
gentle-vanguard repository, no model-router changes, no new dependencies.
See [`architecture.md` §5](./architecture.md#5-deuda-técnica-0) for the
full audit.
