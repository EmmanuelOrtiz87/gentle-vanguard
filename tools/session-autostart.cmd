@echo off
setlocal

set SCRIPT=%~dp0session-manager.ps1
set OPTIMIZE_SCRIPT=%~dp0optimize-engram-usage.ps1
set TOKEN_GUARD_SCRIPT=%~dp0token-guard.ps1

echo === Session Autostart with Engram Optimization ===

if not exist "%SCRIPT%" (
  echo [ERROR] session-manager.ps1 not found: %SCRIPT%
  echo.
  echo Manual fallback:
  echo   1^) powershell -NoProfile -ExecutionPolicy Bypass -File ".\tools\enforce-response-mode.ps1"
  echo   2^) powershell -NoProfile -ExecutionPolicy Bypass -File ".\workspace-foundation\scripts\utilities\wf.ps1" health
  echo   3^) powershell -NoProfile -ExecutionPolicy Bypass -File ".\workspace-foundation\scripts\utilities\wf.ps1" start-session
  exit /b 1
)

REM Ejecutar optimización de Engram antes del inicio de sesión
if exist "%OPTIMIZE_SCRIPT%" (
  echo [INFO] Running Engram optimization pre-session...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%OPTIMIZE_SCRIPT%" -ProjectName "workspace_local"
)

REM Validar consistencia cross-workspace
echo [INFO] Validating cross-workspace consistency...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\monitoring\cross-workspace-validator.ps1"

REM Inicializar sesión
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Mode AutoStart

REM Extraer SessionId del archivo de sesión
for /f "tokens=*" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path '.\.session\session-*.json') { Get-ChildItem '.\.session\session-*.json' -File | Select-Object -Last 1 | ForEach-Object { $_.BaseName } }"') do set SESSION_ID=%%i

REM Inicializar Token Guard para protección de tokens
echo [INFO] Initializing Token Guard...
if exist "%TOKEN_GUARD_SCRIPT%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%TOKEN_GUARD_SCRIPT%" -ConfigPath "tools/token-guard-config.json" -SessionId "%SESSION_ID%" -Mode "monitor"
) else (
  echo [WARNING] Token Guard script not found: %TOKEN_GUARD_SCRIPT%
)

REM Inicializar Adaptive Mode Mejorado
echo [INFO] Initializing Adaptive Mode Orchestrator...
set ADAPTIVE_MODE_SCRIPT=.\skills\adaptive-mode-orchestrator\adaptive-mode-engine.ps1
if exist "%ADAPTIVE_MODE_SCRIPT%" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%ADAPTIVE_MODE_SCRIPT%" -DryRun -ConfigPath "config/adaptive-dag-config.json"
  if errorlevel 1 (
    echo [WARNING] Adaptive Mode initialization completed with warnings
  ) else (
    echo [INFO] Adaptive Mode initialized successfully
  )
) else (
  echo [WARNING] Adaptive Mode script not found: %ADAPTIVE_MODE_SCRIPT%
)

REM Inicializar orquestador y delegación automática
echo [INFO] Initializing orchestrator and auto-delegation...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module '.\skills\auto-delegation-router\auto-delegation-router.ps1' -Force; Enable-AutoDelegation -ConfigPath 'config/auto-delegation.json' | Out-Null; Write-Host '[ORCHESTRATOR] Auto-delegation enabled' -ForegroundColor Green; Write-Host '[ORCHESTRATOR] Stack ready for automated operations' -ForegroundColor Green"

exit /b %errorlevel%
