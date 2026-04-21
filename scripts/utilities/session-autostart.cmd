@echo off
setlocal

set SCRIPT=%~dp0session-manager.ps1
set OPTIMIZE_SCRIPT=%~dp0optimize-engram-usage.ps1

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

REM Ejecutar backup automático de Engram
echo [INFO] Checking Engram backup status...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\monitoring\engram-backup-manager.ps1" -Action auto-sync

REM Validar consistencia cross-workspace
echo [INFO] Validating cross-workspace consistency...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\monitoring\cross-workspace-validator.ps1"

REM Marcar sesión como activa
echo [INFO] Marking session as active...
if not exist "logs" mkdir logs
echo %date% %time% > logs\.session-active

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Mode AutoStart
exit /b %errorlevel%