---
created: 2026-08-08 18:38:31
tags: [engram, bugfix]
engram_id: 2666
type: bugfix
---

# KiloCode Bedrock Fix - Multi-layer Solution

**What**: Created comprehensive fix for KiloCode Bedrock compatibility error "reasoning_effort not supported"

**Why**: KiloCode sending unsupported parameters to Bedrock via LiteLLM

**Where**:
- ~/.config/litellm/config.yaml (global LiteLLM config)
- %APPDATA%/Code/User/globalStorage/kilocode.kilo-code/config.json (KiloCode specific)
- gentle-vanguard/scripts/fix-kilocode-bedrock.ps1 (automated setup)
- gentle-vanguard/scripts/launch-vscode-bedrock-fix.cmd (launcher with env vars)
- gentle-vanguard/scripts/kilocode-bedrock-fix.reg (Windows registry fix)
- gentle-vanguard/docs/KILOCODE_BEDROCK_FIX_COMPLETE.md (documentation)

**Solution**: Multi-layer approach:
1. Global LiteLLM config with drop_params: true
2. KiloCode-specific config pointing to LiteLLM config
3. Environment variables (LITELLM_DROP_PARAMS=true)
4. Registry fix for persistence
5. Launcher script for guaranteed env vars

**Learned**:
- drop_params: true must be set at multiple levels for reliability
- LiteLLM config file location: ~/.config/litellm/config.yaml
- KiloCode globalStorage: %APPDATA%/Code/User/globalStorage/kilocode.kilo-code/
- VSCode must be completely restarted (not just window) for env vars
- Registry fix provides system-wide persistence

---
*Imported from Engram on 2026-09-06*
