# Model Provider Health Runbook

## Purpose

Keep OpenCode model selection usable when a custom provider fails. The stack must keep operating on
the native fallback model while preserving enough evidence to repair the provider deliberately.

## Incident Pattern

Observed error:

```text
litellm.UnsupportedParamsError: Bedrock doesn't support tool calling without `tools=` param specified.
Pass `tools=` param OR set `litellm.modify_params = True` /
`litellm_settings::modify_params: True`
```

In this stack the error appeared for `littellmott-nuevo/kimi-2-5` during an internal OpenCode
`compaction` call. The model provider was marked unhealthy and the active model was switched to
`opencode/deepseek-v4-flash-free`.

## What It Means

- OpenCode was able to recover the session by switching to the native fallback.
- The custom provider itself is not proven healthy until a new request succeeds after the proxy fix.
- For LiteLLM routes backed by Bedrock, the durable fix belongs on the LiteLLM proxy:
  `litellm_settings.modify_params: true`.
- Local OpenCode metadata still matters. Custom provider models should have explicit `id`,
  `tool_call`, and `temperature` fields so the selector does not treat them as ambiguous name-only
  entries.

## Commands

```bash
npm run model:current
npm run model:list
npm run model:validate-provider
npx tsx src/model-provider-healer.ts --status
npx tsx src/model-provider-healer.ts --scan
```

Use this to switch back only after the proxy is fixed:

```bash
npm run model:switch -- littellmott-nuevo/kimi-2-5
```

If it fails again, keep the fallback active and inspect the LiteLLM proxy config before clearing
health state.

## Local Config Requirements

The global OpenCode config at `~/.config/opencode/opencode.json` should keep:

```json
{
  "model": "opencode/deepseek-v4-flash-free",
  "small_model": "opencode/deepseek-v4-flash-free",
  "provider": {
    "custom-provider": {
      "id": "custom-provider",
      "api": "openai",
      "npm": "@ai-sdk/openai-compatible",
      "models": {
        "model-id": {
          "id": "model-id",
          "name": "model-id",
          "tool_call": true,
          "temperature": true
        }
      }
    }
  }
}
```

Do not commit global provider credentials. The validator prints shape only and does not echo keys.

## Validation Gate

Before considering the provider fixed:

```bash
npm run model:validate-provider
npx tsx src/model-provider-healer.ts --status
npm run health:check
```

The stack is operational when the active model is the fallback and health checks pass. The custom
provider is operational only after a successful OpenCode request using that provider.

## Related Fixes

- `model-switch.ts` now updates both `model` and `small_model` together.
- `model-provider-healer.ts` no longer increments detections repeatedly for the same log hit during
  cooldown.
- `dependency-security-enforcer.ts` parses `pnpm audit --json` and `pnpm licenses list --json`
  instead of relying on fragile text matching.
