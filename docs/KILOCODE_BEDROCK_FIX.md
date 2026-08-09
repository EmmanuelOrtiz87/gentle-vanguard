# KiloCode Bedrock Configuration Fix

## Problem
KiloCode is sending `reasoning_effort` parameter to Bedrock, which doesn't support it.

## Solution Options

### Option 1: KiloCode Provider Settings (RECOMMENDED)

Add this to your VSCode settings.json to configure KiloCode to use drop_params:

```json
{
  "kilo-code.modelSettings": {
    "kimi-2-5": {
      "provider": "bedrock",
      "model": "moonshotai.kimi-k2.5",
      "litellm_settings": {
        "drop_params": true
      }
    }
  },
  "kilo-code.litellm.dropParams": true
}
```

### Option 2: LiteLLM Config File

Create a LiteLLM config file at one of these locations:
- Windows: `%USERPROFILE%\.config\litellm\config.yaml`
- Cross-platform: `~/.litellm_config.yaml`

Content:

```yaml
model_list:
  - model_name: kimi-2-5
    litellm_params:
      model: bedrock/moonshotai.kimi-k2.5
      drop_params: true

litellm_settings:
  drop_params: true
```

### Option 3: Direct Settings in VSCode

In KiloCode's settings, you can often configure the LiteLLM proxy directly. If KiloCode exposes these settings:

1. Open VSCode Settings (Ctrl+,)
2. Search for "kilo" or "kilocode"
3. Look for provider/model settings
4. Add `"drop_params": true` to the model configuration

### Option 4: Environment Variable (Temporary Fix)

Set environment variable before starting VSCode:

```powershell
$env:LITELLM_DROP_PARAMS = "true"
code
```

Or permanently in Windows:
```powershell
[Environment]::SetEnvironmentVariable("LITELLM_DROP_PARAMS", "true", "User")
```

### Option 5: Use Gentle-Vanguard's Native Model (Workaround)

Instead of Bedrock, configure KiloCode to use Gentle-Vanguard's native free model:

```json
{
  "kilo-code.model": "opencode/deepseek-v4-flash-free",
  "kilo-code.provider": "opencode"
}
```

This avoids Bedrock entirely and uses the free model that Gentle-Vanguard manages.

## Immediate Fix

Since the error happens immediately, try **Option 4** first (Environment Variable) as it requires no configuration file changes:

Close VSCode completely, then run in PowerShell:
```powershell
[Environment]::SetEnvironmentVariable("LITELLM_DROP_PARAMS", "true", "User")
code
```

Then try using KiloCode again.

## Verification

After applying any fix, verify it's working:
1. Open a new chat in KiloCode
2. Send a simple message
3. Check that the error about `reasoning_effort` no longer appears

## Notes

- The `drop_params: true` setting tells LiteLLM to automatically discard parameters that the provider doesn't support
- This makes the configuration provider-agnostic
- It's the same setting we applied to all agents in Gentle-Vanguard's opencode.json
