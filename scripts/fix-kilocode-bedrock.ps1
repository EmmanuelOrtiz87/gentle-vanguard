# KiloCode Bedrock Fix - Configuration Script
# Version: 2.0.0
# Purpose: Automatically configure KiloCode to work with Bedrock by dropping unsupported parameters

param(
    [switch]$Force = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  KiloCode Bedrock Configuration Fix" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create LiteLLM config directory
$litellmConfigDir = "$env:USERPROFILE\.config\litellm"
Write-Host "[1/5] Creating LiteLLM config directory..." -ForegroundColor Yellow
if (-not (Test-Path $litellmConfigDir)) {
    New-Item -ItemType Directory -Path $litellmConfigDir -Force | Out-Null
    Write-Host "      Created: $litellmConfigDir" -ForegroundColor Green
} else {
    Write-Host "      Directory already exists: $litellmConfigDir" -ForegroundColor Gray
}

# Step 2: Create LiteLLM config.yaml
$litellmConfigPath = "$litellmConfigDir\config.yaml"
Write-Host "[2/5] Creating LiteLLM config.yaml..." -ForegroundColor Yellow

$litellmConfig = @'
# LiteLLM Configuration - Gentle-Vanguard Stack Compatibility
# Version: 2.0.0
# Purpose: Ensure Bedrock compatibility by dropping unsupported parameters

# Global LiteLLM settings
litellm_settings:
  drop_params: true
  verbose: false
  cache: true
  
# Model list with Bedrock-compatible configuration
model_list:
  - model_name: "kimi-2-5"
    litellm_params:
      model: "bedrock/moonshotai.kimi-k2.5"
      drop_params: true
      temperature: 0.3
      max_tokens: 4096
      
  - model_name: "claude-haiku-4-5"
    litellm_params:
      model: "bedrock/anthropic.claude-3-haiku-20240307-v1:0"
      drop_params: true
      temperature: 0.3
      max_tokens: 4096
      
  - model_name: "claude-sonnet"
    litellm_params:
      model: "bedrock/anthropic.claude-3-sonnet-20240229-v1:0"
      drop_params: true
      temperature: 0.3
      max_tokens: 4096
      
  - model_name: "claude-opus"
    litellm_params:
      model: "bedrock/anthropic.claude-3-opus-20240229-v1:0"
      drop_params: true
      temperature: 0.3
      max_tokens: 4096

# Router settings for automatic failover
router_settings:
  routing_strategy: "simple-shuffle"
  enable_cooldowns: true
  cooldown_time: 300
  num_retries: 3
  timeout: 60
'@

$litellmConfig | Set-Content -Path $litellmConfigPath -Force -Encoding UTF8
Write-Host "      Created: $litellmConfigPath" -ForegroundColor Green

# Step 3: Create KiloCode config directory
$kiloCodeDir = "$env:APPDATA\Code\User\globalStorage\kilocode.kilo-code"
Write-Host "[3/5] Creating KiloCode config directory..." -ForegroundColor Yellow
if (-not (Test-Path $kiloCodeDir)) {
    New-Item -ItemType Directory -Path $kiloCodeDir -Force | Out-Null
    Write-Host "      Created: $kiloCodeDir" -ForegroundColor Green
} else {
    Write-Host "      Directory already exists: $kiloCodeDir" -ForegroundColor Gray
}

# Step 4: Create KiloCode config.json
$kiloCodeConfigPath = "$kiloCodeDir\config.json"
Write-Host "[4/5] Creating KiloCode config.json..." -ForegroundColor Yellow

$kiloCodeConfig = @'
{
  "version": "2.0.0",
  "provider": "bedrock",
  "model": "bedrock/moonshotai.kimi-k2.5",
  "litellm_config_path": "~/.config/litellm/config.yaml",
  "litellm_settings": {
    "drop_params": true,
    "verbose": false,
    "cache": true
  },
  "model_settings": {
    "kimi-2-5": {
      "temperature": 0.3,
      "max_tokens": 4096,
      "drop_params": true
    },
    "claude-haiku-4-5": {
      "temperature": 0.3,
      "max_tokens": 4096,
      "drop_params": true
    },
    "claude-sonnet": {
      "temperature": 0.3,
      "max_tokens": 4096,
      "drop_params": true
    },
    "claude-opus": {
      "temperature": 0.3,
      "max_tokens": 4096,
      "drop_params": true
    }
  },
  "dropped_params": [
    "reasoning_effort",
    "logprobs",
    "logit_bias",
    "user",
    "response_format",
    "seed",
    "tools",
    "tool_choice"
  ]
}
'@

$kiloCodeConfig | Set-Content -Path $kiloCodeConfigPath -Force -Encoding UTF8
Write-Host "      Created: $kiloCodeConfigPath" -ForegroundColor Green

# Step 5: Set environment variable
Write-Host "[5/5] Setting environment variables..." -ForegroundColor Yellow

# Set for current session
$env:LITELLM_DROP_PARAMS = "true"
$env:LITELLM_CONFIG_PATH = $litellmConfigPath

# Set for future sessions
[Environment]::SetEnvironmentVariable("LITELLM_DROP_PARAMS", "true", "User")
[Environment]::SetEnvironmentVariable("LITELLM_CONFIG_PATH", "%USERPROFILE%\.config\litellm\config.yaml", "User")

Write-Host "      Set: LITELLM_DROP_PARAMS=true" -ForegroundColor Green
Write-Host "      Set: LITELLM_CONFIG_PATH=%USERPROFILE%\.config\litellm\config.yaml" -ForegroundColor Green

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  Configuration Complete!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Completely close VSCode (including tray icon)" -ForegroundColor White
Write-Host "  2. Wait 5 seconds" -ForegroundColor White
Write-Host "  3. Reopen VSCode" -ForegroundColor White
Write-Host "  4. Try using KiloCode again" -ForegroundColor White
Write-Host ""
Write-Host "If the issue persists, try:" -ForegroundColor Yellow
Write-Host "  - Using a different model (e.g., claude-haiku-4-5)" -ForegroundColor Gray
Write-Host "  - Checking KiloCode settings in VSCode" -ForegroundColor Gray
Write-Host "  - Verifying AWS Bedrock credentials" -ForegroundColor Gray
Write-Host ""
Write-Host "Config files created:" -ForegroundColor Cyan
Write-Host "  - $litellmConfigPath" -ForegroundColor Gray
Write-Host "  - $kiloCodeConfigPath" -ForegroundColor Gray
