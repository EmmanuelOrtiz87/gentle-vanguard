@echo off
:: KiloCode Launcher with LiteLLM Configuration
:: This launcher ensures LiteLLM drops unsupported params before starting VSCode

set "LITELLM_DROP_PARAMS=true"
set "LITELLM_CONFIG_PATH=%USERPROFILE%\.config\litellm\config.yaml"
set "LITELLM_VERBOSE=false"

echo ===========================================
echo   KiloCode Bedrock Fix - Launcher
echo ===========================================
echo.
echo Environment variables set:
echo   LITELLM_DROP_PARAMS=%LITELLM_DROP_PARAMS%
echo   LITELLM_CONFIG_PATH=%LITELLM_CONFIG_PATH%
echo.
echo Starting VSCode...
echo.

start "" "%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe"

echo.
echo VSCode launched with Bedrock compatibility fix.
echo.
echo If KiloCode still shows errors:
echo   1. Check that LiteLLM config exists: %LITELLM_CONFIG_PATH%
echo   2. Try using model 'claude-haiku-4-5' instead of 'kimi-2-5'
echo   3. Verify your AWS Bedrock credentials
echo.
pause
