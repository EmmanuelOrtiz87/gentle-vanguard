# Bedrock Provider Normatives

## Overview
This document outlines the normative guidelines and safety guards for Bedrock-compatible providers within the Gentle Vanguard stack.

## Provider Compatibility Standards

### Parameter Restrictions
Providers such as Bedrock and Moonshot AI have specific parameter constraints that must be enforced:
- **Unsupported Parameters**: `reasoning_effort` and similar provider-specific attributes that are not supported by Bedrock
- These parameters must be dropped or filtered when targeting Bedrock-compatible models

### Implementation Requirements

#### 1. Drop Parameters Guardrail
Any request to Bedrock-compatible providers must include configuration that drops unsupported parameters:
```json
{
  "litellm_settings": {
    "drop_params": true
  }
}
```

#### 2. Model-Specific Configuration
When routing to models like `moonshotai.kimi-k2.5`, ensure:
- Model-specific parameter validation occurs
- Invalid parameters for the target provider are stripped
- Fallback to compatible parameter set is implemented

#### 3. Provider Health Monitoring
Configure `model-health.json` to detect and handle provider-specific failures:
- Unsupported parameters error signatures
- Tool calling compatibility issues
- Model availability problems

## Security and Compliance

### Data Protection
- Parameter filtering must not affect the integrity of user inputs
- All sensitive data should remain protected throughout processing
- No unauthorized modifications to request payloads

### Operational Safety
- Fallback mechanisms should be defined for provider failures
- Configuration validation must prevent invalid parameter combinations
- Session scoring should penalize misconfigured providers

## Implementation Example
When using models from Moonshot AI (kimi-2-5), the stack should:
1. Identify the target provider (Bedrock)
2. Apply provider-specific parameter filtering 
3. Strip unsupported parameters like `reasoning_effort`
4. Proceed with compatible request structure

## Related Documents
- `model-health.json` - Provider error detection and handling
- `model-fallback.json` - Fallback chain for Bedrock models
- `correction-rules.json` - Auto-correction on provider errors
- `model-router.json` - Model/temperature routing policy