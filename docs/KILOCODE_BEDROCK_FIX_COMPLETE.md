# KiloCode Bedrock Fix - Opt-in Solution

# Version: 2.0.0

# Date: 2026-08-08

# Author: Gentle-Vanguard Stack

## 🚨 Problem

KiloCode throws error when using Bedrock models:

```
litellm.UnsupportedParamsError: bedrock does not support parameters: ['reasoning_effort']
```

## ✅ Solution Implemented

We've created a multi-layer fix that ensures `drop_params: true` is applied at every level:

### Files Created

| File                              | Purpose                                | Location                                                           |
| --------------------------------- | -------------------------------------- | ------------------------------------------------------------------ |
| `~/.config/litellm/config.yaml`   | LiteLLM master config with drop_params | `%USERPROFILE%\.config\litellm\config.yaml`                        |
| `KiloCode config.json`            | KiloCode-specific settings             | `%APPDATA%\Code\User\globalStorage\kilocode.kilo-code\config.json` |
| `src/cli/fix-kilocode-bedrock.ts` | Dry-run-by-default configuration CLI   | Repository source                                                  |

## 🚀 Immediate Action Required

### Step 1: Review and apply the fix

The CLI makes no changes by default. Review the planned paths first:

```powershell
npx tsx src/cli/fix-kilocode-bedrock.ts
```

Apply only after explicit confirmation:

```powershell
npx tsx src/cli/fix-kilocode-bedrock.ts --apply
```

The apply mode always asks for confirmation. Existing files are renamed to a timestamped `.bak-*`
file before replacement. No credentials or keys are written.

### Step 2: Restart VSCode Properly

**Important**: You must completely restart VSCode for the changes to take effect.

1. **Close VSCode completely**
   - Close all VSCode windows
   - Check system tray (may have icon there)
   - Kill any remaining VSCode processes:

     ```powershell
     Get-Process code | Stop-Process -Force
     ```

2. **Wait 5 seconds**

3. **Reopen VSCode**

4. **Test KiloCode**
   - Open a new conversation
   - Send a simple message
   - The error should be gone

## 🔧 If the Error Persists

### Option A: Use a Different Model

In KiloCode settings, change the model to:

- `claude-haiku-4-5` instead of `kimi-2-5`
- Or use `claude-sonnet`
- Or use `claude-opus`

All these have `drop_params: true` configured.

## 📋 What Was Fixed

### Root Cause

LiteLLM was sending the `reasoning_effort` parameter to Bedrock, which doesn't support it. The
parameter comes from OpenAI's API but isn't compatible with Bedrock.

### Solution

1. **Global LiteLLM Config** (`~/.config/litellm/config.yaml`):
   - Sets `drop_params: true` globally
   - Configures all Bedrock models with proper settings
   - Includes router settings for automatic failover

2. **KiloCode Config** (`config.json`):
   - KiloCode-specific settings
   - Points to the LiteLLM config
   - Lists parameters to drop

3. **Environment Variables**:
   - `LITELLM_DROP_PARAMS=true`
   - `LITELLM_CONFIG_PATH` pointing to the config

4. **Registry Fix** (optional):
   - Sets environment variables system-wide
   - Persistent across reboots

## 🔍 Verification

After applying the fix and restarting VSCode:

1. Open PowerShell in VSCode terminal:

   ```powershell
   $env:LITELLM_DROP_PARAMS
   ```

   Should output: `true`

2. Check LiteLLM config exists:

   ```powershell
   Test-Path ~/.config/litellm/config.yaml
   ```

   Should output: `True`

3. Try KiloCode - the error should be gone

## 📝 Configuration Details

### LiteLLM Config Structure

```yaml
litellm_settings:
  drop_params: true # <-- This is the key setting
  verbose: false
  cache: true

model_list:
  - model_name: 'kimi-2-5'
    litellm_params:
      model: 'bedrock/moonshotai.kimi-k2.5'
      drop_params: true # <-- Also set per-model
      temperature: 0.3
      max_tokens: 4096
```

### What `drop_params: true` Does

- Intercepts all API calls before sending to the provider
- Removes parameters not supported by the specific provider
- Logs which parameters were dropped (if verbose mode enabled)
- Allows your code to be **provider-agnostic**

## 🌐 Compatibility

This fix makes KiloCode compatible with:

- ✅ AWS Bedrock
- ✅ OpenAI API
- ✅ Anthropic API
- ✅ Any LiteLLM-compatible provider

## 🎯 Next Steps

1. ⏳ Review and explicitly apply the fix
2. ⏳ Restart VSCode completely
3. ⏳ Test KiloCode
4. (Optional) Apply registry fix for persistence

## 📞 Troubleshooting

| Problem                  | Solution                                                 |
| ------------------------ | -------------------------------------------------------- |
| Still getting error      | Restart computer after applying registry fix             |
| Config file not found    | Run the TypeScript CLI and review its dry-run paths      |
| Different model error    | Change model in KiloCode settings to one from the config |
| Environment vars not set | Re-run the TypeScript CLI with `--apply` and confirm     |

## 🔒 Security Notes

- The CLI changes user configuration only after `--apply` and confirmation
- No passwords or keys are stored
- All config files are local to your machine
- Timestamped backups are created before existing files are replaced

## 🎉 Expected Result

After completing Step 2 (Restart VSCode):

- ✅ No more `reasoning_effort` errors
- ✅ KiloCode works with Bedrock models
- ✅ All agent delegations work normally
- ✅ Token budget tracking works correctly

---

**Ready to test?** Please completely restart VSCode now and let me know if KiloCode works.
