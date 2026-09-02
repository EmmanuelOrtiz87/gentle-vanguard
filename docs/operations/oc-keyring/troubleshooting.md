# oc-keyring — Troubleshooting

Common issues and their solutions. Updated as new incidents are resolved.

## Quick diagnostic command

```powershell
oc-keyring probe
```

This runs a direct API probe against OpenCode's endpoints with each of your configured keys and
reports per-model status. It's the fastest way to distinguish between:

- Auth problems (401, 403)
- Quota exhaustion (429, `FreeUsageLimitError`, `GoUsageLimitError`)
- Credit problems (401, `CreditsError`)
- Provider misconfiguration (404, `ModelError`)

## Issue: Free model returns "no quota/credit" or "rate limit exceeded"

**Symptom**: Big Pickle or other free model returns an error like "no tengo cupo", "no credits", or
"Rate limit exceeded". Affects both Cuenta A and Cuenta B identically.

**Cause**: OpenCode Zen free models share a single rate limit per IP (see
[incidents/2026-09-01-zen-free-rate-limit.md](./incidents/2026-09-01-zen-free-rate-limit.md)).
Rotating between accounts does NOT bypass it.

**Verify with probe**:

```powershell
oc-keyring probe
```

Expect `429 FreeUsageLimitError` for big-pickle, mimo-v2.5-free, etc.

**Solutions** (in order of preference):

1. Wait — rate limits reset, typically within hours
2. Switch network (VPN, mobile hotspot) — if rate limit is per IP
3. Use non-OpenCode providers (see [alternatives.md](./alternatives.md))
4. Load Zen billing to use paid models

## Issue: Paid model returns "Insufficient balance"

**Symptom**: Models like `claude-sonnet-4-5`, `gpt-5`, `deepseek-v4-pro` return
`401 CreditsError: Insufficient balance`.

**Cause**: The account has no billing balance on opencode.io.

**Verify with probe**:

```powershell
oc-keyring probe
```

Expect `401 CreditsError` for paid models.

**Solution**:

1. Go to `https://opencode.io/auth`
2. Add a payment method
3. Set a monthly limit if desired
4. Balance propagates in ~5 minutes

## Issue: Go model returns "Monthly usage limit reached"

**Symptom**: `gpt-5.6-luna`, `minimax-m3`, etc. return
`429 GoUsageLimitError: Monthly usage limit reached. Resets in N days.`

**Cause**: OpenCode Go has a per-account monthly cap. Once hit, the account is rate-limited until
the billing cycle resets.

**Verify with probe**:

```powershell
oc-keyring probe
```

Expect `429 GoUsageLimitError` with `Resets in N days`.

**Solutions**:

1. **Rotate to the other account** (if its cap isn't exhausted) — this is the only case where
   `oc-keyring` actually helps. `oc-keyring switch go B` (assuming Cuenta A is the exhausted one)
2. Upgrade the Go plan on opencode.io
3. Wait for the reset date

## Issue: Custom provider not showing in picker

**Symptom**: After running `oc-keyring add`, the new provider doesn't appear in OpenCode Desktop's
model picker.

**Cause**: OpenCode Desktop caches the model list at startup.

**Solution**:

1. Close OpenCode Desktop fully (Cmd+Q / Alt+F4)
2. Reopen OpenCode Desktop
3. The new provider should be visible

If still missing, verify:

```powershell
& "C:\Users\emman\AppData\Local\Microsoft\WinGet\Links\opencode.exe" auth list
& "C:\Users\emman\AppData\Local\Microsoft\WinGet\Links\opencode.exe" models
```

## Issue: "Confirm-Action" fails in non-interactive shell

**Symptom**: Running `oc-keyring remove` from a script or CI hangs on a confirmation prompt that
never appears.

**Cause**: `Read-Host` doesn't work when PowerShell is in NonInteractive mode.

**Solution**: Pass `-Force` or set the env var:

```powershell
oc-keyring remove zen B -Force
# or
$env:OC_KEYRING_FORCE = '1'; oc-keyring remove zen B
```

## Issue: Vault gets out of sync with auth.json

**Symptom**: You edited `accounts.json` by hand but `auth.json` doesn't reflect the changes.

**Solution**:

```powershell
oc-keyring sync
```

This rebuilds `auth.json` from the vault. A backup is created automatically before the write.

## Issue: Lost the API key for a cuenta

**Symptom**: You need to recover a key but the original is gone.

**Solution**:

1. Check the latest backup: `~/.local/share/opencode/backups/<latest>/auth.json`
2. Or re-login to opencode.io with that account, create a new key, and update with
   `oc-keyring add <zen|go> <letter> sk-<new-key>`

## Issue: Want to use a model not in the curated list

**Symptom**: The model picker shows a subset of OpenCode's 94 Zen models. You want to use one that's
not curated.

**Solution**: Edit `~/.config/opencode/opencode.json` and add the model to the relevant provider
block. The `npm` field defaults to the provider's `npm`; override per-model only for special cases
like muse-spark-1.2-contributor-free (which needs `@ai-sdk/openai`).

After editing, close and reopen OpenCode Desktop.

## Issue: First free model in picker is wrong

**Symptom**: `oc-keyring switch` sets `opencode.json.model` to a model you didn't expect (e.g.,
`qwen3.8-max` instead of `gpt-5.6-luna`).

**Cause**: This was a bug in v1.0.0. Fixed in v1.0.1 by using `[ordered]@{}` for the default model
lists.

**Solution**: Update to v1.0.1+ (the current `oc-keyring.ps1`):

```powershell
# Check version: look at the top of the script
Get-Content C:\Users\emman\bin\oc-keyring.ps1 | Select-Object -First 5
```

If you have an older version, replace the file with the one in this documentation set.

## Issue: Backup count growing too large

**Symptom**: `~/.local/share/opencode/backups/` has hundreds of timestamped directories.

**Solution**:

```powershell
# Remove backups older than 30 days
Get-ChildItem "$env:USERPROFILE\.local\share\opencode\backups" |
  Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
  Remove-Item -Recurse -Force
```

The script does NOT auto-prune backups. This is intentional — you decide when to clean them.

## Getting more help

1. Run `oc-keyring probe` and capture the output
2. Read the relevant section above
3. If the issue is not listed, check [incidents/](./incidents/) for similar past incidents
4. If still stuck, file an issue with:
   - The output of `oc-keyring status`
   - The output of `oc-keyring probe`
   - The exact error message from OpenCode Desktop
